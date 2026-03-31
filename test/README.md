# Test Harness

Automated testing for dotfiles installation using Podman containers.

## Quick Start

```bash
# Run all tests
make test

# Open an interactive shell in the test container
make shell

# Clean up
make clean
```

## What Gets Tested

1. **Repository Structure** - All expected files exist
2. **Dependencies** - Required packages install correctly on Debian 13
3. **Installation** - `install.sh` runs without errors
4. **Symlinks** - All dotfiles are correctly symlinked
5. **Symlink Targets** - Point to correct source files
6. **Backup Creation** - Backup directory is created
7. **Idempotency** - Re-running installation handles existing symlinks
8. **Directory Creation** - Nested directories like `.config/gh` and `.dotzsh` are created

## Running Outside Podman

To test on your local system:

```bash
# Create a test user
sudo useradd -m -s /bin/bash testuser

# Run as that user
sudo -u testuser bash install.sh
```

## CI/CD Integration

The test can be run in CI using:

```yaml
test:
  image: debian:trixie-slim
  script:
    - apt-get update && apt-get install -y podman
    - make test
```
