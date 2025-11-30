<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class AchievementUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Fetch Student IDs dynamically
        // utilizing the 'value' method to get just the ID string directly
        $studentCharlieId = DB::table('users')
            ->where('email', 'charlie@example.com') // Querying by email is usually safer/unique
            ->value('user_id');

        $studentDianaId = DB::table('users')
            ->where('email', 'diana@example.com')
            ->value('user_id');

        // 2. Fetch Achievement IDs dynamically
        $achievement1Id = DB::table('achievements')
            ->where('achievement_name', 'First Lesson Plan')
            ->value('achievement_id');

        $achievement2Id = DB::table('achievements')
            ->where('achievement_name', 'pengenalan html')
            ->value('achievement_id');

        // Safety check: Ensure all records exist before trying to seed
        if (!$studentCharlieId || !$studentDianaId || !$achievement1Id || !$achievement2Id) {
            $this->command->error('Skipping AchievementUserSeeder: Required Users or Achievements not found.');
            return;
        }

        // 3. Insert into Pivot Table
        DB::table('achievement_user')->insert([
            // --- Student Charlie's Achievements ---
            [
                'id' => (string) Str::uuid7(),
                'user_id' => $studentCharlieId,
                'achievement_id' => $achievement1Id,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ],
            [
                'id' => (string) Str::uuid7(),
                'user_id' => $studentCharlieId,
                'achievement_id' => $achievement2Id,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ],

            // --- Student Diana's Achievements ---
            [
                'id' => (string) Str::uuid7(),
                'user_id' => $studentDianaId,
                'achievement_id' => $achievement1Id,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ],
            [
                'id' => (string) Str::uuid7(),
                'user_id' => $studentDianaId,
                'achievement_id' => $achievement2Id,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ],
        ]);
        
        $this->command->info('Achievement User Pivot table seeded successfully!');
    }
}
