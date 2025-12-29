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
        Schema::create('class_levels', function (Blueprint $table) {
            $table->uuid('class_level_id')->primary();
            $table->uuid('class_id');
            $table->uuid('level_id');
            $table->boolean('is_private')->default(false);
            $table->timestamps();

            // Foreign key constraints
            $table->foreign('class_id')
                  ->references('class_id')
                  ->on('classes')
                  ->onDelete('cascade');
            
            $table->foreign('level_id')
                  ->references('level_id')
                  ->on('levels')
                  ->onDelete('cascade');

            // Ensure unique combination of class and level
            $table->unique(['class_id', 'level_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('class_levels');
    }
};
