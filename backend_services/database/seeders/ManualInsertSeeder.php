<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;

class ManualInsertSeeder extends Seeder
{
    public function run()
    {
        $userId = '019b9b2d-bd08-73dd-8f04-d57806b721d7';
        $achievementId = '019b9df8-3244-70e9-b4ad-b72855d30336';
        $timer = 80;

        // Check if exists to avoid duplicates (optional but good practice)
        $exists = DB::table('achievement_user')
            ->where('user_id', $userId)
            ->where('achievement_id', $achievementId)
            ->exists();

        if ($exists) {
            $this->command->info('Record already exists. Updating timer...');
            DB::table('achievement_user')
                ->where('user_id', $userId)
                ->where('achievement_id', $achievementId)
                ->update([
                    'timer' => $timer,
                    'updated_at' => Carbon::now(),
                ]);
        } else {
            DB::table('achievement_user')->insert([
                'id' => (string) Str::uuid(), // Generate a UUID for the pivot primary key
                'user_id' => $userId,
                'achievement_id' => $achievementId,
                'timer' => $timer,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ]);
            $this->command->info('Record inserted successfully.');
        }
    }
}
