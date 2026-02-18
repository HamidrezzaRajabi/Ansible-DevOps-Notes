# 🔐 SSH Connectivity for Ansible

**Date Learned:** [Date]
**Related Videos:** 006-Configuring SSH connectivity between hosts

## 📌 Key Concepts

### Why SSH Matters for Ansible
- Ansible uses **agentless architecture** (no agents needed on target hosts)
- Requires **trusted relationship** for automated passwordless connectivity
- Uses SSH as the transport mechanism

### SSH Connection Process
1. **Protocol Version Exchange** - Client & server agree on supported SSH versions
2. **Key Exchange** - Cryptographic primitives negotiation
3. **Session Key Creation** - Uses **Diffie-Hellman algorithm** for symmetric key
4. **Host Key Verification** - First-time connection prompts for fingerprint verification
5. **Encrypted Channel Established** - Secure communication channel created
6. **Authentication** - User authentication (password or key-based)

## 💻 Essential Commands

### Basic SSH Commands
```bash
# Connect to a remote host
ssh username@hostname

# Example from the video
ssh ubuntu1

# Exit remote session
exit

# Generate SSH key pair
ssh-keygen
# Accept defaults to create ~/.ssh/id_rsa (private) and ~/.ssh/id_rsa.pub (public)

# View public key
cat ~/.ssh/id_rsa.pub

# View private key (should be kept secret!)
cat ~/.ssh/id_rsa

# Copy public key to remote host
ssh-copy-id ansible@ubuntu1
# This adds your public key to remote's ~/.ssh/authorized_keys

# View known hosts (stores verified host fingerprints)
cat ~/.ssh/known_hosts

# Generate fingerprint for verification
ssh-keygen -F hostname
ssh-keygen -F ip-address
 ``` 

### SSH with sshpass (for automation)
```bash
# Install sshpass (Ubuntu/Debian)
sudo apt update
sudo apt install sshpass

# Create password file
echo "password" > password.txt

# Use sshpass with ssh-copy-id
sshpass -f password.txt ssh-copy-id -o StrictHostKeyChecking=no user@host


###  📝 Automation Script
# Bulk SSH Key Distribution Script

# Set up passwordless SSH to all hosts
for user in ansible root; do
  for os in ubuntu centos; do
    for instance in 1 2 3; do
      sshpass -f password.txt ssh-copy-id \
        -o StrictHostKeyChecking=no \
        ${user}@${os}${instance}
    done
  done
done

# Clean up password file
rm password.txt


# 🔧 Ansible Connection Testing

# Test Ansible connectivity to all hosts
ansible -i ubuntu1,ubuntu2,ubuntu3,centos1,centos2,centos3 all -m ping

# Expected output: "pong" for successful connections
 ``` 



## ⚠️ Common Pitfalls & Solutions
### 1. Host Key Verification
Problem: First-time connection prompts for fingerprint verification <br> Solution:

```bash
# For automation, disable host key checking
export ANSIBLE_HOST_KEY_CHECKING=False
# Or use SSH option
ssh -o StrictHostKeyChecking=no user@host
```

### 2. Permission Issues
Problem: SSH rejects key authentication due to wrong permissions  <br>Solution:

```bash
# Correct permissions for SSH files
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### 3. Multiple Fingerprint Entries
Note: SSH stores fingerprints for both hostname and IP address, which is normal behavior.

🔍 Verification Commands
```bash
# Check current user ID
id

# Test passwordless SSH (shouldn't prompt for password)
ssh ansible@ubuntu1

# View SSH process in detail (debug mode)
ssh -vvv user@host
```