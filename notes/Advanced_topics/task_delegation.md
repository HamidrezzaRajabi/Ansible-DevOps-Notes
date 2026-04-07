# 🎯 Task Delegation



## 📌 What is Task Delegation?

Task delegation allows you to run a task on a **different host** than the one defined in `hosts`.

| Concept | Meaning |
|---------|---------|
| `hosts:` | Which host(s) the play targets |
| `delegate_to:` | Which host actually executes the task |

> 💡 **Use case:** Configure a load balancer from web server facts, manage central logging servers, update firewall rules from multiple hosts

---

## 🎯 Real-World Example: TCP Wrappers

**Goal:** Restrict SSH access to `ubuntu3` so only `ubuntu-c`, `centos1`, and `ubuntu1` can connect.

**TCP Wrapper files:**
- `/etc/hosts.allow` - Allowed connections
- `/etc/hosts.deny` - Denied connections

**Order of evaluation:** `hosts.allow` → `hosts.deny`

---

## 📁 1: Setup SSH Key for ubuntu3

### Play 1: Generate SSH Key on Control Host
```yaml
-
  hosts: ubuntu-c
  gather_facts: False
  
  tasks:
    - name: Generate an OpenSSH keypair for ubuntu3
      openssh_keypair:
        path: ~/.ssh/ubuntu3_id_rsa
```

### Play 2: Copy Key to All Linux Hosts
```yaml
-
  hosts: linux
  gather_facts: False
  
  tasks:
    - name: Copy ubuntu3 OpenSSH keypair with permissions
      copy:
        owner: root
        src: "{{ item.0 }}"
        dest: "{{ item.0 }}"
        mode: "{{ item.1 }}"
      with_together:
        - [ ~/.ssh/ubuntu3_id_rsa, ~/.ssh/ubuntu3_id_rsa.pub ]
        - [ "0600", "0644" ]
```

### Play 3: Install Public Key on ubuntu3
```yaml
-
  hosts: ubuntu3
  gather_facts: False
  
  tasks:
    - name: Add public key to the ubuntu3 authorized_keys file
      authorized_key:
        user: root
        state: present
        key: "{{ lookup('file', '~/.ssh/ubuntu3_id_rsa.pub') }}"
```

---

## 📁 2: Test SSH Connectivity

```yaml
-
  hosts: all
  gather_facts: False
  
  tasks:
    - name: Check that ssh can connect to ubuntu3 using the ssh tool
      command: ssh -i ~/.ssh/ubuntu3_id_rsa -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@ubuntu3 date
      changed_when: False
      ignore_errors: True
```

**SSH Options Explained:**
| Option | Purpose |
|--------|---------|
| `-i ~/.ssh/ubuntu3_id_rsa` | Use specific private key |
| `-o BatchMode=yes` | No password prompt (fail if key fails) |
| `-o StrictHostKeyChecking=no` | Auto-accept unknown hosts |
| `-o UserKnownHostsFile=/dev/null` | Don't save fingerprints |
| `changed_when: False` | Don't mark as changed (informational only) |
| `ignore_errors: True` | Don't fail playbook on connection error |

---

## 📁 3: Add Allowed Hosts (Task Delegation)

### The Key Play - Delegation in Action

```yaml
-
  hosts: ubuntu-c, centos1, ubuntu1
  serial: 1              # Write one at a time to avoid conflicts
  
  tasks:
    - name: Add host to /etc/hosts.allow for sshd
      lineinfile:
        path: /etc/hosts.allow
        line: "sshd: {{ ansible_hostname }}.diveinto.io"
        create: True
      delegate_to: ubuntu3    # ← Run on ubuntu3, not the source host!
```

**How it works:**
```
Source hosts: ubuntu-c, centos1, ubuntu1
Target for delegation: ubuntu3

For each source host:
  1. Get its hostname ({{ ansible_hostname }})
  2. Run lineinfile task on ubuntu3
  3. Add "sshd: hostname.diveinto.io" to ubuntu3's /etc/hosts.allow
```

**Result after revision 03:** ubuntu3's `/etc/hosts.allow`:
```
sshd: ubuntu-c.diveinto.io
sshd: centos1.diveinto.io
sshd: ubuntu1.diveinto.io
```

> ⚠️ **Important:** `serial: 1` prevents multiple hosts writing to the same file simultaneously

---

## 📁 4: Deny Everyone Else

### Add Deny Rule on ubuntu3
```yaml
-
  hosts: ubuntu3
  gather_facts: False
  
  tasks:
    - name: Drop SSH connectivity from everywhere else
      lineinfile:
        path: /etc/hosts.deny
        line: "sshd: ALL"
        create: True
```

**Effect:**
- Hosts in `hosts.allow` → ✅ Can connect
- All other hosts → ❌ Connection denied

**SSH check results:**
```
✅ ubuntu-c    - can connect (in allow)
✅ centos1     - can connect (in allow)
✅ ubuntu1     - can connect (in allow)
❌ centos2     - cannot connect (denied)
❌ centos3     - cannot connect (denied)
❌ ubuntu2     - cannot connect (denied)
❌ ubuntu3     - cannot connect (denied itself? yes!)
```

---

## 📁 5: Cleanup (Idempotent)

