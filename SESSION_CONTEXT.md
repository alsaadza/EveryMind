# Session context — pickup notes

Last updated: 2026-10-17

## 1. EducateAI → GitHub (done)

- Local project: `/Users/zain/EducateAI` (iOS app in Swift/Xcode + Python `gateway/` server).
- Pushed to **https://github.com/alsaadza/EveryMind** on branch `main` (tracks `origin/main`, in sync).
- History: local "Initial commit" (169 files), then a merge of GitHub's placeholder README commit (`e200337`) using `-s ours`, so the local README was kept. No force-push.
- `.gitignore` additions: `__pycache__/`, `.claude/settings.local.json`, `.claude/scheduled_tasks.lock`. `gateway/.env` and `gateway/.venv/` were already ignored. A secret scan found no keys.

### GitHub auth gotcha
- macOS Keychain holds a **different** GitHub account (`ZainAlsaadBelmontU` / zain.alsaad@bruins.belmont.edu), which got a 403 on this repo.
- `gh` CLI was installed via Homebrew and logged in as **alsaadza**.
- This repo has a **local** credential override, so pushes use `gh` instead of the Keychain:
  ```
  git config --local credential.helper ""
  git config --local --add credential.helper '!gh auth git-credential'
  ```
- Other repos on this Mac still use the Keychain (Belmont) account unless they're set up the same way.
- Git author: `Zain Alsaad <alsaadza@outlook.com>` (global config).

## 2. OCI Container Instances guide (done)

- Claude Doc: https://claude.ai/code/artifact/80c1d1a3-387d-406c-89c5-be7b3a51a190
- Sections: Overview, Key concepts (with architecture diagram), When to use it (vs OKE / VM / Functions), Create a container instance (Console + OCI CLI), Networking/security/monitoring, Pricing/limits/best practices + troubleshooting table.
- "OCI" was taken to mean **Oracle Cloud Infrastructure**. A doc comment asks whether to also cover the Open Container Initiative spec. **Still waiting on an answer.**
- Pricing and limits were written from memory, not checked against Oracle's current docs. Check them before relying on them.
- A spoken summary was played on the Mac (`say`), and a ~2 min audio file (`oci-container-instances.m4a`) was sent to the user. It lived in the session scratchpad, which is temporary.

## Open items / next steps
- [ ] Answer the OCI-meaning question in the doc (add an Open Container Initiative section if wanted).
- [ ] Check OCI pricing, limits, and the volume/restart-policy details against current Oracle docs, then add a Sources section.
- [x] This `SESSION_CONTEXT.md` is committed to the repo. Update it at the end of each session.
