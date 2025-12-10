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
        Schema::table('achievement_user', function (Blueprint $table) {
        // 1. Link to Users Table
        $table->foreign('user_id')
              ->references('user_id') // Assuming 'id' is the PK of users
              ->on('users')
              ->cascadeOnDelete();

        // 2. Link to Achievements Table
        // NOTE: We reference 'achievement_id' because that is the PK in your image
        $table->foreign('achievement_id')
              ->references('achievement_id') 
              ->on('achievements')
              ->cascadeOnDelete();

        // 3. Add the Unique Constraint (Prevent duplicates)
        $table->unique(['user_id', 'achievement_id']);
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('achievement_user', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropForeign(['achievement_id']);

            // 2. Drop the Unique Constraint
            $table->dropUnique(['user_id', 'achievement_id']);

        });
    }
};
