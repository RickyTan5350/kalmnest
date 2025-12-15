<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Ramsey\Uuid\Uuid;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('achievements', function (Blueprint $table) {
            $table->uuid('achievement_id')->primary();

            // Other columns (no change)
            $table->string('achievement_name');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('type');

            // Foreign Keys: Use binary(16) directly
            $table->uuid('level_id'); 
            $table->uuid('created_by');

            // Laravel's standard timestamps
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('achievements');
    }
};
