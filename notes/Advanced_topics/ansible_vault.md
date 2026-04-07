# 🔐 Ansible Vault - Secret Management



## 📌 What is Ansible Vault?

Ansible Vault encrypts sensitive data so it can be safely stored in version control.

| Feature | Purpose |
|---------|---------|
| **Encrypt variables** | Single sensitive values |
| **Encrypt files** | Entire variable files |
| **Encrypt playbooks** | Complete playbooks |
| **Multiple vaults** | Different passwords for different environments |

> 💡 **Use case:** Passwords, API keys, SSH private keys, certificates

---

## 🎯 1. Encrypting Single Variables

### 📁 1: Before Vault (Broken)

**`group_vars/ubuntu`:**
```yaml
---
ansible_become: true
# ansible_become_pass: password  ← Removed, will fail!
```

**Test without password:**
```bash
ansible ubuntu -m ping -o
# FAILED! - missing sudo password
```

### Encrypt a String

```bash
ansible-vault encrypt_string --ask-vault-pass --name 'ansible_become_pass' 'password'
```

**Prompt:**
```
New Vault password: ****** (vaultpass)
Confirm New Vault password: ******
```

**Output:**
```yaml
ansible_become_pass: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653236336...663336538613530
          3936653433353763650...3336316566383631
```

### Add to Group Vars

**`group_vars/ubuntu`:**
```yaml
---
ansible_become: true
ansible_become_pass: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653236336...663336538613530
          3936653433353763650...3336316566383631
```

### Use with Ansible

```bash
ansible-playbook playbook.yml --ask-vault-pass
# Vault password: ****** (vaultpass)
```

---

## 🎯 2. Encrypting Entire Files

### 📁 2: External Variables File

**`external_vault_vars.yaml` (plain text):**
```yaml
external_vault_var: Example External Vault Var
```

### Encrypt the File

```bash
ansible-vault encrypt external_vault_vars.yaml
```

**Prompt:**
```
New Vault password: ****** (vaultpass)
Confirm New Vault password: ******
Encryption successful
```

**Result (encrypted file):**
```yaml
$ANSIBLE_VAULT;1.1;AES256
66386439653236336...663336538613530
3936653433353763650...3336316566383631
```

### Use Encrypted File in Playbook

**`vault_playbook.yaml`:**
```yaml
---
-
  hosts: linux
  vars_files:
    - external_vault_vars.yaml   # ← Automatically detected as vault

  tasks:
    - name: Show external_vault_var
      debug:
        var: external_vault_var
```

### Run with Vault Password

```bash
ansible-playbook vault_playbook.yaml --ask-vault-pass
# Vault password: ****** (vaultpass)
```

**Output:**
```
"external_vault_var": "Example External Vault Var"
```

> 💡 **Note:** Ansible automatically detects vault-encrypted files!

---

## 🛠️ Ansible-Vault Command Reference

### Basic Commands

| Command | Purpose |
|---------|---------|
| `ansible-vault encrypt FILE` | Encrypt a file |
| `ansible-vault decrypt FILE` | Decrypt a file |
| `ansible-vault view FILE` | View encrypted file content |
| `ansible-vault edit FILE` | Edit encrypted file |
| `ansible-vault rekey FILE` | Change vault password |
| `ansible-vault encrypt_string` | Encrypt a single string |

### Examples

```bash
# Encrypt file
ansible-vault encrypt secrets.yml

# Decrypt file
ansible-vault decrypt secrets.yml

# View encrypted file
ansible-vault view secrets.yml

# Edit encrypted file (decrypts temporarily)
ansible-vault edit secrets.yml

# Change password (rekey)
ansible-vault rekey secrets.yml

# Encrypt string for playbook
ansible-vault encrypt_string --name 'api_key' 'secret123'
```

---

## 🎯 3. Working with Multiple Vaults (Named Vaults)

### Encrypt File with Named Vault

```bash
ansible-vault encrypt --vault-id vars@prompt external_vault_vars.yaml
```

**Prompt:**
```
Enter vault password for 'vars': ****** (varspass)
Confirm Enter vault password for 'vars': ******
```

**Encrypted file header includes vault name:**
```yaml
$ANSIBLE_VAULT;1.2;AES256;vars
66386439653236336...663336538613530
```

### Encrypt String with Named Vault

```bash
ansible-vault encrypt_string --vault-id ssh@prompt --name 'ansible_become_pass' 'password'
```

**Prompt:**
```
Enter vault password for 'ssh': ****** (sshpass)
Confirm Enter vault password for 'ssh': ******
```

**Output with vault name:**
```yaml
ansible_become_pass: !vault |
          $ANSIBLE_VAULT;1.2;AES256;ssh
          66386439653236336...663336538613530
```

