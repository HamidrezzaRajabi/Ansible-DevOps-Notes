#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Control node entrypoint
# Provisions guest user, SSH keypair, and ansible.cfg on boot.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

CONFIG_DIR="/etc/lab-config"

# ── Read config files (with sane defaults) ──────────────────
GUEST_NAME=$(cat "${CONFIG_DIR}/guest_name"   2>/dev/null | tr -d '[:space:]' || echo "labuser")
GUEST_PASS=$(cat "${CONFIG_DIR}/guest_passwd" 2>/dev/null | tr -d '[:space:]' || echo "labpass")
GUEST_SHELL=$(cat "${CONFIG_DIR}/guest_shell" 2>/dev/null | tr -d '[:space:]' || echo "/bin/bash")
ROOT_PASS=$(cat "${CONFIG_DIR}/root_passwd"   2>/dev/null | tr -d '[:space:]' || echo "rootpass")

# ── Provision guest user (runs as root via sudo) ────────────
sudo bash -c "
  if ! id '${GUEST_NAME}' &>/dev/null; then
    useradd -m -s '${GUEST_SHELL}' '${GUEST_NAME}'
    echo '${GUEST_NAME}:${GUEST_PASS}' | chpasswd
    echo '${GUEST_NAME} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/lab-guest
    chmod 0440 /etc/sudoers.d/lab-guest
  fi
  echo 'root:${ROOT_PASS}' | chpasswd
"

# ── Generate SSH keypair for ansible user (if missing) ──────
if [[ ! -f /home/ansible/.ssh/id_rsa ]]; then
  ssh-keygen -t rsa -b 4096 -N "" -C "ansible-lab-control" \
    -f /home/ansible/.ssh/id_rsa
  echo "✔  SSH keypair generated."
fi

# ── Write a baseline ansible.cfg ────────────────────────────
ANSIBLE_CFG="/home/ansible/ansible.cfg"
if [[ ! -f "${ANSIBLE_CFG}" ]]; then
  cat > "${ANSIBLE_CFG}" <<'EOF'
[defaults]
inventory          = ~/inventory
remote_user        = ansible
private_key_file   = ~/.ssh/id_rsa
host_key_checking  = False
retry_files_enabled = False
stdout_callback    = yaml
callbacks_enabled  = timer, profile_tasks

[privilege_escalation]
become        = True
become_method = sudo
become_user   = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
pipelining = True
EOF
  echo "✔  ansible.cfg written."
fi

# ── Write a starter inventory ────────────────────────────────
INVENTORY="/home/ansible/inventory"
if [[ ! -f "${INVENTORY}" ]]; then
  cat > "${INVENTORY}" <<'EOF'
[control]
ubuntu-c ansible_connection=local

[ubuntu]
ubuntu1
ubuntu2

[rocky]
rocky1
rocky2

[targets:children]
ubuntu
rocky

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
  echo "✔  Inventory written."
fi

echo "──────────────────────────────────────────"
echo " Ansible Control Node ready"
echo " Ansible: $(ansible --version | head -1)"
echo "──────────────────────────────────────────"

exec "$@"
