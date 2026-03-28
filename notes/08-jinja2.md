# 🎨 Ansible Playbooks - Templating with Jinja2



## 📌 What is Jinja2?

Jinja2 is the **templating language** used by Ansible. It allows you to:
- 🔄 Create **dynamic** content and configuration files
- 🧠 Use **logic** (if statements, loops) in your automation
- 📝 Generate **customized** files per host
- 💪 Make playbooks **intelligent** and **adaptive**

> 💡 **Pro Tip:** The more effective you are with Jinja2, the more effective you'll be with Ansible!

---

## 🎯 Two Main Uses in Ansible

| Use Case | Example |
|----------|---------|
| **1. Syntactical language in playbooks** | `{% if condition %}...{% endif %}` |
| **2. Template files (config files)** | `template: src=config.j2 dest=/etc/app.conf` |

---

## 🔧 Basic Syntax

| Symbol | Purpose | Example |
|--------|---------|---------|
| `{{ }}` | **Print variable** | `{{ ansible_hostname }}` |
| `{% %}` | **Logic statements** | `{% if condition %}` |
| `{# #}` | **Comments** | `{# This is a comment #}` |
| `-` | **Whitespace control** | `{% if x -%}` removes trailing newline |

---

## 📚 1. Conditional Statements (if/elif/else)

### 📁 01: Simple If Statement
```yaml
tasks:
  - debug:
      msg: >
        {% if ansible_hostname == "ubuntu-c" -%}
          This is ubuntu-c
        {% endif %}
```
**✅ Only ubuntu-c shows the message**

### 📁 02: If/Elif
```yaml
tasks:
  - debug:
      msg: >
        {% if ansible_hostname == "ubuntu-c" -%}
          This is ubuntu-c
        {% elif ansible_hostname == "centos1" -%}
          This is centos1 with its modified SSH Port
        {% endif %}
```
**✅ Matches ubuntu-c OR centos1**

### 📁 03: If/Elif/Else (Complete)
```yaml
tasks:
  - debug:
      msg: >
        --== Ansible Jinja2 if elif else statement ==--

        {% if ansible_hostname == "ubuntu-c" -%}
           This is ubuntu-c
        {% elif ansible_hostname == "centos1" -%}
           This is centos1 with it's modified SSH Port
        {% else -%}
           This is good old {{ ansible_hostname }}
        {% endif %}
```
**✅ Matches ALL hosts** (specific ones get special messages, others get generic)

---

## 🔍 2. Checking if Variable is Defined

### 📁 04: Variable Not Defined
```yaml
tasks:
  - debug:
      msg: >
        {% if example_variable is defined -%}
          example_variable is defined
        {% else -%}
          example_variable is not defined
        {% endif %}
```
**🔴 Output:** `example_variable is not defined`

### 📁 05: Variable Defined (using `set`)
```yaml
tasks:
  - debug:
      msg: >
        --== Ansible Jinja2 if variable is defined (where variable is defined) ==--

        {% set example_variable = 'defined' -%}
        {% if example_variable is defined -%}
          example_variable is defined
        {% else -%}
          example_variable is not defined
        {% endif %}
```
**✅ Output:** `example_variable is defined`

> 💡 **Tip:** Use `{% set var = value %}` to create variables within templates!

---

## 🔄 3. Loops (For Loops)

### 📁 06: Loop Through Network Interfaces
```yaml
tasks:
  - debug:
      msg: >
        --== Network Interfaces ==--

        {% for interface in ansible_interfaces %}
          {{ loop.index }}: {{ interface }}
        {% endfor %}
```
**✅ Output:** List of all network interfaces with index numbers

| Variable | Purpose |
|----------|---------|
| `loop.index` | Current iteration (1-indexed) |
| `loop.index0` | Current iteration (0-indexed) |
| `loop.first` | True if first iteration |
| `loop.last` | True if last iteration |

---

## 📊 4. Ranges

### 📁  07: Basic Range (1 to 10)
```yaml
tasks:
  - debug:
      msg: >
        {% for number in range(1, 11) %}
          {{ number }}
        {% endfor %}
```
**Output:**
```
1
2
3
4
5
6
7
8
9
10
```

> 📝 **Note:** `range(start, stop)` stops **before** the stop value, so `range(1, 11)` = 1-10

---

