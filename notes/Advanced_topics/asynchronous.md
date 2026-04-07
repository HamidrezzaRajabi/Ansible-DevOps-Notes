# ⚡ Asynchronous, Serial and Parallel Execution


## 📌 What You'll Learn

| Concept | Purpose |
|---------|---------|
| **Linear Strategy** | Default - wait for all hosts before next task |
| **Forks** | Number of parallel SSH connections |
| **Serial** | Batch execution (rolling updates) |
| **Async/Poll** | Fire and forget with status checking |
| **Free Strategy** | Each host runs independently |

---

## 🎯 1. Linear Strategy (Default Behavior)

### 📁 1: All Hosts, All Tasks

```yaml
---
-
  hosts: linux
  tasks:
    - name: Task 1
      command: /bin/sleep 5
    - name: Task 2
      command: /bin/sleep 5
    - name: Task 3
      command: /bin/sleep 5
    - name: Task 4
      command: /bin/sleep 5
    - name: Task 5
      command: /bin/sleep 5
    - name: Task 6
      command: /bin/sleep 5
```

**How it works:**
```
Task 1: [centos1][centos2][centos3][ubuntu1][ubuntu2][ubuntu3] → 5 sec each
Task 2: [centos1][centos2][centos3][ubuntu1][ubuntu2][ubuntu3] → 5 sec each
...
Task 6: [centos1][centos2][centos3][ubuntu1][ubuntu2][ubuntu3] → 5 sec each
```

**Result:** ~70+ seconds (6 tasks × ~12 seconds due to forks)

> 💡 **Key Insight:** Linear strategy waits for ALL hosts to finish a task before moving to the next task

---

### 📁 2: One Host Per Task (Pitfall)

```yaml
tasks:
  - name: Task 1
    command: /bin/sleep 5
    when: ansible_hostname == 'centos1'
  - name: Task 2
    command: /bin/sleep 5
    when: ansible_hostname == 'centos2'
  # ... one task per host
```

**Result:** ~41 seconds (slightly better but still inefficient)

---

## 🎯 2. Async with Polling

### 📁 3: Async with Poll > 0

```yaml
tasks:
  - name: Task 1
    command: /bin/sleep 5
    when: ansible_hostname == 'centos1'
    async: 10      # Timeout (wait max 10 seconds)
    poll: 1        # Check status every 1 second
```

| Parameter | Meaning |
|-----------|---------|
| `async` | Maximum time to wait for task (seconds) |
| `poll` | How often to check status (seconds) |
| `poll: 0` | Fire and forget (no status checking) |

**Behavior:** Still waits for each task sequentially

---

### 📁 4: Async with Poll = 0 (Fire and Forget)

```yaml
tasks:
  - name: Task 1
    command: /bin/sleep 5
    when: ansible_hostname == 'centos1'
    async: 10
    poll: 0        # Don't wait, just fire

  - name: Task 4
    command: /bin/sleep 30
    when: ansible_hostname == 'ubuntu1'
    async: 10
    poll: 0
```

**Result:** ~12 seconds total!

**⚠️ Problem:** Playbook finishes before long-running tasks complete!

---

## 🎯 3. Capturing Async Job IDs

### 📁 5: Register Async Output

```yaml
tasks:
  - name: Task 1
    command: /bin/sleep 5
    async: 10
    poll: 0
    register: result1

  - name: Show registered context
    debug:
      var: result1
```

**Registered output includes:**
```json
{
    "result1": {
        "ansible_job_id": "1234567890.12345",
        "changed": true,
        "finished": 0,
        "started": 1
    }
}
```

| Field | Meaning |
|-------|---------|
| `ansible_job_id` | Unique ID for the background job |
| `finished` | 0 = still running, 1 = complete |
| `started` | 1 = started successfully |

---

### 📁 6: Collect Job IDs

