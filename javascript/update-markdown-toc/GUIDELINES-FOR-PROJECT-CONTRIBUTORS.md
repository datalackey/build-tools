# Guidelines for Project Contributors


<!-- TOC:START -->
<!-- TOC:END -->


This document describes workflows intended for maintainers of update-markdown-toc. End users do not need these steps.


## Running Tests

All tests are shell-based and live under `scripts/`. 

### Run the full test suite

From `javascript/update-markdown-toc/`:

```bash
bash scripts/run-all-tests.sh
```

This runs, in order:

- fixture-based TOC generation tests
- CLI contract tests
- recursive traversal tests

The test runner exits non-zero on the first failure.

### Run a single test suite

You can invoke any test script directly, for example:

```bash
bash scripts/recursive-traversal-test.sh
```

### Test trace mode (recommended when debugging)

All recursive-mode test scripts accept a test-harness trace flag (`--trace` or `--show-run`), which prints the exact CLI command being executed before it runs. We may apply this to non-recursive tests in the future.

This flag does not alter CLI behavior. To enable CLI verbosity or debugging, re-run the printed command manually with `--verbose` or `--debug`.

Example output printed by the test harness:

```
[run] node bin/update-readme-toc.js --verbose --recursive /tmp/tmp.XYZ/tree
```

This trace output exists purely to aid test debugging and is independent of the CLI’s own `--verbose` flag.

---

## Releasing a New Version to npm

The package is published to npm as:

`@datalackey/update-markdown-toc`

Releases are manual and intentionally explicit.

1. Ensure a clean working tree

```bash
git status
```

There should be no uncommitted changes.

2. Run the full test suite

```bash
bash scripts/run-all-tests.sh
```

Do not publish if any test fails.

3. Update the version

Edit `package.json` and bump the version following semver:

- Patch: bug fixes, test-only changes
- Minor: new flags or non-breaking behavior
- Major: breaking CLI or behavior changes

Example:

```json
{
  "version": "0.1.2"
}
```

Commit the version bump:

```bash
git add package.json
git commit -m "chore: bump version to 0.1.2"
```

4. Publish to npm

Make sure you are logged in:

```bash
npm whoami
```

Then publish from `javascript/update-markdown-toc/`:

```bash
npm publish
```

Note: This package is intentionally published with no build step. The published files are those listed in `package.json` under `files`.

5. Tag the release (recommended)

```bash
git tag v0.1.2
git push origin v0.1.2
```
