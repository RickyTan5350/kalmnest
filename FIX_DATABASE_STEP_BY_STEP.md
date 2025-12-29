# Step-by-Step: Fix Database Connection

## Part 1: Fix MariaDB Permissions

### Method A: Using phpMyAdmin (Easiest - Recommended)

#### Step 1: Open phpMyAdmin
1. Open your web browser
2. Go to: `http://localhost/phpmyadmin`
   - If that doesn't work, try: `http://127.0.0.1/phpmyadmin`
   - Or check if XAMPP has phpMyAdmin on a different port

#### Step 2: Login
- **Username:** `root`
- **Password:** (leave empty if you don't have a password set)
- Click **"Go"** or press Enter

#### Step 3: Open SQL Tab
1. Once logged in, click on the **"SQL"** tab at the top
2. You'll see a text area where you can type SQL commands

#### Step 4: Run the SQL Commands
Copy and paste this into the SQL text area:

```sql
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '';
CREATE DATABASE IF NOT EXISTS kalmnest CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON kalmnest.* TO 'root'@'localhost';
GRANT ALL PRIVILEGES ON kalmnest.* TO 'root'@'127.0.0.1';
FLUSH PRIVILEGES;
```

#### Step 5: Execute
1. Click the **"Go"** button at the bottom right
2. You should see a success message like "Your SQL query has been executed successfully"

#### Step 6: Verify Database Created
1. Look at the left sidebar in phpMyAdmin
2. You should see `kalmnest` database listed
3. Click on it to verify it's empty (ready for migrations)

---

### Method B: Using MariaDB Command Line

#### Step 1: Open Command Prompt or PowerShell
- Press `Win + R`, type `cmd` or `powershell`, press Enter
- Or search for "Command Prompt" or "PowerShell" in Start menu

#### Step 2: Navigate to MariaDB/MySQL
If MariaDB is installed via XAMPP:
```powershell
cd C:\xampp\mysql\bin
```

Or if MariaDB is installed separately, find the `bin` directory.

#### Step 3: Connect to MariaDB
```powershell
mysql.exe -u root -p
```
- When prompted for password, just press Enter (if no password)
- If you have a password, type it and press Enter

#### Step 4: Run SQL Commands
Once connected (you'll see `MariaDB [(none)]>` prompt), type or paste:

```sql
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '';
CREATE DATABASE IF NOT EXISTS kalmnest CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON kalmnest.* TO 'root'@'localhost';
GRANT ALL PRIVILEGES ON kalmnest.* TO 'root'@'127.0.0.1';
FLUSH PRIVILEGES;
```

Press Enter after each command, or paste all at once.

#### Step 5: Verify
```sql
SHOW DATABASES;
```
You should see `kalmnest` in the list.

#### Step 6: Exit
```sql
EXIT;
```

---

## Part 2: Clear Laravel Config Cache

### Using PowerShell/Command Prompt

#### Step 1: Navigate to Backend Services
```powershell
cd C:\Users\junyi\Downloads\kalmnest\kalmnest\backend_services
```

#### Step 2: Clear Config Cache
```powershell
php artisan config:clear
```

You should see: `Configuration cache cleared!`

---

## Part 3: Run Migrations and Seed Database

### Step 1: Run Migrations
Still in the `backend_services` directory:

```powershell
php artisan migrate
```

This will create all the database tables. You should see output like:
```
Migrating: 2025_11_10_051000_create_users_table
Migrated:  2025_11_10_051000_create_users_table
...
```

### Step 2: Seed the Database (Optional but Recommended)
This populates the database with initial data:

```powershell
php artisan db:seed
```

You should see output like:
```
Seeding: RoleSeeder
Seeding: UserSeeder
...
```

---

## Part 4: Test the Connection

### Test from Laravel
```powershell
php artisan migrate:status
```

This should work without errors now.

### Test Login from Flutter App
1. Run your Flutter app
2. Try to login
3. It should work now!

---

## Troubleshooting

### Issue: Can't access phpMyAdmin
**Solutions:**
- Make sure XAMPP Apache is running
- Check if phpMyAdmin is on a different port: `http://localhost:8080/phpmyadmin`
- Try: `http://127.0.0.1/phpmyadmin`

### Issue: "Access denied" when running SQL
**Solutions:**
- Make sure you're logged in as `root` user
- If you have a password, include it in the GRANT command:
  ```sql
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'your_password';
  ```

### Issue: "Database already exists" error
**Solution:**
- This is fine! The `IF NOT EXISTS` clause prevents errors
- The database is ready to use

### Issue: Migration errors
**Solutions:**
- Make sure database `kalmnest` exists
- Check `.env` file has correct database name: `DB_DATABASE=kalmnest`
- Run `php artisan config:clear` again
- Try `php artisan migrate:fresh` (WARNING: This deletes all data!)

### Issue: "SQLSTATE[HY000] [1130]" error persists
**Solutions:**
- Make sure you ran `FLUSH PRIVILEGES;` after GRANT commands
- Restart MySQL/MariaDB service in XAMPP
- Try using `127.0.0.1` instead of `localhost` in `.env` (already set)

---

## Quick Command Summary

```powershell
# 1. Navigate to backend
cd C:\Users\junyi\Downloads\kalmnest\kalmnest\backend_services

# 2. Clear config
php artisan config:clear

# 3. Run migrations
php artisan migrate

# 4. Seed database
php artisan db:seed

# 5. Test connection
php artisan migrate:status
```