```yaml
vars:
  jobids: []

tasks:
  # ... async tasks with register ...

  - name: Capture Job IDs
    set_fact:
      jobids: >
              {% if item.ansible_job_id is defined -%}
                {{ jobids + [item.ansible_job_id] }}
              {% else -%}
                {{ jobids }}
              {% endif %}
    with_items: "{{ [ result1, result2, result3, result4, result5, result6 ] }}"

  - name: Show Job IDs
    debug:
      var: jobids
```

---

### 📁 7: Wait for All Jobs to Complete

```yaml
- name: 'Wait for Job IDs'
  async_status:
    jid: "{{ item }}"
  with_items: "{{ jobids }}"
  register: jobs_result
  until: jobs_result.finished
  retries: 30
```

| Parameter | Meaning |
|-----------|---------|
| `async_status` | Module to check job status |
| `jid` | Job ID to check |
| `until` | Condition to stop retrying |
| `retries` | Maximum attempts |

---

### 📁 8: Full Async Parallel Execution

```yaml
---
-
  hosts: linux
  vars:
    jobids: []

  tasks:
    - name: Task 1
      command: /bin/sleep 5
      async: 10
      poll: 0
      register: result1

    - name: Task 2
      command: /bin/sleep 5
      async: 10
      poll: 0
      register: result2

    - name: Task 3
      command: /bin/sleep 5
      async: 10
      poll: 0
      register: result3

    - name: Task 4
      command: /bin/sleep 30
      async: 60
      poll: 0
      register: result4

    - name: Task 5
      command: /bin/sleep 5
      async: 10
      poll: 0
      register: result5

    - name: Task 6
      command: /bin/sleep 5
      async: 10
      poll: 0
      register: result6

    - name: Capture Job IDs
      set_fact:
        jobids: >
                {% if item.ansible_job_id is defined -%}
                  {{ jobids + [item.ansible_job_id] }}
                {% else -%}
                  {{ jobids }}
                {% endif %}
      with_items: "{{ [ result1, result2, result3, result4, result5, result6 ] }}"

    - name: Wait for Job IDs
      async_status:
        jid: "{{ item }}"
      with_items: "{{ jobids }}"
      register: jobs_result
      until: jobs_result.finished
      retries: 30
```

**Result:** ~48 seconds (all tasks run in parallel!)

> 🎯 **Key Insight:** Async + job tracking allows true parallel execution

---

## 🎯 4. Forks - Parallel Connections

### 📁 9: Default Forks (5)

```yaml
# No forks setting in ansible.cfg (default = 5)
```

With 6 hosts and 5 forks:
- First 5 hosts run Task 1
- Last host waits for a fork to free up
- Then runs Task 1

**Result:** ~70 seconds

### 📁 10: Increase Forks to 6

**`ansible.cfg`:**
```ini
[defaults]
inventory = hosts
host_key_checking = False
forks = 6
```

**Result:** ~38 seconds (all 6 hosts run simultaneously)

> 💡 **Formula:** `forks` should be ≥ number of hosts for maximum parallelism

---

## 🎯 5. Serial - Batch Execution (Rolling Updates)

### 📁 11: Fixed Batch Size

```yaml
---
-
  hosts: linux
  gather_facts: false
  serial: 2    # Run on 2 hosts at a time
  
  tasks:
    - name: Task 1
      command: /bin/sleep 1
    - name: Task 2
      command: /bin/sleep 1
```

**Execution order:**
```
Batch 1: centos1, centos2
Batch 2: centos3, ubuntu1
Batch 3: ubuntu2, ubuntu3
```

> 💡 **Use case:** Rolling updates where you can't take all servers offline at once

---

### 📁 12: Incremental Batch Sizes

```yaml
---
-
  hosts: linux
  gather_facts: false
  serial: 
    - 1    # First batch: 1 host
    - 2    # Second batch: 2 hosts
    - 3    # Third batch: 3 hosts
```

**Execution:**
```
Batch 1: 1 host
Batch 2: 2 hosts
Batch 3: 3 hosts
```

> 💡 **Use case:** Canary deployments - test on 1, then more, then all

---

### 📁 13: Percentage-Based Batching

