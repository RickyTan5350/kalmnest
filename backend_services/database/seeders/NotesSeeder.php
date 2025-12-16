<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NotesSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Fetch Admin ID
        $adminId = DB::table('users')
            ->where('email', 'admin@example.com')
            ->value('user_id');

        // 2. Fetch Topic IDs [ 'HTML' => 'uuid...', 'CSS' => 'uuid...' ]
        $topicIds = DB::table('topics')->pluck('topic_id', 'topic_name');

        if (!$adminId || $topicIds->isEmpty()) {
            $this->command->warn("Skipping: Admin or Topics not found.");
            return;
        }

        $baseSeedPath = database_path('seed_data/notes');

        // 3. THIS WAS MISSING: Loop through every topic found in the DB
        foreach ($topicIds as $topicName => $topicId) {
            
            // Look for a folder matching the topic name (e.g., notes/HTML)
            $targetPath = $baseSeedPath . '/' . $topicName;

            if (is_dir($targetPath)) {
                $this->command->info("Seeding $topicName...");

                // Now $topicId exists because we are inside the loop
                $this->command->call('notes:import', [
                    'path' => $targetPath,
                    '--user_id' => $adminId,
                    '--topic' => $topicId, 
                ]);
            }
        }
    }
}