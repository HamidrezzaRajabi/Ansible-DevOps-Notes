# 🔄 Looping in Ansible


## 📌 What You'll Learn

All loops in Ansible start with `with_` and allow you to repeat tasks efficiently.

| Loop Type | Purpose |
|-----------|---------|
| `with_items` | Loop over a simple list |
| `with_dict` | Loop over dictionary keys/values |
| `with_subelements` | Loop over nested structures |
| `with_nested` | Cartesian product (nested loops) |
| `with_together` | Pair elements from multiple lists |
| `with_file` | Read file contents |
| `with_sequence` | Generate number sequences |
| `with_random_choice` | Pick random item |
| `until` | Retry until condition met |

---

## 🎯 1. with_items - Simple Lists

### 📁 01: Original (No Loop)
```yaml
tasks:
  - name: Configure MOTD for CentOS
    copy:
      content: "Welcome to CentOS Linux - Ansible Rocks\n"
      dest: /etc/motd
    when: ansible_distribution == "CentOS"

  - name: Configure MOTD for Ubuntu
    copy:
      content: "Welcome to Ubuntu Linux - Ansible Rocks\n"
      dest: /etc/motd
    when: ansible_distribution == "Ubuntu"
```
**❌ Problem:** Duplicate tasks

### 📁 02: Simplified (No Loop Needed)
```yaml
tasks:
  - name: Configure MOTD
    copy:
      content: "Welcome to {{ ansible_distribution }} Linux - Ansible Rocks\n"
      dest: /etc/motd
```
**✅ Better:** Single task using fact

### 📁 03: with_items (List Format)
```yaml
tasks:
  - name: Configure MOTD
    copy:
      content: "Welcome to {{ item }} Linux - Ansible Rocks!\n"
      dest: /etc/motd
    with_items: [ 'CentOS', 'Ubuntu' ]
    when: ansible_distribution == item
```

### 📁 04: with_items (YAML List)
```yaml
tasks:
  - name: Configure MOTD
    copy:
      content: "Welcome to {{ item }} Linux - Ansible Rocks!\n"
      dest: /etc/motd
    with_items: 
      - CentOS
      - Ubuntu
    when: ansible_distribution == item
```

### 📁 05: Creating Users
```yaml
tasks:
  - name: Creating user
    user:
      name: "{{ item }}"
    with_items: 
      - james
      - hayley
      - lily
      - anwen
```

### 📁 06: Removing Users
```yaml
tasks:
  - name: Removing user
    user:
      name: "{{ item }}"
      state: absent
    with_items: 
      - james
      - hayley
      - lily
      - anwen
```

> 💡 **Key Point:** `item` is the magic variable containing the current loop value

---

## 🎯 2. with_dict - Dictionaries

### 📁 07: Creating Users with Comments
```yaml
tasks:
  - name: Creating user
    user:
      name: "{{ item.key }}"
      comment: "{{ item.value.full_name }}"
    with_dict: 
      james: 
        full_name: James Spurin
      hayley: 
        full_name: Hayley Spurin
      lily: 
        full_name: Lily Spurin
      anwen:
        full_name: Anwen Spurin
```

| Variable | Meaning |
|----------|---------|
| `item.key` | Dictionary key (username) |
| `item.value` | Dictionary value (full_name) |

### 📁 08: Removing Users with Dict
```yaml
tasks:
  - name: Removing user
    user:
      name: "{{ item.key }}"
      comment: "{{ item.value.full_name }}"
      state: absent
    with_dict: 
      james: 
        full_name: James Spurin
      hayley: 
        full_name: Hayley Spurin
      lily: 
        full_name: Lily Spurin
      anwen:
        full_name: Anwen Spurin
```

---

## 🎯 3. with_subelements - Nested Structures

