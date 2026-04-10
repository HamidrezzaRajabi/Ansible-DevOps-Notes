# 📁 Using Includes and Imports



## 📌 What are Includes and Imports?

Ansible provides directives to **split playbooks into multiple files** for better organization and reusability.

| Directive | Purpose |
|-----------|---------|
| `include_tasks` | Dynamically include tasks at runtime |
| `import_tasks` | Statically import tasks at parse time |
| `import_playbook` | Statically import entire playbooks |

---

## 🎯 The Key Difference: Static vs Dynamic

| Feature | Static (`import_*`) | Dynamic (`include_*`) |
|---------|---------------------|-----------------------|
| **When processed** | At playbook parse time | At runtime when encountered |
| **When condition** | Evaluated per task in file | Evaluated once for entire file |
| **Loop behavior** | Can't loop over imports | Can loop over includes |
| **Performance** | Slightly faster | Slightly slower |
| **Variable vars** | Limited | Full support |

---

## 📁 01: include_tasks (Dynamic)

### Main Playbook (`include_tasks_playbook.yaml`)

```yaml
---
-
  hosts: all

  tasks:
    - name: Play 1 - Task 1
      debug: 
        msg: Play 1 - Task 1

    - include_tasks: play1_task2.yaml
```

### Included File (`play1_task2.yaml`)

```yaml
---
- name: Play 1 - Task 2
  debug: 
    msg: Play 1 - Task 2
```

**Output:**
```
msg: Play 1 - Task 1
msg: Play 1 - Task 2
```

> 💡 **Dynamic:** The included file is read and processed when `include_tasks` is reached

---

## 📁  02: import_tasks (Static)

```yaml
---
-
  hosts: all

  tasks:
    - name: Play 1 - Task 1
      debug: 
        msg: Play 1 - Task 1

    - import_tasks: play1_task2.yaml
```

**Output appears identical!** But behavior differs with conditionals.

---

## 📁  03: Static vs Dynamic with Conditions

### The Test Playbook (`include_import_tasks_playbook.yaml`)

```yaml
---
-
  hosts: centos1

  tasks:
    - debug:
        msg: "===================== Testing include_tasks ====================="

    - include_tasks: include_tasks.yaml
      when: include_tasks_var is not defined

    - debug:
        msg: "===================== Testing import_tasks ======================"

    - import_tasks: import_tasks.yaml
      when: import_tasks_var is not defined
```

### Included Tasks File (`include_tasks.yaml`)

```yaml
---
- set_fact:
    include_tasks_var: foo

- name: 2nd Task
  debug: 
    msg: 2nd Task

- name: 3rd Task
  debug: 
    msg: 3rd Task
```

### Imported Tasks File (`import_tasks.yaml`)

```yaml
---
- set_fact:
    import_tasks_var: foo

- name: 2nd Task
  debug: 
    msg: 2nd Task

- name: 3rd Task
  debug: 
    msg: 3rd Task
```

### Execution Flow Comparison

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           include_tasks (DYNAMIC)                            │
│                                                                              │
│  when condition checked ONCE at include_tasks line                          │
│  ↓                                                                           │
│  Condition true? (include_tasks_var is not defined) → YES                    │
│  ↓                                                                           │
│  Execute ALL tasks in include_tasks.yaml                                     │
│  ├── set_fact (sets include_tasks_var)                                       │
│  ├── 2nd Task (prints)                                                       │
│  └── 3rd Task (prints)                                                       │
│                                                                              │
│  ✓ All 3 tasks executed regardless of variable change                        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           import_tasks (STATIC)                              │
│                                                                              │
│  when condition checked PER TASK at parse time                               │
│  ↓                                                                           │
│  Task 1 condition: import_tasks_var is not defined? → YES                    │
│  ├── set_fact (sets import_tasks_var) ✓                                      │
│  ↓                                                                           │
│  Task 2 condition: import_tasks_var is not defined? → NO (now defined)       │
│  └── 2nd Task ✗ SKIPPED                                                      │
│  ↓                                                                           │
│  Task 3 condition: import_tasks_var is not defined? → NO                     │
│  └── 3rd Task ✗ SKIPPED                                                      │
│                                                                              │
│  ✓ Only first task executes, others skipped                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Output

**include_tasks (Dynamic):**
```
msg: ===================== Testing include_tasks =====================
msg: 2nd Task
msg: 3rd Task
```

