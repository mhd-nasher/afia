/**
 * @afia/rules — pure, deterministic, dependency-free clinical rules.
 *
 * This package is the part a regulator would examine (HANDOFF §8). Everything
 * here is a pure function: same input → same output, no I/O, no network, no
 * model inference. It works in airplane mode by construction.
 */
export * from './answer'
export * from './redFlags'
export * from './gaps'
export * from './formulary'
export * from './chips'
export * from './queue'
export * from './wellbeing'
