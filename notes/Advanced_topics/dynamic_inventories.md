# 🔄 Ansible Dynamic Inventories



## 📌 What are Dynamic Inventories?

Dynamic Inventories are **executable scripts** that generate inventory data on-the-fly instead of using static files.

| Static Inventory | Dynamic Inventory |
|-----------------|-------------------|
| `.ini`, `.yaml`, `.json` files | Executable scripts (Python, Bash, etc.) |
| Manual updates required | Auto-generated from external sources |
| Good for stable environments | Ideal for cloud/containers |

> 💡 **Use cases:** AWS EC2, Docker containers, VMware VMs, CMDBs, or any environment that changes frequently

---

## 🎯 Requirements for Dynamic Inventory

| Requirement | Description |
|-------------|-------------|
| **Executable** | File must have `+x` permission |
| **--list flag** | Returns all groups and hosts |
| **--host flag** | Returns variables for a specific host |
| **JSON output** | Must print valid JSON to stdout |

```bash
# Basic usage
./inventory.py --list                    # Returns all inventory
./inventory.py --host centos1            # Returns host variables
```

---

## 📁 Basic Dynamic Inventory

### The Python Script (`inventory.py`)

```python
#!/usr/bin/env python3

'''
Dynamic inventory for Ansible in Python
'''

from __future__ import print_function
import argparse
import json

class Inventory(object):

    def __init__(self, include_hostvars_in_list):
        # Parse command line arguments
        parser = argparse.ArgumentParser()
        parser.add_argument('--list', action='store_true', help='list inventory')
        parser.add_argument('--host', action='store', help='show HOST variables')
        self.args = parser.parse_args()

        # Show usage if no arguments
        if not (self.args.list or self.args.host):
            parser.print_usage()
            raise SystemExit

        # Define the inventory structure
        self.define_inventory()

        # Handle --list or --host
        if self.args.list:
            self.print_json(self.list())
        elif self.args.host:
            self.print_json(self.host())

    def define_inventory(self):
        # Define groups, hosts, and variables
        self.groups = {
            "centos": {
                "hosts": ["centos1", "centos2", "centos3"],
                "vars": {
                    "ansible_user": 'root'
                }
            },
            "control": {
                "hosts": ["ubuntu-c"],
            },
            "ubuntu": {
                "hosts": ["ubuntu1", "ubuntu2", "ubuntu3"],
                "vars": {
                    "ansible_become": True,
                    "ansible_become_pass": 'password'
                }
            },
            "linux": {
                "children": ["centos", "ubuntu"],
            }
        }

        self.hostvars = {
            'centos1': {
                'ansible_port': 2222
            },
            'ubuntu-c': {
                'ansible_connection': 'local'
            }
        }

    def print_json(self, content):
        print(json.dumps(content, indent=4, sort_keys=True))

    def list(self):
        # Returns groups without hostvars (_meta)
        return self.groups

    def host(self):
        # Returns variables for specific host
        if self.args.host in self.hostvars:
            return self.hostvars[self.args.host]
        else:
            return {}

# Initialize the inventory
Inventory(include_hostvars_in_list=False)
```

### Testing the Script

```bash
# Make it executable
chmod +x inventory.py

# Test --list
./inventory.py --list
```

**Output:**
```json
{
    "centos": {
        "hosts": ["centos1", "centos2", "centos3"],
        "vars": {
            "ansible_user": "root"
        }
    },
    "control": {
        "hosts": ["ubuntu-c"]
    },
    "linux": {
        "children": ["centos", "ubuntu"]
    },
    "ubuntu": {
        "hosts": ["ubuntu1", "ubuntu2", "ubuntu3"],
        "vars": {
            "ansible_become": true,
            "ansible_become_pass": "password"
        }
    }
}
```

```bash
# Test --host
./inventory.py --host centos1
```

**Output:**
```json
{
    "ansible_port": 2222
}
```

```bash
# Host without custom vars
./inventory.py --host centos2
```

