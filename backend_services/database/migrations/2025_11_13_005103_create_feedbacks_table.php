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
        Schema::create('feedbacks', function (Blueprint $table) {
            $table->uuid('feedback_id')->primary();
            $table->uuid('student_id');
            $table->uuid('teacher_id');
            $table->string('topic');
            $table->text('comment');
            $table->timestamps();

        $table->foreign('student_id')
            ->references('user_id')
            ->on('users')
            ->onDelete('cascade');

        $table->foreign('teacher_id')
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
        Schema::dropIfExists('feedbacks');
    }
};

