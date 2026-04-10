# 🐳 Docker with Ansible - Key Concepts with Examples



## 📌 Core Idea

Ansible can manage Docker containers just like it manages cloud resources. This includes pulling images, creating containers, building custom images, and even **using containers as Ansible targets** (a lesser-known but powerful feature).

---

## 🔑 Key Concepts with Examples

### 1. Two Main Docker Modules

| Module | Purpose |
|--------|---------|
| `docker_image` | Pull images from registry OR build custom images from Dockerfiles |
| `docker_container` | Create, start, stop, and remove containers |

**Example - Pull an image:**
```yaml
- name: Pull nginx image
  docker_image:
    name: nginx
    source: pull
```

**Example - Create a container:**
```yaml
- name: Create nginx container
  docker_container:
    name: mywebserver
    image: nginx
    ports:
      - "80:80"
```

---

### 2. Remote Docker Connection

- Docker can run in a separate container
- Use `docker_host` parameter when Docker is not local

**Example - Remote Docker:**
```yaml
- name: Pull image on remote Docker
  docker_image:
    docker_host: tcp://docker:2375
    name: nginx
    source: pull
```

> 📝 **Note:** Omit `docker_host` if Docker runs locally on the control node

---

### 3. Building Custom Images

**Process:**
1. Create a Dockerfile
2. Build image using `docker_image` with `source: build`

**Example - Build custom image:**
```yaml
# Step 1: Create Dockerfile
- name: Create Dockerfile
  copy:
    dest: /build/Dockerfile
    content: |
      FROM nginx
      COPY index.html /usr/share/nginx/html/

# Step 2: Build image
- name: Build custom image
  docker_image:
    name: mycustomnginx:latest
    source: build
    build:
      path: /build
```

---

### 4. Containers as Ansible Targets (Powerful Feature!)

**What it does:** Ansible connects directly to **running containers** and manages them like regular hosts.

**Requirements:**
- Container has Python installed
- Container is **running** (use `sleep infinity` to keep alive)
- Inventory specifies `ansible_connection: docker`

**Example - Create keep-alive containers:**
```yaml
- name: Create Python containers that stay alive
  docker_container:
    name: "python{{ item }}"
    image: python:3.8
    command: sleep infinity
  with_sequence: 1-3
```

**Example Inventory (`hosts` file):**
```ini
[containers]
python1 ansible_connection=docker
python2 ansible_connection=docker
python3 ansible_connection=docker
```

**Example - Run playbook against containers:**
```yaml
- name: Manage containers as hosts
  hosts: containers
  tasks:
    - name: Check container uptime
      command: uptime
    
    - name: Install package inside container
      apt:
        name: curl
        state: present
```

> 🎯 **Why this is cool:** You can run any Ansible module **inside containers** just like on VMs!

---

### 5. Pull Multiple Images with Loop

**Example:**
```yaml
- name: Pull multiple images
  docker_image:
    name: "{{ item }}"
    source: pull
  with_items:
    - nginx
    - redis
    - postgres
    - ubuntu
```

---

### 6. Cleanup Pattern

Always clean up in this order: **Containers → Images → Files**

**Example - Complete cleanup:**
```yaml
# Step 1: Remove containers
- name: Remove containers
  docker_container:
    name: "{{ item }}"
    state: absent
  with_items:
    - mywebserver
    - python1
    - python2

# Step 2: Remove images
- name: Remove images
  docker_image:
    name: "{{ item }}"
    state: absent
  with_items:
    - mycustomnginx
    - nginx
    - python:3.8

# Step 3: Remove temporary files
- name: Clean up build files
  file:
    path: /build
    state: absent
```

---

## 📊 Quick Reference

| Task | Module | Key Parameters |
|------|--------|----------------|
| Pull image | `docker_image` | `name`, `source: pull` |
| Build image | `docker_image` | `name`, `source: build`, `build.path` |
| Create container | `docker_container` | `name`, `image`, `ports` |
| Keep container alive | `docker_container` | `command: sleep infinity` |
| Remove container | `docker_container` | `name`, `state: absent` |
| Remove image | `docker_image` | `name`, `state: absent` |
| Connect to container | Inventory | `ansible_connection: docker` |

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **docker_image** | Pull images OR build custom ones from Dockerfiles |
| **docker_container** | Create, start, stop, and remove containers |
| **docker_host** | Required ONLY for remote Docker (omit if local) |
| **sleep infinity** | Keeps container alive for Ansible management |
| **ansible_connection: docker** | Treat containers as Ansible targets in inventory |
| **Cleanup order** | Containers → Images → Files |

> 💡 **Pro Tip:** The ability to use containers as Ansible targets is perfect for testing roles, development environments, and lightweight automation without VMs!

---