**Output:**
```json
{}
```

---

## 🚀 Using Dynamic Inventory with Ansible

```bash
# List all hosts from dynamic inventory
ansible -i ./inventory.py all --list-hosts

# Output:
#   centos1
#   centos2
#   centos3
#   ubuntu1
#   ubuntu2
#   ubuntu3
#   ubuntu-c

# Ping all hosts
ansible -i ./inventory.py all -m ping

# Target specific group
ansible -i ./inventory.py centos -m ping

# Run playbook with dynamic inventory
ansible-playbook -i ./inventory.py playbook.yml
```

---

## ⚠️ The Performance Problem

### How Ansible Uses Dynamic Inventory

When you run `ansible -i inventory.py all -m ping`:

```
1. Ansible calls: inventory.py --list
   → Gets all groups and hosts

2. For EACH host, Ansible calls: inventory.py --host hostname
   → Gets variables for that specific host
```

### The Issue

```bash
# With 7 hosts → 1 + 7 = 8 script executions
# With 1000 hosts → 1 + 1000 = 1001 script executions!
```

**Revision 03 Example with 1000 hosts:**

```bash
# This would take ~69 seconds!
time ansible -i inventory.py all --list-hosts
# real    1m9s
```

---

## ✅ The Solution: _meta (Revision 04)

### Optimized Script (include_hostvars_in_list=True)

```python
# At the bottom of the script
Inventory(include_hostvars_in_list=True)  # Changed from False to True
```

### Updated `list()` Method

```python
def list(self):
    # If include_hostvars_in_list is True, merge hostvars as _meta
    if self.include_hostvars_in_list:
        merged = self.groups
        merged['_meta'] = {}
        merged['_meta']['hostvars'] = self.hostvars
        return merged
    else:
        return self.groups
```

### New --list Output with _meta

```json
{
    "centos": {
        "hosts": ["centos1", "centos2", "centos3"],
        "vars": {"ansible_user": "root"}
    },
    "control": {
        "hosts": ["ubuntu-c"]
    },
    "linux": {
        "children": ["centos", "ubuntu"]
    },
    "ubuntu": {
        "hosts": ["ubuntu1", "ubuntu2", "ubuntu3"],
        "vars": {
            "ansible_become": true,
            "ansible_become_pass": "password"
        }
    },
    "_meta": {
        "hostvars": {
            "centos1": {"ansible_port": 2222},
            "ubuntu-c": {"ansible_connection": "local"}
        }
    }
}
```

### Performance Improvement

```bash
# With _meta, Ansible only calls --list ONCE
# No separate --host calls for each host!

time ansible -i inventory.py all --list-hosts
# real    0m3s  (was 1m9s!)
```

> 🎯 **Key Insight:** With `_meta`, Ansible gets ALL host variables in the initial `--list` call. No extra `--host` calls needed!

---

## 📊 How Ansible Uses Dynamic Inventory

### Without _meta (Old way - Ansible < 1.3)
```
┌─────────────────────────────────────────────────────────┐
│ 1. inventory.py --list                                   │
│    ← Returns groups and hosts                           │
│                                                          │
│ 2. For each host: inventory.py --host hostname          │
│    ← Returns host-specific variables                    │
│                                                          │
│    Total calls = 1 + (number of hosts)                  │
└─────────────────────────────────────────────────────────┘
```

### With _meta (Modern Ansible)
```
┌─────────────────────────────────────────────────────────┐
│ 1. inventory.py --list                                   │
│    ← Returns groups, hosts, AND _meta.hostvars          │
│                                                          │
│    Total calls = 1                                       │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Debugging Dynamic Inventories

### Enable Logging

```python
def configure_logger(self):
    self.logger = logging.getLogger('ansible_dynamic_inventory')
    self.hdlr = logging.FileHandler('/var/tmp/ansible_dynamic_inventory.log')
    self.formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
    self.hdlr.setFormatter(self.formatter)
    self.logger.addHandler(self.hdlr)
    self.logger.setLevel(logging.DEBUG)
