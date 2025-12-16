<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FeedbackSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get user IDs
        $studentCharlieId = DB::table('users')
            ->where('email', 'charlie@example.com')
            ->value('user_id');

        $studentDianaId = DB::table('users')
            ->where('email', 'diana@example.com')
            ->value('user_id');

        $teacherAliceId = DB::table('users')
            ->where('email', 'alice@example.com')
            ->value('user_id');

        $teacherBobId = DB::table('users')
            ->where('email', 'bob@example.com')
            ->value('user_id');

        // Safety check (important for foreign keys)
        if (!$studentCharlieId || !$studentDianaId || !$teacherAliceId || !$teacherBobId) {
            $this->command->warn('Required users not found. Skipping FeedbackSeeder.');
            return;
        }

        // Insert feedbacks
        DB::table('feedbacks')->insert([
            [
                'feedback_id' => (string) Str::uuid(),
                'student_id' => $studentCharlieId,
                'teacher_id' => $teacherAliceId,
                'topic' => 'Lecture Content',
                'comment' => 'The lecture was very informative and clear.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'feedback_id' => (string) Str::uuid(),
                'student_id' => $studentDianaId,
                'teacher_id' => $teacherBobId,
                'topic' => 'Assignments',
                'comment' => 'Assignments were challenging but helpful.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
