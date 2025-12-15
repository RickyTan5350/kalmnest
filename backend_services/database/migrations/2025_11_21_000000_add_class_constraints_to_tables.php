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
        // 1. Add constraints to the classes table
        Schema::table('classes', function (Blueprint $table) {
            $table->foreign('teacher_id')
                  ->references('user_id')
                  ->on('users')
                  ->onDelete('cascade');
            $table->foreign('admin_id')
                  ->references('user_id')
                  ->on('users')
                  ->onDelete('set null');
        });

        // 2. Add constraints to the class_student pivot table
        Schema::table('class_student', function (Blueprint $table) {
            $table->foreign('class_id')
                  ->references('class_id')
                  ->on('classes')
                  ->onDelete('cascade');
            $table->foreign('student_id')
                  ->references('user_id')
                  ->on('users')
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('classes', function (Blueprint $table) {
            $table->dropForeign(['teacher_id']); 
            $table->dropForeign(['admin_id']); 
        });

        Schema::table('class_student', function (Blueprint $table) {
            $table->dropForeign(['class_id']);
            $table->dropForeign(['student_id']);
        });
    }
};