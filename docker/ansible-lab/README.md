# 🧪 Ansible Practice Lab

A lightweight, fully self-contained Ansible lab built with Docker Compose.  
Spin up a realistic multi-distro environment in minutes — no VMs, no cloud accounts.

```
┌──────────────────────────────────────────────────────────────┐
│                      ansible-lab network                     │
│                                                              │
│  ┌─────────────┐   SSH   ┌──────────┐   ┌──────────┐        │
│  │  ubuntu-c   │────────►│ ubuntu1  │   │ ubuntu2  │        │
│  │  (control)  │────────►│(Ubuntu)  │   │(Ubuntu)  │        │
│  └─────────────┘   SSH   └──────────┘   └──────────┘        │
│         │                ┌──────────┐   ┌──────────┐        │
│         └───────────────►│  rocky1  │   │  rocky2  │        │
│                    SSH   │ (Alma 9) │   │ (Alma 9) │        │
│                          └──────────┘   └──────────┘        │
└──────────────────────────────────────────────────────────────┘
```

---

## 📋 Requirements

| Tool | Minimum version |
|------|----------------|
| Docker | 24.x |
| Docker Compose | v2.x (`docker compose`) |
| Git | any |
| Free disk space | ~2 GB |

---

## 🗂 Directory Structure

```
my-ansible-lab/
├── docker-compose.yaml          # Main orchestration file
├── .env.example                 # Port mappings & subnet config
├── .gitignore
├── README.md
│
├── config/                      # Mounted into every container
│   ├── guest_name               # Guest OS username
│   ├── guest_passwd             # Guest OS password  ← in .gitignore
│   ├── guest_shell              # Default shell (e.g. /bin/bash)
│   └── root_passwd              # Root password       ← in .gitignore
│
├── images/
│   ├── control/                 # Ansible control node image
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   ├── ubuntu-target/           # Ubuntu 24.04 slim target image
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   └── rocky-target/            # AlmaLinux 9 minimal target image
│       ├── Dockerfile
│       └── entrypoint.sh
│
└── ansible_home/                # Bind-mounted persistent volumes
    ├── ubuntu-c/
    │   ├── ansible/             → /home/ansible  (control node)
    │   └── root/                → /root          (control node)
    ├── ubuntu1/
    │   ├── ansible/             → /home/ansible  (ubuntu1)
    │   └── root/                → /root          (ubuntu1)
    ├── ubuntu2/
    │   ├── ansible/             → /home/ansible  (ubuntu2)
    │   └── root/                → /root          (ubuntu2)
    ├── rocky1/
    │   ├── ansible/             → /home/ansible  (rocky1)
    │   └── root/                → /root          (rocky1)
    ├── rocky2/
    │   ├── ansible/             → /home/ansible  (rocky2)
    │   └── root/                → /root          (rocky2)
    └── shared/                  → /shared        (all containers)
```

---

## 🚀 Quick Start

### 1 — Clone and configure

```bash
git clone https://github.com/YOUR_USERNAME/my-ansible-lab.git
cd my-ansible-lab

# Copy and review environment variables
cp .env.example .env

# (Optional) Change default passwords before first boot
echo "mysecretpass"  > config/guest_passwd
echo "myrootpass"    > config/root_passwd
```

### 2 — Build and start

```bash
docker compose up -d --build
```

> First build takes ~3–5 minutes (downloading base images + installing Ansible).  
> Subsequent starts are instant.

### 3 — Verify all containers are running

```bash
docker compose ps
```

Expected output:

```
NAME        IMAGE                      STATUS          PORTS
ubuntu-c    ansible-lab-ubuntu-c       Up              0.0.0.0:2200->22/tcp
ubuntu1     ansible-lab-ubuntu-target  Up              0.0.0.0:2201->22/tcp
ubuntu2     ansible-lab-ubuntu-target  Up              0.0.0.0:2202->22/tcp
rocky1      ansible-lab-rocky-target   Up              0.0.0.0:2203->22/tcp
rocky2      ansible-lab-rocky-target   Up              0.0.0.0:2204->22/tcp
```

### 4 — Enter the control node

```bash
docker exec -it ubuntu-c bash
# or connect via SSH from your host
ssh -p 2200 ansible@localhost
```

### 5 — Run your first ping

