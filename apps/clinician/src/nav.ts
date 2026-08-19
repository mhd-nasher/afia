/**
 * Screen switching is plain React state — no router library (stack rule).
 */

export type Screen =
  | { name: 'ward' }
  | { name: 'patient'; patientId: string }
  | { name: 'recording'; handoverId: string }
  | { name: 'draft'; handoverId: string }
  | { name: 'received' }
  | { name: 'receivedDetail'; handoverId: string }
  | { name: 'shift' }
  | { name: 'account' }
  | { name: 'template' }

export type TabName = 'patients' | 'received' | 'shift' | 'account'

export type Go = (screen: Screen) => void

export const TAB_OF: Record<Screen['name'], TabName> = {
  ward: 'patients',
  patient: 'patients',
  recording: 'patients',
  draft: 'patients',
  received: 'received',
  receivedDetail: 'received',
  shift: 'shift',
  account: 'account',
  template: 'account',
}
