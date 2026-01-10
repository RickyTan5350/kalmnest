#!/bin/bash
set -e  # Exit on error (but we use || true for non-critical steps)

# CRITICAL: Fix storage permissions BEFORE any Laravel commands
# Render containers may reset permissions, so we fix them at runtime
echo "Setting storage permissions..."

# Ensure directories exist
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/storage/framework/cache
mkdir -p /var/www/html/storage/framework/sessions
mkdir -p /var/www/html/storage/framework/views
mkdir -p /var/www/html/bootstrap/cache

# Set ownership and permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Ensure log file exists and is writable
touch /var/www/html/storage/logs/laravel.log
chown www-data:www-data /var/www/html/storage/logs/laravel.log
chmod 664 /var/www/html/storage/logs/laravel.log

# Verify permissions (for debugging)
ls -la /var/www/html/storage/logs/ || true

echo "Storage permissions set successfully"

# Clear any cached config (may fail if permissions not set)
php artisan config:clear || true
php artisan cache:clear || true
php artisan route:clear || true
php artisan view:clear || true

# Cache config for production (now that env vars are available)
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo "Laravel caches cleared and rebuilt"

# Start Apache
echo "Starting Apache..."
exec apache2-foreground