```bash
# Inside ubuntu-c
ansible all -m ping
```

Expected:

```yaml
ubuntu1 | SUCCESS => { "ping": "pong" }
ubuntu2 | SUCCESS => { "ping": "pong" }
rocky1  | SUCCESS => { "ping": "pong" }
rocky2  | SUCCESS => { "ping": "pong" }
```

---

## 🔑 SSH Key Distribution (Automatic)

The lab handles key distribution automatically on first boot:

1. **Control node** generates an RSA-4096 keypair at `/home/ansible/.ssh/id_rsa`
2. The public key is written to the **shared volume** at `/shared/.ansible_pubkey`
3. **Each target node** polls the shared volume and injects the key into `/home/ansible/.ssh/authorized_keys`

No manual `ssh-copy-id` needed. If you want to re-key, delete the files and restart:

```bash
rm ansible_home/ubuntu-c/ansible/.ssh/id_rsa*
rm ansible_home/shared/.ansible_pubkey
docker compose restart
```

---

## ⚙️ Configuration

### Port mappings (`  .env`)

| Variable | Default | Container |
|----------|---------|-----------|
| `CONTROL_SSH_PORT` | 2200 | ubuntu-c |
| `UBUNTU1_SSH_PORT` | 2201 | ubuntu1  |
| `UBUNTU2_SSH_PORT` | 2202 | ubuntu2  |
| `ROCKY1_SSH_PORT`  | 2203 | rocky1   |
| `ROCKY2_SSH_PORT`  | 2204 | rocky2   |
| `DIND_PORT`        | 2375 | dind     |
| `LAB_SUBNET`       | 172.20.0.0/24 | bridge network |

### Guest user (`config/`)

| File | Purpose | Default |
|------|---------|---------|
| `guest_name`   | OS username created on boot | `labuser` |
| `guest_passwd` | Password for that user | `labpass` |
| `guest_shell`  | Login shell | `/bin/bash` |
| `root_passwd`  | Root password | `rootpass` |

Changes to config files take effect on the **next container restart**.

---

## 🐳 Optional: Docker-in-Docker (DinD)

To test Ansible's `community.docker` modules, uncomment the `dind` block in `docker-compose.yaml`:

```yaml
  dind:
    image: docker:dind
    container_name: dind
    privileged: true
    ...
```

Then install the collection on the control node:

```bash
ansible-galaxy collection install community.docker
```

> ⚠️ DinD requires `--privileged`. Only use in trusted, local environments.

---

## 📦 Ansible Collections

Install extra collections on the control node:

```bash
# Inside ubuntu-c
ansible-galaxy collection install \
  ansible.posix \
  community.general \
  community.docker \
  community.crypto
```

Or add a `requirements.yml` to `/home/ansible/` and run:

```bash
ansible-galaxy collection install -r ~/requirements.yml
```

---

## 🛠 Useful Commands

```bash
# Start the lab
docker compose up -d

# Stop without destroying volumes
docker compose stop

# Full teardown (keeps bind-mount data in ansible_home/)
docker compose down

# Full teardown + remove anonymous volumes
docker compose down -v

# Watch logs of all containers
docker compose logs -f

# Watch logs of one container
docker compose logs -f ubuntu-c

# Rebuild a single image after Dockerfile changes
docker compose build ubuntu-c
docker compose up -d ubuntu-c

# SSH from host to a specific node
ssh -p 2201 ansible@localhost   # ubuntu1
ssh -p 2203 ansible@localhost   # rocky1

# Run an ad-hoc command against all targets
docker exec -it ubuntu-c ansible all -a "uname -a"

# Run a playbook
docker exec -it ubuntu-c ansible-playbook ~/playbooks/site.yml
```

---

## 🧩 Inventory

The control node auto-generates `~/inventory` on first boot:

```ini
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
```

Host names resolve via Docker's internal DNS — no `/etc/hosts` edits needed.

---

## 🔒 Security Notes

- This lab is intended for **local development only** — do not expose SSH ports publicly.
- Default passwords in `config/` are weak by design for convenience; change them before use.
- Private SSH keys are excluded from git via `.gitignore`.
- The `config/guest_passwd` and `config/root_passwd` files are also gitignored.

---

## 📝 License

MIT — do whatever you like with it.
