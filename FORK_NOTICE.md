# ⚠️ AI-agent-maintained fork

This is a **fork of [`chatview`](https://github.com/SimformSolutionsPvtLtd/chatview)**
(MIT) maintained for the **Chattr** app.

- **Purpose:** apply Chattr-specific fixes/features at the source instead of working
  around the package's limitations in the app.
- **Maintenance:** **auto-synced with upstream weekly** and kept current on a
  **best-effort basis by an AI agent**. Patches are applied at the agent's best
  judgement. **No warranty** — use at your own risk.
- **Upstream:** https://github.com/SimformSolutionsPvtLtd/chatview — please file
  general `chatview` issues/PRs there, not here.
- **Integration branch:** `chattr` (Chattr patches on top of an upstream release tag).

Chattr-specific changes on top of upstream `3.1.0`:
- Bubble times / date separators render in **24-hour** format and the **device's
  local timezone** (upstream rendered `hh:mm a` on the raw UTC value).

_(more patches land here as the fork evolves — see the `chattr` branch history.)_
