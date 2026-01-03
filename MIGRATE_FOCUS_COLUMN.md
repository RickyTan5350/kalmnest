# 🔧 How to Migrate Only the Focus Column

## Method 1: Run Specific Migration (If Not Run Yet)

### Step 1: Check Migration Status

```bash
cd backend_services
php artisan migrate:status
```

Look for `2025_12_30_155942_add_focus_to_classes_table.php`:
- If it shows **"Ran"** → Migration already ran (skip to Method 2)
- If it shows **"Pending"** → Run Method 1

### Step 2: Run All Pending Migrations

```bash
php artisan migrate
```

This will run all pending migrations, including the focus column migration.

---

## Method 2: If Migration Already Ran (Rollback & Re-run)

### Step 1: Rollback Last Migration

```bash
cd backend_services
php artisan migrate:rollback --step=1
```

This rolls back the last migration.

### Step 2: Re-run the Migration

```bash
php artisan migrate
```

---

## Method 3: Run Specific Migration File Directly

### Step 1: Use migrate:refresh for Specific File

```bash
cd backend_services

# First, check if the migration exists
php artisan migrate:status | grep focus

# If it shows as "Ran", rollback first:
php artisan migrate:rollback --step=1

# Then run migrations again:
php artisan migrate
```

---

## Method 4: Manual SQL (Fastest)

If migrations are causing issues, run SQL directly:

```sql
-- Check if column exists
SHOW COLUMNS FROM classes LIKE 'focus';

-- If not exists, add it:
ALTER TABLE `classes` 
ADD COLUMN `focus` VARCHAR(50) NULL AFTER `description`;
```

### Using Laravel Tinker:

```bash
cd backend_services
php artisan tinker
```

Then in tinker:
```php
DB::statement("ALTER TABLE `classes` ADD COLUMN `focus` VARCHAR(50) NULL AFTER `description`");
exit
```

---

## Method 5: Force Re-run Specific Migration

### Step 1: Mark Migration as Not Run

```bash
cd backend_services
php artisan migrate:status
```

Note the migration file name: `2025_12_30_155942_add_focus_to_classes_table`

### Step 2: Remove from migrations table (if needed)

```bash
php artisan tinker
```

```php
DB::table('migrations')->where('migration', '2025_12_30_155942_add_focus_to_classes_table')->delete();
exit
```

### Step 3: Run Migration Again

```bash
php artisan migrate
```

---

## ✅ Recommended: Quick Check & Run

```bash
cd backend_services

# 1. Check migration status
php artisan migrate:status

# 2. If focus migration shows "Pending", run:
php artisan migrate

# 3. If focus migration shows "Ran" but column doesn't exist, use manual SQL:
php artisan tinker
# Then run:
DB::statement("ALTER TABLE `classes` ADD COLUMN `focus` VARCHAR(50) NULL AFTER `description`");
exit
```

---

## 🔍 Verify Column Was Added

```bash
php artisan tinker
```

```php
Schema::hasColumn('classes', 'focus');
// Should return: true

DB::select("DESCRIBE classes");
// Should show 'focus' column in the list

exit
```

---

## 📝 Migration File Details

**File**: `database/migrations/2025_12_30_155942_add_focus_to_classes_table.php`

**What it does**:
- Adds `focus` column (VARCHAR 50, nullable)
- Places it after `description` column

**To undo** (if needed):
```bash
php artisan migrate:rollback --step=1
```

---

**Choose the method that works best for your situation!** 🚀









