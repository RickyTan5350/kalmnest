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
        Schema::table('levels', function (Blueprint $table) {
            // Add the constraint to the existing 'role_id' UUID column
            $table->foreign('level_type_id')
                  ->references('level_type_id')
                  ->on('level_types')
                  ->onDelete('set null');      
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('levels', function (Blueprint $table) {
            $table->dropForeign(['level_type_id']); 
        });
    }
};
