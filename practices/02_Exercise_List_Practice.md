# Exercise 2: List Practice

### Create a playbook that:

- #### Defines a list of database servers

- #### Prints the first and last server

---

<br>
<br>
<br>

### Solution:

```yaml
---
-
  hosts: localhost
  gather_facts: false
  vars:
    db_servers:
      - db01
      - db02
      - db03
  
  tasks:
    - name: Show all servers
      debug:
        var: db_servers
    
    - name: Show first server
      debug:
        msg: "First server: {{ db_servers.0 }}"
    
    - name: Show last server
      debug:
        msg: "Last server: {{ db_servers[-1] }}"
...
```