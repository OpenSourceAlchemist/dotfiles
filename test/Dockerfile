# Test harness for dotfiles installation
# Runs on Debian 13 (trixie)

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Install test dependencies
# Note: terraform not in Debian repos - download directly
# Note: tflint is used as terraform alternative since terraform package unavailable
RUN apt-get update && apt-get install -y \
    zsh \
    vim-nox \
    tmux \
    git \
    direnv \
    unzip \
    curl \
    gh \
    && rm -rf /var/lib/apt/lists/* \
    # Install terraform (matching version in .tool-versions)
    && TERRAFORM_VER=1.5.6 \
    && curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip -o /tmp/terraform.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip

# Create test user
RUN useradd -m -s /bin/bash testuser

# Copy dotfiles repo (from parent directory - one level up from Dockerfile)
COPY .. /dotfiles

# Set up test script
COPY test/run-tests.sh /usr/local/bin/run-tests.sh
RUN chmod +x /usr/local/bin/run-tests.sh

# Default command runs tests
CMD ["/usr/local/bin/run-tests.sh"]
