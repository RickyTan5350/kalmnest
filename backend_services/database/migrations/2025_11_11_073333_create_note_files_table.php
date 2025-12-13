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
       Schema::create('note_files', function (Blueprint $table) {
        $table->id();
        
        // Link to the Note
        $table->foreignUuid('note_id')->constrained('notes', 'note_id')->onDelete('cascade');
        
        // Link to the File
        $table->foreignUuid('file_id')->constrained('files', 'file_id')->onDelete('cascade');
        
        $table->timestamps();
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('note_files');
    }
};
