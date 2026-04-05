# 📝 Register and When - Capturing & Using Task Output



## 📌 What You'll Learn

| Concept | Purpose |
|---------|---------|
| **`register`** | Capture output from tasks into variables |
| **`when`** | Conditional execution based on facts or registered output |
| **Combined** | Create dynamic workflows that adapt to task results |

> 💡 **Real-world use:** Run a command, check if it succeeded, then take action based on the result!

---

## 🎯 1. Basic Register Usage

### 📁 01: Capturing Output

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      register: hostname_output   # ← Captures everything
...
```

**What happens?** Output is saved but NOT displayed automatically.

---

### 📁 02: Viewing Registered Data

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      register: hostname_output

    - name: Show hostname_output
      debug:
        var: hostname_output      # ← Shows ALL captured data
...
```

**Output Structure (for ubuntu3):**
```json
{
    "hostname_output": {
        "changed": true,
        "cmd": ["hostname", "-s"],
        "end": "2024-01-15 10:30:00",
        "failed": false,
        "rc": 0,
        "start": "2024-01-15 10:30:00",
        "stderr": "",
        "stderr_lines": [],
        "stdout": "ubuntu3",
        "stdout_lines": ["ubuntu3"]
    }
}
```

### Key Registered Variables

| Field | Meaning | Use Case |
|-------|---------|----------|
| `stdout` | Standard output | The actual command result |
| `stderr` | Standard error | Error messages |
| `rc` | Return code | 0 = success, non-zero = failure |
| `changed` | Boolean | True if task made changes |
| `failed` | Boolean | True if task failed |
| `skipped` | Boolean | True if task was skipped |

---

### 📁 03: Accessing Specific Output

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      register: hostname_output

    - name: Show hostname_output
      debug:
        var: hostname_output.stdout   # ← Only the stdout field
...
```

**Output:**
```
msg: ubuntu3
msg: centos1
msg: centos2
...
```

> 🎯 **Key Insight:** Use `.stdout` to get just the command output!

---

## 🎯 2. When Conditions with Facts

### 📁 04: Simple When

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      when: ansible_distribution == "CentOS" and ansible_distribution_major_version == "8"
...
```

**Result:** Command runs ONLY on CentOS 8 hosts

---

### 📁 05: Multiple OR Conditions

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      when: ( ansible_distribution == "CentOS" and ansible_distribution_major_version == "8" ) or
            ( ansible_distribution == "Ubuntu" and ansible_distribution_major_version == "22" )
...
```

**Result:** Runs on CentOS 8 OR Ubuntu 22

---

### 📁 06: Version Comparison with `int` Filter

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      when: ( ansible_distribution == "CentOS" and ansible_distribution_major_version | int >= 8 ) or
            ( ansible_distribution == "Ubuntu" and ansible_distribution_major_version | int >= 22 )
...
```

**Result:** Runs on CentOS 8+ OR Ubuntu 22+

> 💡 **Why `| int`?** Converts string to integer for proper comparison!

---

### 📁 07: When as a List (AND conditions)

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      when: 
        - ansible_distribution == "CentOS" 
        - ansible_distribution_major_version | int >= 8
...
```

**Result:** Same as AND condition - cleaner syntax!

---

## 🎯 3. Combining Register with When

### 📁 08: Register with Conditional

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      when: 
        - ansible_distribution == "CentOS" 
        - ansible_distribution_major_version | int >= 8
      register: command_register   # ← Only registers when condition is true

    - name: Show register
      debug:
        var: command_register
...
```

**What happens?**
- CentOS hosts: `command_register` contains command output
- Ubuntu hosts: `command_register` is NOT created (task skipped)

---

### 📁 09: Act on Changes

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      when: 
        - ansible_distribution == "CentOS" 
        - ansible_distribution_major_version | int >= 8
      register: command_register

    - name: Install patch when changed
      yum:
        name: patch
        state: present
      when: command_register.changed   # ← Only if previous task changed
