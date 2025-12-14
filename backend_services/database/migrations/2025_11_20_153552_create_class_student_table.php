<?php
//database/migrations/2025_11_20_153552_create_class_student_table.php 
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('class_student', function (Blueprint $table) {
            $table->uuid('class_id')->index();;
            $table->uuid('student_id')->index();;
            $table->timestamp('enrolled_at')->useCurrent();

            // Composite Primary Key
            $table->primary(['class_id', 'student_id']);

    
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('class_student');
    }
};