```

### Watch Logs in Real-time

```bash
# Tail the log file
tail -f /var/tmp/ansible_dynamic_inventory.log

# In another terminal, run Ansible
ansible -i inventory.py all --list-hosts
```

**Sample log output:**
```
2024-01-15 10:30:00 INFO list executed
2024-01-15 10:30:01 INFO host executed for centos1
2024-01-15 10:30:01 INFO host executed for centos2
2024-01-15 10:30:02 INFO host executed for centos3
...
```

---

## 📝 Dynamic Inventory Output Structure

### Required JSON Structure

```json
{
    "group_name": {
        "hosts": ["host1", "host2"],
        "vars": {
            "var1": "value1"
        },
        "children": ["child_group1"]
    },
    "_meta": {
        "hostvars": {
            "host1": {"host_var1": "value1"},
            "host2": {"host_var2": "value2"}
        }
    }
}
```

### Special Keys

| Key | Purpose |
|-----|---------|
| `hosts` | List of hosts in the group |
| `vars` | Variables for the group |
| `children` | Nested groups |
| `_meta` | Container for hostvars (optimization) |
| `hostvars` | Variables for specific hosts |

---

## 🎯 Creating Your Own Dynamic Inventory

### Template Structure

```python
#!/usr/bin/env python3
import argparse
import json

class Inventory:
    def __init__(self):
        self.parse_args()
        self.build_inventory()
        self.output()

    def parse_args(self):
        parser = argparse.ArgumentParser()
        parser.add_argument('--list', action='store_true')
        parser.add_argument('--host', action='store')
        self.args = parser.parse_args()

    def build_inventory(self):
        # TODO: Fetch hosts from your source (AWS API, database, etc.)
        self.groups = {
            "production": {
                "hosts": ["web1", "web2", "db1"],
                "vars": {"environment": "prod"}
            },
            "staging": {
                "hosts": ["stg-web1", "stg-db1"],
                "vars": {"environment": "staging"}
            }
        }
        
        self.hostvars = {
            "web1": {"ansible_port": 22},
            "db1": {"ansible_port": 2222}
        }

    def output(self):
        if self.args.list:
            # Include _meta for performance
            result = self.groups
            result['_meta'] = {'hostvars': self.hostvars}
            print(json.dumps(result, indent=2))
        elif self.args.host:
            vars = self.hostvars.get(self.args.host, {})
            print(json.dumps(vars, indent=2))

if __name__ == '__main__':
    Inventory()
```



## 📊 Quick Reference

### Command Line Testing

```bash
# Test inventory script manually
./inventory.py --list | jq '.'
./inventory.py --list | jq '._meta.hostvars'
./inventory.py --list | jq '.centos.hosts'
./inventory.py --host centos1

# Use with Ansible commands
ansible -i inventory.py all --list-hosts
ansible -i inventory.py all -m ping -o
ansible-inventory -i inventory.py --list
ansible-inventory -i inventory.py --graph
```

### Script Requirements Checklist

| Requirement | Command | Expected |
|-------------|---------|----------|
| Executable | `ls -l inventory.py` | `-rwxr-xr-x` |
| Python3 shebang | `head -1 inventory.py` | `#!/usr/bin/env python3` |
| --list works | `./inventory.py --list` | JSON output |
| --host works | `./inventory.py --host x` | JSON output |
| Valid JSON | `./inventory.py --list \| jq .` | Valid JSON |

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **Dynamic Inventory** | Executable script that outputs JSON |
| **--list flag** | Returns all groups and hosts |
| **--host flag** | Returns host-specific variables |
| **_meta optimization** | Embed hostvars in --list output |
| **Performance** | Without _meta: N+1 calls, With _meta: 1 call |
| **Any language** | Python, Bash, Ruby, Go, etc. |

> 💡 **Pro Tip:** Always implement `_meta` in your dynamic inventories for production use!

---
