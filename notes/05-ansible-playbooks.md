# 📜 Ansible Playbooks - Complete Guide

## 📌 What are Ansible Playbooks?

Playbooks are **YAML files** that define automation workflows in Ansible. They are:

- **Human-readable** - Written in YAML format
- **Idempotent** - Can be run multiple times safely
- **Ordered** - Tasks execute in the order defined
- **Reusable** - Can include variables, handlers, and roles

## 🏗️ Playbook Structure

### Basic Playbook Skeleton

```yaml
---
# YAML documents begin with the document separator ---

# The minus in YAML this indicates a list item.  The playbook contains a list 
# of plays, with each play being a dictionary
-

  # Hosts: where our play will run and options it will run with

  # Vars: variables that will apply to the play, on all target systems

  # Tasks: the list of tasks that will be executed within the play, this section
  #       can also be used for pre and post tasks

  # Handlers: the list of handlers that are executed as a notify key from a task

  # Roles: list of roles to be imported into the play

# Three dots indicate the end of a YAML document
...
```

## 📌 Key Sections Explained

| Section        | Purpose                               | Required? |
|---------------|----------------------------------------|-----------|
| `hosts`       | Target systems for the play            | ✅ Yes    |
| `tasks`       | Actions to perform                    | ✅ Yes    |
| `vars`        | Variables defined for the play        | ❌ Optional |
| `handlers`    | Special tasks triggered on change     | ❌ Optional |
| `roles`       | Reusable automation components        | ❌ Optional |
| `gather_facts`| Enable or disable fact gathering      | ❌ Optional |

<br>

## 📚 Learning Path

### 1. Template Structure

```yaml
---
-
  # Hosts section (empty template)
  # Vars section (empty template)
  # Tasks section (empty template)
  # Handlers section (empty template)
  # Roles section (empty template)
...
```

### 2. Basic MOTD Playbook

```yaml
---
# YAML documents begin with the document separator ---

# The minus in YAML this indicates a list item.  The playbook contains a list 
# of plays, with each play being a dictionary
-
 
  # Hosts: where our play will run and options it will run with
  hosts: centos
  user: root

  # Vars: variables that will apply to the play, on all target systems

  # Tasks: the list of tasks that will be executed within the playbook
  tasks:
    - name: Configure a MOTD (message of the day)
      copy:
        src: centos_motd
        dest: /etc/motd

  # Handlers: the list of handlers that are executed as a notify key from a task

  # Roles: list of roles to be imported into the play

# Three dots indicate the end of a YAML document
...
```

### Key Learnings

- Playbook execution: ansible-playbook motd_playbook.yaml

- First run: 🟡 Yellow (changes made)

- Second run: 🟢 Green (no changes - idempotent)

- Facts gathering happens automatically (setup module)

<br>

### 3. Disable Facts Gathering

```yaml
---
# YAML documents begin with the document separator ---

# The minus in YAML this indicates a list item.  The playbook contains a list 
# of plays, with each play being a dictionary
-
 
  # Hosts: where our play will run and options it will run with
  hosts: centos
  user: root
  gather_facts: False

  # Vars: variables that will apply to the play, on all target systems

  # Tasks: the list of tasks that will be executed within the playbook
  tasks:
    - name: Configure a MOTD (message of the day)
      copy:
        src: centos_motd
        dest: /etc/motd

  # Handlers: the list of handlers that are executed as a notify key from a task

  # Roles: list of roles to be imported into the play

# Three dots indicate the end of a YAML document
...
```

### 4. Using Content Instead of File

```yaml
---
# YAML documents begin with the document separator ---

# The minus in YAML this indicates a list item.  The playbook contains a list 
# of plays, with each play being a dictionary
-

  # Hosts: where our play will run and options it will run with
  hosts: centos
  user: root
  gather_facts: False

  # Vars: variables that will apply to the play, on all target systems

  # Tasks: the list of tasks that will be executed within the playbook
  tasks:
    - name: Configure a MOTD (message of the day)
      copy:
        content: Welcome to CentOS Linux - Ansible Rocks
        dest: /etc/motd

  # Handlers: the list of handlers that are executed as a notify key from a task

  # Roles: list of roles to be imported into the play

# Three dots indicate the end of a YAML document
...
```

### 5. Variables and Newline

