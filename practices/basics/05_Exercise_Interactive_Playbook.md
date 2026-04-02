# Exercise 4: Interactive Playbook

### Create a playbook that:

- #### Prompts for username and password

- #### Password should be hidden

- #### Prints confirmation without exposing password


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
  vars_prompt:
    - name: username
      prompt: "Enter username"
      private: false
    
    - name: password
      prompt: "Enter password"
      private: true
      confirm: true  # Ask twice to confirm
  
  tasks:
    - name: Confirm user creation
      debug:
        msg: "User {{ username }} will be created (password hidden)"
    
    - name: Hash password (example)
      debug:
        msg: "Password hash would be created here"
      when: password is defined
...
```