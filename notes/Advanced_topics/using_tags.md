# 🏷️ Using Tags


## 📌 What are Tags?

Tags allow you to **selectively run or skip** specific parts of a playbook.

| Feature | Purpose |
|---------|---------|
| **Run specific tasks** | Only execute tagged tasks |
| **Skip specific tasks** | Run everything except tagged tasks |
| **Segment large playbooks** | Break into manageable pieces |
| **Speed up development** | Test only relevant sections |

---

## 🎯 1. Basic Task Tags

### 📁 Tagging Tasks

```yaml
---
-
  hosts: linux
  vars_files:
    - vars/logos.yaml

  tasks:
    - name: Install EPEL
      yum:
        name: epel-release
        update_cache: yes
        state: latest
      when: ansible_distribution == 'CentOS'
      tags:
        - install-epel

    - name: Install Nginx
      package:
        name: nginx
        state: latest
      tags:
        - install-nginx

    - name: Restart nginx
      service:
        name: nginx
        state: restarted
      notify: Check HTTP Service
      tags:
        - restart-nginx

    - name: Template index.html
      template:
        src: index.html-easter_egg.j2
        dest: "{{ nginx_root_location }}/index.html"
        mode: 0644
      tags:
        - deploy-app

    - name: Install unzip
      package:
        name: unzip
        state: latest
      # No tags - will always run unless skipped

    - name: Unarchive game
      unarchive:
        src: playbook_stacker.zip
        dest: "{{ nginx_root_location }}"
        mode: 0755
      tags:
        - deploy-app
```

### Running Specific Tags

```bash
# Run only install-epel tag
ansible-playbook nginx_playbook.yaml --tags install-epel

# Run multiple tags
ansible-playbook nginx_playbook.yaml --tags "install-nginx,restart-nginx"

# Run deploy-app tag (both template and unarchive tasks)
ansible-playbook nginx_playbook.yaml --tags deploy-app

# Skip specific tags
ansible-playbook nginx_playbook.yaml --skip-tags deploy-app
```

---

## 🎯 2. Play-Level Tags

### 📁 Tagging Entire Plays

```yaml
---
-
  hosts: linux
  tags:
    - webapp           # ← Entire play has this tag
  
  vars_files:
    - vars/logos.yaml

  tasks:
    - name: Install EPEL
      yum:
        name: epel-release
        update_cache: yes
        state: latest
      when: ansible_distribution == 'CentOS'
      tags:
        - install-epel

    - name: Install Nginx
      package:
        name: nginx
        state: latest
      tags:
        - install-nginx

    - name: Restart nginx
      service:
        name: nginx
        state: restarted
      notify: Check HTTP Service
      tags:
        - restart-nginx

    - name: Template index.html
      template:
        src: index.html-easter_egg.j2
        dest: "{{ nginx_root_location }}/index.html"
        mode: 0644
      tags:
        - deploy-app

    - name: Install unzip
      package:
        name: unzip
        state: latest

    - name: Unarchive game
      unarchive:
        src: playbook_stacker.zip
        dest: "{{ nginx_root_location }}"
        mode: 0755
      tags:
        - deploy-app
```

### ⚠️ Important: Facts Are Affected!

When you tag a play, `gather_facts` (the implicit setup task) **inherits the play tag**.

```bash
# Revision 02 - Facts gathering is SKIPPED!
ansible-playbook nginx_playbook.yaml --tags install-nginx
# Note: Gathering facts does NOT run
```

---

## 🎯 3. Fixing Facts with an Empty Play

### 📁 Empty Play for Facts

```yaml
---
# Empty play - ensures facts are gathered (no tags)
-
  hosts: linux

# Main play with tags
-
  hosts: linux
  tags:
    - webapp
  
  vars_files:
    - vars/logos.yaml

  tasks:
    - name: Install EPEL
      yum:
        name: epel-release
        update_cache: yes
        state: latest
      when: ansible_distribution == 'CentOS'
      tags:
        - install-epel

    - name: Install Nginx
      package:
        name: nginx
        state: latest
      tags:
        - install-nginx

    # ... rest of tasks
```

**How it works:**
```
Play 1 (no tags) → gather_facts runs (always)
Play 2 (webapp tag) → tasks run when tag matches
```

```bash
# Now facts are available!
ansible-playbook nginx_playbook.yaml --tags install-nginx
# Gathering facts... ✓
# Install Nginx... ✓
```

---

## 🎯 4. Special Tags

### always - Task Always Runs

### 📁 Using `always` Tag

```yaml
---
-
  hosts: linux
  tags:
    - webapp
  
  vars_files:
    - vars/logos.yaml

  tasks:
    - name: Install EPEL
      yum:
        name: epel-release
        update_cache: yes
        state: latest
      when: ansible_distribution == 'CentOS'
      tags:
        - install-epel

    - name: Install Nginx
      package:
        name: nginx
        state: latest
      tags:
        - install-nginx

    - name: Restart nginx
      service:
        name: nginx
        state: restarted
      notify: Check HTTP Service
      tags:
        - always              # ← Runs with ANY tag!

    - name: Template index.html
      template:
        src: index.html-easter_egg.j2
        dest: "{{ nginx_root_location }}/index.html"
        mode: 0644
      tags:
        - deploy-app

    - name: Install unzip
      package:
        name: unzip
        state: latest

    - name: Unarchive game
      unarchive:
        src: playbook_stacker.zip
        dest: "{{ nginx_root_location }}"
        mode: 0755
      tags:
        - deploy-app
```

```bash
# Restart nginx ALWAYS runs, even with install-nginx tag
ansible-playbook nginx_playbook.yaml --tags install-nginx
# Install Nginx ✓
# Restart nginx ✓ (because of always)
```

