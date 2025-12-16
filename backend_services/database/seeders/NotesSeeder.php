<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\Models\File;

class NotesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Fetch the ID of a valid creator (Admin user) to satisfy the database trigger
        $adminId = DB::table('users')
            ->where('email', 'admin@example.com') 
            ->value('user_id');

        // 2. Fetch the IDs for the three topics
        $topicIds = DB::table('topics')->pluck('topic_id', 'topic_name');

        if (!$adminId || $topicIds->isEmpty()) {
            echo "Skipping NoteSeeder: Admin user or Topics not found. Ensure previous seeders ran.\n";
            return;
        }

        // 1. Define the path for the seed data (committed notes)
        $seedDataPath = database_path('seed_data/notes');

        if (is_dir($seedDataPath)) {
            $this->command->info("Seeding notes from: $seedDataPath");
            
            // Call the existing Artisan command to import notes
            // Syntax: notes:import {path} {--user_id=} {--topic=}
            $this->command->call('notes:import', [
                'path' => $seedDataPath,
                '--user_id' => $adminId ?? 1, // Fallback to ID 1 if admin not found
                '--topic' => 'General', // Default topic, file structure can override this if logic expands
            ]);
        } else {
            $this->command->warn("No seed data found at $seedDataPath. Skipping note import.");
            $this->command->warn("To sync notes, create this folder and add your .md files there.");
        }
    }
}