```yaml
---
# YAML documents begin with the document separator ---

# The minus in YAML this indicates a list item.  The playbook contains a list 
# of plays, with each play being a dictionary
-

  # Hosts: where our play will run and options it will run with
  hosts: centos
  user: root
  gather_facts: False

  # Vars: variables that will apply to the play, on all target systems
  vars:
    motd: "Welcome to CentOS Linux - Ansible Rocks\n"

  # Tasks: the list of tasks that will be executed within the playbook
  tasks:
    - name: Configure a MOTD (message of the day)
      copy:
        content: "{{ motd }}"  # Jinja2 variable syntax
        dest: /etc/motd

  # Handlers: the list of handlers that are executed as a notify key from a task

  # Roles: list of roles to be imported into the play

# Three dots indicate the end of a YAML document
...
```

#### Variable Usage

```yaml
# Variable syntax: {{ variable_name }}
content: "{{ motd }}"

# Variables with strings: always in quotes
content: "{{ motd }} with extra text"
```

### Command-line Variable Override

```bash
# Override variable with -e or --extra-vars
ansible-playbook motd_playbook.yaml -e "motd='Custom MOTD\n'"
```

### 6. Adding Handlers

```yaml
---
# YAML documents begin with the document separator ---

# The minus in YAML this indicates a list item.  The playbook contains a list 
# of plays, with each play being a dictionary
-

  # Hosts: where our play will run and options it will run with
  hosts: centos
  user: root
  gather_facts: False

  # Vars: variables that will apply to the play, on all target systems
  vars:
    motd: "Welcome to CentOS Linux - Ansible Rocks\n"

  # Tasks: the list of tasks that will be executed within the playbook
  tasks:
    - name: Configure a MOTD (message of the day)
      copy:
        content: "{{ motd }}"
        dest: /etc/motd
      notify: MOTD changed   # Triggers handler on change

  # Handlers: the list of handlers that are executed as a notify key from a task
  handlers:
    - name: MOTD changed
      debug:
        msg: The MOTD was changed

  # Roles: list of roles to be imported into the play

# Three dots indicate the end of a YAML document
...
```

#### Handler Behavior

* Only runs when a task reports "changed" (🟡)
- Runs once at the end of all tasks
- Won't run if no changes occurred (🟢)

<br>

### 7. Multi-OS Support with Conditions

```yaml
---
# YAML documents begin with the document separator ---
 
# The minus in YAML this indicates a list item.  The playbook contains a list
# of plays, with each play being a dictionary
-
 
  # Hosts: where our play will run and options it will run with
  hosts: linux
 
  # Vars: variables that will apply to the play, on all target systems
  vars:
    motd_centos: "Welcome to CentOS Linux - Ansible Rocks\n"
    motd_ubuntu: "Welcome to Ubuntu Linux - Ansible Rocks\n"
 
  # Tasks: the list of tasks that will be executed within the playbook
  tasks:
    - name: Configure a MOTD (message of the day)
      copy:
        content: "{{ motd_centos }}"
        dest: /etc/motd
      notify: MOTD changed
      when: ansible_distribution == "CentOS"    # Condition

    - name: Configure a MOTD (message of the day)
      copy:
        content: "{{ motd_ubuntu }}"
        dest: /etc/motd
      notify: MOTD changed
      when: ansible_distribution == "Ubuntu"    # Condition
 
  # Handlers: the list of handlers that are executed as a notify key from a task
  handlers:
    - name: MOTD changed
      debug:
        msg: The MOTD was changed
 
  # Roles: list of roles to be imported into the play
 
# Three dots indicate the end of a YAML document
...
```

### 🔍 Working with Facts

#### Check Available Facts

```bash
# View all facts for a host
ansible centos1 -m setup

# Filter specific facts
ansible centos1 -m setup -a "filter=ansible_distribution*"
ansible centos1 -m setup -a "filter=ansible_*_mb"

# Compare facts across systems
ansible ubuntu2 -m setup -a "filter=ansible_distribution"
ansible centos1 -m setup -a "filter=ansible_distribution"
```

#### Common Facts Used in Conditions

``` yaml
# OS Facts
ansible_distribution: "CentOS" / "Ubuntu" / "RedHat"
ansible_os_family: "RedHat" / "Debian"
ansible_system: "Linux" / "Windows"

# Hardware Facts
ansible_processor_cores: 4
ansible_memtotal_mb: 2048
ansible_devices: {}

# Network Facts
ansible_default_ipv4.address: "192.168.1.10"
ansible_hostname: "centos1"
ansible_fqdn: "centos1.example.com"
```

#### 🛠️ Complete Inventory File

```ini
# File: hosts
[control]
ubuntu-c ansible_connection=local

[centos]
centos1 ansible_port=2222
centos[2:3]

[centos:vars]
ansible_user=root

[ubuntu]
ubuntu[1:3]

[ubuntu:vars]
ansible_become=true
ansible_become_pass=password

[linux:children]
centos
ubuntu
```

