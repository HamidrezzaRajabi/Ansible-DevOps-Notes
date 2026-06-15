#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Target node entrypoint (Rocky/AlmaLinux)
# Provisions guest user, injects control node pub key on boot.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

CONFIG_DIR="/etc/lab-config"
SHARED_DIR="/shared"
PUBKEY_FILE="${SHARED_DIR}/.ansible_pubkey"

# ── Read config files ────────────────────────────────────────
GUEST_NAME=$(cat "${CONFIG_DIR}/guest_name"   2>/dev/null | tr -d '[:space:]' || echo "labuser")
GUEST_PASS=$(cat "${CONFIG_DIR}/guest_passwd" 2>/dev/null | tr -d '[:space:]' || echo "labpass")
GUEST_SHELL=$(cat "${CONFIG_DIR}/guest_shell" 2>/dev/null | tr -d '[:space:]' || echo "/bin/bash")
ROOT_PASS=$(cat "${CONFIG_DIR}/root_passwd"   2>/dev/null | tr -d '[:space:]' || echo "rootpass")

# ── Root password ────────────────────────────────────────────
echo "root:${ROOT_PASS}" | chpasswd

# ── Provision guest user ─────────────────────────────────────
if ! id "${GUEST_NAME}" &>/dev/null; then
  useradd -m -s "${GUEST_SHELL}" "${GUEST_NAME}"
  echo "${GUEST_NAME}:${GUEST_PASS}" | chpasswd
  echo "${GUEST_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/lab-guest
  chmod 0440 /etc/sudoers.d/lab-guest
  echo "✔  Guest user '${GUEST_NAME}' created."
fi

# ── Inject control node's public key (wait up to 30 s) ──────
echo "⏳ Waiting for control node public key at ${PUBKEY_FILE}…"
for i in $(seq 1 30); do
  if [[ -f "${PUBKEY_FILE}" && -s "${PUBKEY_FILE}" ]]; then
    break
  fi
  sleep 1
done

if [[ -f "${PUBKEY_FILE}" && -s "${PUBKEY_FILE}" ]]; then
  AK="/home/ansible/.ssh/authorized_keys"
  touch "${AK}"
  PUBKEY=$(cat "${PUBKEY_FILE}")
  if ! grep -qF "${PUBKEY}" "${AK}" 2>/dev/null; then
    echo "${PUBKEY}" >> "${AK}"
    chmod 600 "${AK}"
    chown ansible:ansible "${AK}"
    echo "✔  Control node public key injected into ansible@$(hostname)."
  fi
else
  echo "⚠  Public key not found – SSH key auth will not work until key is shared."
fi

echo "──────────────────────────────────────────"
echo " Rocky/Alma Target Node ready: $(hostname)"
echo "──────────────────────────────────────────"

exec "$@"
