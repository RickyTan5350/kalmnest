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
    Schema::create('users', function (Blueprint $table) {
        // Correct Primary Key
        $table->uuid('user_id')->primary(); 
        
        $table->string('email')->unique();
        $table->string('name');
        $table->string('phone_no');
        $table->text('address')->nullable();
        $table->string('gender');
        $table->string('password');
        $table->enum('account_status', ['Active', 'Inactive'])->default('Active');
        
        // **CORRECT FOREIGN KEY DEFINITION** (UUID)
        $table->uuid('role_id'); 
        
        // Correct Timestamps (defined only once)
        $table->timestamps();

        // Foreign Key Constraint
        $table->foreign('role_id')
              ->references('role_id')
              ->on('roles')
              ->onDelete('cascade');
    });
}


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
