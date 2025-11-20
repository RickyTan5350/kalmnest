<?php
//database/migrations/2025_11_20_153552_create_class_student_table.php 
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('class_student', function (Blueprint $table) {
            $table->uuid('class_id');
            $table->uuid('student_id');
            $table->timestamp('enrolled_at')->useCurrent();

            // Composite Primary Key
            $table->primary(['class_id', 'student_id']);

            // Foreign Keys
            // $table->foreign('class_id')->references('class_id')->on('classes')->onDelete('cascade');
            // $table->foreign('student_id')->references('user_id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('class_student');
    }
};