### Skipping `always` Tasks

```bash
# To skip always tasks, use --skip-tags
ansible-playbook nginx_playbook.yaml --tags install-nginx --skip-tags always
```

---

## 📊 Special Tags Reference

| Tag | Behavior |
|-----|----------|
| `always` | Task runs regardless of which tags are specified |
| `never` | Task only runs with `--tags never` or no tags |
| `tagged` | Filter tasks that have ANY tag |
| `untagged` | Filter tasks with NO tags |
| `all` | All tasks (default behavior) |

---

## 🎯 5. Tag Command Line Options

### Basic Tag Operations

```bash
# Run specific tags
ansible-playbook playbook.yml --tags "tag1,tag2"

# Skip specific tags
ansible-playbook playbook.yml --skip-tags "tag1,tag2"

# List all tags in playbook
ansible-playbook playbook.yml --list-tags

# Run only tasks with tags (skip untagged)
ansible-playbook playbook.yml --tags tagged

# Run only untagged tasks
ansible-playbook playbook.yml --tags untagged

# Run all tasks (default)
ansible-playbook playbook.yml --tags all
```

### Command Line Examples

```bash
# Run only epel and nginx installation
ansible-playbook nginx.yml --tags "install-epel,install-nginx"

# Run everything except application deployment
ansible-playbook nginx.yml --skip-tags deploy-app

# See what would run with a tag
ansible-playbook nginx.yml --tags install-nginx --check
```

---

## 📁 Tag Inheritance with Includes/Imports

### Main Playbook (`include_import_playbook.yaml`)

```yaml
---
-
  hosts: ubuntu3

  tasks:
    - include_tasks: include_tasks.yaml
      tags:
        - include_tasks

    - import_tasks: import_tasks.yaml
      tags:
        - import_tasks

- import_playbook: import_playbook.yaml
  tags:
    - import_playbook
```

### Included File (`include_tasks.yaml`)
```yaml
---
- debug:
    msg: Include tasks executed
```

### Imported File (`import_tasks.yaml`)
```yaml
---
- debug:
    msg: Import tasks executed
```

### Imported Playbook (`import_playbook.yaml`)
```yaml
---
-
  hosts: centos1
  tasks:
    - debug:
        msg: Import playbook executed
```

### Running with Tags

```bash
# Run include_tasks tag
ansible-playbook include_import_playbook.yaml --tags include_tasks

# Run import_tasks tag
ansible-playbook include_import_playbook.yaml --tags import_tasks

# Run import_playbook tag
ansible-playbook include_import_playbook.yaml --tags import_playbook
```

> 💡 **Inheritance:** Tags applied to `include_*` or `import_*` are inherited by all tasks within the included/imported file!

---

## 📊 Tag Comparison

| Tag Type | Scope | Use Case |
|----------|-------|----------|
| **Task tags** | Individual tasks | Fine-grained control |
| **Play tags** | Entire play | Group related tasks |
| **Include/Import tags** | External files | Tag entire includes |
| **always** | Critical tasks | Must-always-run operations |

---

## 🛠️ Best Practices

| Practice | Reason |
|----------|--------|
| **Use consistent naming** | `install-nginx`, not `nginx-install` |
| **Tag by function** | `database`, `webserver`, `monitoring` |
| **Tag by layer** | `os`, `app`, `config`, `deploy` |
| **Use `always` sparingly** | Only for critical tasks |
| **Test with `--list-tags`** | Verify tags before running |

---

## 🎯 Common Tag Patterns

### Pattern 1: Environment Tags
```yaml
tasks:
  - name: Dev only config
    copy:
      src: dev.conf
      dest: /etc/app.conf
    tags: dev

  - name: Prod only config
    copy:
      src: prod.conf
      dest: /etc/app.conf
    tags: prod
```

```bash
ansible-playbook deploy.yml --tags prod
```

### Pattern 2: Idempotency Check Tags
```yaml
tasks:
  - name: Expensive operation
    command: /opt/long-task
    tags: 
      - expensive
      - deploy
```

```bash
# Skip expensive tasks during testing
ansible-playbook deploy.yml --skip-tags expensive
```

### Pattern 3: Debugging Tags
```yaml
tasks:
  - name: Debug output
    debug:
      var: ansible_facts
    tags: debug

  - name: Verbose logging
    command: echo "Starting..."
    tags: debug
```

```bash
# Run with debug output
ansible-playbook playbook.yml --tags debug -v
```

---

## ⚡ Quick Reference

### Task Level
```yaml
- name: Task name
  module:
    param: value
  tags:
    - tag1
    - tag2
```

### Play Level
```yaml
- hosts: all
  tags:
    - play_tag
  tasks:
    - ...
```

### Include/Import Level
```yaml
- include_tasks: file.yml
  tags: include_tag

- import_playbook: other.yml
  tags: import_tag
```

### Special Tags
```yaml
- name: Always runs
  debug:
    msg: "Always"
  tags: always

- name: Never runs by default
  debug:
    msg: "Never"
  tags: never
```

### Command Line
```bash
# Run tags
--tags "tag1,tag2"
-t "tag1,tag2"

# Skip tags
--skip-tags "tag1,tag2"

# List tags
--list-tags

# Special filters
--tags tagged
--tags untagged
--tags all
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **Task tags** | Control execution of individual tasks |
| **Play tags** | Tag entire play (affects facts gathering!) |
| **Empty play** | Workaround to ensure facts run |
| **always tag** | Task runs with ANY tag |
| **Tag inheritance** | Include/import tasks inherit parent tags |
| **--skip-tags** | Run everything except specified tags |

> 💡 **Pro Tip:** Use `--list-tags` to discover available tags before running a playbook!

---
