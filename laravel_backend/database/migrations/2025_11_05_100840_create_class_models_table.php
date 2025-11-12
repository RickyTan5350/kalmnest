<!-- database/migrations/2025_11_05_100840_create_class_models_table.php -->
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('classes', function (Blueprint $table) {
            $table->uuid('class_id')->primary();
            $table->string('class_name', 100);
            $table->integer('teacher_id');
            $table->text('description')->nullable();
            $table->integer('admin_id');
            $table->timestamps();

            // Foreign key constraints 
            // $table->foreign('teacher_id')->references('user_id')->on('users');
            // $table->foreign('admin_id')->references('user_id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('classes');
    }
};
