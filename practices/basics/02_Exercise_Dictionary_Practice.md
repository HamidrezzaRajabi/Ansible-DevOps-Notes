# Exercise 1: Dictionary Practice

### Create a playbook that:

- #### Defines a dictionary with server settings (host, port, protocol)

- #### Prints each value individually using both dot and bracket notation

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
    server:
      host: "192.168.1.100"
      port: 443
      protocol: "https"
  
  tasks:
    - name: Show full dictionary
      debug:
        var: server
    
    - name: Show host (dot notation)
      debug:
        msg: "Host: {{ server.host }}"
    
    - name: Show port (bracket notation)
      debug:
        msg: "Port: {{ server['port'] }}"
    
    - name: Show protocol
      debug:
        msg: "Protocol: {{ server.protocol }}"
...
```
