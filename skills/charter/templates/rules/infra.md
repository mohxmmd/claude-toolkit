---
paths:
  - "<infra dir>/**"
---
# Infrastructure

Applying infrastructure changes is blocked by a deny rule. Preparing them is not.

Allowed here: write the change, run the plan or validate step, explain the diff
the plan reports, and hand it to the user to apply.

Never: apply, destroy, or touch a production workspace, context, or profile.
Never assume the current context is the one intended — check it and say which.
