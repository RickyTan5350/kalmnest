<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AchievementSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Fetch the user_ids for Admin and Teacher
        $adminId = DB::table('users')
                      ->join('roles', 'users.role_id', '=', 'roles.role_id')
                      ->where('roles.role_name', 'Admin')
                      ->value('user_id');

        $teacherId = DB::table('users')
                       ->join('roles', 'users.role_id', '=', 'roles.role_id')
                       ->where('roles.role_name', 'Teacher')
                       ->value('user_id');

        // Check for required IDs
        if (!$adminId || !$teacherId) {
            echo "Skipping AchievementSeeder: Admin or Teacher users not found. Ensure UserSeeder ran first.\n";
            return;
        }

        $levelCssAttr = DB::table('levels')->where('level_name', 'css level 1: atribut')->value('level_id');
        $levelHtmlP   = DB::table('levels')->where('level_name', 'html level 1: <p>')->value('level_id');
        $levelHtmlStyle = DB::table('levels')->where('level_name', 'html level 2: style')->value('level_id');

        DB::table('achievements')->insert([
            // // Achievement 1: Created by Admin
            [
                'achievement_id' => (string) Str::uuid7(), 
                'achievement_name' => 'System Setup Complete',
                'title' => 'Initial Configuration',
                'description' => 'All initial database configurations and constraints were applied.',
                'associated_level' => null,
                 'icon' =>'html',
                'created_by' => $adminId,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            // // Achievement 2: Created by Teacher
            [
                'achievement_id' => (string) Str::uuid7(),
                'achievement_name' => 'First Lesson Plan',
                'title' => 'Teaching Milestone',
                'description' => 'Teacher submitted their first required lesson plan.',
                'associated_level' => null,
                'created_by' => $teacherId,
                'icon' =>'html',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'achievement_id' => (string) Str::uuid7(), 
                'achievement_name' => 'html level 1: <p>',
                'title' => 'Penguasaan Tag <p>',
                'description' => 'Penguasaan penggunaan tag asas HTML <p>',
                'associated_level' => $levelHtmlP,
                'created_by' => $adminId,
                'icon' => 'html',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'achievement_id' => (string) Str::uuid7(), 
                'achievement_name' => 'html level 2: style',
                'title' => 'Penguasaan Style HTML',
                'description' => 'Penguasaan penggunaan style HTML ',
                'associated_level' => $levelHtmlStyle,
                'created_by' => $adminId,
                'icon' => 'html',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'achievement_id' => (string) Str::uuid7(), 
                'achievement_name' => 'css level 1: atribut',
                'title' => 'Penguasaan Atribut CSS',
                'description' => 'Penguasaan penggunaan atribut CSS',
                'associated_level' => $levelCssAttr,
                'created_by' => $adminId,
                'icon' => 'css',    
                'created_at' => now(),
                'updated_at' => now(),
            ]
        ]);
    }
}