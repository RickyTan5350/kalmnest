# 🚀 Quick Fix: Database Column Missing

## ❌ Error

```
Column not found: 1054 Unknown column 'focus' in 'field list'
```

## ✅ Solution: Run Migrations

Your database is missing the `focus` column. Run migrations to add it:

```bash
cd backend_services
php artisan migrate
```

This will add:
- `focus` column to `classes` table
- Unique constraint on `class_name` (if not exists)

## 🔍 Verify

After running migration, check:

```bash
php artisan tinker
DB::select("DESCRIBE classes");
```

You should see `focus` column listed.

## 📝 Alternative: Manual SQL

If migration fails, run this SQL directly:

```sql
ALTER TABLE `classes` 
ADD COLUMN `focus` VARCHAR(50) NULL AFTER `description`;
```

## ✅ Code Already Fixed

The code has been updated to:
- Check if `focus` column exists before using it
- Work even if column doesn't exist (focus will be ignored)

But **you should still run migrations** to add the column properly.

---

**Run**: `php artisan migrate` in `backend_services` directory









