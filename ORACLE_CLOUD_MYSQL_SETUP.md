# MySQL Setup on Oracle Cloud Free Tier - Easy Guide

This guide will walk you through setting up MySQL on Oracle Cloud's Always Free tier.

## Prerequisites

- Email address for Oracle Cloud account
- Credit card (for verification only, won't be charged for free tier)
- Basic command-line knowledge

---

## Step 1: Create Oracle Cloud Account

1. Go to [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)
2. Click **"Start for Free"**
3. Fill in your details:
   - Email address
   - Password
   - Country/Region
   - Name
4. Add payment method (credit card - **only for verification, no charges for free tier**)
5. Verify your email address
6. Complete the account setup

---

## Step 2: Create a Compute Instance (VM)

1. **Log in** to Oracle Cloud Console: https://cloud.oracle.com/
2. Click the **hamburger menu** (☰) → **Compute** → **Instances**
3. Click **"Create Instance"**

### Instance Configuration:

- **Name**: `mysql-server` (or any name you prefer)
- **Image**: Select **"Canonical Ubuntu"** → Choose **"Ubuntu 22.04"** or **"Ubuntu 20.04"**
- **Shape**: Select **"VM.Standard.E2.1.Micro"** (Always Free eligible)
- **Networking**: 
  - Create new VCN or use existing
  - Select a public subnet
  - **Assign a public IPv4 address**: ✅ Check this box
- **Add SSH Keys**: 
  - Click **"Paste SSH Keys"**
  - Paste your public SSH key (or generate one if needed)
  - Or use **"Generate SSH Key Pair"** and download the private key

4. Click **"Create"**
5. Wait 2-3 minutes for the instance to be provisioned

---

## Step 3: Configure Security Rules (Firewall)

1. In the instance details, find **"Primary VNIC"** → Click the **Subnet** link
2. Click **"Security Lists"** → Click the default security list
3. Click **"Add Ingress Rules"**

### Add MySQL Port (3306):

- **Source Type**: CIDR
- **Source CIDR**: `0.0.0.0/0` (or your IP for better security)
- **IP Protocol**: TCP
- **Destination Port Range**: `3306`
- **Description**: `MySQL Access`
- Click **"Add Ingress Rules"**

### Add SSH Port (22) if not already present:

- **Source Type**: CIDR
- **Source CIDR**: `0.0.0.0/0` (or your IP)
- **IP Protocol**: TCP
- **Destination Port Range**: `22`
- **Description**: `SSH Access`
- Click **"Add Ingress Rules"**

---

## Step 4: Connect to Your Instance

### Get Your Public IP:

1. Go back to **Compute** → **Instances**
2. Find your instance and copy the **Public IP address**

### Connect via SSH:

**On Windows (using PowerShell or Git Bash):**
```bash
ssh -i path/to/your/private-key ubuntu@YOUR_PUBLIC_IP
```

**On Mac/Linux:**
```bash
ssh -i ~/.ssh/your-private-key ubuntu@YOUR_PUBLIC_IP
```

**Example:**
```bash
ssh -i ~/.ssh/oracle-cloud-key ubuntu@123.45.67.89
```

---

## Step 5: Install MySQL

Once connected to your instance, run these commands:

### Update System:
```bash
sudo apt update
sudo apt upgrade -y
```

### Install MySQL Server:
```bash
sudo apt install mysql-server -y
```

### Check MySQL Status:
```bash
sudo systemctl status mysql
```

### Start MySQL (if not running):
```bash
sudo systemctl start mysql
sudo systemctl enable mysql  # Enable auto-start on boot
```

---

## Step 6: Secure MySQL Installation

Run the MySQL security script:

```bash
sudo mysql_secure_installation
```

**Follow the prompts:**

1. **Validate Password Plugin**: 
   - Press `N` (or `Y` if you want password validation)
   
2. **Set Root Password**: 
   - Press `Y` and enter a strong password
   - **Save this password!**

3. **Remove Anonymous Users**: 
   - Press `Y`

4. **Disallow Root Login Remotely**: 
   - Press `Y` (recommended for security)

5. **Remove Test Database**: 
   - Press `Y`

6. **Reload Privilege Tables**: 
   - Press `Y`

---

## Step 7: Configure MySQL for Remote Access

### Edit MySQL Configuration:

```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

**Find this line:**
```
bind-address = 127.0.0.1
```

**Change it to:**
```
bind-address = 0.0.0.0
```

**Save and exit:**
- Press `Ctrl + X`
- Press `Y` to confirm
- Press `Enter`

### Restart MySQL:
```bash
sudo systemctl restart mysql
```

---

## Step 8: Create MySQL User for Remote Access

### Login to MySQL:
```bash
sudo mysql -u root -p
```

Enter your root password when prompted.

### Create a Remote User:

```sql
-- Create a new user (replace 'your_username' and 'your_password')
CREATE USER 'your_username'@'%' IDENTIFIED BY 'your_strong_password';

-- Grant all privileges (or specific privileges as needed)
GRANT ALL PRIVILEGES ON *.* TO 'your_username'@'%' WITH GRANT OPTION;

-- Or grant privileges to a specific database
-- CREATE DATABASE your_database;
-- GRANT ALL PRIVILEGES ON your_database.* TO 'your_username'@'%';

-- Apply changes
FLUSH PRIVILEGES;

-- Exit MySQL
EXIT;
```

**Example:**
```sql
CREATE USER 'appuser'@'%' IDENTIFIED BY 'MySecurePass123!';
GRANT ALL PRIVILEGES ON *.* TO 'appuser'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
```

---

## Step 9: Test Remote Connection

### From Your Local Machine:

Install MySQL client if needed:

**Windows:**
- Download MySQL Workbench or MySQL Command Line Client

**Mac:**
```bash
brew install mysql-client
```

**Linux:**
```bash
sudo apt install mysql-client
```

### Test Connection:

```bash
mysql -h YOUR_PUBLIC_IP -u your_username -p
```

**Example:**
```bash
mysql -h 123.45.67.89 -u appuser -p
```

Enter your password when prompted. If successful, you'll see the MySQL prompt!

---

## Step 10: Basic MySQL Commands

Once connected, try these commands:

```sql
-- Show all databases
SHOW DATABASES;

-- Create a new database
CREATE DATABASE myapp_db;

-- Use a database
USE myapp_db;

-- Show tables
SHOW TABLES;

-- Create a table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

-- Insert data
INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');

-- Select data
SELECT * FROM users;

-- Exit
EXIT;
```

---

## Step 11: Connect from Your Application

### Connection String Examples:

**Laravel (.env):**
```env
DB_CONNECTION=mysql
DB_HOST=YOUR_PUBLIC_IP
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password
```

**Node.js:**
```javascript
const mysql = require('mysql2');
const connection = mysql.createConnection({
  host: 'YOUR_PUBLIC_IP',
  user: 'your_username',
  password: 'your_password',
  database: 'your_database'
});
```

**Python:**
```python
import mysql.connector

conn = mysql.connector.connect(
    host='YOUR_PUBLIC_IP',
    user='your_username',
    password='your_password',
    database='your_database'
)
```

---

## Security Best Practices

1. **Use Strong Passwords**: Always use complex passwords
2. **Limit Access**: Only allow specific IPs in security rules instead of `0.0.0.0/0`
3. **Use SSL**: Enable SSL for MySQL connections
4. **Regular Updates**: Keep MySQL and Ubuntu updated
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
5. **Firewall**: Consider using UFW (Uncomplicated Firewall)
   ```bash
   sudo ufw enable
   sudo ufw allow 22/tcp
   sudo ufw allow 3306/tcp
   ```

---

## Troubleshooting

### Can't Connect Remotely?

1. **Check Security Rules**: Ensure port 3306 is open in Oracle Cloud
2. **Check MySQL Bind Address**: Verify `bind-address = 0.0.0.0` in config
3. **Check User Privileges**: Ensure user has `@'%'` (not `@'localhost'`)
4. **Check MySQL Status**: `sudo systemctl status mysql`
5. **Check Firewall**: `sudo ufw status`

### MySQL Won't Start?

```bash
# Check logs
sudo journalctl -u mysql

# Restart MySQL
sudo systemctl restart mysql
```

### Forgot Root Password?

```bash
# Stop MySQL
sudo systemctl stop mysql

# Start MySQL in safe mode
sudo mysqld_safe --skip-grant-tables &

# Login without password
mysql -u root

# Reset password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
EXIT;

# Restart MySQL normally
sudo systemctl restart mysql
```

---

## Useful Commands Reference

```bash
# MySQL Service Management
sudo systemctl start mysql
sudo systemctl stop mysql
sudo systemctl restart mysql
sudo systemctl status mysql

# MySQL Login
sudo mysql -u root -p
mysql -u username -p -h host

# Backup Database
mysqldump -u username -p database_name > backup.sql

# Restore Database
mysql -u username -p database_name < backup.sql

# Check MySQL Version
mysql --version
```

---

## Free Tier Limits

- **2 VM.Standard.E2.1.Micro instances** (1 OCPU, 1 GB RAM each)
- **10 TB storage** (block storage)
- **10 GB object storage**
- **No time limit** - Always Free

---

## Additional Resources

- [Oracle Cloud Documentation](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [MySQL Official Documentation](https://dev.mysql.com/doc/)
- [MySQL Workbench](https://www.mysql.com/products/workbench/) - GUI Tool

---

## Quick Setup Script (Optional)

Save this as `setup-mysql.sh` and run it on your instance:

```bash
#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install MySQL
sudo apt install mysql-server -y

# Start and enable MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Configure MySQL for remote access
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart MySQL
sudo systemctl restart mysql

echo "MySQL installed and configured!"
echo "Don't forget to:"
echo "1. Run: sudo mysql_secure_installation"
echo "2. Create remote user in MySQL"
echo "3. Open port 3306 in Oracle Cloud security rules"
```

**Run it:**
```bash
chmod +x setup-mysql.sh
./setup-mysql.sh
```

---

**That's it!** You now have MySQL running on Oracle Cloud Free Tier. 🎉

