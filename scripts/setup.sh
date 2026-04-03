#!/bin/bash
set -e

cd /vercel/share/v0-project

echo "=== Step 1: Install Composer ==="
if ! command -v composer &> /dev/null; then
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi
composer --version

echo "=== Step 2: Install PHP dependencies ==="
composer install --no-interaction --prefer-dist --optimize-autoloader 2>&1

echo "=== Step 3: Create .env file ==="
cp .env.example .env

# Use SQLite so no MySQL server is required
sed -i 's/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/' .env
sed -i 's/DB_HOST=127.0.0.1/# DB_HOST=127.0.0.1/' .env
sed -i 's/DB_PORT=3306/# DB_PORT=3306/' .env
sed -i 's/DB_DATABASE=roblox/DB_DATABASE=\/vercel\/share\/v0-project\/database\/database.sqlite/' .env
sed -i 's/DB_USERNAME=root/# DB_USERNAME=root/' .env
sed -i 's/DB_PASSWORD=/# DB_PASSWORD=/' .env

# Disable captcha for local dev
sed -i 's/NOCAPTCHA_SITEKEY=/NOCAPTCHA_SITEKEY=test/' .env
sed -i 's/NOCAPTCHA_SECRET=/NOCAPTCHA_SECRET=test/' .env

echo "=== Step 4: Generate app key ==="
php artisan key:generate --ansi

echo "=== Step 5: Create SQLite database ==="
touch database/database.sqlite

echo "=== Step 6: Run migrations ==="
php artisan migrate --force 2>&1

echo "=== Step 7: Seed initial site settings ==="
php artisan db:seed --force 2>&1 || true

echo "=== Step 8: Set storage permissions ==="
chmod -R 775 storage bootstrap/cache || true

echo "=== Setup complete! Starting server on port 3000 ==="
php artisan serve --host=0.0.0.0 --port=3000
