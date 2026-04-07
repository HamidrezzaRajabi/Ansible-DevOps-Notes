# 🔧 Blocks - Task Grouping and Error Handling



## 📌 What are Blocks?

Blocks allow you to **group multiple tasks** together and apply common directives or error handling to the entire group.

| Feature | Purpose |
|---------|---------|
| **Grouping** | Organize related tasks |
| **Error Handling** | Try/rescue/always pattern |
| **Common Directives** | Apply `when`, `with_items` to multiple tasks |

> 💡 **Added in Ansible 2.0** | Named blocks added in Ansible 2.3

---

## 🎯 1. Basic Block - Grouping Tasks

### 📁 1: Simple Block

```yaml
---
-
  hosts: linux

  tasks:
    - name: A block of modules being executed
      block:
        - name: Example 1
          debug:
            msg: Example 1

        - name: Example 2
          debug:
            msg: Example 2

        - name: Example 3
          debug:
            msg: Example 3
```

**Result:** All three debug messages execute sequentially

---

## 🎯 2. Blocks with Common Directives

### 📁 2: Block with `when` and `with_items`

```yaml
---
-
  hosts: linux

  tasks:
    - name: A block of modules being executed
      block:
        - name: Example 1 CentOS only
          debug:
            msg: Example 1 CentOS only
          when: ansible_distribution == 'CentOS'

        - name: Example 2 Ubuntu only
          debug:
            msg: Example 2 Ubuntu only
          when: ansible_distribution == 'Ubuntu'

        - name: Example 3 with items
          debug:
            msg: "Example 3 with items - {{ item }}"
          with_items: ['x', 'y', 'z']
```

**Key Points:**
- Each task can have its own `when` condition
- Loops (`with_items`) work inside blocks
- Blocks don't automatically apply directives to child tasks

> 📝 **Note:** To apply a directive to ALL tasks in a block, put it at the block level

```yaml
- name: Block with common condition
  block:
    - name: Task 1
      debug:
        msg: "Only runs on CentOS"
    - name: Task 2
      debug:
        msg: "Also only on CentOS"
  when: ansible_distribution == 'CentOS'  # Applies to entire block
```

---

## 🎯 3. Error Handling: try/rescue/always

### 📁 3: Block with Rescue and Always

```yaml
---
-
  hosts: linux

  tasks:
    - name: Install patch and python3-dnspython
      block:
        - name: Install patch
          package:
            name: patch

        - name: Install python3-dnspython
          package:
            name: python3-dnspython

      rescue:
        - name: Rollback patch
          package:
            name: patch
            state: absent

        - name: Rollback python3-dnspython
          package:
            name: python3-dnspython
            state: absent

      always:
        - debug:
            msg: This always runs, regardless
```

**Flow Diagram:**
```
┌─────────────────────────────────────────────────────────────┐
│                         BLOCK                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Task 1: Install patch      → SUCCESS                │    │
│  │  Task 2: Install python3-dnspython                   │    │
│  │           ├─ Ubuntu → SUCCESS                        │    │
│  │           └─ CentOS → FAILURE (package not available)│    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                      RESCUE                          │    │
│  │  (Only runs if ANY task in block FAILS)              │    │
│  │                                                       │    │
│  │  Task: Rollback patch (on CentOS hosts)              │    │
│  │  Task: Rollback python3-dnspython                    │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                      ALWAYS                          │    │
│  │  (Runs regardless of success or failure)             │    │
│  │                                                       │    │
│  │  debug: msg="This always runs, regardless"          │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Execution Results:**

| Host | block | rescue | always |
|------|-------|--------|--------|
| Ubuntu | ✅ Both install succeed | ⏭️ Skipped (no failure) | ✅ Runs |
| CentOS | ❌ Second task fails | ✅ Runs rollback | ✅ Runs |

---

## 📊 Block Structure Summary

```yaml
- name: Optional block name
  block:
    - name: Task 1
      module: ...
    - name: Task 2
      module: ...
  
  rescue:
    - name: Error recovery task 1
      module: ...
    - name: Error recovery task 2
      module: ...
  
  always:
    - name: Cleanup task
      module: ...
  
  # Optional directives at block level
  when: some_condition
  ignore_errors: yes
