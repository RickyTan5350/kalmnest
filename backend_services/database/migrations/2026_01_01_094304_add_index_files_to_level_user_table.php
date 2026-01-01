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
        Schema::table('level_user', function (Blueprint $table) {
            $table->longText('index_files')->nullable()->after('saved_data');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('level_user', function (Blueprint $table) {
            $table->dropColumn('index_files');
        });
    }
};
