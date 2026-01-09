#!/bin/bash

# Clear any cached config
php artisan config:clear || true
php artisan cache:clear || true

# Cache config for production (now that env vars are available)
php artisan config:cache || true

# Start Apache
apache2-foreground
