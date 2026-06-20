# Contributing to vigiar

Thank you for your interest in contributing! This document
outlines the process for reporting bugs, suggesting features,
and submitting code changes.

## Code of Conduct

Please review our [Code of Conduct](CODE_OF_CONDUCT.md) before
participating.

## How to Contribute

### Reporting Bugs

1. Check the [issue tracker](https://github.com/santosry/vigiar-download/issues)
   to see if the bug has already been reported.
2. Open a new issue with a **minimal reproducible example** (reprex).
3. Include your `sessionInfo()` output.

### Suggesting Features

Open an issue with:
- A clear description of the feature
- Use cases and expected behaviour
- Why it belongs in this package (vs. a separate package)

### Pull Requests

1. Fork the repository.
2. Create a branch: `git checkout -b feature/nome-da-feature`
3. Make your changes. Follow the existing code style.
4. Add tests for new functionality.
5. Run `devtools::check()` and ensure it passes.
6. Update `NEWS.md` with your changes.
7. Submit a pull request against `main`.

### Development Setup

```r
# Install dependencies
install.packages(c("devtools", "testthat", "httptest2"))

# Load package for development
devtools::load_all()

# Run tests
devtools::test()

# Run checks
devtools::check()
```

### Code Style

- Use `cli::cli_abort()` and `cli::cli_inform()` for user messages.
- Prefer base R functions over tidyverse in package code.
- Internal functions are prefixed with `.vigiar_`.
- Document with roxygen2.

### Testing

- Unit tests use `testthat` 3e.
- Online tests (that require internet) should be guarded by
  `skip_if_offline()` and the environment variable
  `VIGIAR_RUN_ONLINE_TESTS=true`.
- Add a snapshot test when modifying output formats.

## License

By contributing, you agree that your contributions will be
licensed under the MIT License.
