# ─────────────────────────────────────────────
# Ansible Control Node
# Base: Ubuntu 24.04 (Noble) – slim variant
# ─────────────────────────────────────────────
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# ── System packages ───────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    openssh-client \
    sshpass \
    sudo \
    curl \
    wget \
    git \
    vim \
    nano \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ── Install latest Ansible via pipx (isolated, no PEP-668 issues) ──
RUN python3 -m pip install --break-system-packages pipx \
    && pipx install --global ansible \
    && pipx inject --global ansible \
        paramiko \
        netaddr \
        jmespath \
        boto3 \
        dnspython \
    && ansible --version

# ── Create ansible user ───────────────────────
RUN useradd -m -s /bin/bash ansible \
    && echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible \
    && chmod 0440 /etc/sudoers.d/ansible

# ── SSH directory for ansible user ───────────
RUN mkdir -p /home/ansible/.ssh \
    && chmod 700 /home/ansible/.ssh \
    && chown -R ansible:ansible /home/ansible/.ssh

# ── Entrypoint: provision guest user + SSH key ─
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER ansible
WORKDIR /home/ansible

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
