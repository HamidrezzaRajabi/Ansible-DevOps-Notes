# Ansible Playbooks - Facts




## What are Ansible Facts?

Facts are **system information** automatically gathered by Ansible when a playbook runs. They provide details about your managed hosts like:

- Operating system
- IP addresses
- Memory and CPU
- Network interfaces
- Disk usage

Facts are collected by the **setup module**, which runs automatically by default.

---

## 1. Viewing Facts

### Basic Commands
```bash
# Show all facts for a host
ansible centos1 -m setup

# Show with pagination
ansible centos1 -m setup | more

# Count total facts
ansible centos1 -m setup | wc -l
```

### Filtering Facts
```bash
# Filter by keyword
ansible centos1 -m setup -a "filter=ansible_distribution"

# Filter with wildcard (all memory facts)
ansible centos1 -m setup -a "filter=ansible_mem*"

# Filter network facts only
ansible centos1 -m setup -a "gather_subset=network"

# Exclude default facts
ansible centos1 -m setup -a "gather_subset=network,!all,!min"
```

---

## 2. Common Facts Reference

| Fact | Description | Example |
|------|-------------|---------|
| `ansible_distribution` | OS distribution | "CentOS", "Ubuntu" |
| `ansible_os_family` | OS family | "RedHat", "Debian" |
| `ansible_hostname` | Hostname | "centos1" |
| `ansible_default_ipv4.address` | Primary IP | "192.168.1.10" |
| `ansible_memtotal_mb` | Total memory (MB) | 2048 |
| `ansible_processor_cores` | CPU cores | 4 |
| `ansible_processor_count` | Physical CPUs | 2 |
| `ansible_architecture` | System architecture | "x86_64" |

---

## 3. Using Facts in Playbooks

### Accessing Facts
```yaml
- hosts: all
  gather_facts: true  # Default, can be omitted

  tasks:
    # Direct access (no ansible_facts prefix)
    - name: Show OS
      debug:
        msg: "Running on {{ ansible_distribution }} {{ ansible_distribution_version }}"

    - name: Show IP
      debug:
        msg: "IP: {{ ansible_default_ipv4.address }}"

    - name: Show memory
      debug:
        msg: "Memory: {{ ansible_memtotal_mb }} MB"

    - name: Conditional tasks
      debug:
        msg: "This is a CentOS system"
      when: ansible_distribution == "CentOS"

    - name: Different package manager
      debug:
        msg: "Using {{ 'yum' if ansible_os_family == 'RedHat' else 'apt' }}"
```

---

## 4. Disabling Facts

When you don't need facts (saves time):
```yaml
- hosts: all
  gather_facts: false  # Skip fact gathering

  tasks:
    - name: Quick task without facts
      command: hostname
```

**Performance impact:** Disabling facts can reduce execution time by 1-2 seconds per host.

---

## 5. Custom Facts

### Why Custom Facts?
- Ansible's built-in facts don't cover everything
- You may need custom system information
- Perfect for application-specific data

### Creating Custom Facts

**Location:** `/etc/ansible/facts.d/` (requires root) or custom path

**Format:** Any executable script returning JSON or INI

**JSON Fact Example** (`/etc/ansible/facts.d/getdate.fact`):
```bash
#!/bin/bash
echo '{"date": "'$(date)'"}'
```
```bash
chmod +x /etc/ansible/facts.d/getdate.fact
```

**INI Fact Example** (`/etc/ansible/facts.d/getdate2.fact`):
```bash
#!/bin/bash
echo "[date]
value=$(date)"
```
```bash
chmod +x /etc/ansible/facts.d/getdate2.fact
```

### Using Custom Facts
```yaml
- hosts: all
  tasks:
    # Custom facts appear under ansible_local
    - name: Show custom fact (JSON)
      debug:
        msg: "{{ ansible_local.getdate.date }}"

    - name: Show custom fact (INI)
      debug:
        msg: "{{ ansible_local.getdate2.date.value }}"
```