### 📁 09: Single Family
```yaml
tasks:
  - name: Creating user
    user:
      name: "{{ item.1 }}"
      comment: "{{ item.1 | title }} {{ item.0.surname }}"
    with_subelements: 
      - family:
          surname: Spurin
          members:
            - james
            - hayley
            - lily
            - anwen
      - members
```

| Variable | Meaning |
|----------|---------|
| `item.0` | Parent dictionary (family) |
| `item.1` | Child item (member name) |
| `item.0.surname` | Access parent's surname |
| `title` filter | Capitalizes first letter |

### 📁 10: Multiple Families
```yaml
tasks:
  - name: Creating user
    user:
      name: "{{ item.1 }}"
      comment: "{{ item.1 | title }} {{ item.0.surname }}"
    with_subelements: 
      - 
        - surname: Spurin
          members:
            - james
            - hayley
            - lily
            - anwen
        - surname: Darlington
          members:
            - freya
        - surname: Jalba
            members:
              - ana
      - members
```

### 📁 11: With Passwords
```yaml
tasks:
  - name: Creating user
    user:
      name: "{{ item.1 }}"
      comment: "{{ item.1 | title }} {{ item.0.surname }}"
      password: "{{ lookup('password', '/dev/null length=15 chars=ascii_letters,digits,hexdigits,punctuation') | password_hash('sha512') }}"
    with_subelements:
      -
        - surname: Spurin
          members:
            - james
            - hayley
            - lily
            - anwen
        - surname: Darlington
          members:
            - freya
      - members
```

> 🔐 **Password Lookup:** Generates random password, doesn't save to file (/dev/null discards it)

---

## 🎯 4. with_nested - Cartesian Product

### 📁 12: Create Directories for Multiple Users
```yaml
tasks:
  - name: Creating user directories
    file:
      dest: "/home/{{ item.0 }}/{{ item.1 }}"
      owner: "{{ item.0 }}"
      group: "{{ item.0 }}"
      state: directory
    with_nested:
      - [ james, hayley, freya, lily, anwen, ana, abhishek, sara ]
      - [ photos, movies, documents ]
```

**Result:** 8 users × 3 directories = 24 iterations

| Users | Directories |
|-------|-------------|
| james | photos |
| james | movies |
| james | documents |
| hayley | photos |
| ... | ... |

---

## 🎯 5. with_together - Pair Elements

### 📁 13: Pair Users with Interests
```yaml
tasks:
  - name: Creating user directories
    file:
      dest: "/home/{{ item.0 }}/{{ item.1 }}"
      owner: "{{ item.0 }}"
      group: "{{ item.0 }}"
      state: directory
    with_together:
      - [ james, hayley, freya, lily, anwen, ana, abhishek, sara ]
      - [ tech, psychology, acting, dancing, playing, japanese, coffee, music ]
```

**Result:** Pairs first with first, second with second:

| Pair | User | Directory |
|------|------|-----------|
| 1 | james | tech |
| 2 | hayley | psychology |
| 3 | freya | acting |
| 4 | lily | dancing |

---

## 🎯 6. with_file - Read File Content

### 📁 14: Single SSH Key
```yaml
tasks:
  - name: Create authorized key
    authorized_key:
      user: james
      key: "{{ item }}"
    with_file:
      - /home/ansible/.ssh/id_rsa.pub
```

### 📁 15: Multiple SSH Keys
```yaml
tasks:
  - name: Create authorized key
    authorized_key:
      user: james
      key: "{{ item }}"
    with_file:
      - /home/ansible/.ssh/id_rsa.pub
      - custom_key.pub
```

> 📝 **Note:** `with_file` reads the entire file content and passes it as `{{ item }}`

---

## 🎯 7. with_sequence - Number Ranges

### 📁 Revision 16: Basic Sequence (start/end/stride)
```yaml
tasks:
  - name: Create sequence directories
    file:
      dest: "/home/james/sequence_{{ item }}"
      state: directory
    with_sequence: start=0 end=100 stride=10
```

