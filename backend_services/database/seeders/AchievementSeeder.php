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
                      ->where('roles.role_name', 'admin')
                      ->value('user_id');

        $teacherId = DB::table('users')
                       ->join('roles', 'users.role_id', '=', 'roles.role_id')
                       ->where('roles.role_name', 'teacher')
                       ->value('user_id');

        // Check for required IDs
        if (!$adminId || !$teacherId) {
            echo "Skipping AchievementSeeder: Admin or Teacher users not found. Ensure UserSeeder ran first.\n";
            return;
        }

        DB::table('achievements')->insert([
            // Achievement 1: Created by Admin
            [
                'achievement_id' => (string) Str::uuid7(), 
                'achievement_name' => 'System Setup Complete',
                'title' => 'Initial Configuration',
                'description' => 'All initial database configurations and constraints were applied.',
                'associated_level' => null,
                'created_by' => $adminId,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            // Achievement 2: Created by Teacher
            [
                'achievement_id' => (string) Str::uuid7(),
                'achievement_name' => 'First Lesson Plan',
                'title' => 'Teaching Milestone',
                'description' => 'Teacher submitted their first required lesson plan.',
                'associated_level' => null,
                'created_by' => $teacherId,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}