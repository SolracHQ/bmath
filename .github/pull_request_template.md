## Description

Provide a concise description of your changes and the overall purpose of this pull request.

## Related Issue(s)

Link any related issues using keywords (e.g., "fixes #123", "closes #456").

## Motivation and Context

Explain why this change is needed and what problem it addresses.

## How Has This Been Tested?

Describe the tests you ran to verify your changes and provide instructions for the reviewers to test manually. Common local verification commands:

```bash
# build the `bm` binary via nimble
nimble build bm

# run Nim unit tests (nimble task)
nimble test

# run the project's BM-style integration tests
./bmath_test/run_tests.sh
```

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Checklist (match project CONTRIBUTING.md)

- [ ] Brief description of change in PR title and body
- [ ] Add/modify tests under `tests/` and/or `bmath_test/` depending on scope
- [ ] Update `docs/` for any stdlib or public API changes
- [ ] Use existing error constructors from `src/types/errors.nim` for runtime errors
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, especially in hard-to-understand areas
- [ ] New and existing tests pass locally (run `nimble test` and `./bmath_test/run_tests.sh`)
- [ ] Formatted code with `nph` (run `./format_all.sh` or `nph --check src/**/*.nim`)

## Additional Notes

Include any additional information that might help the reviewer.
