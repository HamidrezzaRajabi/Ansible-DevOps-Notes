# 📜 Ansible Playbooks - Variables Complete Guide


## 📌 What are Ansible Variables?

Variables in Ansible provide a way to store and manage values that can be used throughout your playbooks. They make your automation:

- **Dynamic** - Same playbook can work with different values
- **Reusable** - Write once, use with different configurations
- **Maintainable** - Change values in one place, affect everywhere
- **Secure** - Sensitive data can be stored separately

---

## 🏗️ Variable Types and Structures

### 1. Simple Key-Value Variables

```yaml
vars:
  example_key: "example value"
  username: "john"
  port_number: 8080
  enable_feature: true
  ```
  

### 2. Dictionaries (Hashes)

```yaml
vars:
  # Standard dictionary
  user_info:
    name: "John Doe"
    age: 30
    email: "john@example.com"
  
  # Inline dictionary
  server_config: {host: "webserver", port: 443, ssl: true}
  ```

 ### 3. Lists (Arrays)

```yaml
vars:
  # Standard list
  packages:
    - httpd
    - mariadb
    - php
  
  # Inline list
  users: ["alice", "bob", "charlie"]
  
  # List of dictionaries
  employees:
    - name: "Alice"
      role: "Developer"
    - name: "Bob"
      role: "Manager"
```

<br>
<br>

## 📚 Ansible Variables -- Learning Path 


### 🔹 Basic Key-Value Variables

``` yaml
---
- hosts: centos1
  gather_facts: False
  vars:
    example_key: example value

  tasks:
    - name: Test dictionary key value
      debug:
        msg: "{{ example_key }}"
...
```

<br>

**Key Takeaway:** Simple variables are accessed using
`{{ variable_name }}`

---


### 🔹 Dictionary Variables

``` yaml
---
- hosts: centos1
  gather_facts: False
  vars:
    dict:
      dict_key: This is a dictionary value

  tasks:
    - name: Test named dictionary
      debug:
        msg: "{{ dict }}"

    - name: Test with dot notation
      debug:
        msg: "{{ dict.dict_key }}"

    - name: Test with bracket notation
      debug:
        msg: "{{ dict['dict_key'] }}"
...
```
<br>

**Key Takeaway:** Dictionaries can be accessed using dot notation
(`.key`) or bracket notation (`['key']`).

------------------------------------------------------------------------

### 🔹 Inline Dictionary Variables

``` yaml
---
- hosts: centos1
  gather_facts: False
  vars:
    inline_dict: { inline_dict_key: This is an inline dictionary value }

  tasks:
    - name: Test inline dictionary
      debug:
        msg: "{{ inline_dict.inline_dict_key }}"
...
```

------------------------------------------------------------------------

### 🔹 List Variables

``` yaml
---
- hosts: centos1
  gather_facts: False
  vars:
    named_list:
      - item1
      - item2
      - item3
      - item4

  tasks:
    - name: Test first item
      debug:
        msg: "{{ named_list[0] }}"
...
```
<br>

**Key Takeaway:** Lists are zero-indexed.

------------------------------------------------------------------------

### 🔹 Inline List Variables

``` yaml
---
-
  hosts: centos1
  gather_facts: False
  vars:
    inline_named_list:
      [ item1, item2, item3, item4 ]
 
  tasks:
    - name: Test inline list
      debug:
        msg: "{{ inline_named_list }}"
 
    - name: Test first item with dot notation
      debug:
        msg: "{{ inline_named_list.0 }}"
 
    - name: Test first item with bracket notation
      debug:
        msg: "{{ inline_named_list[0] }}"
...
```

------------------------------------------------------------------------

### 🔹 External Variable Files

