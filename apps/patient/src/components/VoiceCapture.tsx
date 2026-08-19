import { useEffect, useRef, useState } from 'react'
import { BrowserTranscriber, mergeSegments } from '@afia/ai'
import { newId, type AudioRecording } from '@afia/core'

/**
 * Big Record / Stop control. Uses the browser transcriber when available and
 * captures mic audio via MediaRecorder (data-URI AudioRecording) when the
 * microphone is permitted. Recording is optional — typing is always enough,
 * and the parent renders the textarea. Every final speech segment is pushed
 * up through onTranscript so it persists immediately (F-055).
 */
export function VoiceCapture({
  transcript,
  onTranscript,
  audio,
  onAudio,
}: {
  transcript: string
  onTranscript: (text: string) => void
  audio: AudioRecording | null
  onAudio: (a: AudioRecording) => void
}) {
  const [recording, setRecording] = useState(false)
  const [interim, setInterim] = useState('')
  const [note, setNote] = useState<string | null>(null)

  const transcriberRef = useRef<BrowserTranscriber | null>(null)
  const recorderRef = useRef<MediaRecorder | null>(null)
  const chunksRef = useRef<Blob[]>([])
  const startedAtRef = useRef(0)
  const interimRef = useRef('')

  // Keep latest values reachable from long-lived callbacks.
  const latest = useRef({ transcript, onTranscript, onAudio })
  useEffect(() => {
    latest.current = { transcript, onTranscript, onAudio }
  })

  useEffect(
    () => () => {
      transcriberRef.current?.stop()
      const r = recorderRef.current
      if (r !== null && r.state !== 'inactive') r.stop()
    },
    [],
  )

  const appendFinal = (text: string) => {
    const merged = mergeSegments([latest.current.transcript, text])
    latest.current.onTranscript(merged)
  }

  const startCapture = async () => {
    setNote(null)
    const t = new BrowserTranscriber()
    transcriberRef.current = t
    if (t.available()) {
      t.start(
        (text, isFinal) => {
          if (isFinal) {
            appendFinal(text)
            interimRef.current = ''
            setInterim('')
          } else {
            interimRef.current = text
            setInterim(text)
          }
        },
        (message) => setNote(message),
      )
    } else {
      setNote(
        'Voice-to-text is not available in this browser. Your voice can still be recorded, and typing below works just as well.',
      )
    }

    // Mic audio → data-URI AudioRecording. Optional: failure is fine, typing is enough.
    try {
      if (navigator.mediaDevices !== undefined) {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
        const rec = new MediaRecorder(stream)
        chunksRef.current = []
        rec.ondataavailable = (e) => {
          if (e.data.size > 0) chunksRef.current.push(e.data)
        }
        rec.onstop = () => {
          for (const track of stream.getTracks()) track.stop()
          const blob = new Blob(chunksRef.current, { type: rec.mimeType !== '' ? rec.mimeType : 'audio/webm' })
          if (blob.size === 0) return
          const reader = new FileReader()
          reader.onloadend = () => {
            if (typeof reader.result === 'string') {
              latest.current.onAudio({
                id: newId('audio'),
                url: reader.result,
                mimeType: blob.type,
                durationSec: Math.max(1, Math.round((Date.now() - startedAtRef.current) / 1000)),
                recordedAt: Date.now(),
              })
            }
          }
          reader.readAsDataURL(blob)
        }
        startedAtRef.current = Date.now()
        rec.start()
        recorderRef.current = rec
      }
    } catch {
      // Microphone declined or unavailable — no problem, typing is enough.
    }
    setRecording(true)
  }

  const stopCapture = () => {
    transcriberRef.current?.stop()
    transcriberRef.current = null
    const r = recorderRef.current
    if (r !== null && r.state !== 'inactive') r.stop()
    recorderRef.current = null
    if (interimRef.current.trim() !== '') {
      appendFinal(interimRef.current)
      interimRef.current = ''
    }
    setInterim('')
    setRecording(false)
  }

  return (
    <div className="voice-box">
      {audio !== null && !recording ? (
        <audio className="voice-audio" controls src={audio.url} aria-label="Your recording" />
      ) : null}
      <button
        type="button"
        className={recording ? 'record-btn record-btn--stop' : 'record-btn'}
        onClick={() => {
          if (recording) stopCapture()
          else void startCapture()
        }}
      >
        {recording ? 'Stop recording' : audio !== null ? 'Record again' : 'Start talking'}
      </button>
      {recording ? (
        <p className="hint" aria-live="polite">
          Listening — speak naturally, take your time.
          {interim !== '' ? ` “${interim}”` : ''}
        </p>
      ) : null}
      {note !== null ? <p className="hint">{note}</p> : null}
    </div>
  )
}
