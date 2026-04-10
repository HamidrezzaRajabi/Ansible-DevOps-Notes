# 📚 Best Practices with Ansible


## 📌 Core Philosophy

The official Ansible documentation provides evolving best practices. Rather than memorizing static rules, understand the **principles** demonstrated throughout this course.

---

## 🔑 Key Best Practices Covered in This Course

### 1. Code Organization & Readability

| Practice | How We Applied It |
|----------|-------------------|
| **Use whitespace** | Playbooks neatly formatted, tasks broken up |
| **Name all tasks** | Every task has a descriptive `name:` |
| **Add comments** | Comment blocks explaining playbook sections |
| **Consistent indentation** | 2 spaces (YAML standard) |

**Example:**
```yaml
---
# This playbook configures MOTD across Linux hosts
-
  # Hosts: where our play will run
  hosts: linux
  
  tasks:
    # First task: Install necessary packages
    - name: Install EPEL for CentOS
      yum:
        name: epel-release
        state: latest
      when: ansible_distribution == 'CentOS'
```

---

### 2. Use Dynamic Inventories for Cloud

| Practice | Why It Matters |
|----------|----------------|
| **AWS Dynamic Inventory** | Automatically discovers EC2 instances |
| **Reference AWS example** | Considered the gold standard for dynamic inventory design |
| **Stand on shoulders of giants** | Learn from production-tested implementations |

> 💡 If you create custom dynamic inventories, study the AWS `ec2.py` script as a reference example.

---

### 3. Update in Batches (Serial Execution)

| Practice | Why It Matters |
|----------|----------------|
| **Use `serial:` keyword** | Rolling updates, not all servers at once |
| **Production safety** | Minimize blast radius of failures |
| **Gradual rollout** | Canary deployments with increasing batch sizes |

**Example:**
```yaml
- name: Rolling update
  hosts: webservers
  serial: 2          # Update 2 servers at a time
  tasks:
    - name: Restart service
      service:
        name: nginx
        state: restarted
```

---

### 4. Handle OS and Distribution Differences

| Practice | How We Applied It |
|----------|-------------------|
| **Use `group_by` module** | Dynamically create OS-specific groups |
| **Leverage facts** | `ansible_distribution`, `ansible_os_family` |
| **Conditional tasks** | `when: ansible_distribution == 'CentOS'` |

**Example:**
```yaml
# Create dynamic groups
- name: Group by OS
  group_by:
    key: "os_{{ ansible_distribution | lower }}"

# Then target specific OS
- hosts: os_ubuntu
  tasks:
    - name: Ubuntu specific task
      apt:
        name: some-package
```

---

### 5. Comment Your Variables

| Practice | Why It Matters |
|----------|----------------|
| **Document variable source** | Where does this value come from? |
| **Explain purpose** | Why does this variable exist? |
| **Team collaboration** | Helps new team members understand |

**Example:**
```yaml
# From: group_vars/production
# Purpose: Database connection timeout in seconds
# Source: Infrastructure team request
db_connection_timeout: 30

# From: vault (encrypted)
# Purpose: Service account password
# Rotates: Every 90 days
service_account_password: !vault ...
```

---

## 📊 Best Practices Summary Table

| Category | Best Practice | Course Example |
|----------|---------------|----------------|
| **Readability** | Name all tasks | Every task has `name:` |
| **Readability** | Use comments | Section headers in playbooks |
| **Cloud** | Dynamic inventories | AWS `ec2.py` inventory |
| **Deployment** | Serial batching | `serial: 2` for rolling updates |
| **Cross-platform** | Use facts | `when: ansible_distribution == 'CentOS'` |
| **Cross-platform** | `group_by` module | OS-based dynamic groups |
| **Variables** | Comment sources | Document variable origins |
| **Variables** | Use `default()` | Safe variable access |

---

## 🔗 Official Best Practices Reference

The official Ansible documentation page contains:
- Whitespace and formatting guidelines
- Naming conventions
- Directory structure recommendations
- Content organization tips
- Variable management strategies

> 💡 **Recommendation:** Bookmark and review the official best practices page periodically as Ansible evolves.

---

## ✅ Course Takeaways

| What We Learned | Where to Apply |
|----------------|----------------|
| **SSH connectivity** | Foundation of Ansible communication |
| **Inventories** | Organize hosts with INI/YAML/JSON |
| **Modules** | Idempotent operations with `package`, `copy`, `file` |
| **Playbooks** | Multi-task automation with YAML |
| **Variables** | Dynamic values with proper precedence |
| **Jinja2** | Templating for dynamic content |
| **Loops** | `with_items`, `with_dict`, `with_nested` |
| **Roles** | Reusable, shareable components |
| **Vault** | Secure secret management |
| **AWS + Docker** | Cloud and container automation |
| **Troubleshooting** | `-vvv`, debug module, check mode |

---

## 📝 Final Notes

> "I spent over six months creating this course. I hope it's given you the foundation you were looking for in Ansible." — James Spurin

| Next Steps | Actions |
|------------|---------|
| **Practice** | Build your own playbooks and roles |
| **Share** | Publish roles to Ansible Galaxy |
| **Connect** | Reach out on LinkedIn |
| **Stay updated** | Follow Ansible release notes |

---

> 💡 **Final Pro Tip:** Best practices evolve. Always check the official Ansible documentation for the most current recommendations!

---
