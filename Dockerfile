FROM nixos/nix:latest

# Enable flakes; disable nix sandbox (no user namespaces inside Docker)
RUN mkdir -p /etc/nix \
    && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf \
    && echo "sandbox = false" >> /etc/nix/nix.conf

# Create non-root user
# /etc/passwd and /etc/group are deep symlinks in nixos/nix — dereference to real files
# so that shadow's groupadd/useradd can modify them
RUN nix-env -iA nixpkgs.shadow \
    && cp -L /etc/passwd /tmp/passwd && mv /tmp/passwd /etc/passwd \
    && cp -L /etc/group /tmp/group && mv /tmp/group /etc/group \
    && cp -L /etc/shadow /tmp/shadow && mv /tmp/shadow /etc/shadow \
    && groupadd -g 1000 sandbox \
    && useradd -m -u 1000 -g sandbox -s /bin/sh sandbox \
    && chown -R sandbox:sandbox /nix

# Copy flake — path: URL works without git init in single-user nix
COPY --chown=sandbox:sandbox flake.nix flake.lock /sandbox-flake/

ENV PATH="/home/sandbox/.nix-profile/bin:${PATH}"
ENV CLAUDE_CONFIG_DIR=/home/sandbox/.claude
ENV CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
ENV ENABLE_CLAUDEAI_MCP_SERVERS=false
ENV CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1

USER sandbox
RUN nix profile add path:/sandbox-flake \
    && git config --global --add safe.directory /home/sandbox/work \
    && git lfs install \
    && git config --global core.autocrlf input \
    && echo 'eval "$(direnv hook bash)"' >> /home/sandbox/.bashrc


ENTRYPOINT ["bash"]
WORKDIR /home/sandbox/work
