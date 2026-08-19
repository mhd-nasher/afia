import type { AudioRecording } from '@afia/core'
import { VoiceCapture } from '../components/VoiceCapture'

/**
 * Voice description (and the "what has changed" delta capture — same screen,
 * different words). Big Record/Stop, and ALWAYS a large textarea:
 * "Type instead if talking is hard right now." Recording is optional,
 * typing is enough. Every keystroke and speech segment persists (F-055).
 */
export function DescribeScreen({
  eyebrow,
  title,
  lead,
  transcript,
  audio,
  continueLabel,
  onTranscript,
  onAudio,
  onContinue,
}: {
  eyebrow: string
  title: string
  lead: string
  transcript: string
  audio: AudioRecording | null
  continueLabel: string
  onTranscript: (t: string) => void
  onAudio: (a: AudioRecording) => void
  onContinue: () => void
}) {
  return (
    <div className="stack">
      <p className="eyebrow">{eyebrow}</p>
      <h1>{title}</h1>
      <p>{lead}</p>

      <VoiceCapture
        transcript={transcript}
        onTranscript={onTranscript}
        audio={audio}
        onAudio={onAudio}
      />

      <div>
        <label className="field-label" htmlFor="describe-text">
          Type instead if talking is hard right now
        </label>
        <textarea
          id="describe-text"
          value={transcript}
          onChange={(e) => onTranscript(e.target.value)}
          rows={6}
        />
      </div>

      <button type="button" className="btn-primary" onClick={onContinue}>
        {continueLabel}
      </button>
    </div>
  )
}
