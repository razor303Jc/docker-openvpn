# Contributing to docker-openvpn

Community contributions are welcome and help move the project along. Please review this document before sending any pull requests.

Thanks!

## Security First

When contributing to this project, security is our top priority:

* **Never commit secrets**: Ensure no private keys, certificates, or credentials are included in commits
* **Validate inputs**: All user inputs should be properly validated and sanitized  
* **Review dependencies**: New package dependencies should be justified and security-reviewed
* **Follow secure coding practices**: Use proper quoting, error handling, and avoid dangerous shell constructs

## Development Environment

### Prerequisites

* Docker Engine 20.10+ 
* Basic knowledge of OpenVPN, PKI, and containerization
* Familiarity with shell scripting and Alpine Linux

### Setup

```bash
# Clone the repository
git clone https://github.com/kylemanna/docker-openvpn.git
cd docker-openvpn

# Build the image for testing
docker build -t test-openvpn .

# Run security validation
./validate-scripts.sh

# Use the helper script for testing
./openvpn-helper.sh --help
```

## Bug Fixes

All bug fixes are welcome. Please try to add a test if the bug is something that should have been fixed already.

### Bug Report Guidelines

* **Check existing issues** before creating new ones
* **Provide detailed reproduction steps**
* **Include version information** (Docker, OpenVPN, Alpine)
* **Test with minimal configuration** to isolate the issue

## Feature Additions

New features are welcome provided that:

* The feature has a **general audience** and is **reasonably simple**
* It doesn't compromise security or significantly increase complexity
* It maintains backward compatibility where possible
* It follows established patterns in the codebase

### Feature Request Process

1. **Create an issue** describing the feature and use case
2. **Wait for feedback** from maintainers and community
3. **Implement with tests** if approved
4. **Update documentation** as needed

Please add new documentation in the `docs` folder for any new features. Pull requests for missing documentation are welcome as well. Keep the `README.md` focused on the most popular use case; details belong in the docs directory.

## Testing

All changes should be tested to ensure they don't break existing functionality:

### Running Tests

```bash
# Build test image
docker build -t test-openvpn .

# Run existing test suite
./test/run.sh test-openvpn

# Run security validation
./validate-scripts.sh

# Test with helper script
./openvpn-helper.sh status
```

### Test Requirements

* **Unit tests** for new functionality in `test/tests` directory
* **Integration tests** for end-to-end scenarios
* **Security tests** for security-related changes
* **Documentation tests** for new features

Tests are run on GitHub Actions (replacing Travis CI). The goal is to be simple and comprehensive.

## Code Quality Standards

### Shell Scripting

* **Use `set -euo pipefail`** for error handling
* **Quote all variables** to prevent word splitting
* **Avoid `eval` and `exec`** unless absolutely necessary
* **Use meaningful variable names**
* **Add error handling and logging**

### Docker Best Practices

* **Use specific base image versions** (not `latest`)
* **Minimize layer count** and image size
* **Use `.dockerignore`** to exclude unnecessary files
* **Add health checks** where appropriate
* **Follow security best practices**

### Documentation

* **Use clear, concise language**
* **Include practical examples**
* **Update both README and docs/** as needed
* **Test all documented commands**

## Style Guidelines

The style of the repo follows these principles:

### Git Commits

* **Atomic commits**: Each commit should represent a single logical change
* **Descriptive messages**: Use format "`<subsystem>: <description>`"
* **Rebase before submitting**: Clean up commit history
* **Sign commits**: Use GPG signing where possible

Example commit messages:
```
dockerfile: Update Alpine to 3.22 and add health check
docs: Add security best practices section
helper: Add backup and restore functionality
ci: Replace Travis CI with GitHub Actions
```

### Code Style

* **Match surrounding style** (indentation, spacing, etc.)
* **Use consistent naming** throughout the codebase
* **Add comments** for complex logic
* **Keep functions small** and focused

## Pull Request Process

1. **Fork the repository** and create a feature branch
2. **Make your changes** following the guidelines above
3. **Test thoroughly** with the test suite
4. **Update documentation** as needed
5. **Run validation tools** (`./validate-scripts.sh`)
6. **Submit the pull request** with clear description

### Pull Request Requirements

* **Clear description** of changes and motivation
* **Tests pass** in CI/CD pipeline
* **Documentation updated** if needed
* **Security review** for security-related changes
* **Backward compatibility** maintained

## Security Reporting

For security vulnerabilities, please:

* **Do not create public issues**
* **Email maintainers directly** with details
* **Allow time for patching** before disclosure
* **Follow responsible disclosure practices**

## Questions and Support

* **Check documentation** in `docs/` first
* **Search existing issues** before asking
* **Use discussions** for general questions
* **Create issues** for specific problems

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
