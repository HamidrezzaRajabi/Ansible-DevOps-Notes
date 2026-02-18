# 🔧 Ansible Modules


## 📌 Key Concepts

### What are Ansible Modules?
- **Batteries included** framework with hundreds of built-in modules
- Each module performs a specific task (file operations, package management, etc.)
- Modules are **idempotent** - can be run multiple times safely
- Core modules moved to **ansible.builtin** collection in Ansible 2.10+

### Module Categories
- **System Modules** (user, group, mount, service)
- **Commands Modules** (command, shell, script)
- **File Modules** (copy, file, fetch, lineinfile)
- **Database Modules** (mysql_db, postgresql_db)
- **Cloud Modules** (aws, azure, gcp)
- **Windows Modules** (win_file, win_service)

## 💻 Essential Modules with Examples

### 1. **Setup Module** (Facts Gathering)

```bash
# Gather all facts about a host
ansible centos1 -m setup

# Pipe through 'more' for easier reading
ansible centos1 -m setup | more

# Filter specific facts
ansible centos1 -m setup -a "filter=ansible_distribution*"
ansible centos1 -m setup -a "filter=ansible_*_mb"  # Memory facts

# Using fully qualified collection name (FQCN)
ansible centos1 -m ansible.builtin.setup
```
#### Common Facts Examples:


```json
{
  "ansible_distribution": "CentOS",
  "ansible_os_family": "RedHat",
  "ansible_processor_cores": 4,
  "ansible_memtotal_mb": 2048,
  "ansible_default_ipv4": { "address": "192.168.1.10" }
}
```
### 2. File Module (File Operations)
```bash
# Create a file (like touch)
ansible all -m file -a "path=/tmp/test.txt state=touch"

# Create directory
ansible all -m file -a "path=/tmp/mydir state=directory mode=0755"

# Set file permissions (600 = rw-------)
ansible all -m file -a "path=/tmp/test.txt state=file mode=0600"

# Remove file
ansible all -m file -a "path=/tmp/test.txt state=absent"

# Create symbolic link
ansible all -m file -a "src=/tmp/test.txt dest=/tmp/link.txt state=link"

# Set ownership
ansible all -m file -a "path=/tmp/test.txt owner=ansible group=ansible"
```
### 3. Copy Module (File Transfer)
```bash
# Create a local file to copy
touch /tmp/local-file.txt

# Copy local file to all hosts
ansible all -m copy -a "src=/tmp/local-file.txt dest=/tmp/remote-file.txt"

# Copy with permissions
ansible all -m copy -a "src=/tmp/local-file.txt dest=/tmp/remote-file.txt mode=0600"

# Copy content directly (create file with content)
ansible all -m copy -a "content='Hello Ansible' dest=/tmp/hello.txt"

# Copy file on remote system (remote_src)
ansible all -m copy -a "src=/tmp/test.txt dest=/tmp/test2.txt remote_src=yes"

# Backup existing file before copying
ansible all -m copy -a "src=/tmp/local-file.txt dest=/tmp/remote-file.txt backup=yes"
```

### 4. Command Module (Execute Commands)
```bash
# Run command (default module, so -m optional)
ansible all -a "hostname"
ansible all -m command -a "hostname"

# Run command with creates (skip if file exists)
ansible all -a "touch /tmp/created.txt creates=/tmp/created.txt"

# Run command with removes (only run if file exists)
ansible all -a "rm /tmp/test.txt removes=/tmp/test.txt"

# Change directory before running
ansible all -a "ls -la chdir=/tmp"

# Set environment variable
ansible all -a "echo $HOME"  # Won't work with command module
```

### 5. Shell Module (When you need shell features)

```bash
# Use shell features (environment variables, pipes, redirects)
ansible all -m shell -a "echo $HOME > /tmp/home.txt"
ansible all -m shell -a "ps aux | grep ssh"
ansible all -m shell -a "cat /etc/passwd | grep ansible"

# Run multiple commands
ansible all -m shell -a "cd /tmp && ls -la && pwd"
```

### 6. Fetch Module (Retrieve files from remote)

```bash
# Fetch file from remote to local (creates host-specific directories)
ansible all -m fetch -a "src=/tmp/test.txt dest=/tmp/fetched/ flat=no"

# Fetch with flat structure (overwrite warning)
ansible all -m fetch -a "src=/tmp/test.txt dest=/tmp/ flat=yes"
```

