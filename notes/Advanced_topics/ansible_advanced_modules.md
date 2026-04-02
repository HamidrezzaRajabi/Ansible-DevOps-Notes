# 📦 Ansible Playbook Modules - Deep Dive



## 📌 What You'll Learn

This section covers **essential modules** for production playbooks:

| Module | Purpose |
|--------|---------|
| `set_fact` | Create/modify variables at runtime |
| `pause` | Stop execution for time or user input |
| `wait_for` | Wait for conditions (ports, files) |
| `assemble` | Merge config files into one |
| `add_host` | Dynamically add hosts to inventory |
| `group_by` | Create groups based on facts |
| `fetch` | Retrieve files from remote hosts |

---

## 🎯 1. set_fact - Dynamic Variables

### 📁 1: Basic Set Fact

```yaml
---
-
  hosts: ubuntu3,centos3
  
  tasks:
    - name: Set a fact
      set_fact:
        our_fact: Ansible Rocks!

    - name: Show custom fact
      debug:
        msg: "{{ our_fact }}"
...
```

**Output:** `msg: Ansible Rocks!`

> 💡 **Use case:** Create variables during playbook execution

---

### 📁 2: Set Multiple Facts + Override

```yaml
---
-
  hosts: ubuntu3,centos3
  
  tasks:
    - name: Set multiple facts
      set_fact:
        our_fact: Ansible Rocks!
        ansible_distribution: "{{ ansible_distribution | upper }}"

    - name: Show our_fact
      debug:
        msg: "{{ our_fact }}"

    - name: Show ansible_distribution (overridden)
      debug:
        msg: "{{ ansible_distribution }}"
...
```

**Output:**
```
msg: Ansible Rocks!
msg: UBUNTU   (or CENTOS)
```

> ⚠️ **Warning:** You can override built-in facts!

---

### 📁 3: OS-Specific Variables

```yaml
---
-
  hosts: ubuntu3,centos3
  
  tasks:
    - name: Set CentOS variables
      set_fact:
        webserver_application_port: 80
        webserver_application_path: /usr/share/nginx/html
        webserver_application_user: root
      when: ansible_distribution == 'CentOS'

    - name: Set Ubuntu variables
      set_fact:
        webserver_application_port: 8080
        webserver_application_path: /var/www/html
        webserver_application_user: nginx
      when: ansible_distribution == 'Ubuntu'

    - name: Show facts
      debug:
        msg: "port:{{ webserver_application_port }} path:{{ webserver_application_path }} user:{{ webserver_application_user }}"
...
```

**Output (CentOS):**
```
msg: port:80 path:/usr/share/nginx/html user:root
```

**Output (Ubuntu):**
```
msg: port:8080 path:/var/www/html user:nginx
```

> 💡 **Use case:** Replace group_vars with dynamic decisions!

---

## ⏸️ 2. pause - Stop Execution

### 📁 4: Pause for Time

```yaml
---
-
  hosts: ubuntu3,centos3
  
  tasks:
    - name: Pause our playbook for 10 seconds
      pause:
        seconds: 10
...
```

**Execution:**
```
TASK [Pause our playbook for 10 seconds] 
Pausing for 10 seconds
(ctrl+C then 'C' = continue early, 'A' = abort)
```

> 💡 **Use case:** Wait for services to stabilize

---

### 📁 5: Pause with User Prompt

```yaml
---
-
  hosts: ubuntu3,centos3
  
  tasks:
    - name: Prompt user to verify before continue
      pause:
        prompt: Please check that the webserver is running, press enter to continue
...
```

**Execution:**
```
TASK [Prompt user to verify] 
Please check that the webserver is running, press enter to continue
[press enter]
```

> 💡 **Use case:** Manual verification before critical changes

---

## ⏰ 3. wait_for - Wait for Conditions

### Setup: Run Web Server First

**`run_webserver_playbook.yaml`:**
```yaml
---
-
  hosts: ubuntu3,centos3
  
  tasks:
    - name: Install EPEL (CentOS)
      yum:
        name: epel-release
        update_cache: yes
        state: latest
      when: ansible_distribution == 'CentOS'

    - name: Install Nginx
      package:
        name: nginx
        state: latest

    - name: Restart nginx
      service:
        name: nginx
        state: restarted
...
```

### 📁 6: Wait for Port

