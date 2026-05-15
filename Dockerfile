FROM nixos/nix:latest

# Enable flakes; disable nix sandbox (no user namespaces inside Docker)
RUN mkdir -p /etc/nix \
    && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf \
    && echo "sandbox = false" >> /etc/nix/nix.conf

# Create non-root user; give them ownership of /nix for single-user nix at runtime
RUN groupadd -g 1000 sandbox \
    && useradd -m -u 1000 -g sandbox -s /bin/bash sandbox \
    && chown -R sandbox:sandbox /nix \
    && mkdir -p /work && chown sandbox:sandbox /work

# Copy flake — path: URL works without git init in single-user nix
COPY --chown=sandbox:sandbox flake.nix flake.lock /sandbox-flake/

ARG CACHE_BUST=default_value

USER sandbox
RUN nix profile install path:/sandbox-flake \
    && git config --global --add safe.directory /work \
    && git lfs install \
    && git config --global core.autocrlf input

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
WORKDIR /work
