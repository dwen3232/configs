---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Write tests alongside the implementation at natural seams, following this repo's existing testing conventions, rather than saving all testing for the end.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use the `code-review-2axis` skill to review the work.

Commit your work to the current branch.
