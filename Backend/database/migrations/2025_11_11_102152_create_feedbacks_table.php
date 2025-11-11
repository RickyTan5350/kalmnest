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
        $table->uuid('activity_id');
        $table->text('comment');
        $table->timestamps();

        $table->foreign('student_id')->references('id')->on('users')->onDelete('cascade');
        $table->foreign('teacher_id')->references('id')->on('users')->onDelete('cascade');
        $table->foreign('activity_id')->references('activity_id')->on('activities')->onDelete('cascade');
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
