# ☁️ AWS with Ansible



## 📌 Prerequisites

| Requirement | Purpose |
|-------------|---------|
| **AWS Account** | Free tier available (monitor costs!) |
| **IAM Access Key** | API access to AWS |
| **Key Pair** | SSH access to EC2 instances |
| **boto3 library** | Python AWS SDK |
| **Default VPC** | Network for instances |

### ⚠️ Cost Warning
- AWS free tier available but **not unlimited**
- Set up **billing alerts** in AWS
- Always terminate instances after testing
- Review EC2 dashboard to ensure cleanup

---

## 🔧 Initial Setup

### 1. Create AWS Key Pair
```
EC2 Dashboard → Key Pairs → Create Key Pair
Name: ansible
Format: .pem
```
> 💾 Save the `.pem` file securely - you'll need it for SSH!

### 2. Create IAM Access Key
```
Account Settings → My Security Credentials → Create Access Key
```
> 🔐 Save both Access Key ID and Secret Access Key immediately!

### 3. Set Environment Variables
```bash
export AWS_ACCESS_KEY_ID="AKIAxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### 4. Install boto3
```bash
pip install boto3
# or
apt install python3-boto3
```

---

## 🎯 Core AWS Modules

| Module | Purpose |
|--------|---------|
| `ec2_group` | Create/manage security groups |
| `ec2_instance` | Provision EC2 instances |
| `ec2_instance_info` | Gather instance information |
| `ec2_key` | Manage SSH key pairs |

---

## 📂 AWS Playbook Structure (Revision Flow)

### Step 1: Create Security Group
- Open ports: `22` (SSH) and `80` (HTTP)
- Runs on `localhost` with `connection: local`

### Step 2: Gather Existing Instances
- Query AWS for instances tagged with `Name: Ansible`
- Count running instances

### Step 3: Calculate Instances to Launch
- Compare desired count vs existing
- Launch only the difference (idempotent!)

### Step 4: Provision Instances
- Instance type: `t2.micro` (free tier)
- AMI: Red Hat Enterprise Linux 8
- Region: `us-east-1`
- Tag: `Name: Ansible`

### Step 5: Refresh Inventory & Wait for SSH
- `meta: refresh_inventory` to update dynamic inventory
- `wait_for_connection` to ensure SSH is ready

### Step 6: Deploy Application
- Apply `webapp` role to `tag_Name_Ansible` group

### Step 7: Cleanup (Optional)
- Terminate instances
- Remove security group

---

## 🏷️ AWS Dynamic Inventory

### Download AWS Inventory Script
```bash
mkdir inventory
cd inventory
wget https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/ec2.py
wget https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/ec2.ini
chmod +x ec2.py
```

### Configure Inventory Script
**`ec2.py`** - change shebang to Python 3:
```python
#!/usr/bin/env python3  # instead of python
```

**`ec2.ini`** - disable caching for development:
```ini
cache_max_age = 0
```

### Set Inventory Path
```bash
export EC2_INI_PATH=./inventory/ec2.ini
```

### Test Dynamic Inventory
```bash
./inventory/ec2.py --list | jq '._meta.hostvars'
```

### Group by Tag
Instances with tag `Name: Ansible` automatically appear in group:
```
tag_Name_Ansible
```

---

## 🔐 Group Variables for AWS Hosts

**`group_vars/tag_Name_Ansible`:**
```yaml
---
ansible_ssh_private_key_file: ~/.ssh/ansible.pem
ansible_user: ec2-user
ansible_become: true
```

---

## 📊 Important Configuration (ansible.cfg)

```ini
[defaults]
inventory = ./inventory
enable_plugins = aws_ec2
host_key_checking = False
forks = 20
ansible_managed = Managed by Ansible - file:{file} - host:{host} - uid:{uid}
```

| Setting | Purpose |
|---------|---------|
| `inventory = ./inventory` | Points to dynamic inventory script |
| `enable_plugins = aws_ec2` | Enables AWS EC2 inventory plugin |
| `forks = 20` | Match number of instances for parallelism |

---

## 🔄 Idempotent Instance Management

### Key Pattern: Calculate Desired vs Existing
```yaml
- name: Gather existing instances
  ec2_instance_info:
    filters:
      "tag:Name": Ansible
      instance-state-name: running
  register: ec2_info

- name: Calculate instances to launch
  set_fact:
    instances_to_launch: "{{ [0, desired_instances - (ec2_info.instances | length)] | max }}"

- name: Provision instances
  ec2_instance:
    count: "{{ instances_to_launch }}"
    # ... other parameters
```

> 💡 This ensures you never exceed desired count and don't duplicate instances!

---

## 🧹 Cleanup Tasks

### Terminate Instances
```yaml
- name: Terminate EC2 instances
  ec2_instance:
    state: absent
    instance_ids: "{{ instance_id }}"
    region: "{{ placement.region }}"
    wait: true
  delegate_to: localhost
```

### Remove Security Group
```yaml
- name: Remove security group
  ec2_group:
    name: ansible
    region: us-east-1
    state: absent
  register: result
  until: result is success
  retries: 20
  delay: 10
```

---

## 📊 AWS Module Parameters Reference

### ec2_group (Security Group)
| Parameter | Example | Purpose |
|-----------|---------|---------|
| `name` | `ansible` | Security group name |
| `description` | `Ansible Security Group` | Group description |
| `rules` | `proto: tcp, from_port: 80` | Firewall rules |
| `state` | `present` / `absent` | Create or delete |

### ec2_instance
| Parameter | Example | Purpose |
|-----------|---------|---------|
| `key_name` | `ansible` | SSH key pair name |
| `instance_type` | `t2.micro` | Instance size |
| `image_id` | `ami-0fe630eb857a6ec83` | AMI (RHEL 8) |
| `count` | `20` | Number of instances |
| `security_group` | `ansible` | Security group name |
| `wait` | `true` | Wait for completion |
| `state` | `present` / `absent` | Create or terminate |

### ec2_instance_info
| Parameter | Example | Purpose |
|-----------|---------|---------|
| `filters` | `"tag:Name": Ansible` | Filter instances |
| `region` | `us-east-1` | AWS region |

---

## ⚡ Common Commands

```bash
# Test AWS connection
ansible localhost -m ec2_metadata_info

# List EC2 instances via dynamic inventory
ansible tag_Name_Ansible --list-hosts

# Ping all AWS instances
ansible tag_Name_Ansible -m ping -o

# Run ad-hoc command
ansible tag_Name_Ansible -a "uptime"
```

---

## 🎯 Important Notes

| Note | Explanation |
|------|-------------|
| **Free tier AMI** | RHEL 8 is free tier eligible |
| **AMI IDs change** | Check AWS Console for current AMI ID |
| **Region matters** | AMI IDs are region-specific |
| **Wait for SSH** | Instances need time to boot |
| **Clean up resources** | Terminate instances and delete security groups |

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **boto3 required** | AWS modules need Python SDK |
| **ec2_instance** | Main module for provisioning |
| **ec2_group** | Security group management |
| **Dynamic inventory** | `ec2.py` script provides groups by tag |
| **tag_Name_Ansible** | Auto-generated group for tagged instances |
| **Idempotent pattern** | Calculate desired vs existing instances |
| **Cleanup** | Terminate instances + remove security group |

> 💡 **Pro Tip:** Always use `wait_for_connection` before running tasks on new EC2 instances!

---
