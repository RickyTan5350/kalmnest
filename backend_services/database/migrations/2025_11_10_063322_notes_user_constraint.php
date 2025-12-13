<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        

        Schema::table('notes', function (Blueprint $table) {
            $table->foreign('created_by')
                  ->references('user_id')
                  ->on('users')
                  ->onDelete('set null');
        });

        // 2. Create the trigger with the correct logic
        //  DB::unprepared("
        //     CREATE TRIGGER check_note_creator_role
        //     BEFORE INSERT ON `notes` FOR EACH ROW
        //     BEGIN
        //         DECLARE userRoleName VARCHAR(255);
                
        //         -- Get the role_id of the user being inserted
        //         SELECT r.role_name INTO userRoleName
        //         FROM users u
        //         JOIN roles r ON u.role_id = r.role_id
        //         WHERE u.user_id = NEW.created_by;
                
        //         -- Check if the role_id is NULL or not one of the allowed roles
        //         IF NEW.created_by IS NOT NULL AND (userRoleName IS NULL OR userRoleName NOT IN ('Admin', 'Teacher')) THEN
        //             SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Note creator must be an admin or a teacher.';
        //         END IF;
        //     END;
        // ");
    }
    /**
     * Reverse the migrations.
     */
      public function down(): void
    {
        DB::unprepared('DROP TRIGGER IF EXISTS check_note_creator_role');
        
        Schema::table('notes', function (Blueprint $table) {
            $table->dropForeign(['created_by']); 
        });
    }
};