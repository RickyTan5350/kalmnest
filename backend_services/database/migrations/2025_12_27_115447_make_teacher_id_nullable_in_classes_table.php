<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Drop the foreign key constraint if it exists
        Schema::table('classes', function (Blueprint $table) {
            $table->dropForeign(['teacher_id']);
        });

        // Modify the column to be nullable using raw SQL for MySQL compatibility
        DB::statement('ALTER TABLE `classes` MODIFY COLUMN `teacher_id` CHAR(36) NULL');

        // Re-add the foreign key constraint with onDelete('set null')
        Schema::table('classes', function (Blueprint $table) {
            $table->foreign('teacher_id')
                  ->references('user_id')
                  ->on('users')
                  ->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop the foreign key constraint
        Schema::table('classes', function (Blueprint $table) {
            $table->dropForeign(['teacher_id']);
        });

        // Make teacher_id NOT NULL again using raw SQL
        DB::statement('ALTER TABLE `classes` MODIFY COLUMN `teacher_id` CHAR(36) NOT NULL');

        // Re-add the foreign key constraint with onDelete('cascade')
        Schema::table('classes', function (Blueprint $table) {
            $table->foreign('teacher_id')
                  ->references('user_id')
                  ->on('users')
                  ->onDelete('cascade');
        });
    }
};
