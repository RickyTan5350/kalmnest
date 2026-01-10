#!/bin/bash

# Fix storage permissions (in case they were reset)
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache || true

# Ensure log directory exists and is writable
mkdir -p /var/www/html/storage/logs || true
chmod -R 775 /var/www/html/storage/logs || true
touch /var/www/html/storage/logs/laravel.log || true
chmod 664 /var/www/html/storage/logs/laravel.log || true

# Clear any cached config
php artisan config:clear || true
php artisan cache:clear || true

# Cache config for production (now that env vars are available)
php artisan config:cache || true

# Start Apache
apache2-foreground