``` yaml
---
-
  hosts: centos1
  gather_facts: False
  vars_files:
    - external_vars.yaml
 
  tasks:
    - name: Test external key value
      debug:
        msg: "{{ external_example_key }}"

    - name: Test external dictionary
      debug:
        msg: "{{ external_dict }}"

    - name: Test external dict with dot notation
      debug:
        msg: "{{ external_dict.dict_key }}"

    - name: Test external dict with bracket notation
      debug:
        msg: "{{ external_dict['dict_key'] }}"
 
    - name: Test external list
      debug:
        msg: "{{ external_named_list }}"
 
    - name: Test external list first item
      debug:
        msg: "{{ external_named_list.0 }}"
...
```

<br>

**External Variables File (`external_vars.yaml`):**

``` yaml
---
external_example_key: example value from external file

external_dict:
  dict_key: This is a dictionary value from an external file

external_inline_dict: {inline_dict_key: This is an inline dictionary value from an external file}

external_named_list:
  - item1 from external file
  - item2 from external file

external_inline_named_list: [ item1 from external file, item2 from external file ]
...
```
<br>

**Key Takeaway:**  Use `vars_files` to separate variables from playbook logic for better organization



------------------------------------------------------------------------

### 🔹 Vars Prompt (Username - Non-Private)

``` yaml
---
-
  hosts: centos1
  gather_facts: False
  vars_prompt:
    - name: username
      private: False  # Value will be shown as you type
 
  tasks:
    - name: Test vars_prompt
      debug:
        msg: "{{ username }}"
...
```

<br>

**Key Takeaway:** Use `vars_prompt` for interactive playbooks and use `private: True` for sensitive values.

------------------------------------------------------------------------

### 🔹  Vars Prompt (Password - Private)

``` yaml
---
-
  hosts: centos1
  gather_facts: False
  vars_prompt:
    - name: password
      private: True  # Value will be hidden as you type
 
  tasks:
    - name: Test vars_prompt
      debug:
        msg: "{{ password }}"
...
```
<br>

**Key Takeaway:** Use `default()` to prevent failures from undefined
variables.

------------------------------------------------------------------------

### 🔹 Accessing Host Variables with hostvars


```yaml
---
-
  hosts: centos1
  gather_facts: True
 
  tasks:
    - name: Test hostvars with dot notation
      debug:
        msg: "{{ hostvars[ansible_hostname].ansible_port }}"

    - name: Test hostvars with dict notation
      debug:
        msg: "{{ hostvars[ansible_hostname]['ansible_port'] }}"
...
```

#### Inventory `(hosts)`:

```ini
[centos]
centos1 ansible_port=2222
centos2
centos3
```

**Key Takeaway:** `hostvars` allows access to any host's variables from any host

Inventory example:

``` ini
[centos:vars]
ansible_user=root
```

## Accessing Group Variables


```yaml
---
-
  hosts: centos
  gather_facts: True
 
  tasks:
    - name: Test groupvars
      debug:
        msg: "{{ ansible_user }}"
...
```

#### Inventory Group Vars:

```ini
[centos:vars]
ansible_user=root
```

Output:

```text
centos1: msg: root
centos2: msg: root
centos3: msg: root
```

**Key Takeaway:**  Group variables are automatically available to all hosts in the group

<br>

### Group Variables in hostvars


```yaml
---
-
  hosts: centos1
  gather_facts: True
 
  tasks:
    - name: Test groupvars in hostvars
      debug:
        msg: "{{ hostvars[ansible_hostname].ansible_user }}"
...
```

Output:

```text
msg: root
```

**Key Takeaway:** Group variables are also accessible through hostvars

<br>


### Combining Multiple Variable Access Methods


```yaml
---
-
  hosts: centos1
  gather_facts: True
 
  tasks:
    - name: Test hostvars for port
      debug:
        msg: "{{ hostvars[ansible_hostname].ansible_port }}"

    - name: Test groupvars for user
      debug:
        msg: "{{ ansible_user }}"
...
```

Output:

```text
msg: 2222
msg: root
```

---

## 📁 Directory-Based Variables

### Directory Structure for Host and Group Variables

```text
inventory/
├── hosts
├── host_vars/
│   ├── centos1
│   ├── centos2
│   ├── ubuntu-c
│   └── ...
└── group_vars/
    ├── centos
    ├── ubuntu
    ├── linux
    └── ...
```

