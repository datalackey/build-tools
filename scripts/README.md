# Repo Scripts

Utility scripts that operate across the whole repo (not tied to a single `javascript/` package).

## `lights-out.mjs`

Runs an unattended ("lights-out") Claude Code session against a spec file, inside its own
git worktree + branch, so the session can edit/commit freely without touching your main
working tree.

### Usage

```bash
node scripts/lights-out.mjs --spec <path-to-spec-file> --branch <branch-name>
```

- `--spec` — path to a plain-text spec file describing the task (e.g. `spec/build.cleanup`).
  Passed verbatim as the prompt to `claude -p`.
- `--branch` — name of the new branch to create. The script creates a sibling worktree at
  `../lights-out-<branch>` (relative to the repo root) checked out on this branch, and fails
  if that path already exists.

Example:
```bash
node scripts/lights-out.mjs --spec spec/build.cleanup --branch build.cleanup
```

### What it does

1. Creates `../lights-out-<branch>` as a new git worktree on a new branch `<branch>`.
2. Spawns `claude -p <spec contents> --dangerously-skip-permissions` inside that worktree.
3. Mirrors all of the session's stdout/stderr to your terminal **and** to a log file (see below).
4. Watches for idle gaps and warns if the session goes quiet for too long.

### Logging — where to look

Every run writes a full transcript to:
```
.lights-out-logs/<branch>-<timestamp>.log
```
(relative to the repo root; the directory is git-ignored). The script prints the exact path
when it starts, e.g.:
```
Log:      /home/chris/build-tools/.lights-out-logs/build.cleanup-2026-06-16T20-31-04-123Z.log
```

Follow it live from any other terminal with:
```bash
tail -f .lights-out-logs/<branch>-<timestamp>.log
```

This is useful even after the launching terminal is closed or scrolled away — the log file is
the durable record of everything the session did.

### Detecting a stuck session

If no output arrives for 3 minutes, the script writes:
```
⚠ no output for <N>s — session may be stuck (pid <pid>)
```
to both the terminal and the log. This is advisory only — it does not kill the process.

### Tracking phase progress

For specs that define multiple phases (see `spec/build.cleanup` for an example), have the spec
instruct the agent to commit after each phase is validated, e.g.:
```
phase 3: nx-graph-to-mermaid — validated
```
Then, independent of the log, `git log --oneline` inside the worktree tells you exactly which
phase last completed:
```bash
cd ../lights-out-<branch> && git log --oneline -5 && git status -s
```

### When it finishes

The script prints next steps: review the diff against `main`, push the branch, and remove the
worktree once you're done with it (`git worktree remove ../lights-out-<branch>`).

[![No US Tax$ 4 genocide](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
