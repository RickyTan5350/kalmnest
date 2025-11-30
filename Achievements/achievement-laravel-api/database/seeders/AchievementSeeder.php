<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;

class AchievementSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run(): void
    {
        // Define common UUIDs for related tables (Levels and Users)
        // These are placeholder IDs and should match existing IDs in your levels/users table.
        // If your related tables (levels, users) are empty, you must seed them first.
        $levelUuid = (string) Str::uuid(); 
        $userUuid = (string) Str::uuid(); 
        $now = Carbon::now();

        DB::table('achievements')->insert([
            // --- Achievement 1: Beginner Level Completion ---
            [
                'achievement_id' => (string) Str::uuid(),
                'achievement_name' => 'First Steps',
                'title' => 'Completed the Tutorial Level',
                'description' => 'You successfully navigated the initial steps and are ready for more!',
                'type' => 'Level Completion',
                'level_id' => $levelUuid,
                'created_by' => $userUuid,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            
            // --- Achievement 2: Quantity Based (e.g., 5 items collected) ---
            [
                'achievement_id' => (string) Str::uuid(),
                'achievement_name' => 'Collector I',
                'title' => 'Found 5 Rare Items',
                'description' => 'You have a good eye for treasure. Keep hunting!',
                'type' => 'Collection',
                'level_id' => $levelUuid, // Can be the same level, or a different one
                'created_by' => $userUuid,
                'created_at' => $now,
                'updated_at' => $now,
            ],

            // --- Achievement 3: Time/Event Based ---
            [
                'achievement_id' => (string) Str::uuid(),
                'achievement_name' => 'Night Owl',
                'title' => 'Played 10 Hours After Midnight',
                'description' => 'Dedication knows no hour.',
                'type' => 'Activity',
                'level_id' => $levelUuid,
                'created_by' => $userUuid,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ]);
    }
}