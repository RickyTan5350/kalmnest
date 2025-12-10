// database/migrations/2025_11_10_051001_create_class_models_table.php
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
            $table->uuid('teacher_id')->index(); // <-- Must be uuid
            $table->text('description')->nullable();
            $table->uuid('admin_id')->nullable()->index();   // <-- Must be uuid
            $table->timestamps();
            
            // CRITICAL: NO foreign key constraints here. Remove any $table->foreign(...) lines.
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('classes');
    }
};