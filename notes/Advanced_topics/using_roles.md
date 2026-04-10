# 📦 Using Roles


## 📌 What are Roles?

Roles are a way to **organize playbooks into reusable components** with a standardized directory structure.

| Benefit | Description |
|---------|-------------|
| **Reusability** | Use the same role across multiple projects |
| **Shareability** | Easy to share via Ansible Galaxy |
| **Maintainability** | Logical separation of concerns |
| **Parallel development** | Different teams can work on different roles |
| **Dependencies** | Roles can depend on other roles |

---

## 🏗️ Role Directory Structure

```
role_name/
├── defaults/      # Default variables (lowest priority)
│   └── main.yml
├── files/         # Static files for copy/file modules
│   └── ...
├── handlers/      # Handler definitions
│   └── main.yml
├── meta/          # Role metadata and dependencies
│   └── main.yml
├── tasks/         # Main task list
│   └── main.yml
├── templates/     # Jinja2 template files
│   └── *.j2
├── tests/         # Test inventory and playbook
│   ├── inventory
│   └── test.yml
├── vars/          # Variables (higher priority than defaults)
│   └── main.yml
└── README.md      # Documentation
```

---

## 🎯 Variable Priority in Roles

| Location | Priority | Purpose |
|----------|----------|---------|
| `defaults/main.yml` | Lowest | Default values (can be easily overridden) |
| `vars/main.yml` | Higher | Variables that shouldn't be overridden |
| Playbook `vars` | Higher | Playbook-level overrides |
| `--extra-vars` | Highest | Command-line overrides |

---

## 🛠️ Creating a Role with Ansible Galaxy

```bash
# Create role skeleton
ansible-galaxy init role_name

# Example: create nginx role
ansible-galaxy init nginx

# Resulting structure
nginx/
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
├── tests/
│   ├── inventory
│   └── test.yml
├── vars/
│   └── main.yml
└── README.md
```

---

## 📂 Converting a Playbook to a Role

### Step 1: Move Handlers
```bash
# From playbook handlers section → role/handlers/main.yml
```

### Step 2: Move Templates
```bash
# From templates/ directory → role/templates/
```

### Step 3: Move Files
```bash
# From files/ directory → role/files/
```

### Step 4: Move Variables
```bash
# From vars/ directory → role/vars/main.yml
# Or for defaults → role/defaults/main.yml
```

### Step 5: Move Tasks
```bash
# From playbook tasks section → role/tasks/main.yml
```

### Step 6: Update Playbook
```yaml
---
- hosts: linux
  roles:
    - nginx
```

---

## 🔄 Using Roles in Playbooks

### Basic Syntax
```yaml
---
- hosts: webservers
  roles:
    - common
    - nginx
    - database
```

### Passing Parameters to Roles
```yaml
---
- hosts: webservers
  roles:
    - role: nginx
      vars:
        port: 8080
        root: /var/www
```

### Conditional Role Execution
```yaml
---
- hosts: webservers
  roles:
    - role: nginx
      when: ansible_distribution == "CentOS"
    - role: apache
      when: ansible_distribution == "Ubuntu"
```

---

## 🔗 Role Dependencies

Define dependencies in `meta/main.yml`:

```yaml
---
dependencies:
  - role: common
  - role: nginx
  - role: firewall
    vars:
      allow_port: 80
```

When you include a role, its dependencies are automatically executed **before** the role itself.

---

## 📊 Role Variables Precedence (from lowest to highest)

```
1. Role defaults (defaults/main.yml)
2. Inventory group_vars
3. Inventory host_vars
4. Playbook vars
5. Role vars (vars/main.yml)
6. Role parameters (in roles: section)
7. Extra vars (--extra-vars) ← Highest
```

---

## 🎯 Best Practices

| Practice | Why |
|----------|-----|
| **Use `defaults/` for configurable vars** | Easy to override |
| **Use `vars/` for internal vars** | Shouldn't be changed by users |
| **Keep roles focused** | One role = one responsibility |
| **Use meaningful names** | `nginx` not `webserver_config` |
| **Document with README** | Explain purpose and variables |
| **Version your roles** | Use tags in Git |

---

## 📁 Role Distribution Methods

| Method | Command |
|--------|---------|
| **Ansible Galaxy** | `ansible-galaxy install username.role_name` |
| **GitHub** | `ansible-galaxy install git+https://github.com/user/repo.git` |
| **Local directory** | `ansible-galaxy install /path/to/role` |
| **Requirements file** | `ansible-galaxy install -r requirements.yml` |

### requirements.yml Example
```yaml
---
- src: geerlingguy.nginx
  version: 2.8.0

- src: https://github.com/user/role.git
  version: main

- src: /local/path/to/role
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **Role structure** | Standardized directories: tasks, handlers, templates, files, vars, defaults, meta |
| **ansible-galaxy init** | Creates role skeleton |
| **defaults/** | Lowest priority variables |
| **vars/** | Higher priority internal variables |
| **Dependencies** | Defined in `meta/main.yml` |
| **Role parameters** | Pass variables when including role |
| **Reusability** | Main benefit of roles |

> 💡 **Pro Tip:** Start with roles when your playbook exceeds 20-30 tasks or when you need to reuse functionality across multiple projects!

---
