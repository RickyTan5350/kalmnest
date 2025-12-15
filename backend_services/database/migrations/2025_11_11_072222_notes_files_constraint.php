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
        Schema::table('notes', function (Blueprint $table) {
            $table->foreign('file_id')
                  ->references('file_id')
                  ->on('files')
                  ->onDelete('set null'); 
                  // 'set null' is used because your file_id is nullable. 
                  // If a file is deleted, the note remains but the link is cleared.
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notes', function (Blueprint $table) {
            // Drop the foreign key constraint
            $table->dropForeign(['file_id']);
        });
    }
};