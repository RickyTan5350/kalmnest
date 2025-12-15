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

        DB::table('notes')->insert([
            // Note 1: HTML
            [
                'note_id' => (string) Str::uuid7(),
                'title' => 'HTML Structure Basics',
                // FIX: Set file_id to null as you do not want to seed files
                'file_id' => null, 
                'visibility' => true,
                'topic_id' => $topicIds['HTML'],
                'created_by' => $adminId,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            // Note 2: CSS
            [
                'note_id' => (string) Str::uuid7(),
                'title' => 'CSS Flexbox Layout Guide',
                // FIX: Corrected key from 'file_path' to 'file_id' AND set value to null
                'file_id' => null,
                'visibility' => true,
                'topic_id' => $topicIds['CSS'],
                'created_by' => $adminId,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            // Note 3: JS
            [
                'note_id' => (string) Str::uuid7(),
                'title' => 'JavaScript Async/Await Tutorial',
                // FIX: Corrected key from 'file_path' to 'file_id' AND set value to null
                'file_id' => null, 
                'visibility' => false,
                'topic_id' => $topicIds['JS'],
                'created_by' => $adminId,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}