```

| Section | When it runs |
|---------|--------------|
| `block` | Always runs first |
| `rescue` | Runs ONLY if ANY task in `block` fails |
| `always` | Runs ALWAYS (success or failure) |

---

## 🎯 Practical Use Cases

### Use Case 1: Database Migration with Rollback

```yaml
- name: Run database migration
  block:
    - name: Backup database
      command: pg_dump mydb > /backup/mydb.sql
    
    - name: Run migration script
      command: /opt/migrate.py
    
    - name: Verify migration
      command: /opt/verify.py

  rescue:
    - name: Restore from backup
      command: psql mydb < /backup/mydb.sql
    
    - name: Notify failure
      uri:
        url: https://alerts.example.com/failed
        method: POST

  always:
    - name: Clean up temp files
      file:
        path: /tmp/migration.lock
        state: absent
```

### Use Case 2: Service Deployment with Health Check

```yaml
- name: Deploy web application
  block:
    - name: Stop old service
      service:
        name: myapp
        state: stopped
    
    - name: Deploy new code
      copy:
        src: /build/myapp.war
        dest: /opt/myapp/
    
    - name: Start new service
      service:
        name: myapp
        state: started
    
    - name: Health check
      uri:
        url: http://localhost:8080/health
        status_code: 200

  rescue:
    - name: Rollback to previous version
      copy:
        src: /backup/myapp.war
        dest: /opt/myapp/
    
    - name: Start old version
      service:
        name: myapp
        state: started

  always:
    - name: Send deployment notification
      mail:
        to: team@example.com
        subject: "Deployment complete"
```

### Use Case 3: Multi-step Configuration

```yaml
- name: Configure network interface
  block:
    - name: Copy network config
      template:
        src: interfaces.j2
        dest: /etc/network/interfaces
    
    - name: Restart networking
      service:
        name: networking
        state: restarted
    
    - name: Verify connectivity
      command: ping -c 3 8.8.8.8

  rescue:
    - name: Revert to backup config
      copy:
        src: /backup/interfaces
        dest: /etc/network/interfaces
    
    - name: Restart networking (rollback)
      service:
        name: networking
        state: restarted

  always:
    - name: Log configuration change
      copy:
        content: "{{ ansible_date_time.iso8601 }} - Network configured"
        dest: /var/log/network_changes.log
```

---

## 🛠️ Block-Level vs Task-Level Directives

### Block-Level (Applies to all tasks in block)

```yaml
- name: Block with common condition
  block:
    - name: Task 1
      debug:
        msg: "Message 1"
    - name: Task 2
      debug:
        msg: "Message 2"
  when: ansible_distribution == 'CentOS'
  ignore_errors: yes
```

### Task-Level (Individual task only)

```yaml
- name: Block with individual conditions
  block:
    - name: Task 1
      debug:
        msg: "Message 1"
      when: ansible_distribution == 'CentOS'
    
    - name: Task 2
      debug:
        msg: "Message 2"
      when: ansible_distribution == 'Ubuntu'
```

---

## ⚠️ Important Notes

| Note | Explanation |
|------|-------------|
| **Named blocks** | Available in Ansible 2.3+ |
| **rescue runs on ANY failure** | If any task in block fails, rescue executes |
| **always always runs** | Even if rescue fails |
| **Nested blocks** | Blocks can contain blocks inside |
| **Directives at block level** | Apply to all tasks in the block |

---

## 📊 Quick Reference

### Basic Block
```yaml
- name: My Block
  block:
    - name: Task 1
      module: ...
    - name: Task 2
      module: ...
```

### Block with Error Handling
```yaml
- name: My Block
  block:
    - task: risky operation
  rescue:
    - task: recovery operation
  always:
    - task: cleanup operation
```

### Block with Directives
```yaml
- name: My Block
  block:
    - task 1
    - task 2
  when: condition
  ignore_errors: yes
```

### Nested Blocks
```yaml
- name: Outer Block
  block:
    - name: Inner Block
      block:
        - task 1
        - task 2
      rescue:
        - recovery
  rescue:
    - outer recovery
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **block** | Groups tasks together |
| **rescue** | Runs only when block fails |
| **always** | Runs regardless of success/failure |
| **Block-level directives** | Apply to all tasks in block |
| **Named blocks** | Available in Ansible 2.3+ |

> 💡 **Pro Tip:** Use blocks with `rescue` for critical operations like database migrations, deployments, or any task that needs rollback capability!

---