#### 📝 Configuration File (ansible.cfg)

```ini
[defaults]
inventory = hosts
host_key_checking = False
```

<br>

## 📊 Playbook Execution Flow

1. Parse YAML playbook
2. Load inventory
3. Connect to targets
4. Gather facts (if enabled)
5. Execute tasks in order
   ↓
6. If task changes → mark as changed
   ↓
7. After all tasks → run handlers for changed tasks
   ↓
8. Display results with color coding

## 🎨 Color Coding in Output

| Color        | Meaning                         | Example                              |
|-------------|----------------------------------|--------------------------------------|
| 🟢 Green     | OK – No changes                 | Task already in desired state       |
| 🟡 Yellow    | Changed – Success with changes  | Task modified the system            |
| 🔴 Red       | Failed – Error occurred         | Connection or execution error       |
| 🔵 Blue      | Skipped – Condition not met     | Task skipped when condition is false|

<br>

## 📋 Common Playbook Directives

#### Host/Connection Directives

```yaml
hosts: webservers           # Target hosts/group
user: ansible                # SSH user
become: yes                  # Enable privilege escalation
become_method: sudo          # Escalation method
become_user: root            # User to become
connection: ssh              # Connection type
port: 2222                   # SSH port
```

#### Task Control Directives

``` yaml
ignore_errors: yes           # Continue even if task fails
changed_when: false          # Don't mark as changed
failed_when: result.rc != 0  # Custom failure condition
when: ansible_os_family == "Debian"  # Conditional execution
loop: "{{ items_list }}"     # Loop over items
Play Control Directives
yaml
gather_facts: true           # Collect facts (default)
gather_timeout: 10           # Fact gathering timeout
serial: 5                     # Batch size for rolling updates
max_fail_percentage: 30       # Fail if >30% hosts fail
any_errors_fatal: true        # Stop play on any error
```

### 💡 Pro Tips

#### 1. Debug Your Playbooks

```yaml
- name: Debug variable
  debug:
    var: motd_centos

- name: Debug with message
  debug:
    msg: "Current OS is {{ ansible_distribution }}"
```

#### 2. Check Mode (Dry Run)

```bash
# See what would change without applying
ansible-playbook motd_playbook.yaml --check
```

#### 3. Step-by-Step Execution

```bash
# Confirm each task before running
ansible-playbook motd_playbook.yaml --step
```

#### 4. Limit to Specific Hosts

```bash
# Run only on centos1
ansible-playbook motd_playbook.yaml --limit centos1
```

#### 5. Verbose Output

```bash
# More details (-v, -vv, -vvv, -vvvv)
ansible-playbook motd_playbook.yaml -v
ansible-playbook motd_playbook.yaml -vvv
```

### ⚠️ Common Pitfalls

#### 1. YAML Syntax Errors

```yaml
# ❌ Wrong - missing space after colon
content:"{{ motd }}"

# ✅ Correct
content: "{{ motd }}"
```

#### 2. Variable Quotes

```yaml
# ❌ Wrong - quotes inside variable
content: "{{ "motd" }}"

# ✅ Correct
content: "{{ motd }}"
```

### 3. Boolean Values

``` yaml
# ❌ Wrong (string instead of boolean)
gather_facts: "false"

# ✅ Correct
gather_facts: false
```

#### 4. Handler Not Running

```yaml
# ❌ Wrong - notify before task definition
handlers:
  - name: MOTD changed
    debug:

tasks:
  - name: Configure MOTD
    notify: MOTD changed  # This works, but order matters

# ✅ Correct - handlers after tasks
tasks:
  - name: Configure MOTD
    notify: MOTD changed

handlers:
  - name: MOTD changed
    debug:
```


## 📚 Playbook Keywords Reference

Essential keywords from  [Ansible Playbook Keywords](https://docs.ansible.com/projects/ansible/latest/reference_appendices/playbooks_keywords.html)

| Keyword        | Used In     | Purpose                         |
|---------------|------------|----------------------------------|
| `hosts`       | Play        | Target hosts                    |
| `tasks`       | Play        | List of tasks                   |
| `handlers`    | Play        | Special task list               |
| `vars`        | Play        | Play-level variables            |
| `roles`       | Play        | Import reusable roles           |
| `gather_facts`| Play        | Enable or disable fact gathering|
| `become`      | Play/Task   | Privilege escalation            |
| `when`        | Task        | Conditional execution           |
| `notify`      | Task        | Trigger a handler               |
| `ignore_errors`| Task       | Continue execution on error     |
| `changed_when`| Task        | Custom change condition         |
| `failed_when` | Task        | Custom failure condition        |

