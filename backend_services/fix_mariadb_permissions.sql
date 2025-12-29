-- Fix MariaDB Permissions for Laravel Application
-- Run this script in MariaDB/MySQL command line or phpMyAdmin SQL tab

-- Grant permissions to root user from both localhost and 127.0.0.1
-- (Replace '' with your root password if you have one)
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '';

-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS kalmnest CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant privileges on the specific database
GRANT ALL PRIVILEGES ON kalmnest.* TO 'root'@'localhost';
GRANT ALL PRIVILEGES ON kalmnest.* TO 'root'@'127.0.0.1';

-- Refresh privileges
FLUSH PRIVILEGES;

-- Verify the user can connect
SELECT user, host FROM mysql.user WHERE user='root';

