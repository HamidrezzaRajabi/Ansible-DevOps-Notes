# ─────────────────────────────────────────────
# Rocky/RHEL-family Target Node
# Base: AlmaLinux 9 – minimal variant
# ─────────────────────────────────────────────
FROM almalinux:9-minimal

# ── Minimal packages required by Ansible + SSH ─
RUN microdnf install -y --nodocs \
    openssh-server \
    openssh-clients \
    python3 \
    sudo \
    curl \
    vim-minimal \
    ca-certificates \
    shadow-utils \
    && microdnf clean all

# ── SSH server setup ───────────────────────────
RUN ssh-keygen -A \
    && sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/'           /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/'     /etc/ssh/sshd_config \
    && echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config

# ── Create ansible user ───────────────────────
RUN useradd -m -s /bin/bash ansible \
    && echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible \
    && chmod 0440 /etc/sudoers.d/ansible \
    && mkdir -p /home/ansible/.ssh \
    && chmod 700 /home/ansible/.ssh \
    && chown -R ansible:ansible /home/ansible/.ssh

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