**import_tasks (Static):**
```
msg: ===================== Testing import_tasks ======================
[Task 1 executes, Task 2 and 3 skipped]
```

> 🎯 **Key Insight:** Dynamic `include_tasks` evaluates `when` once for the whole file. Static `import_tasks` evaluates `when` for each task individually.

---

## 📁 04: import_playbook

### Main Playbook (`import_playbook.yaml`)

```yaml
---
# import_playbook is static
# Each task in the imported playbook is independently evaluated against when
- import_playbook: imported_playbook.yaml
  when: import_playbook_var is not defined
```

### Imported Playbook (`imported_playbook.yaml`)

```yaml
---
- name: Play 1
  hosts: centos1
  tasks:
    - set_fact:
        import_playbook_var: foo

    - name: 2nd Task
      debug:
        msg: 2nd Task

    - name: 3rd Task
      debug:
        msg: 3rd Task
```

**Result:** Like `import_tasks`, each task in the imported playbook is evaluated independently against the `when` condition.

---

## 📊 include_tasks vs import_tasks Comparison

| Aspect | include_tasks | import_tasks |
|--------|---------------|---------------|
| **Type** | Dynamic | Static |
| **When processed** | Runtime | Parse time |
| **when condition** | Once per include | Per task in file |
| **with_items loop** | ✅ Supported | ❌ Not supported |
| **vars for file** | ✅ Can pass variables | ❌ Limited |
| **Debugging** | Harder (runtime) | Easier (static) |
| **Use case** | Conditional includes, loops | Static reusable task groups |

---

## 🎯 Practical Use Cases

### Use Case 1: Loop Over Includes (Dynamic only)

```yaml
# Only possible with include_tasks
- include_tasks: setup_user.yml
  with_items: "{{ users }}"
  vars:
    username: "{{ item }}"
```

### Use Case 2: Conditional Task Groups

```yaml
# Dynamic - runs entire file or nothing
- include_tasks: configure_nginx.yml
  when: install_nginx | default(false)

# Static - each task condition checked separately
- import_tasks: security_hardening.yml
  when: environment == 'production'
```

### Use Case 3: Multi-Environment Playbooks

```yaml
# import_playbook - static inclusion
---
- import_playbook: common.yml

- import_playbook: prod_specific.yml
  when: environment == 'production'

- import_playbook: staging_specific.yml
  when: environment == 'staging'
```

### Use Case 4: Breaking Down Large Playbooks

```yaml
---
# main.yml
- import_playbook: prerequisites.yml
- import_playbook: database.yml
- import_playbook: webserver.yml
- import_playbook: monitoring.yml
```

---

## 🛠️ Best Practices

| Practice | Reason |
|----------|--------|
| **Use `import_*` for static includes** | Better performance, easier debugging |
| **Use `include_*` for loops** | Only dynamic supports loops |
| **Use `include_*` with conditional vars** | Variables can be passed at runtime |
| **Avoid deep nesting** | Makes debugging difficult |
| **Use meaningful file names** | `setup_database.yml` not `task2.yml` |

---

## 📁 Directory Structure Example

```
playbooks/
├── site.yml                 # Main playbook (imports everything)
├── webservers.yml           # Web server specific
├── databases.yml            # Database specific
├── tasks/
│   ├── install_nginx.yml
│   ├── configure_firewall.yml
│   └── setup_monitoring.yml
└── handlers/
    └── restart_services.yml
```

**`site.yml`:**
```yaml
---
- import_playbook: webservers.yml
- import_playbook: databases.yml
```

---

## ⚡ Quick Reference

### include_tasks
```yaml
- include_tasks: file.yml
  when: condition
  vars:
    var1: value1

# With loop
- include_tasks: file.yml
  with_items: "{{ list }}"
```

### import_tasks
```yaml
- import_tasks: file.yml
  when: condition
  # No loop support
  # vars passed at task level not recommended
```

### import_playbook
```yaml
---
- import_playbook: other.yml
  when: condition

- import_playbook: prod.yml
  when: environment == 'prod'
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **include_tasks** | Dynamic - evaluated at runtime, when once per file |
| **import_tasks** | Static - evaluated at parse time, when per task |
| **import_playbook** | Static - for entire playbooks |
| **Loops** | Only work with `include_*` |
| **When condition** | Dynamic = once, Static = per task |

> 💡 **Pro Tip:** Use `import_tasks` by default for better performance. Use `include_tasks` when you need loops or conditional variables!

---
