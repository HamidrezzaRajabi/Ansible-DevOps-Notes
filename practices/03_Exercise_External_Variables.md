# Exercise 3: External Variables

### Create a playbook that:

- #### Uses an external variables file

- #### Contains both dictionary and list variables

- #### Prints specific values


<br>
<br>
<br>

### Solution:


`external_config.yaml:`

```yaml
---
app_name: "mywebapp"
environment: "production"
versions:
  - "1.0.0"
  - "1.1.0"
  - "2.0.0"
database:
  host: "db.example.com"
  port: 3306
  name: "appdb"
...
```


`playbook.yaml:`

```yaml
---
-
  hosts: localhost
  gather_facts: false
  vars_files:
    - external_config.yaml
  
  tasks:
    - name: Show app info
      debug:
        msg: "App: {{ app_name }} in {{ environment }}"
    
    - name: Show latest version
      debug:
        msg: "Latest version: {{ versions[-1] }}"
    
    - name: Show database details
      debug:
        msg: "DB: {{ database.host }}:{{ database.port }}/{{ database.name }}"
...
```