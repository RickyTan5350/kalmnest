<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB; 

return new class extends Migration
{
    public function up(): void
    {
        // 1. Get the UUIDs for admin and teacher roles
        //    NOTE: Role names are now lowercase: 'admin', 'teacher', 'student'
        $adminRoleID = DB::table('roles')->where('role_name', 'Admin')->value('role_id');
        $teacherRoleID = DB::table('roles')->where('role_name', 'Teacher')->value('role_id');

        // 2. Add the basic foreign key constraint using Schema Builder (PHP)
        Schema::table('achievements', function (Blueprint $table) {
            $table->foreign('created_by')
                  ->references('user_id')
                  ->on('users')
                  ->onDelete('set null');
        });

        // 3. Add the SQL TRIGGER using DB::unprepared() (Raw SQL)
        DB::unprepared("
            CREATE TRIGGER check_achievement_creator_role
            BEFORE INSERT ON `achievements` FOR EACH ROW
            BEGIN
                DECLARE userRoleID CHAR(36);
                
                -- Get the role_id of the user being inserted
                SELECT role_id INTO userRoleID FROM users WHERE user_id = NEW.created_by;
                
                -- Check if the user's role_id is NOT admin OR teacher
                IF userRoleID IS NULL OR (userRoleID <> '$adminRoleID' AND userRoleID <> '$teacherRoleID') THEN
                    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Achievement can only be created by an Admin or a Teacher.';
                END IF;
            END;
        ");
        
        // You should add a BEFORE UPDATE trigger as well if 'created_by' can change.
        // If 'created_by' is fixed after creation, you can skip the update trigger.
        
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