### Run with Multiple Vaults

```bash
ansible-playbook vault_playbook.yaml \
  --vault-id vars@prompt \
  --vault-id ssh@prompt
```

**Prompts:**
```
Enter vault password for 'vars': ****** (varspass)
Enter vault password for 'ssh': ****** (sshpass)
```

---

## 🎯 4. Encrypting Entire Playbooks

```bash
ansible-vault encrypt --vault-id playbook@prompt vault_playbook.yaml
```

**Result:** The entire playbook is encrypted!

### Run Encrypted Playbook

```bash
ansible-playbook vault_playbook.yaml \
  --vault-id vars@prompt \
  --vault-id ssh@prompt \
  --vault-id playbook@prompt
```

**Three separate password prompts!**

---

## 🔑 Vault Password Methods

### Method 1: Interactive Prompt
```bash
ansible-playbook playbook.yml --ask-vault-pass
```

### Method 2: Password File
```bash
echo 'myvaultpass' > .vault_pass
chmod 600 .vault_pass

ansible-playbook playbook.yml --vault-password-file .vault_pass
```

### Method 3: Named Vault with Password File
```bash
ansible-playbook playbook.yml --vault-id vars@.vault_pass_vars
```

### Method 4: Named Vault with Prompt
```bash
ansible-playbook playbook.yml --vault-id vars@prompt --vault-id ssh@prompt
```

### Method 5: Environment Variable
```bash
export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass
ansible-playbook playbook.yml
```

---

## 📊 Vault ID Formats

| Format | Meaning | Example |
|--------|---------|---------|
| `@prompt` | Prompt for password | `--vault-id vars@prompt` |
| `@filename` | Read password from file | `--vault-id vars@.vault_vars` |
| `name@prompt` | Named vault with prompt | `--vault-id ssh@prompt` |
| `name@filename` | Named vault with file | `--vault-id prod@.vault_prod` |

---

## 🛡️ Best Practices

| Practice | Why |
|----------|-----|
| **Don't commit vault password** | Add `.vault_pass` to `.gitignore` |
| **Use different passwords** | Separate dev/staging/prod vaults |
| **Name your vaults** | Easier to manage multiple passwords |
| **Back up vault passwords** | Lost password = lost data |
| **Use password files in CI/CD** | Automate without interactive prompts |

---

## 📁 `.gitignore` Entry

```gitignore
# Vault password files
.vault_pass
.vault_*
*_vault_pass

# Decrypted files (if any)
*_decrypted.yml
```

---

## 🎯 Common Workflows

### Workflow 1: Adding Secrets to Repo

```bash
# 1. Create encrypted file
ansible-vault encrypt --vault-id prod@prompt prod_secrets.yml

# 2. Commit encrypted file
git add prod_secrets.yml
git commit -m "Add encrypted prod secrets"

# 3. Store password separately (password manager / vault server)
```

### Workflow 2: Rotating Passwords

```bash
# Rekey all vaults with new password
ansible-vault rekey --vault-id prod@prompt --new-vault-id prod_new@prompt prod_secrets.yml
```

### Workflow 3: Local Development

```bash
# Create local password file
echo "devpassword" > .vault_dev
chmod 600 .vault_dev

# Run playbook
ansible-playbook playbook.yml --vault-id dev@.vault_dev
```

---

## 📊 Quick Reference

### Command Summary

| Command | Action |
|---------|--------|
| `ansible-vault encrypt file` | Encrypt file |
| `ansible-vault decrypt file` | Decrypt file |
| `ansible-vault view file` | View encrypted file |
| `ansible-vault edit file` | Edit encrypted file |
| `ansible-vault rekey file` | Change password |
| `ansible-vault encrypt_string` | Encrypt string |

### Run Options

| Option | Purpose |
|--------|---------|
| `--ask-vault-pass` | Prompt for vault password |
| `--vault-password-file FILE` | Read password from file |
| `--vault-id NAME@PROMPT` | Named vault with prompt |
| `--vault-id NAME@FILE` | Named vault with file |

### Vault Header Format

```
$ANSIBLE_VAULT;1.2;AES256;VAULT_NAME
encrypted_data_here...
```

---

## ✅ Summary

| Concept | Key Takeaway |
|---------|--------------|
| **encrypt_string** | Encrypt single variables |
| **encrypt** | Encrypt entire files |
| **Named vaults** | Multiple passwords for different environments |
| **rekey** | Change vault password |
| **view** | See encrypted content without decrypting |
| **--ask-vault-pass** | Interactive password entry |
| **--vault-id** | Modern way to specify vault credentials |

> 💡 **Pro Tip:** Use named vaults with different passwords for dev, staging, and production environments!

---
