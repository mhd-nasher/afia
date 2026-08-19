import { useEffect, useRef, useState, type ReactNode } from 'react'
import type { AudioRecording, Practitioner } from '@afia/core'
import { BrowserTranscriber, KeywordStructurer, mergeSegments } from '@afia/ai'
import type { Go } from '../nav'
import { store } from '../store'
import { blobToDataUrl, fmtElapsed } from '../lib'
import { MissingRecord } from '../bits'

const CHECKPOINT_MS = 3000

/**
 * Screen 3 — recording. Near-empty: a large elapsed timer, a subtle live
 * transcript, one big Stop. Speech via BrowserTranscriber when available,
 * ALWAYS a visible typing fallback, microphone captured via MediaRecorder
 * when permitted, and an auto-checkpoint every 3 seconds so putting the
 * device down is safe (F-033).
 */
export function RecordingScreen({
  handoverId,
  practitioner,
  go,
}: {
  handoverId: string
  practitioner: Practitioner
  go: Go
}): ReactNode {
  const handover = store.handover(handoverId)

  const [elapsed, setElapsed] = useState(0)
  const [segments, setSegments] = useState<string[]>(() =>
    handover !== undefined && handover.transcript.trim() !== '' ? [handover.transcript] : [],
  )
  const [interim, setInterim] = useState('')
  const [typed, setTyped] = useState('')
  const [speechState, setSpeechState] = useState<'listening' | 'unavailable' | 'error'>('unavailable')
  const [micState, setMicState] = useState<'pending' | 'on' | 'denied'>('pending')
  const [stopping, setStopping] = useState(false)

  const transcriberRef = useRef<BrowserTranscriber | null>(null)
  const recorderRef = useRef<MediaRecorder | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const chunksRef = useRef<Blob[]>([])
  const startedAtRef = useRef(Date.now())
  const stoppingRef = useRef(false)

  // Latest composed transcript, readable from interval/stop callbacks.
  const composed = mergeSegments([...segments, interim, typed])
  const composedRef = useRef(composed)
  composedRef.current = composed

  // Elapsed timer.
  useEffect(() => {
    const t = window.setInterval(() => setElapsed((s) => s + 1), 1000)
    return () => window.clearInterval(t)
  }, [])

  // Auto-checkpoint every 3 s while still recording.
  useEffect(() => {
    const t = window.setInterval(() => {
      const current = store.handover(handoverId)
      if (current !== undefined && current.status === 'recording' && !stoppingRef.current) {
        store.updateDraft(handoverId, { transcript: composedRef.current }, practitioner.id)
      }
    }, CHECKPOINT_MS)
    return () => window.clearInterval(t)
  }, [handoverId, practitioner.id])

  // Live speech recognition, when the browser offers it.
  useEffect(() => {
    const t = new BrowserTranscriber()
    transcriberRef.current = t
    if (t.available()) {
      setSpeechState('listening')
      t.start(
        (text, isFinal) => {
          if (isFinal) {
            setSegments((prev) => [...prev, text.trim()])
            setInterim('')
          } else {
            setInterim(text)
          }
        },
        () => setSpeechState('error'),
      )
    }
    return () => t.stop()
  }, [])

  // Microphone capture — §2.6: the raw audio is stored and delivered playable.
  useEffect(() => {
    let cancelled = false
    if (
      typeof navigator.mediaDevices?.getUserMedia === 'function' &&
      typeof window.MediaRecorder === 'function'
    ) {
      navigator.mediaDevices
        .getUserMedia({ audio: true })
        .then((stream) => {
          if (cancelled) {
            stream.getTracks().forEach((track) => track.stop())
            return
          }
          streamRef.current = stream
          const rec = new MediaRecorder(stream)
          rec.ondataavailable = (e: BlobEvent) => {
            if (e.data.size > 0) chunksRef.current.push(e.data)
          }
          rec.start()
          recorderRef.current = rec
          setMicState('on')
        })
        .catch(() => setMicState('denied'))
    } else {
      setMicState('denied')
    }
    return () => {
      cancelled = true
      const rec = recorderRef.current
      if (rec !== null && rec.state !== 'inactive') rec.stop()
      streamRef.current?.getTracks().forEach((track) => track.stop())
    }
  }, [])

  if (handover === undefined) return <MissingRecord go={go} />

  const stop = async (): Promise<void> => {
    if (stoppingRef.current) return
    stoppingRef.current = true
    setStopping(true)

    transcriberRef.current?.stop()

    let audio: AudioRecording | null = null
    const rec = recorderRef.current
    if (rec !== null && rec.state !== 'inactive') {
      const blob = await new Promise<Blob>((resolve) => {
        rec.onstop = () =>
          resolve(new Blob(chunksRef.current, { type: rec.mimeType || 'audio/webm' }))
        rec.stop()
      })
      streamRef.current?.getTracks().forEach((track) => track.stop())
      if (blob.size > 0) {
        try {
          const url = await blobToDataUrl(blob)
          audio = {
            id: `audio-${handoverId}-${Date.now()}`,
            url,
            mimeType: blob.type || 'audio/webm',
            durationSec: Math.max(1, Math.round((Date.now() - startedAtRef.current) / 1000)),
            recordedAt: startedAtRef.current,
          }
        } catch {
          audio = null // typing-only path still completes
        }
      }
    }

    // Merge interrupted segments in order, structure into the template, save.
    const transcript = mergeSegments([...segments, interim, typed])
    const fields = new KeywordStructurer().structure(transcript, store.template())
    store.updateDraft(
      handoverId,
      audio !== null ? { transcript, fields, audio } : { transcript, fields },
      practitioner.id,
    )
    store.setHandoverStatus(handoverId, 'draft_ready', practitioner.id)
    go({ name: 'draft', handoverId })
  }

  const patient = store.patient(handover.patientId)
  const liveText = mergeSegments([...segments, interim])

  return (
    <div className="rec">
      <p className="rec__patient">
        Recording — {patient?.name ?? 'patient'} {patient !== undefined ? `(bed ${patient.bed})` : ''}
      </p>
      <div className="rec__timer" aria-live="off">
        {fmtElapsed(elapsed)}
      </div>
      <p className="rec__status">
        {speechState === 'listening'
          ? 'Listening…'
          : 'Speech recognition unavailable in this browser'}
        {' · '}
        {micState === 'on'
          ? 'audio is being captured'
          : micState === 'pending'
            ? 'requesting microphone…'
            : 'microphone unavailable — no audio will be attached'}
        {' · auto-saves every 3 s'}
      </p>

      <div className="rec__live">{liveText === '' ? 'Speak naturally — the transcript appears here.' : liveText}</div>

      <label className="rec__typed-label" htmlFor="rec-typed">
        Type instead (speech unavailable or noisy ward)
      </label>
      <textarea
        id="rec-typed"
        className="rec__typed"
        value={typed}
        onChange={(e) => setTyped(e.target.value)}
        placeholder="Anything typed here is merged into the handover…"
      />

      <button
        type="button"
        className="rec__stop"
        onClick={() => {
          void stop()
        }}
        disabled={stopping}
      >
        {stopping ? 'Structuring…' : 'Stop'}
      </button>
    </div>
  )
}
