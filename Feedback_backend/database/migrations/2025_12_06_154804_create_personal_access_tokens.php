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
    Schema::create('personal_access_tokens', function (Blueprint $table) {
        //$table->uuid('token_id')->primary();
        //$table->uuidMorphs('tokenable');
        $table->id(); // instead of $table->uuid('token_id')
        $table->morphs('tokenable'); // keeps tokenable_type + tokenable_id
        $table->string('name'); // name of token
        $table->string('token', 64)->unique(); // hashed token
        $table->text('abilities')->nullable();
        $table->timestamp('last_used_at')->nullable();
        $table->timestamp('expires_at')->nullable()->index();
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('personal_access_tokens');
    }
};
