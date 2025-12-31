<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Check if column already exists before adding it
        if (!Schema::hasColumn('class_levels', 'is_private')) {
            Schema::table('class_levels', function (Blueprint $table) {
                $table->boolean('is_private')->default(false)->after('level_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Check if column exists before dropping it
        if (Schema::hasColumn('class_levels', 'is_private')) {
            Schema::table('class_levels', function (Blueprint $table) {
                $table->dropColumn('is_private');
            });
        }
    }
};
