# Fix phpMyAdmin Login Issue with Laravel Herd

## Problem
You can access phpMyAdmin login page but can't login because "localhost can't login". This is the same MariaDB permission issue.

## Solution: Fix via Command Line

Since you can't login to phpMyAdmin, we'll fix the permissions using MySQL/MariaDB command line.

### Step 1: Find MySQL/MariaDB Location

If you're using XAMPP (which is common with Herd), MySQL is usually at:
- `C:\xampp\mysql\bin\mysql.exe`

### Step 2: Connect to MariaDB via Command Line

Open PowerShell and run:

```powershell
# Navigate to MySQL bin directory
cd C:\xampp\mysql\bin

# Connect to MariaDB (no password)
.\mysql.exe -u root
```

If you have a password:
```powershell
.\mysql.exe -u root -p
# Then enter your password when prompted
```

### Step 3: Run SQL Commands to Fix Permissions

Once connected (you'll see `MariaDB [(none)]>` prompt), copy and paste these commands:

```sql
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '';
CREATE DATABASE IF NOT EXISTS kalmnest CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON kalmnest.* TO 'root'@'localhost';
GRANT ALL PRIVILEGES ON kalmnest.* TO 'root'@'127.0.0.1';
FLUSH PRIVILEGES;
EXIT;
```

### Step 4: Test phpMyAdmin Login

1. Go back to phpMyAdmin: `http://localhost/phpmyadmin`
2. Try logging in with:
   - Username: `root`
   - Password: (leave empty)
3. It should work now!

### Alternative: If XAMPP MySQL Path is Different

If MySQL is not in `C:\xampp\mysql\bin`, try:

```powershell
# Search for mysql.exe
Get-ChildItem -Path C:\ -Filter mysql.exe -Recurse -ErrorAction SilentlyContinue | Select-Object FullName
```

Or check common locations:
- `C:\Program Files\MySQL\MySQL Server X.X\bin\mysql.exe`
- `C:\Program Files\MariaDB\bin\mysql.exe`
- `C:\laragon\bin\mysql\mysql-X.X\bin\mysql.exe`

### Alternative: Use Herd's MySQL (if available)

If Herd has its own MySQL installation:

```powershell
# Check if Herd has MySQL
herd mysql
```

Or check Herd's installation directory (usually):
- `C:\Users\<YourUsername>\AppData\Roaming\Herd\bin\mysql\bin\mysql.exe`

## After Fixing Permissions

Once you can login to phpMyAdmin:

1. **Verify database exists**: You should see `kalmnest` in the left sidebar
2. **Run Laravel migrations** (from PowerShell):
   ```powershell
   cd C:\Users\junyi\Downloads\kalmnest\kalmnest\backend_services
   php artisan config:clear
   php artisan migrate
   php artisan db:seed
   ```

## Troubleshooting

### Issue: "mysql.exe not found"
**Solution:**
- Make sure XAMPP MySQL service is running
- Check XAMPP Control Panel → MySQL should be "Running"
- Try the full path: `C:\xampp\mysql\bin\mysql.exe -u root`

### Issue: "Access denied" when connecting
**Solutions:**
- Try: `mysql.exe -u root --password=` (explicit empty password)
- Or: `mysql.exe -u root -p` and press Enter when asked for password
- Check if root user exists: You might need to use a different user

### Issue: Still can't login to phpMyAdmin after fixing
**Solutions:**
1. Restart XAMPP MySQL service
2. Clear browser cache
3. Try incognito/private browsing window
4. Check phpMyAdmin config allows empty password

### Issue: "Unknown database 'kalmnest'" error
**Solution:**
- Make sure you ran the `CREATE DATABASE` command
- Verify in phpMyAdmin that `kalmnest` database exists

