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
        Schema::create('level_user', function (Blueprint $table) {
            $table->uuid('level_user_id')->primary();
            $table->uuid('level_id');
            $table->uuid('user_id');
            $table->longText('saved_data')->nullable();
            $table->timestamps();

            // Foreign key constraints
            $table->foreign('level_id')
                  ->references('level_id')
                  ->on('levels')
                  ->onDelete('cascade');
            
            $table->foreign('user_id')
                  ->references('user_id')
                  ->on('users')
                  ->onDelete('cascade');

            // Ensure unique combination of level and user
            $table->unique(['level_id', 'user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('level_user');
    }
};