```yaml
---
-
  hosts: linux
  gather_facts: false
  serial: 
    - 16%   # First batch: 16% of hosts (~1 host)
    - 34%   # Second batch: 34% of hosts (~2 hosts)
    - 50%   # Third batch: 50% of hosts (~3 hosts)
```

> 💡 **Use case:** Dynamic environments where host count changes

---

## 🎯 6. Free Strategy - True Independence

### 📁 14: Linear Strategy (Baseline)

```yaml
---
-
  hosts: linux
  gather_facts: false
  # strategy: linear (default)
  
  tasks:
    - name: Task 1
      command: "/bin/sleep {{ 10 | random }}"
    - name: Task 2
      command: "/bin/sleep {{ 10 | random }}"
    # ... more tasks
```

**Result:** ~55 seconds (waits for all hosts at each task)

### 📁 15: Free Strategy

```yaml
---
-
  hosts: linux
  gather_facts: false
  strategy: free    # Each host runs independently
  
  tasks:
    - name: Task 1
      command: "/bin/sleep {{ 10 | random }}"
    - name: Task 2
      command: "/bin/sleep {{ 10 | random }}"
    # ... more tasks
```

**Result:** ~42 seconds (hosts don't wait for each other)

**How Free Strategy works:**
```
Host A: Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6 (runs all tasks)
Host B: Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6 (runs all tasks)
```

No waiting between hosts!

---

## 📊 Performance Comparison Summary

| Revision | Method | Time | Improvement |
|----------|--------|------|-------------|
| 01 | Default (linear, forks=5) | ~70s | Baseline |
| 02 | One host per task | ~41s | 41% faster |
| 04 | Async with poll=0 | ~12s | 83% faster (but incomplete!) |
| 08 | Full async + tracking | ~48s | 31% faster |
| 10 | Forks=6 | ~38s | 46% faster |
| 15 | Free strategy | ~42s | 40% faster |

---

## 🎯 When to Use Each Strategy

| Strategy | Best For | Example |
|----------|----------|---------|
| **Linear (default)** | Simple playbooks, dependencies between hosts | Configuring all web servers identically |
| **Serial** | Rolling updates, canary deployments | Updating app servers one batch at a time |
| **Free** | Independent tasks, no cross-host dependencies | Each host running its own cleanup |
| **Async** | Long-running tasks, fire-and-forget | Database backups, large file downloads |
| **Forks tuning** | Many hosts, simple tasks | Running same command on 100+ servers |

---

## ⚡ Quick Reference

### Async Parameters
```yaml
- name: Long running task
  command: /usr/local/bin/long-task
  async: 3600      # Max wait 1 hour
  poll: 60         # Check every 60 seconds
  register: task_result
```

### Fire and Forget
```yaml
- name: Fire and forget
  command: /usr/local/bin/background-job
  async: 3600
  poll: 0          # Don't wait at all
  register: job
```

### Check Async Status
```yaml
- name: Check job status
  async_status:
    jid: "{{ job.ansible_job_id }}"
  register: job_status
  until: job_status.finished
  retries: 30
```

### Serial Batching
```yaml
serial: 2                    # Fixed batch size
serial: [1, 2, 4]           # Incremental batches
serial: [25%, 50%, 100%]    # Percentage batches
```

### Strategy Setting
```yaml
strategy: linear    # Default - wait for all hosts
strategy: free      # Each host runs independently
```

### Forks Setting (ansible.cfg)
```ini
[defaults]
forks = 50          # Parallel SSH connections
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **Linear Strategy** | Default - waits for all hosts per task |
| **Forks** | Controls parallel connections (default 5) |
| **Serial** | Batch execution for rolling updates |
| **Async + poll=0** | Fire and forget - playbook doesn't wait |
| **async_status** | Check status of background jobs |
| **Free Strategy** | Hosts run tasks independently |
| **Percentages** | Dynamic batching based on host count |

> 💡 **Pro Tip:** For production rolling updates, use `serial` with small batches. For independent tasks, try `strategy: free`

---