...
```

**Flow:**
1. Run `hostname` on CentOS hosts
2. If it succeeded (changed=True), install patch

---

### 📁 10: Using `is changed` (Cleaner Syntax)

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      when:
        - ansible_distribution == "CentOS"
        - ansible_distribution_major_version | int >= 8
      register: command_register

    - name: Install patch when changed
      yum:
        name: patch
        state: present
      when: command_register is changed   # ← More readable
...
```

### Available `is` Conditions

| Condition | True When |
|-----------|-----------|
| `is changed` | Task made changes |
| `is failed` | Task failed |
| `is skipped` | Task was skipped |
| `is success` | Task succeeded |

---

### 📁 11: Handle Both Changed and Skipped

```yaml
---
-
  hosts: linux
  
  tasks:
    - name: Exploring register
      command: hostname -s
      when: 
        - ansible_distribution == "CentOS" 
        - ansible_distribution_major_version | int >= 8
      register: command_register

    - name: Install patch on CentOS (when changed)
      yum:
        name: patch
        state: present
      when: command_register is changed

    - name: Install patch on Ubuntu (when skipped)
      apt:
        name: patch
        state: present
      when: command_register is skipped
...
```

**Result:**
- CentOS hosts: Install via `yum`
- Ubuntu hosts: Install via `apt`

> 🎯 **Perfect example:** One playbook that works across different OS!

---

## 📊 Complete Register Output Reference

When you register a task, these fields are available:

```yaml
# Command module output
command_register.stdout      # Standard output as string
command_register.stdout_lines # Standard output as list (each line)
command_register.stderr      # Error output
command_register.rc          # Return code (0=success)
command_register.changed     # Boolean - did it change?
command_register.failed      # Boolean - did it fail?
command_register.skipped     # Boolean - was it skipped?

# Package module output
package_register.results     # Detailed package operations

# Service module output
service_register.status      # Service status
service_register.state       # Current state

# Shell/Command specific
command_register.cmd         # Command that was executed
command_register.start       # Start time
command_register.end         # End time
command_register.delta       # Duration
```


---

## ⚠️ Common Pitfalls

### 1. Register on Skipped Tasks
```yaml
# ❌ Problem: variable doesn't exist on skipped hosts
- name: Task that skips on Ubuntu
  command: hostname
  when: ansible_distribution == "CentOS"
  register: result

- name: This fails on Ubuntu!
  debug:
    var: result.stdout
  when: result is defined  # ← Always check!
```

### 2. Comparing Strings vs Numbers
```yaml
# ❌ Wrong - string comparison
when: ansible_distribution_major_version >= "8"

# ✅ Correct - convert to int
when: ansible_distribution_major_version | int >= 8
```

### 3. Checking stdout for Success
```yaml
# ❌ Unreliable - command might output something else
when: result.stdout == ""

# ✅ Better - check return code
when: result.rc == 0
```

---

## 🚀 Quick Reference

### Register Syntax
```yaml
- name: Task name
  module_name:
    param: value
  register: variable_name
```

### When Conditions
```yaml
# Simple
when: ansible_distribution == "CentOS"

# Multiple AND (list format)
when:
  - condition1
  - condition2

# Multiple AND (single line)
when: condition1 and condition2

# Multiple OR
when: condition1 or condition2

# Complex
when: (cond1 and cond2) or (cond3 and cond4)
```

### Registered Variable Checks
```yaml
# Check if task changed
when: result.changed
when: result is changed

# Check if task failed
when: result.failed
when: result is failed

# Check if task skipped
when: result.skipped
when: result is skipped

# Check return code
when: result.rc == 0

# Check if variable exists
when: result is defined
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **`register`** | Captures task output into a variable |
| **`.stdout`** | Most commonly used field (command output) |
| **`.rc`** | Check if command succeeded (0=success) |
| **`.changed`** | Check if task made modifications |
| **`when` with `is`** | Cleaner syntax: `result is changed` |
| **List format** | Multiple AND conditions as a list |
| **`| int`** | Convert string to number for comparisons |

> 💡 **Pro Tip:** Always check if a registered variable exists before using it on skipped tasks!

---

