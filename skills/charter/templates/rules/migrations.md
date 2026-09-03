---
paths:
  - "<migrations dir>/**"
---
# Schema changes

<How this team actually applies a schema change. The framework default is often
not what the team does — that gap is exactly why this file exists.>

Before writing any migration:
- Confirm which connection and which database it targets.
- Confirm whether it runs automatically or by hand.
- Write the down path, and check it actually reverses the up path.

Verify by applying up then down on a scratch database. Never against anything shared.
