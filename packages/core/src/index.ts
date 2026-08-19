/**
 * @afia/core — domain model, state machines, store, audit trail, seed data.
 * FHIR-shaped (§3.1), constraint-enforcing at the model layer (§2).
 */
export * from './priority'
export * from './ids'
export * from './entities'
export * from './handover'
export * from './case'
export * from './audit'
export * from './store'
export * from './seed'
// NOTE: the Firebase-backed store lives in '@afia/core/src/firebase' as a
// separate entry point, so apps that run local-only never bundle the SDK.
