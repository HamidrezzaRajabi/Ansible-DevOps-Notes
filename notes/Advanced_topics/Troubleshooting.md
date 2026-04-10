# 🔧 Troubleshooting Ansible - Key Concepts



## 📌 Core Philosophy

Troubleshooting in Ansible is about **understanding where problems occur** and knowing the right tools to diagnose them. Most issues fall into one of these categories:

| Category | Common Issues |
|----------|---------------|
| **Connection** | SSH failures, authentication, host unreachable |
| **Execution** | Module failures, syntax errors, privilege escalation |
| **Variable** | Undefined variables, wrong precedence, scope issues |
| **Idempotence** | Tasks always reporting changes |
| **Performance** | Slow execution, timeout issues |

---

## 🔑 Key Troubleshooting Techniques

### 1. Increase Verbosity

The most powerful troubleshooting tool is increasing output verbosity.

| Verbosity Level | Command | Output |
|-----------------|---------|--------|
| `-v` | `ansible-playbook play.yml -v` | Basic task output |
| `-vv` | `ansible-playbook play.yml -vv` | Task + connection details |
| `-vvv` | `ansible-playbook play.yml -vvv` | + SSH debug messages |
| `-vvvv` | `ansible-playbook play.yml -vvvv` | Full debug (everything) |

**Example output at `-vvvv`:**
- Raw SSH commands being executed
- Module arguments being passed
- Return values from modules
- Connection timing information

---

### 2. Check Mode (Dry Run)

```bash
ansible-playbook playbook.yml --check
```

**What it does:** Shows what WOULD change without making actual changes

**Use case:** Validate playbook behavior before production

**Important note:** Some modules don't support check mode (they will still make changes)

---

### 3. Step Mode (Interactive)

```bash
ansible-playbook playbook.yml --step
```

**What it does:** Confirms each task before execution

```
Perform task: Install nginx (yum)? (y/n/a)
```

| Response | Meaning |
|----------|---------|
| `y` | Execute this task |
| `n` | Skip this task |
| `a` | Execute all remaining tasks |

---

### 4. Limit Execution to Specific Hosts

```bash
# Run on single host
ansible-playbook playbook.yml --limit hostname

# Run on group
ansible-playbook playbook.yml --limit webservers

# Run on multiple specific hosts
ansible-playbook playbook.yml --limit "host1,host2,host3"
```

**Use case:** Test on one server before rolling to all

---

### 5. Start at Specific Task

```bash
ansible-playbook playbook.yml --start-at-task="Task Name"
```

**Use case:** Resume failed playbook from the point of failure

---

### 6. Debug Module

**Example - Print variable value:**
```yaml
- name: Debug variable
  debug:
    var: my_variable
```

**Example - Print custom message:**
```yaml
- name: Debug message
  debug:
    msg: "Current host is {{ inventory_hostname }}"
```

**Example - Print all variables:**
```yaml
- name: Dump all variables
  debug:
    var: hostvars[inventory_hostname]
```

---

### 7. Register and Display Output

```yaml
- name: Run command and capture output
  command: /usr/bin/problematic-command
  register: result
  ignore_errors: yes

- name: Debug the output
  debug:
    msg: |
      Return code: {{ result.rc }}
      Stdout: {{ result.stdout }}
      Stderr: {{ result.stderr }}
```

---

### 8. Validate Syntax

```bash
ansible-playbook playbook.yml --syntax-check
```

**What it does:** Validates YAML syntax without executing

**Common syntax errors:**
- Missing spaces after colons
- Incorrect indentation
- Missing quotes around variables

---

### 9. List Tasks and Hosts

```bash
# List all tasks in playbook
ansible-playbook playbook.yml --list-tasks

# List all hosts that would be targeted
ansible-playbook playbook.yml --list-hosts

# List all tags
ansible-playbook playbook.yml --list-tags
```

---

### 10. Connection Troubleshooting (SSH)

**Test connectivity manually:**
```bash
ansible hostname -m ping
```

**Test with specific user:**
```bash
ansible hostname -m ping -u root
```

**Test with password:**
```bash
ansible hostname -m ping --ask-pass
```

**Test with become (sudo):**
```bash
ansible hostname -m ping -b --ask-become-pass
```

---

## 📊 Common Error Patterns and Solutions

| Error | Likely Cause | Solution |
|-------|--------------|----------|
| `UNREACHABLE` | SSH connection failed | Check network, SSH service, firewall |
| `Authentication failed` | Wrong SSH key/password | Verify credentials, check `ansible_user` |
| `sudo: a password is required` | Become password missing | Add `--ask-become-pass` or set `ansible_become_pass` |
| `'dict object' has no attribute` | Undefined variable | Check variable name, use `default()` filter |
| `Syntax Error` | YAML formatting | Validate with `--syntax-check` |
| `Module not found` | Missing collection | Install collection: `ansible-galaxy collection install` |
| `Timeout` | Task taking too long | Increase timeout or use `async` |

---

## 🛠️ Troubleshooting Playbook Example

```yaml
---
- name: Troubleshooting template
  hosts: all
  gather_facts: yes
  
  tasks:
    # Step 1: Verify connectivity
    - name: Ping test
      ping:
    
    # Step 2: Check if we can escalate privileges
    - name: Check become works
      command: whoami
      register: whoami_result
    
    - name: Display current user
      debug:
        msg: "Running as {{ whoami_result.stdout }}"
    
    # Step 3: Debug important facts
    - name: Display OS distribution
      debug:
        msg: "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    # Step 4: Test variable existence with default
    - name: Safe variable access
      debug:
        msg: "Value: {{ my_optional_var | default('NOT DEFINED') }}"
    
    # Step 5: Capture and display command output
    - name: Run diagnostic command
      command: uptime
      register: uptime_result
      ignore_errors: yes
    
    - name: Show uptime
      debug:
        var: uptime_result.stdout
      when: uptime_result is success
```

---

## ⚡ Quick Troubleshooting Commands

```bash
# Basic connectivity test
ansible all -m ping

# Test single host with verbosity
ansible host1 -m ping -vvv

# Check inventory resolution
ansible host1 --list-hosts

# Debug a specific variable
ansible host1 -m debug -a "var=hostvars[inventory_hostname]"

# Run ad-hoc command to test become
ansible host1 -b -a "whoami"

# Test with different user
ansible host1 -u different_user -m ping

# Check if host is in inventory
ansible-inventory --host host1 --list

# Validate playbook syntax
ansible-playbook playbook.yml --syntax-check
```

---

## 📝 ansible.cfg Debug Settings

```ini
[defaults]
# Increase default verbosity
verbosity = 3

# Show task paths in output
display_args_to_stdout = True

# Don't retry failed hosts
retry_files_enabled = False

# Increase timeout for slow connections
timeout = 30

# Log to file
log_path = /var/log/ansible.log
```

---

## ✅ Summary Checklist

| Step | Action |
|------|--------|
| 1 | Run with `-vvv` to see detailed output |
| 2 | Test connectivity with `ansible -m ping` |
| 3 | Validate syntax with `--syntax-check` |
| 4 | Use `--check` for dry run |
| 5 | Use `--limit` to isolate to one host |
| 6 | Add `debug` tasks to print variables |
| 7 | Check `ansible.cfg` for timeout/logging settings |
| 8 | Verify inventory with `ansible-inventory --list` |

> 💡 **Pro Tip:** Start with `-vvv` for most issues. Use `-vvvv` only when you need to see raw SSH traffic and module internals!

---