#### Host Variables Files


`host_vars/centos1:`


```yaml
---
ansible_port: 2222
...
```


`host_vars/ubuntu-c:`

```yaml
---
ansible_connection: local
...
```

#### Group Variables Files

`group_vars/centos:`

```yaml
---
ansible_user: root
...
group_vars/ubuntu:
```

```yaml
---
ansible_become: true
ansible_become_pass: password
...
```

**Key Takeaway:**
- Place host-specific variables in host_vars/hostname
- Place group-specific variables in group_vars/groupname
- Ansible automatically loads these files


------------------------------------------------------------------------

## 🚀 Extra Variables (Command Line)

### Passing Variables via Command Line

```yaml
---
-
  hosts: centos1
  tasks:
    - name: Test extra vars
      debug:
        msg: "{{ extra_vars_key }}"
...
```

### Different Ways to Pass Extra Variables

#### 1. Key=Value Format (INI style):

```bash
ansible-playbook variables_playbook.yaml -e "extra_vars_key=value_from_cli"
```

#### 2. JSON Format:

```bash
ansible-playbook variables_playbook.yaml -e '{"extra_vars_key":"value_from_json"}'
```

#### 3. YAML Format:

```bash
ansible-playbook variables_playbook.yaml -e "extra_vars_key: value_from_yaml"
```

#### 4. From File (YAML):

```bash
# extra_vars.yaml
# ---
# extra_vars_key: value_from_yaml_file

ansible-playbook variables_playbook.yaml -e @extra_vars.yaml
```

#### 5. From File (JSON):

```bash
# extra_vars.json
# {"extra_vars_key": "value_from_json_file"}

ansible-playbook variables_playbook.yaml -e @extra_vars.json
```


## 🎯 Complete Reference: Variable Access Methods

### 📌 Variable Definition Methods

| Method                | Syntax            | Use Case                          |
|----------------------|------------------|----------------------------------|
| Playbook vars        | `vars:`          | Play-specific variables          |
| Playbook vars_files  | `vars_files:`    | External variable files          |
| Inventory (INI)      | `[group:vars]`   | Group-level variables            |
| Inventory (YAML)     | `group_vars/`    | Directory-based group variables  |
| Host variables       | `host_vars/`     | Host-specific variables          |
| Command line (`-e`)  | `-e "key=value"` | Runtime overrides                |
| vars_prompt          | `vars_prompt:`   | Interactive input                |
| Facts                | `ansible_facts`  | System-gathered data             |

---

### 🔑 Variable Access Syntax

| Data Type            | Access Method                              | Example                                      |
|---------------------|---------------------------------------------|----------------------------------------------|
| Simple variable     | `{{ variable }}`                            | `{{ username }}`                             |
| Dictionary (dot)    | `{{ dict.key }}`                            | `{{ user.name }}`                            |
| Dictionary (bracket)| `{{ dict['key'] }}`                         | `{{ user['name'] }}`                         |
| List item (dot)     | `{{ list.0 }}`                              | `{{ packages.0 }}`                           |
| List item (bracket) | `{{ list[0] }}`                             | `{{ packages[0] }}`                          |
| hostvars (dot)      | `{{ hostvars[host].var }}`                  | `{{ hostvars['centos1'].ansible_port }}`     |
| hostvars (bracket)  | `{{ hostvars[host]['var'] }}`               | `{{ hostvars['centos1']['ansible_port'] }}`  |
| With default        | `{{ variable \| default('default') }}`      | `{{ ansible_port \| default('22') }}`        |

---

### 📊 Variable Precedence (Highest to Lowest)

```text
1. Extra vars (-e) always win
2. vars_prompt
3. vars_files
4. Playbook vars
5. Host variables (host_vars/)
6. Group variables (group_vars/)
7. Inventory group vars ([group:vars])
8. Role defaults
```

### 💡 Pro Tips

#### 1. Debugging Variables

