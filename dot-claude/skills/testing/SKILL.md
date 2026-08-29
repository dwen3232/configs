---
name: testing
description: >
  Load this skill when you are about to write or edit test code — including new
  test files, adding test cases, or modifying existing tests. Load it
  proactively before writing tests even if the user hasn't mentioned testing
  explicitly. Do not load for one-off shell scripts or ad-hoc commands that are
  not part of a repeatable test suite.

  Examples of when to load this skill:
  - "write tests for this function"
  - "add unit tests"
  - "update the tests to cover this new behavior"
  - "fix the failing test"
  - "add test coverage for the edge case"
  - You are about to create or edit a test file as part of implementing a feature or fixing a bug
---

# Testing Philosophy

## DAMP over DRY

Tests should prioritize readability over eliminating repetition. Unlike
production code, tests have no tests of their own — a reader must be able to
verify correctness by inspection. Prefer inlining data and setup directly in
each test over hiding it in shared state. Some duplication is fine if it makes
each test self-contained and immediately understandable.

## AHA abstraction

Avoid both extremes: no abstraction (copy-pasted walls of setup) and over-
abstraction (logic scattered across `beforeEach` chains and shared variables).
When setup is genuinely identical across many tests, extract it into a **setup
function** that returns its values explicitly. Prefer this over `beforeEach`
with mutable shared variables — the function call at the top of each test makes
dependencies visible and keeps state local. Never nest multiple layers of setup
hooks or fixtures.

## One behavior per test

Each test verifies one specific behavior. If the test name contains "and",
split it. A failing test name should tell you exactly what broke without reading
the body.

## Descriptive names

Name tests by observable behavior, not implementation. "returns 0 for an empty
cart" is better than "calls reduce correctly". The test output is documentation
— it should read like a specification of what the code does.

## Arrange / Act / Assert

Structure each test in three phases: set up the data, perform the action, check
the result. Keep each phase visible. A test that does too much in the assert
phase is often testing more than one behavior.

## Test behavior, not implementation

Assert on outputs and observable side effects — not on which internal methods
were called or what intermediate state was set. If a refactor doesn't change
observable behavior, no test should break. Tightly coupling tests to
implementation details makes refactoring painful without adding confidence.

## Mocking discipline

Mock at external boundaries: network, database, filesystem, time, third-party
services. Do not mock classes or modules internal to your own codebase — test
through them using real implementations. If you find yourself wanting to mock an
internal class, that is a signal the dependency boundary is in the wrong place.

## Assert the full call signature on mocks

When asserting on an external mock call, always assert the complete argument
list. Never rely on `.toHaveBeenCalled()` alone — the call to an external
system *is* the behavior under test, and an incomplete assertion lets the wrong
data silently pass through. If you only care about specific arguments, use the
framework's wildcard matcher (e.g. `expect.any()`) for the rest rather than
omitting them.

## No circular assertions

Never import a constant from application code and assert that it equals itself. That test can never fail — it proves nothing. Assert against the raw literal value instead, or define a separate constant local to the test.

## Edge cases

Cover boundaries, error paths, and realistic unusual inputs — each in its own
test. Do not bundle multiple edge cases into one test. Ask: could a real caller
trigger this? If yes, test it.

---

## Framework reference

Before writing tests, check the `index/` directory for framework-specific patterns and examples.
