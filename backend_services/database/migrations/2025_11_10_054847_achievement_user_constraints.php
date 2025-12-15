<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB; 

return new class extends Migration
{
    public function up(): void
    {
        // 1. Add the basic foreign key constraint (Keep this)
        Schema::table('achievements', function (Blueprint $table) {
            $table->foreign('created_by')
                ->references('user_id')
                ->on('users')
                ->onDelete('set null');
        });

        // 2. Add the SQL TRIGGER using DB::unprepared() (Raw SQL)
        DB::unprepared("
            CREATE TRIGGER check_achievement_creator_role
            BEFORE INSERT ON `achievements` FOR EACH ROW
            BEGIN
                DECLARE creatorRoleName VARCHAR(255);
                
                -- Get the role_name of the user being inserted by joining users and roles tables
                SELECT r.role_name INTO creatorRoleName 
                FROM users u
                JOIN roles r ON u.role_id = r.role_id
                WHERE u.user_id = NEW.created_by;
                
                -- Check if the creator's role is NOT Admin AND NOT Teacher
                IF creatorRoleName IS NULL OR (creatorRoleName <> 'Admin' AND creatorRoleName <> 'Teacher') THEN
                    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Achievement can only be created by an Admin or a Teacher.';
                END IF;
            END;
        ");
    }
        
    

    public function down(): void
    {
        // 1. Drop the SQL TRIGGER first
        DB::unprepared('DROP TRIGGER IF EXISTS check_achievement_creator_role');
        
        // 2. Then, drop the foreign key constraint
        Schema::table('achievements', function (Blueprint $table) {
            $table->dropForeign(['created_by']); 
        });
    }
};