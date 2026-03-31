# Test harness for dotfiles installation
# Runs on Debian 13 (trixie)

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Install test dependencies
RUN apt-get update && apt-get install -y \
    zsh \
    vim-tiny \
    tmux \
    git \
    direnv \
    terraform \
    gh \
    && rm -rf /var/lib/apt/lists/*

# Create test user
RUN useradd -m -s /bin/bash testuser

# Copy dotfiles repo
COPY . /dotfiles

# Set up test script
COPY test/run-tests.sh /usr/local/bin/run-tests.sh
RUN chmod +x /usr/local/bin/run-tests.sh

# Default command runs tests
CMD ["/usr/local/bin/run-tests.sh"]