**`wait_for_playbook.yaml`:**
```yaml
---
-
  hosts: ubuntu3,centos3
  
  tasks:
    - name: Wait for the webserver to be running on port 80
      wait_for:
        port: 80
...
```

**Demo Commands:**
```bash
# Start web server
ansible-playbook run_webserver_playbook.yaml

# Wait for port (should succeed quickly)
ansible-playbook wait_for_playbook.yaml

# Stop nginx on one host
ansible centos3 -m service -a "name=nginx state=stopped"

# Run wait_for in background
ansible-playbook wait_for_playbook.yaml &

# Start nginx again
ansible centos3 -m service -a "name=nginx state=started"

# Background task completes!
```

> 💡 **Use case:** Wait for services to start after reboot

**wait_for options:**
| Parameter | Purpose |
|-----------|---------|
| `port: 80` | Wait for port to be open |
| `host: 0.0.0.0` | Specific host |
| `timeout: 300` | Max seconds to wait |
| `delay: 10` | Seconds before checking |
| `path: /tmp/file` | Wait for file to exist |

---

## 🔧 4. assemble - Merge Config Files

### File Structure
```
conf.d/
├── defaults      # Default SSH config
└── centos1       # Host-specific config
```

**`conf.d/defaults`:**
```
## Defaults

Port 22
Protocol 2
ForwardX11 yes
GSSAPIAuthentication no
```

**`conf.d/centos1`:**
```
## Custom for centos1
Host centos1
  User root
  Port 2222
```

### 📁 7: Assemble Playbook

```yaml
---
-
  hosts: centos1
  
  tasks:
    - name: Assemble SSH config from fragments
      assemble:
        src: conf.d/
        dest: sshd_config
...
```

**Result (`sshd_config`):**
```
## Custom for centos1
Host centos1
  User root
  Port 2222

## Defaults

Port 22
Protocol 2
ForwardX11 yes
GSSAPIAuthentication no
```

> 💡 **Use case:** Manage large configs by splitting into smaller files

**assemble options:**
| Parameter | Purpose |
|-----------|---------|
| `src` | Source directory with fragments |
| `dest` | Destination assembled file |
| `regexp: '^[a-zA-Z]'` | Only include files matching pattern |
| `ignore_hidden: yes` | Skip hidden files |

---

## 🏷️ 5. add_host - Dynamic Inventory

### 📁 8: Add Hosts During Play

```yaml
---
# PLAY 1
-
  hosts: ubuntu-c
  
  tasks:
    - name: Add centos1 to adhoc_group
      add_host:
        name: centos1
        groups: adhoc_group1, adhoc_group2

# PLAY 2 - Uses newly created group
-
  hosts: adhoc_group1
  
  tasks:
    - name: Ping all in adhoc_group1
      ping:
...
```

**Output:**
```
PLAY [ubuntu-c] *************
TASK [Add centos1 to adhoc_group] **********
ok: [ubuntu-c]

PLAY [adhoc_group1] *************
TASK [Ping all in adhoc_group1] **********
pong: centos1
```

> 💡 **Use case:** Build dynamic inventory based on previous tasks

### 📁 9: Alternative YAML Format

```yaml
---
- hosts: ubuntu-c
  tasks:
    - name: Add centos1 to adhoc_group
      add_host:
        name: centos1
        groups: adhoc_group1, adhoc_group2

- hosts: adhoc_group1
  tasks:
    - name: Ping all in adhoc_group1
      ping:
...
```

> 📝 **Note:** Both indentation styles are valid YAML!

---

## 👥 6. group_by - Dynamic Groups

### 📁 10: Create Groups from Facts

```yaml
---
# PLAY 1 - Create dynamic groups
-
  hosts: all
  
  tasks:
    - name: Create group based on ansible_distribution
      group_by:
        key: "custom_{{ ansible_distribution | lower }}"

# PLAY 2 - Target only CentOS hosts
-
  hosts: custom_centos
  
  tasks:
    - name: Ping all in custom_centos
      ping:
...
```

**Dynamic groups created:**
- `custom_centos` (centos1, centos2, centos3)
- `custom_ubuntu` (ubuntu1, ubuntu2, ubuntu3)

**Output:**
```
PLAY [custom_centos] *************
TASK [Ping all in custom_centos] **********
pong: centos1
pong: centos2
pong: centos3
```