**Creates:** sequence_0, sequence_10, sequence_20, ..., sequence_100

### 📁 17: Format String
```yaml
tasks:
  - name: Create sequence directories
    file:
      dest: "{{ item }}"
      state: directory
    with_sequence: start=0 end=100 stride=10 format=/home/james/sequence_%d
```

| Format Code | Meaning |
|-------------|---------|
| `%d` | Decimal (0, 10, 20...) |
| `%x` | Hexadecimal (0, a, 14...) |
| `%o` | Octal |

### 📁 18: Hexadecimal Sequence
```yaml
tasks:
  - name: Create hex sequence directories
    file:
      dest: "{{ item }}"
      state: directory
    with_sequence: start=0 end=16 stride=1 format=/home/james/hex_sequence_%x
```

**Creates:** hex_sequence_0, hex_sequence_1, ..., hex_sequence_f

### 📁  19: Count (Number of Items)
```yaml
tasks:
  - name: Create count directories
    file:
      dest: "{{ item }}"
      state: directory
    with_sequence: count=5 format=/home/james/count_sequence_%x
```

**Creates:** count_sequence_0, count_sequence_1, count_sequence_2, count_sequence_3, count_sequence_4

---

## 🎯 8. with_random_choice - Random Selection

### 📁 Revsion 20: Random Directory
```yaml
tasks:
  - name: Create random directory
    file:
      dest: "/home/james/{{ item }}"
      state: directory
    with_random_choice:
      - "google"
      - "facebook"
      - "microsoft"
      - "apple"
```

> 🎲 **Result:** Randomly picks one item from the list for EACH host

---

## 🎯 9. until - Retry Until Condition

### Script (`random.sh`)
```bash
#!/bin/bash
echo $((1 + RANDOM % 10))
```

### 📁 21: Retry Until Value is 10
```yaml
tasks:
  - name: Run a script until we hit 10
    script: random.sh
    register: result
    retries: 100
    until: result.stdout.find("10") != -1
    delay: 1
```

| Parameter | Meaning |
|-----------|---------|
| `retries` | Maximum attempts (default: 3) |
| `until` | Condition to stop retrying |
| `delay` | Seconds between retries (default: 5) |

**Use cases:**
- Wait for service to start
- Wait for file to appear
- Wait for API to respond
- Wait for deployment to complete

---

## 📊 Loop Types Quick Reference

| Loop | Input | item value | Use Case |
|------|-------|------------|----------|
| `with_items` | `[a, b, c]` | a, then b, then c | Simple lists |
| `with_dict` | `{key: value}` | `item.key`, `item.value` | Key-value pairs |
| `with_subelements` | Nested dict | `item.0`, `item.1` | Hierarchical data |
| `with_nested` | `[list1, list2]` | `[item.0, item.1]` | Cartesian product |
| `with_together` | `[list1, list2]` | `[item.0, item.1]` | Pair elements |
| `with_file` | File paths | File content | Reading files |
| `with_sequence` | start/end/stride | Generated numbers | Number sequences |
| `with_random_choice` | List of items | Random item | Random selection |
| `until` | Condition | N/A | Retry logic |

---

## ⚡ Performance Note

**Revision 03-04:** Using `with_items` runs the task multiple times (2 times × number of hosts)

```
6 hosts × 2 items = 12 task executions
```

This is normal and expected behavior.

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **with_items** | Loop over simple lists, use `{{ item }}` |
| **with_dict** | Loop over dictionaries, use `item.key` and `item.value` |
| **with_subelements** | Handle nested structures with `item.0` and `item.1` |
| **with_nested** | Cartesian product - for each X, do each Y |
| **with_together** | Pair elements from multiple lists |
| **with_file** | Read file content into loop |
| **with_sequence** | Generate numeric sequences with formatting |
| **with_random_choice** | Pick random item per host |
| **until** | Retry with `retries`, `delay`, and `until` condition |

---
