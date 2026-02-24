# 📝 YAML Essentials for Ansible



## 📌 Why YAML Matters in Ansible

- **YAML** (YAML Ain't Markup Language) is the primary language for Ansible playbooks
- It's a **data-oriented language** designed to be human-readable
- Ansible also accepts JSON, but YAML is the predominant standard
- Understanding YAML = Understanding how Ansible interprets your automation

## 🎯 Key Concepts

### YAML Structure Basics
- **Optional start/end markers**: `---` (start) and `...` (end) - recommended for clarity
- **Indentation**: 2 spaces (standard) - **NO TABS!**
- **Comments**: Start with `#`
- **Key-Value pairs**: `key: value`
- **Data types**: Strings, Numbers, Booleans, Lists, Dictionaries

## 🔧 YAML Testing Tool

The course includes a handy Python utility to see how YAML is interpreted:

```bash
# The utility (show_yaml_python) contains:
python3 -c "
import sys, yaml, pprint
data = yaml.load(open('test.yaml'), Loader=yaml.FullLoader)
pprint.pprint(data)
"

# Make it executable
chmod +x show_yaml_python

# Use it to test your YAML
./show_yaml_python
```

## 📚 YAML Data Types & Structures
### 1. Scalars (Strings, Numbers, Booleans)

String

```yaml
---
# Different string formats - all interpreted the same
string1: this is a string           # No quotes
string2: "this is a string"          # Double quotes
string3: 'this is a string'           # Single quotes
...
```
Python interpretation:

```python
{'string1': 'this is a string',
 'string2': 'this is a string',
 'string3': 'this is a string'}
```

Strings with Escape Characters

```yaml
---
# Control characters need double quotes!
double_quotes: "Line1\nLine2"        # ✅ Correct - \n becomes newline
no_quotes: Line1\nLine2               # ❌ Wrong - \n treated as literal
single_quotes: 'Line1\nLine2'         # ❌ Wrong - \n treated as literal
...
```

Python interpretation:

```python
{
 'double_quotes': 'Line1\nLine2',    # Has actual newline
 'no_quotes': 'Line1\\nLine2',        # Literal \n
 'single_quotes': 'Line1\\nLine2'      # Literal \n
}
```
Multi-line Strings -
<br>
Preserve newlines (Pipe |):

```yaml
---
# | preserves all newlines
description: |
  This is line 1
  This is line 2
  This is line 3
...
```
Result: "This is line 1\nThis is line 2\nThis is line 3\n"
<br>

Fold lines (Greater than >):

```yaml
---
# > folds lines into spaces
description: >
  This is a very long
  string that we want
  to keep as a single line
...
```
Result: "This is a very long string that we want to keep as a single line\n"
<br>

Remove trailing newline (>- or |-):

```yaml
---
# >- removes final newline
single_line: >-
  This is all
  one line
  no newline at end

# |- preserves newlines but removes final one
multi_line: |-
  Line one
  Line two
  no newline at end
...
```

### 2. Numbers

```yaml
---
# Integers (no quotes)
port: 8080
replicas: 3
timeout: 30

# Floats
version: 2.5
cpu_load: 0.75

# Quoted numbers become strings
port_string: "8080"        # This is a string, not a number!
...
```

Python verification:

```python
# In Python interpreter
>>> myvar = {'port': 8080}
>>> type(myvar['port'])
<class 'int'>              # It's an integer!

>>> myvar = {'port': '8080'}
>>> type(myvar['port'])
<class 'str'>              # It's a string!
```

### 3. Booleans 

```yaml
---
# ✅ RECOMMENDED - Clear true/false
enable_ssl: true
debug_mode: False

# ⚠️ POSSIBLE but ambiguous - AVOID!
old_style_yes: yes          # Interpreted as true
old_style_no: no             # Interpreted as false
on_off: on                    # Interpreted as true
enabled: y                    # Interpreted as true (y = yes)

# ❌ NOT BOOLEANS in Python/YAML!
y_as_string: "y"             # String, not boolean
n_as_string: "n"              # String, not boolean
...
```

Python interpretation:

```python
{
 'enable_ssl': True,
 'debug_mode': False,
 'old_style_yes': True,      # 'yes' becomes True
 'old_style_no': False,       # 'no' becomes False
 'on_off': True,               # 'on' becomes True
 'enabled': True,               # 'y' becomes True
 'y_as_string': 'y',           # String, not boolean
 'n_as_string': 'n'            # String, not boolean
}
```

### 4. Lists

```yaml
---
# Block style (RECOMMENDED)
fruits:
  - apple
  - banana
  - orange

# Inline style (LESS COMMON)
colors: ['red', 'green', 'blue']

# Mixed with other types
servers:
  - web01
  - web02
  - db01
...
```

Python interpretation:

```python
{
 'fruits': ['apple', 'banana', 'orange'],
 'colors': ['red', 'green', 'blue'],
 'servers': ['web01', 'web02', 'db01']
}
```

Accessing list items:

```python
# In Python (0-based indexing)
myvar['fruits'][0]  # 'apple'
myvar['fruits'][1]  # 'banana'
myvar['fruits'][2]  # 'orange'
```
### 5. Dictionaries

```yaml
---
# Block style (RECOMMENDED)
person:
  name: John Doe
  age: 30
  occupation: Engineer

# Inline style (LESS COMMON)
address: {street: '123 Main St', city: 'Boston', zip: 02101}

# Nested dictionaries
company:
  name: Acme Inc
  location:
    city: New York
    country: USA
  employees: 500
...
```

Python interpretation:

```python
{
 'person': {'name': 'John Doe', 'age': 30, 'occupation': 'Engineer'},
 'address': {'street': '123 Main St', 'city': 'Boston', 'zip': 2101},
 'company': {
   'name': 'Acme Inc',
   'location': {'city': 'New York', 'country': 'USA'},
   'employees': 500
 }
}
```

### 6. Complex Structures

```yaml
---
employees:
  - name: Alice
    role: Developer
    skills:
      - Python
      - Ansible
  - name: Bob
    role: DevOps
    skills:
      - AWS
      - Kubernetes
      - Terraform
...
```

Python interpretation:

```python
{
 'employees': [
   {'name': 'Alice', 'role': 'Developer', 
    'skills': ['Python', 'Ansible']},
   {'name': 'Bob', 'role': 'DevOps',
    'skills': ['AWS', 'Kubernetes', 'Terraform']}
 ]
}
```
Dictionary of Lists

```yaml
---
departments:
  engineering:
    - Alice
    - Bob
    - Charlie
  sales:
    - Diana
    - Eve
  hr:
    - Frank
...
```
Deep Nesting

```yaml
---
# Dictionary with list of dictionaries containing lists
company:
  name: TechCorp
  departments:
    - name: Engineering
      employees:
        - name: Alice
          projects: ['Project A', 'Project B']
        - name: Bob
          projects: ['Project C']
    - name: Marketing
      employees:
        - name: Carol
          projects: ['Project D']
...
```

## 🚫 Invalid YAML Examples

### Mixing key-value and list at same level

```yaml
# ❌ INVALID - Can't mix dictionary and list at same level
invalid_example:
  key1: value1
  - list_item1
  - list_item2
```

Mixing inline styles

```yaml
# ❌ INVALID - Can't have inline dict followed by inline list
invalid_example: {key1: value1, key2: value2} [item1, item2]
```
<br>

## 📋 YAML Quick Reference Card

### Indentation Rules
```yaml
# ✅ GOOD - 2 spaces, consistent
parent:
  child: value
  another_child:
    grandchild: value

# ❌ BAD - Mixed spaces/tabs
parent:
	child: value    # TAB used here - ERROR!
  child2: value    # Spaces here - INCONSISTENT!
```

### Common Patterns in Ansible Playbooks

```yaml
---
- name: Example Playbook
  hosts: webservers
  become: yes
  
  vars:
    http_port: 80
    max_clients: 200
    
  tasks:
    - name: Install package
      apt:
        name: nginx
        state: present
        
    - name: Start service
      service:
        name: nginx
        state: started
...
```

## 📊 Data Type Summary

| Type                | Example               | Python Result              |
|---------------------|----------------------|----------------------------|
| String (unquoted)   | `name: John`         | `'John'`                   |
| String (quoted)     | `name: "John"`       | `'John'`                   |
| Integer             | `port: 8080`         | `8080`                     |
| Float               | `version: 2.5`       | `2.5`                      |
| Boolean (true)      | `enabled: true`      | `True`                     |
| Boolean (false)     | `debug: false`       | `False`                    |
| List (block)        | <pre>- item1<br>- item2</pre> | `['item1', 'item2']` |
| List (inline)       | `[item1, item2]`     | `['item1', 'item2']`       |
| Dict (block)        | <pre>key: value</pre> | `{'key': 'value'}`        |
| Dict (inline)       | `{key: value}`       | `{'key': 'value'}`         |

<br>

---
<br>

## 🔗 Useful Resources

1. [YAML Specification](https://yaml.org/spec/) – Official specification documentation  
2. [Wikipedia: YAML](https://en.wikipedia.org/wiki/YAML) – High-level overview and background information  
3. [Stack Overflow: YAML Multi-line Strings](https://stackoverflow.com/questions/3790454/how-do-i-break-a-string-in-yaml-over-multiple-lines) – Deep dive into multiline string behavior  
4. [YAML Validator (YAML Lint)](https://www.yamllint.com/) – Online tool to validate YAML syntax  

<br>


## ⚠️ Common YAML Pitfalls

### 1. Tab vs Spaces

```yaml
# ❌ ERROR - Tabs not allowed
task:
	- name: Install    # TAB before dash - FAILS!
```

### 2. Unquoted Booleans as Strings

```yaml
# ❌ This becomes boolean False, not string "no"
response: no

# ✅ Force string with quotes
response: "no"
```

### 3. Special Characters
```yaml
# ❌ Unquoted string with colon causes issues
message: Error: failed    # Colon interpreted as key separator

# ✅ Quote it
message: "Error: failed"
```

### 4. Indentation Inconsistency

```yaml
# ❌ Inconsistent indentation
tasks:
  - name: task1
    debug:
      msg: "Hello"
     another: value    # Wrong indentation (3 spaces)
```     

## 📝 Key Takeaways
1. YAML is data-oriented - understand how Python interprets it

2. Indentation matters - 2 spaces, NO TABS!

3. Use --- and ... - Good practice for clarity

4. Be explicit with booleans - Use true/false, not yes/no/y/n

5. Double quotes for escape sequences - \n, \t, etc.

6. Choose readable formats - Block style > inline style

7. Test your YAML - Use the Python utility or online validators