```yaml
- name: Show all variables for a host
  debug:
    var: hostvars[inventory_hostname]

- name: Show specific variable
  debug:
    var: ansible_port

- name: Show with message
  debug:
    msg: "The port is {{ ansible_port | default('22') }}"
```

#### 2. Combining Variables

```yaml
vars:
  app_name: myapp
  version: 1.0
  full_name: "{{ app_name }}-{{ version }}"
  # Results in: myapp-1.0
```
#### 3. Variable Quoting Rules

```yaml
# ✅ Correct
msg: "{{ variable }}"
msg: "Text {{ variable }} more text"
msg: "{{ variable }} with {{ other }}"

# ❌ Wrong
msg: {{ variable }}  # Missing quotes
msg: "{{ variable }}"  # Extra quotes inside
```

#### 4. Checking if Variable Exists

```yaml
- name: Check if variable is defined
  debug:
    msg: "Variable exists"
  when: my_variable is defined

- name: Check if variable is not defined
  debug:
    msg: "Variable missing"
  when: my_variable is not defined
```

<br>


## 🚀 Quick Reference Card

### Common Variable Operations

```bash
# List all variables for a host
ansible hostname -m setup

# Pass extra variables
ansible-playbook play.yaml -e "key=value"
ansible-playbook play.yaml -e @vars.json
ansible-playbook play.yaml -e @vars.yaml

# Debug variable
ansible hostname -m debug -a "var=variable_name"

# Check variable existence
ansible hostname -m debug -a "var=variable_name" 2>/dev/null || echo "Undefined"
Variable File Templates
```

#### `group_vars/all` (applies to all hosts):


```yaml
---
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
timezone: UTC
...
```

`host_vars/webserver01:`


```yaml
---
ip_address: 192.168.1.10
role: web
apps:
  - nginx
  - nodejs
...

```

### Variable Precedence Summary

```text
-e (highest)
vars_prompt
vars_files
playbook vars
host_vars/
group_vars/
inventory group vars
role defaults (lowest)
```

### ⚠️ Common Pitfalls

#### 1. Missing Quotes

```yaml
# ❌ Wrong
msg: {{ variable }}

# ✅ Correct
msg: "{{ variable }}"
```

#### 2. Undefined Variables

```yaml
# ❌ Will fail if variable doesn't exist
msg: "{{ undefined_var }}"

# ✅ Safe with default
msg: "{{ undefined_var | default('fallback') }}"
```

#### 3. Incorrect Dictionary Access

```yaml
vars:
  user:
    name: "John"

# ❌ Wrong
msg: "{{ user.name }}"  # Works but misleading

# ✅ Correct for nested dicts
msg: "{{ user['name'] }}"
msg: "{{ user.name }}"  # Also correct
```

#### 4. List Index Errors

```yaml
vars:
  items: [1, 2, 3]

# ❌ Wrong if list empty
msg: "{{ items.0 }}"

# ✅ Safe check
msg: "{{ items.0 | default('empty') }}"
msg: "{{ items[0] if items | length > 0 else 'empty' }}"
```

#### 5. Variable Name Conflicts

```yaml
# Avoid using Ansible reserved names
# ❌ Don't use these as variable names
hosts
tasks
vars
handlers
roles
name
```

<br>

## 📚 Summary: Key Takeaways

1. **Variable Types:** Simple key-value pairs, dictionaries, and lists  
2. **Access Methods:** Dot notation (`.`) and bracket notation (`['']`)  
3. **Multiple Sources:** Playbook vars, external files, inventory, and command line  
4. **Precedence:** Command line (`-e`) has the highest priority  
5. **Default Values:** Use `| default('value')` for fallbacks  
6. **hostvars:** Access variables of any host from another host  
7. **Directory Structure:** Use `host_vars/` and `group_vars/` for organization  
8. **Interactive Input:** Use `vars_prompt` for user interaction  
9. **Facts:** Automatically gathered system variables (`ansible_facts`)  
10. **Jinja2:** Variables use Jinja2 templating syntax  