# 🎨 Ansible Output Colors

| Color | Meaning | Example |
|-------|----------|----------|
| 🟢 Green | Success, no changes | File already has correct permissions |
| 🟡 Yellow | Success with changes | File created or modified |
| 🔴 Red | Failure | Connection failed, permission denied |

---
<br>

## 🔄 Understanding Idempotence

## What is Idempotence?

Running an operation multiple times produces the same result as running it once.

### Examples

### ❌ Non-idempotent (Bad)

```bash
# Running this multiple times adds multiple lines
ansible all -a "echo 'line' >> /tmp/file.txt"

# File module ensures exact state
ansible all -m file -a "path=/tmp/file.txt state=touch mode=0600"

# First run: 🟡 Creates file with 600 permissions
# Second run: 🟢 Already correct, no changes
```
<br>

## 📚 Module Documentation
### Using ansible-doc

```bash
# View module documentation
ansible-doc file
ansible-doc copy
ansible-doc fetch

# List all available modules
ansible-doc -l

# Search for modules
ansible-doc -l | grep file
ansible-doc -l | grep cloud

# View module examples
ansible-doc -s file        # Short summary
ansible-doc file | less    # Full documentation
```

## 🎯 Practice Exercises
### Exercise 1: File Operations
```bash
# Create a structured directory tree
ansible all -m file -a "path=/tmp/ansible/{config,logs,data} state=directory"

# Create a config file with specific permissions
ansible all -m copy -a "content='debug=true' dest=/tmp/ansible/config/app.conf mode=0600"

# Create a log file with timestamp
ansible all -m shell -a "date > /tmp/ansible/logs/startup.log"
```

### Exercise 2: Fetch Files Challenge

```bash
# Create a file on all hosts with host-specific content
ansible all -m shell -a "echo 'Host: $(hostname)' > /tmp/host-info.txt"

# Fetch all files to local machine
ansible all -m fetch -a "src=/tmp/host-info.txt dest=./host-files/ flat=no"
```

### Exercise 3: Idempotence Test

```bash
# Run multiple times - observe color changes
ansible all -m file -a "path=/tmp/test-idempotence.txt state=touch mode=0644"
ansible all -m file -a "path=/tmp/test-idempotence.txt state=touch mode=0644"
ansible all -m file -a "path=/tmp/test-idempotence.txt state=touch mode=0644"
````

## ⚠️ Common Pitfalls
### 1️⃣ Command vs Shell Module

```bash
# ❌ Wrong - command doesn't support shell features
ansible all -m command -a "echo $HOME > /tmp/home.txt"

# ✅ Correct - use shell module
ansible all -m shell -a "echo $HOME > /tmp/home.txt"
```

### 2️⃣ Idempotence with Commands
```bash
# ❌ Non-idempotent
ansible all -a "touch /tmp/file.txt"

# ✅ Idempotent with creates
ansible all -a "touch /tmp/file.txt creates=/tmp/file.txt"
```

### 3️⃣ Permission Issues

```bash
# ❌ May fail if user lacks sudo
ansible all -m file -a "path=/root/test.txt state=touch"

# ✅ Use become for privileged operations
ansible all -m file -a "path=/root/test.txt state=touch" --become
```

# 🔗 Module Cheatsheet

| Module    | Purpose           | Common Options                  | Example |
|------------|------------------|----------------------------------|----------|
| `setup`    | Gather facts      | `filter=`                        | `-m setup -a "filter=ansible_mem*"` |
| `file`     | File operations   | `path=`, `state=`, `mode=`       | `-m file -a "path=/tmp/x state=touch mode=600"` |
| `copy`     | Copy files        | `src=`, `dest=`, `backup=`       | `-m copy -a "src=/a dest=/b"` |
| `fetch`    | Retrieve files    | `src=`, `dest=`                  | `-m fetch -a "src=/remote dest=/local"` |
| `command`  | Run commands      | `creates=`, `removes=`, `chdir=` | `-a "hostname"` |
| `shell`    | Shell commands    | Same as `command`                | `-m shell -a "ps aux | grep ssh"` |

---

<br>
<br>

# 📝 Key Takeaways

- Modules are the building blocks of Ansible automation  
- Idempotence ensures safe, repeatable executions  
- Use `ansible-doc` for quick reference  
- Color output indicates change status  
- Choose the right module for each task  
