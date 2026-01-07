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
            $table->integer('timer')->default(0)->after('win_condition');
        });

        Schema::table('level_user', function (Blueprint $table) {
            $table->integer('timer')->default(0)->after('saved_data');
        });

        Schema::table('achievement_user', function (Blueprint $table) {
            $table->integer('timer')->default(0)->after('achievement_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('levels', function (Blueprint $table) {
            $table->dropColumn('timer');
        });

        Schema::table('level_user', function (Blueprint $table) {
            $table->dropColumn('timer');
        });

        Schema::table('achievement_user', function (Blueprint $table) {
            $table->dropColumn('timer');
        });
    }
};