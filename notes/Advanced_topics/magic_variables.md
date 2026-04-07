# ✨ Magic Variables



## 📌 What are Magic Variables?

Magic variables are **automatically available** variables in Ansible that provide information about:
- The playbook execution environment
- Inventory structure
- Host relationships
- Runtime information

> ⚠️ **Note:** Documentation on magic variables is scarce. New Ansible versions may introduce or change them.

---

## 🎯 The Best Way to Discover Magic Variables

Instead of memorizing them, **dump all variables** from a playbook!

### 📁  Variable Dump Playbook

**`dump_vars_playbook.yaml`:**
```yaml
---
-
  hosts: all

  tasks:
    - name: Create remote file with all variables
      template:
        src: templates/dump_variables
        dest: /tmp/ansible_variables

    - name: Fetch the file back to control host
      fetch:
        src: /tmp/ansible_variables
        dest: "captured_variables/{{ ansible_hostname }}"
        flat: yes

    - name: Clean up
      file: 
        name: /tmp/ansible_variables
        state: absent
```

**`templates/dump_variables`:**
```jinja2
PLAYBOOK VARS (Ansible vars):

{{ vars | to_nice_yaml }}
```

> 💡 **`to_nice_yaml` filter** - Formats output as readable YAML instead of raw JSON

---

## 🚀 How to Use This Playbook

```bash
# Run the playbook
ansible-playbook dump_vars_playbook.yaml

# View captured variables for a specific host
cat captured_variables/centos1

# Search for specific variables
cat captured_variables/centos1 | grep -A5 "inventory_hostname"
cat captured_variables/centos1 | grep -A5 "group_names"
```

---

## 📊 Common Magic Variables Reference

| Variable | Purpose | Example Value |
|----------|---------|---------------|
| `hostvars` | All variables for all hosts | `hostvars['centos1'].ansible_port` |
| `groups` | All groups in inventory | `groups['linux']` |
| `group_names` | Groups current host belongs to | `['centos', 'linux']` |
| `inventory_hostname` | Current hostname from inventory | `centos1` |
| `inventory_hostname_short` | Short hostname (no domain) | `centos1` |
| `inventory_dir` | Directory of inventory file | `/home/ansible/inventory` |
| `ansible_play_hosts` | Hosts in current play | `['centos1', 'centos2']` |
| `play_hosts` | Deprecated, use `ansible_play_hosts` | Same as above |
| `ansible_play_batch` | Current batch (with serial) | `['centos1']` |
| `ansible_version` | Ansible version info | `{'full': '2.9.0', ...}` |
| `omit` | Special value to omit parameter | `parameter: {{ value | default(omit) }}` |

---

## 🎯 Using Common Magic Variables

### `hostvars` - Access Any Host's Variables
```yaml
- name: Get web server IP from another host
  debug:
    msg: "Web server IP is {{ hostvars['web01'].ansible_default_ipv4.address }}"
```

### `groups` - List All Hosts in a Group
```yaml
- name: Show all database servers
  debug:
    msg: "DB servers: {{ groups['database'] | join(', ') }}"
```

### `group_names` - Current Host's Groups
```yaml
- name: Conditional based on group membership
  debug:
    msg: "This is a web server"
  when: "'webservers' in group_names"
```

### `inventory_hostname` vs `ansible_hostname`
```yaml
- name: Difference between inventory and system hostname
  debug:
    msg: |
      Inventory name: {{ inventory_hostname }}
      System hostname: {{ ansible_hostname }}
```

| Variable | Source | Example |
|----------|--------|---------|
| `inventory_hostname` | Inventory file | `centos1-prod` |
| `ansible_hostname` | System's actual hostname | `centos1` |

### `omit` - Conditionally Skip Parameters
```yaml
- name: Create user with optional password
  user:
    name: "{{ username }}"
    password: "{{ user_password | default(omit) }}"
    # If user_password not defined, password parameter is omitted entirely
```

---

## 📁 Captured Variables Output Example

Running the dump playbook on `centos1` produces:

```yaml
PLAYBOOK VARS (Ansible vars):

ansible_play_hosts:
  - centos1
  - centos2
  - centos3
  - ubuntu1
  - ubuntu2
  - ubuntu3
ansible_version:
  full: 2.9.0
  major: 2
  minor: 9
  revision: 0
group_names:
  - centos
  - linux
groups:
  all:
    hosts:
      - centos1
      - centos2
      - centos3
      - ubuntu1
      - ubuntu2
      - ubuntu3
  centos:
    hosts:
      - centos1
      - centos2
      - centos3
  linux:
    children:
      - centos
      - ubuntu
  ubuntu:
    hosts:
      - ubuntu1
      - ubuntu2
      - ubuntu3
hostvars:
  centos1:
    ansible_port: 2222
    ansible_user: root
  centos2:
    ansible_user: root
  # ... all host variables
inventory_dir: /home/ansible/diveintoansible/.../01
inventory_hostname: centos1
inventory_hostname_short: centos1
```

---

## 🛠️ Quick Debug Commands

```bash
# Show all variables for a host (command line)
ansible centos1 -m debug -a "var=hostvars[inventory_hostname]"

# Show specific variable
ansible centos1 -m debug -a "var=group_names"

# Show inventory groups
ansible localhost -m debug -a "var=groups"

# Show ansible version
ansible localhost -m debug -a "var=ansible_version"

# List all hosts in a group
ansible localhost -m debug -a "var=groups['centos']"
```

---

## 📊 In-Playbook Debugging

```yaml
- name: Debug all host variables
  debug:
    var: hostvars[inventory_hostname]

- name: Debug specific magic variable
  debug:
    var: group_names

- name: Debug with custom message
  debug:
    msg: "This host is in groups: {{ group_names | join(', ') }}"

- name: Show playbook execution info
  debug:
    msg: |
      Running on {{ inventory_hostname }}
      Ansible version: {{ ansible_version.full }}
      Inventory directory: {{ inventory_dir }}
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **Best Practice** | Dump `{{ vars \| to_nice_yaml }}` to discover available variables |
| **hostvars** | Access variables from ANY host |
| **groups** | List of all inventory groups |
| **group_names** | Groups current host belongs to |
| **inventory_hostname** | Hostname from inventory file |
| **omit** | Skip parameters conditionally |

> 💡 **Pro Tip:** Keep the variable dump playbook in your GitHub repo. Run it whenever you need to discover available variables for your environment!

---