> 💡 **Use case:** Create OS-specific groups without inventory files

---

## 📥 7. fetch - Retrieve Files

### 📁 11: Fetch System Files

```yaml
---
-
  hosts: centos
  
  tasks:
    - name: Fetch /etc/redhat-release
      fetch:
        src: /etc/redhat-release
        dest: /tmp/redhat-release
...
```

**Resulting directory structure:**
```
/tmp/redhat-release/
├── centos1/
│   └── etc/
│       └── redhat-release
├── centos2/
│   └── etc/
│       └── redhat-release
└── centos3/
    └── etc/
        └── redhat-release
```

> 💡 **Use case:** Collect logs or configs from all servers

**fetch options:**
| Parameter | Purpose |
|-----------|---------|
| `src` | Remote file path |
| `dest` | Local destination directory |
| `flat: yes` | Don't create host subdirectories |
| `validate_checksum: yes` | Verify file integrity |

---

## 📊 Module Comparison

| Module | When to Use | Key Feature |
|--------|-------------|-------------|
| `set_fact` | Need runtime variables | Create/override facts |
| `pause` | Need time delay | Simple seconds wait |
| `wait_for` | Need condition check | Port/file/socket ready |
| `assemble` | Many small config files | Merge fragments |
| `add_host` | Dynamic inventory | Add hosts mid-play |
| `group_by` | Group based on facts | Dynamic grouping |
| `fetch` | Collect remote files | Pull to control node |

---

## 🎯 Practice Exercises

### Exercise 1: Dynamic Web Server Config

Create a playbook that:
1. Uses `set_fact` to set web root based on OS
2. Creates a test file in the correct web root
3. Uses `wait_for` to verify it's accessible

**Solution:**
```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Set web root for CentOS
      set_fact:
        web_root: /usr/share/nginx/html
      when: ansible_distribution == 'CentOS'

    - name: Set web root for Ubuntu
      set_fact:
        web_root: /var/www/html
      when: ansible_distribution == 'Ubuntu'

    - name: Create test file
      copy:
        content: "Ansible Rocks!"
        dest: "{{ web_root }}/test.html"

    - name: Wait for file to be accessible
      wait_for:
        path: "{{ web_root }}/test.html"
```

---

### Exercise 2: Dynamic Group Targeting

Create a playbook that:
1. Groups hosts by OS distribution
2. Runs specific tasks only on Ubuntu hosts

**Solution:**
```yaml
---
-
  hosts: all
  tasks:
    - name: Create OS-based groups
      group_by:
        key: "os_{{ ansible_distribution | lower }}"

-
  hosts: os_ubuntu
  tasks:
    - name: Ubuntu specific task
      debug:
        msg: "Running on Ubuntu!"

-
  hosts: os_centos
  tasks:
    - name: CentOS specific task
      debug:
        msg: "Running on CentOS!"
```

---

## 🚀 Quick Reference

### set_fact
```yaml
set_fact:
  var1: value1
  var2: "{{ existing_var | upper }}"
```

### pause
```yaml
pause:
  seconds: 30              # Time delay
  # OR
  prompt: "Press enter"    # User input
```

### wait_for
```yaml
wait_for:
  port: 80                 # TCP port
  host: 0.0.0.0           # Specific host
  timeout: 300            # Max seconds
  delay: 10               # Before checking
```

### assemble
```yaml
assemble:
  src: conf.d/            # Source directory
  dest: config.conf       # Destination file
```

### add_host
```yaml
add_host:
  name: newhost           # Hostname/IP
  groups: group1,group2   # Groups to add to
```

### group_by
```yaml
group_by:
  key: "custom_{{ fact }}"  # Dynamic group name
```

### fetch
```yaml
fetch:
  src: /remote/file       # Remote path
  dest: /local/dir/       # Local destination
```

---

## ✅ Summary

| Module | Command | When to Use |
|--------|---------|-------------|
| `set_fact` | Dynamic vars | OS-specific config |
| `pause` | Stop execution | Manual verification |
| `wait_for` | Condition wait | Service readiness |
| `assemble` | Merge files | Large configs |
| `add_host` | Dynamic inventory | Runtime host addition |
| `group_by` | Dynamic groups | Fact-based grouping |
| `fetch` | Pull files | Log collection |

---