### Remove Allow Entries
```yaml
-
  hosts: ubuntu-c, centos1, ubuntu1
  serial: 1
  
  tasks:
    - name: Remove specific host entries in /etc/hosts.allow
      lineinfile:
        path: /etc/hosts.allow
        line: "sshd: {{ ansible_hostname }}.diveinto.io"
        state: absent      # ← Remove instead of add
      delegate_to: ubuntu3
```

### Remove Deny Rule
```yaml
-
  hosts: ubuntu3
  gather_facts: False
  
  tasks:
    - name: Allow SSH connectivity from everywhere
      lineinfile:
        path: /etc/hosts.deny
        line: "sshd: ALL"
        state: absent      # ← Remove the deny all rule
```

---

## 📊 Complete Flow (Revision 05)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Generate SSH key on ubuntu-c                                 │
│ 2. Copy key to all linux hosts                                  │
│ 3. Install public key on ubuntu3                                │
│ 4. Test SSH (should succeed)                                    │
│                                                                  │
│ 5. DELEGATE: Add allow rules to ubuntu3's hosts.allow           │
│    (from ubuntu-c, centos1, ubuntu1)                            │
│ 6. Test SSH (should still succeed)                              │
│                                                                  │
│ 7. Add deny all to ubuntu3's hosts.deny                         │
│ 8. Test SSH (only 3 hosts succeed, others fail)                 │
│                                                                  │
│ 9. CLEANUP: Remove allow rules from hosts.allow                 │
│10. CLEANUP: Remove deny all from hosts.deny                     │
│11. Test SSH (all succeed again)                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Common Delegation Patterns

### Pattern 1: Central Logging
```yaml
- name: Collect logs from app servers
  hosts: app_servers
  tasks:
    - name: Copy log to central server
      fetch:
        src: /var/log/app.log
        dest: /central/logs/{{ inventory_hostname }}/
      delegate_to: logserver
```

### Pattern 2: Load Balancer Configuration
```yaml
- name: Configure web servers
  hosts: web_servers
  tasks:
    - name: Add web server to load balancer pool
      lineinfile:
        path: /etc/haproxy/haproxy.cfg
        line: "  server {{ inventory_hostname }} {{ ansible_default_ipv4.address }}:80 check"
      delegate_to: lb01
      notify: reload haproxy
```

### Pattern 3: Database Backup from App Server
```yaml
- name: Backup database
  hosts: db_servers
  tasks:
    - name: Run pg_dump
      command: pg_dump mydb > /tmp/mydb.sql
      delegate_to: backup_server
```

### Pattern 4: Central User Management
```yaml
- name: Collect user info
  hosts: all
  tasks:
    - name: Get user list
      command: getent passwd
      register: passwd_output
      
    - name: Store on central server
      copy:
        content: "{{ passwd_output.stdout }}"
        dest: "/var/log/user_audit/{{ inventory_hostname }}.txt"
      delegate_to: audit_server
```

---

## 📊 Key Delegation Options

| Option | Purpose | Example |
|--------|---------|---------|
| `delegate_to: hostname` | Run task on specific host | `delegate_to: localhost` |
| `delegate_to: localhost` | Run on Ansible control node | Common for API calls |
| `serial: 1` | One host at a time (file writes) | Avoid race conditions |
| `run_once: true` | Run only once across all hosts | Combine with delegation |

### delegate_to vs run_once

```yaml
# Run on ONE host (first in inventory)
- name: This runs once
  command: echo "one time"
  run_once: true

# Run on a SPECIFIC host
- name: This runs on ubuntu3
  command: echo "on ubuntu3"
  delegate_to: ubuntu3

# Run once on a specific host
- name: Best of both
  command: echo "once on ubuntu3"
  run_once: true
  delegate_to: ubuntu3
```

---

## 🛠️ Useful Modules for Delegation

| Module | Delegation Use Case |
|--------|---------------------|
| `lineinfile` | Modify config files on central servers |
| `fetch` | Pull files to control node |
| `copy` | Push files from control node |
| `uri` | Make API calls from control node |
| `command` | Run local scripts/tools |
| `template` | Generate configs on central server |

---

## ⚡ Quick Reference

### Basic Delegation
```yaml
- name: Run on control node
  command: echo "local"
  delegate_to: localhost
```

### Serial Writing (avoid conflicts)
```yaml
- name: Update central config
  hosts: web_servers
  serial: 1
  tasks:
    - name: Add server to config
      lineinfile:
        path: /etc/central/config
        line: "{{ inventory_hostname }}"
      delegate_to: central_server
```

### Run Once + Delegate
```yaml
- name: One-time setup
  command: /usr/local/bin/setup.sh
  run_once: true
  delegate_to: localhost
```

### Conditional Delegation
```yaml
- name: Conditional delegate
  command: /opt/special-tool
  delegate_to: "{{ 'backup01' if environment == 'prod' else 'backup-staging' }}"
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **delegate_to** | Task runs on different host than `hosts:` |
| **serial: 1** | Required when multiple hosts write to same file |
| **localhost** | Run on Ansible control node |
| **run_once** | Execute task only once across inventory |
| **hosts.allow/deny** | TCP Wrappers for service access control |

> 💡 **Pro Tip:** Use `delegate_to: localhost` for API calls, AWS CLI commands, or any tool installed on your control node

---

