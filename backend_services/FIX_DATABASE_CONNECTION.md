# Fix Database Connection Issue

## Problem

MariaDB is rejecting connections with error: `Host 'localhost' is not allowed to connect to this MariaDB server`

## Solution Steps

### Option 1: Fix MariaDB User Permissions (Recommended)

1. **Open MariaDB/MySQL command line or phpMyAdmin**

2. **Connect as root user** (or admin user with GRANT privileges)

3. **Grant permissions to root user from localhost:**

    ```sql
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '';
    FLUSH PRIVILEGES;
    ```

    If your root user has a password, replace the empty string with your password:

    ```sql
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'your_password';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY 'your_password';
    FLUSH PRIVILEGES;
    ```

4. **Create the database if it doesn't exist:**
    ```sql
    CREATE DATABASE IF NOT EXISTS kalmnest;
    ```

### Option 2: Create a New Database User (Alternative)

If you prefer not to use root:

1. **Create a new user:**

    ```sql
    CREATE USER 'kalmnest_user'@'localhost' IDENTIFIED BY 'your_password';
    CREATE USER 'kalmnest_user'@'127.0.0.1' IDENTIFIED BY 'your_password';
    ```

2. **Grant privileges:**

    ```sql
    GRANT ALL PRIVILEGES ON kalmnest.* TO 'kalmnest_user'@'localhost';
    GRANT ALL PRIVILEGES ON kalmnest.* TO 'kalmnest_user'@'127.0.0.1';
    FLUSH PRIVILEGES;
    ```

3. **Update your `.env` file:**
    ```
    DB_USERNAME=kalmnest_user
    DB_PASSWORD=your_password
    ```

### Option 3: Using XAMPP phpMyAdmin

1. Open phpMyAdmin (usually at `http://localhost/phpmyadmin`)
2. Click on "User accounts" tab
3. Find the `root` user
4. Click "Edit privileges"
5. Make sure "Host name" includes both `localhost` and `127.0.0.1`
6. Ensure all privileges are granted

### After Fixing Permissions

1. **Clear Laravel config cache:**

    ```bash
    cd backend_services
    php artisan config:clear
    ```

2. **Test the connection:**

    ```bash
    php artisan migrate:status
    ```

3. **Run migrations:**

    ```bash
    php artisan migrate
    ```

4. **Seed the database (optional):**
    ```bash
    php artisan db:seed
    ```

## Quick Check Commands

-   Test database connection: `php artisan migrate:status`
-   Check if database exists: Connect to MariaDB and run `SHOW DATABASES;`
-   Check user permissions: `SELECT user, host FROM mysql.user WHERE user='root';`

## Common Issues

-   **If using XAMPP**: Make sure MySQL/MariaDB service is running
-   **If using Laravel Herd**: You still need XAMPP MySQL running (not Apache)
-   **Port conflicts**: Make sure port 3306 is not blocked
-   **Config cache**: Always run `php artisan config:clear` after changing `.env`
