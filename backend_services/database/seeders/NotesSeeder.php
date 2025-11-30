<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

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
                'file_path' => 'notes/admin/html_basics.pdf',
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
                'file_path' => 'notes/admin/css_flexbox.pdf',
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
                'file_path' => 'notes/admin/js_async.pdf',
                'visibility' => false, // Example of an invisible note
                'topic_id' => $topicIds['JS'],
                'created_by' => $adminId,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}