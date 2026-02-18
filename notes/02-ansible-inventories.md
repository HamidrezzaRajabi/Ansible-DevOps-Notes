
# 📋 Ansible Inventories

**Date Learned:** [Date]
**Related Videos:** 010-Ansible Inventories

## 📌 Key Concepts

### What is an Inventory?
- A list of managed nodes (hosts) that Ansible can connect to
- Can be static files or dynamic scripts
- Supports multiple formats: **INI, YAML, JSON**
- Organizes hosts into groups for easier management

### Inventory Structure Hierarchy

```plaintext
all (default group)
├── linux (parent group)
│   ├── centos (child group)
│   │   ├── centos1
│   │   ├── centos2
│   │   └── centos3
│   └── ubuntu (child group)
│       ├── ubuntu1
│       ├── ubuntu2
│       └── ubuntu3
└── control (group)
    └── ubuntu-c
```


### Variable Types in Inventory
- **Host Variables (hostvars)** - Apply to specific hosts
- **Group Variables (groupvars)** - Apply to all hosts in a group
- **Parent Group Variables** - Inherited by child groups

## 💻 Inventory Formats

### 1. **INI Format** (Traditional)
```ini
# File: hosts.ini

[centos]
centos1 ansible_port=2222 ansible_user=root
centos[2:3] ansible_user=root

[ubuntu]
ubuntu[1:3] ansible_become=yes ansible_become_pass=password

[control]
ubuntu-c ansible_connection=local

[linux:children]
centos
ubuntu

[centos:vars]
ansible_user=root

[ubuntu:vars]
ansible_become=yes
ansible_become_pass=password
```

### 2. YAML Format

#### File: hosts.yaml
```yaml
---
all:
  children:
    linux:
      children:
        centos:
          hosts:
            centos1:
              ansible_port: 2222
              ansible_user: root
            centos2: {}
            centos3: {}
          vars:
            ansible_user: root

        ubuntu:
          hosts:
            ubuntu1: {}
            ubuntu2: {}
            ubuntu3: {}
          vars:
            ansible_become: true
            ansible_become_pass: "password"

    control:
      hosts:
        ubuntu-c:
          ansible_connection: local
...
```

### 3. JSON Format (Machine-readable)
```jason
{
  "all": {
    "children": {
      "centos": {
        "hosts": {
          "centos1": {
            "ansible_port": 2222,
            "ansible_user": "root"
          },
          "centos2": null,
          "centos3": null
        },
        "vars": {
          "ansible_user": "root"
        }
      }
    }
  }
}
```

### 🔧 Essential Inventory Commands
#### Working with Inventories

```bash
# List all hosts in inventory
ansible-inventory --list
ansible-inventory --graph

# List hosts in specific group
ansible all --list-hosts
ansible centos --list-hosts
ansible ubuntu --list-hosts

# Use pattern matching
ansible '*.3' --list-hosts  # All hosts ending with 3
ansible '~.*[23]' --list-hosts  # Regex: hosts ending with 2 or 3

# Specify inventory file
ansible -i hosts.ini all -m ping
ansible -i hosts.yaml all -m ping
ansible -i hosts.json all -m ping

# Command-line inventory (comma-separated)
ansible -i ubuntu1,centos1, all -m ping
```

#### Testing Connectivity

```bash
# Ping all hosts
ansible all -m ping

# Ping with one-line output
ansible all -m ping -o

# Run command on all hosts
ansible all -m command -a "id"
# or simply (command is default)
ansible all -a "id"

# Check specific user
ansible centos -a "id"  # Should show root (UID 0)
ansible ubuntu -a "id"  # Should show ansible user
```
### 📝 Inventory Variables Explained
#### Common Connection Variables
```bash 
# Connection settings
ansible_host: 192.168.1.10        # IP/hostname if different from inventory name
ansible_port: 2222                  # SSH port (default: 22)
ansible_user: admin                  # SSH user
ansible_password: secret             # SSH password (not recommended)
ansible_connection: ssh              # Connection type (ssh, local, docker, winrm)
ansible_ssh_private_key_file: /path/key  # Private key file

# Privilege escalation
ansible_become: yes                  # Enable privilege escalation
ansible_become_method: sudo           # Method: sudo, su, pbrun, etc.
ansible_become_user: root             # User to become
ansible_become_pass: password         # Password for escalation
```
### Host Ranges
```ini
# Numeric ranges
[webservers]
web[01:50].example.com    # web01 to web50

# Alphabetic ranges
[databases]
db-[a:f].example.com      # db-a to db-f

# Mixed with exceptions
[centos]
centos[1:3]               # centos1, centos2, centos3
centos1:2222               # Override port for centos1
```

<br>
<br>


## 🎯 Practical Examples
### Example 1: Basic Inventory with Different Access Methods
```ini
# hosts.ini
[centos]
centos1 ansible_user=root           # Direct root access
centos2 ansible_user=root           # Direct root access

[ubuntu]
ubuntu1 ansible_become=yes          # Sudo access
ubuntu2 ansible_become=yes          # Sudo access

[centos:vars]
ansible_become=no                    # No sudo needed for centos

[ubuntu:vars]
ansible_become_method=sudo
ansible_become_user=root
ansible_become_pass=password
```
### Example 2: Environment-based Inventory
```ini
# environments.ini
[production]
prod-web[01:05].company.com
prod-db[01:02].company.com

[staging]
stg-web[01:02].company.com
stg-db01.company.com

[development]
dev-web01.company.com
dev-db01.company.com

[webservers:children]
production
staging
development
```

#### ⚠️ Variable Precedence
From lowest to highest:<br>
all group variables (all:vars)<br>
Parent group variables<br>
Child group variables<br>
Host variables<br>
Command-line extra vars (-e flag)

```bash
# Example of variable override
ansible centos1 -m ping -e "ansible_port=22"  # Overrides inventory port
```
### 🔍 Inventory Query Examples

```bash
# Show all variables for a host
ansible-inventory --host centos1

# Show group structure
ansible-inventory --graph

# Debug inventory variables
ansible centos1 -m debug -a "var=hostvars[inventory_hostname]"

# Check group membership
ansible centos1 -m debug -a "var=group_names"
```

## 📚 Best Practices

1. Use group variables for common settings  
2. Keep sensitive data in vault or environment variables  
3. Use host ranges for large deployments  
4. Version control your inventory files  
5. Document variable purposes in comments  
6. Test inventory changes with `--list-hosts` first  

## 🔗 Key Takeaways

1. Inventories organize and define your infrastructure  
2. Multiple formats supported (INI, YAML, JSON)  
3. Variables can be applied at different levels  
4. Group inheritance simplifies management  
5. Always test connectivity after inventory changes