---

## 6. Deploying Custom Facts

### Manual Deployment (Root)
```bash
# Create facts directory
sudo mkdir -p /etc/ansible/facts.d

# Copy fact files
sudo cp custom_fact.fact /etc/ansible/facts.d/
sudo chmod +x /etc/ansible/facts.d/custom_fact.fact
```

### Automated Deployment via Playbook
```yaml
- hosts: all
  become: true  # Requires root for /etc/ansible/facts.d

  tasks:
    - name: Create facts directory
      file:
        path: /etc/ansible/facts.d
        state: directory
        mode: '0755'

    - name: Deploy custom fact
      copy:
        src: custom_fact.fact
        dest: /etc/ansible/facts.d/
        mode: '0755'

    - name: Refresh facts
      setup:
        filter: ansible_local
```

---

## 7. Non-Root Custom Facts (Best Practice)

**Problem:** Default location requires root access  
**Solution:** Use `fact_path` to specify a custom directory

### Setup
```yaml
- hosts: all
  gather_facts: false

  tasks:
    # Create facts directory in user's home
    - name: Create facts directory
      file:
        path: "/home/{{ ansible_user }}/facts.d"
        state: directory

    # Deploy custom facts
    - name: Deploy custom facts
      copy:
        src: "{{ item }}"
        dest: "/home/{{ ansible_user }}/facts.d/"
        mode: '0755'
      loop:
        - getdate.fact
        - getdate2.fact

    # Gather facts with custom path
    - name: Gather facts
      setup:
        fact_path: "/home/{{ ansible_user }}/facts.d"

    # Use custom facts
    - name: Use custom fact
      debug:
        msg: "{{ ansible_local.getdate.date }}"
```

**Benefits:**
- No root/sudo required
- Works in restricted environments
- Facts stay with user's home directory

---

## 8. Refreshing Facts Dynamically

Facts are gathered once per play by default. To refresh during a play:

```yaml
- hosts: all
  gather_facts: true

  tasks:
    - name: Make a change to the system
      command: echo "something" > /tmp/changed

    - name: Refresh facts to detect change
      setup:

    - name: Show updated facts
      debug:
        var: ansible_local
```

---

## 9. Quick Reference Card

### Commands
```bash
# View all facts
ansible host -m setup

# Filter specific facts
ansible host -m setup -a "filter=ansible_distribution"

# Show network facts only
ansible host -m setup -a "gather_subset=network"

# View custom facts
ansible host -m setup -a "filter=ansible_local"
```

### Playbook Settings
| Setting | Purpose |
|---------|---------|
| `gather_facts: true` | Collect facts (default) |
| `gather_facts: false` | Skip fact collection |
| `gather_subset: network` | Only network facts |
| `fact_path: /custom/path` | Custom facts location |

---

## 10. Common Use Cases

### OS-Specific Tasks
```yaml
- name: Install package
  package:
    name: nginx
    state: present
  # Works on both RedHat and Debian

- name: Start service
  service:
    name: "{{ 'httpd' if ansible_os_family == 'RedHat' else 'nginx' }}"
    state: started
```

### Dynamic Configuration
```yaml
- name: Configure app with memory settings
  copy:
    content: |
      max_memory={{ ansible_memtotal_mb // 2 }}M
      cpu_cores={{ ansible_processor_cores }}
    dest: /etc/app/config.conf
```

---

## Summary

| Concept | Key Points |
|---------|------------|
| **What** | System information automatically gathered |
| **When** | Every play by default (can disable) |
| **Where** | `ansible_facts` dictionary, accessible directly |
| **How to use** | `{{ ansible_distribution }}`, `{{ ansible_memtotal_mb }}` |
| **Custom facts** | Scripts in `/etc/ansible/facts.d/` or custom path |
| **Non-root** | Use `fact_path` in setup module |
| **Performance** | Disable with `gather_facts: false` to speed up |

---
