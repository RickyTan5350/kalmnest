# 🔧 Fix: Missing 'focus' Column in Database

## ❌ Problem

Error: `Column not found: 1054 Unknown column 'focus' in 'field list'`

**Cause**: The migration to add the `focus` column hasn't been run on your new database.

## ✅ Solution

### Option 1: Run Migrations (Recommended)

```bash
cd backend_services
php artisan migrate
```

This will run all pending migrations, including:
- `2025_12_30_155942_add_focus_to_classes_table.php` - Adds `focus` column
- `2025_12_27_121206_add_unique_constraint_to_class_name_in_classes_table.php` - Adds unique constraint

### Option 2: Manually Add Column (If Migration Fails)

If migration fails, you can manually add the column:

```sql
ALTER TABLE `classes` 
ADD COLUMN `focus` VARCHAR(50) NULL AFTER `description`;
```

### Option 3: Check Migration Status

```bash
cd backend_services
php artisan migrate:status
```

This shows which migrations have run and which are pending.

## 🔍 Verify Column Exists

After running migration, verify:

```sql
DESCRIBE classes;
-- or
SHOW COLUMNS FROM classes;
```

You should see `focus` column listed.

## 📝 Other Columns to Check

Make sure these columns exist in `classes` table:
- `class_id` (UUID, primary key)
- `class_name` (string, unique)
- `teacher_id` (UUID, nullable)
- `description` (text, nullable)
- `admin_id` (UUID, nullable)
- `focus` (string, nullable) ← **This is missing**
- `created_at` (timestamp)
- `updated_at` (timestamp)

---

## 🚀 Quick Fix Command

```bash
cd backend_services
php artisan migrate
php artisan config:clear
php artisan cache:clear
```

Then try creating a class again.