## ⏸️ 5. Break and Continue

### 🔧 Enable Loop Controls (ansible.cfg)
```ini
[defaults]
inventory = hosts
host_key_checking = False
jinja2_extensions = jinja2.ext.loopcontrols   # 🔥 REQUIRED for break/continue
```

### 📁  08: Break on Condition
```yaml
tasks:
  - debug:
      msg: >
        --== Ansible Jinja2 for range, reversed (simulate while greater 5) ==--

        {% for entry in range(10, 0, -1) -%}
          {% if entry == 5 -%}
            {% break %}
          {% endif -%}
          {{ entry }}
        {% endfor %}
```
**Output:**
```
10
9
8
7
6
```
✅ **Stops at 5** (doesn't print 5)

### 📁 09: Continue on Condition (Skip Odds)
```yaml
tasks:
  - debug:
      msg: >
        {% for number in range(1, 11) %}
          {% if number % 2 == 1 %}
            {% continue %}
          {% endif %}
          {{ number }}
        {% endfor %}
```
**Output:**
```
2
4
6
8
10
```
✅ **Only even numbers** displayed (odd numbers skipped)

---

## 🎨 6. Jinja2 Filters (Powerful Transformations)

### 📁 10: Common Filters

```yaml
tasks:
  - name: Ansible Jinja2 filters
    debug:
      msg: >
        ---=== Ansible Jinja2 filters ===---

        --== min [1, 2, 3, 4, 5] ==--
        {{ [1, 2, 3, 4, 5] | min }}

        --== max [1, 2, 3, 4, 5] ==--
        {{ [1, 2, 3, 4, 5] | max }}

        --== unique [1, 1, 2, 2, 3, 3, 4, 4, 5, 5] ==--
        {{ [1, 1, 2, 2, 3, 3, 4, 4, 5, 5] | unique }}

        --== difference [1, 2, 3, 4, 5] vs [2, 3, 4] ==--
        {{ [1, 2, 3, 4, 5] | difference([2, 3, 4]) }}

        --== random ['rod', 'jane', 'freddy'] ==--
        {{ ['rod', 'jane', 'freddy'] | random }}

        --== urlsplit hostname ==--
        {{ "http://docs.ansible.com/ansible/latest/playbooks_filters.html" | urlsplit('hostname') }}
```

### 📊 Filter Output Example (ubuntu-c)

| Filter | Input | Output |
|--------|-------|--------|
| `min` | `[1,2,3,4,5]` | `1` |
| `max` | `[1,2,3,4,5]` | `5` |
| `unique` | `[1,1,2,2,3,3,4,4,5,5]` | `[1,2,3,4,5]` |
| `difference` | `[1,2,3,4,5]` vs `[2,3,4]` | `[1,5]` |
| `random` | `['rod','jane','freddy']` | `rod` (random) |
| `urlsplit` | Full URL | `docs.ansible.com` |

---

## 📄 7. Template Module (Real-World Usage)

### 📁 11: Using Template Files

**Playbook:**
```yaml
tasks:
  - name: Jinja2 template
    template:
      src: template.j2
      dest: "/tmp/{{ ansible_hostname }}_template.out"
      trim_blocks: true
      mode: 0644
```

**Template File (`template.j2`):**
```jinja2
---=== Ansible Jinja2 filters ===---

--== min [1, 2, 3, 4, 5] ==--
{{ [1, 2, 3, 4, 5] | min }}

--== max [1, 2, 3, 4, 5] ==--
{{ [1, 2, 3, 4, 5] | max }}

--== unique [1, 1, 2, 2, 3, 3, 4, 4, 5, 5] ==--
{{ [1, 1, 2, 2, 3, 3, 4, 4, 5, 5] | unique }}

--== difference [1, 2, 3, 4, 5] vs [2, 3, 4] ==--
{{ [1, 2, 3, 4, 5] | difference([2, 3, 4]) }}

--== random ['rod', 'jane', 'freddy'] ==--
{{ ['rod', 'jane', 'freddy'] | random }}

--== urlsplit hostname ==--
{{ "http://docs.ansible.com/ansible/latest/playbooks_filters.html" | urlsplit('hostname') }}
```

**Run it:**
```bash
ansible-playbook jinja2_playbook.yaml --limit ubuntu-c
```

**Result file (`/tmp/ubuntu-c_template.out`):**
```
---=== Ansible Jinja2 filters ===---

--== min [1, 2, 3, 4, 5] ==--
1

--== max [1, 2, 3, 4, 5] ==--
5

--== unique [1, 1, 2, 2, 3, 3, 4, 4, 5, 5] ==--
[1, 2, 3, 4, 5]

--== difference [1, 2, 3, 4, 5] vs [2, 3, 4] ==--
[1, 5]

--== random ['rod', 'jane', 'freddy'] ==--
rod

--== urlsplit hostname ==--
docs.ansible.com
```

---

## 📋 Jinja2 Filter Cheat Sheet

| Filter | Purpose | Example | Output |
|--------|---------|---------|--------|
| `min` | Smallest value | `[1,2,3] \| min` | `1` |
| `max` | Largest value | `[1,2,3] \| max` | `3` |
| `unique` | Remove duplicates | `[1,1,2] \| unique` | `[1,2]` |
| `difference` | Items in A not in B | `[1,2,3] \| difference([2,3])` | `[1]` |
| `random` | Random item | `[a,b,c] \| random` | `b` (random) |
| `default` | Fallback value | `value \| default('n/a')` | `value` or `n/a` |
| `upper` | Uppercase | `'hello' \| upper` | `HELLO` |
| `lower` | Lowercase | `'HELLO' \| lower` | `hello` |
| `replace` | Replace text | `'hello' \| replace('e','a')` | `hallo` |
| `split` | Split string | `'a,b,c' \| split(',')` | `['a','b','c']` |
| `join` | Join list | `[1,2,3] \| join('-')` | `1-2-3` |

---

## 🛠️ Template Module Options

```yaml
- name: Template with options
  template:
    src: template.j2           # Source template file
    dest: /path/to/destination # Destination on target
    mode: '0644'               # File permissions
    owner: root                # File owner
    group: root                # File group
    trim_blocks: true          # Remove first newline after block
    backup: yes                # Backup existing file
```

---

## 💡 Pro Tips

### ✅ Whitespace Control
```jinja2
# Without dash - keeps whitespace
{% if condition %}
  Text
{% endif %}

# With dash - removes whitespace
{% if condition -%}
  Text
{%- endif %}
```

### ✅ Multi-line Messages
```yaml
debug:
  msg: >
    This is a multi-line
    message that will be
    displayed as a single line
```

### ✅ Using `set` to Create Variables
```jinja2
{% set app_name = "myapp" %}
{% set version = "1.0" %}
Welcome to {{ app_name }} version {{ version }}
```

---

## 🎯 Practice Exercises

### Exercise 1: Dynamic MOTD with Conditions
Create a template that shows different messages based on hostname
```jinja2
Welcome to {{ ansible_hostname }}
{% if ansible_distribution == "Ubuntu" %}
  This is an Ubuntu system
{% elif ansible_distribution == "CentOS" %}
  This is a CentOS system
{% endif %}
```

### Exercise 2: Generate Config File from List
```jinja2
# /etc/hosts.allow
{% for ip in allowed_ips %}
ALL: {{ ip }}
{% endfor %}
```

### Exercise 3: Filter Practice
Create a playbook that:
- Takes a list of numbers
- Shows only unique values
- Shows min and max
- Shows random selection

---

## 📚 Resources

- 🔗 [Official Jinja2 Documentation](https://jinja.palletsprojects.com/)
- 🔗 [Ansible Filters Guide](https://docs.ansible.com/ansible/latest/playbooks_guide/playbooks_filters.html)
- 🔗 [Jinja2 Loop Controls](https://jinja.palletsprojects.com/en/stable/templates/#loop-controls)

---

## 📝 Summary

| Concept | Key Takeaway |
|---------|--------------|
| **If/Else** | Use `{% if %}...{% elif %}...{% else %}...{% endif %}` |
| **Loops** | `{% for item in list %}...{% endfor %}` with `loop.index` |
| **Break/Continue** | Enable `jinja2.ext.loopcontrols` in `ansible.cfg` |
| **Ranges** | `range(start, stop, step)` |
| **Filters** | Pipe `\|` to transform data (min, max, unique, etc.) |
| **Templates** | Use `template` module to generate config files |
| **Whitespace** | Use `-` to remove unwanted newlines |

---
