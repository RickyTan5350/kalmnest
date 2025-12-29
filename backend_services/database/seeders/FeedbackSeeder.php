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

        // Get Topic IDs
        $htmlTopicId = DB::table('topics')
            ->where('topic_name', 'HTML')
            ->value('topic_id');

        $cssTopicId = DB::table('topics')
            ->where('topic_name', 'CSS')
            ->value('topic_id');

        $jsTopicId = DB::table('topics')
            ->where('topic_name', 'JS')
            ->value('topic_id');

        $phpTopicId = DB::table('topics')
            ->where('topic_name', 'PHP')
            ->value('topic_id');

        // Safety check (important for foreign keys)
        if (!$studentCharlieId || !$studentDianaId || !$teacherAliceId || !$teacherBobId || !$htmlTopicId || !$cssTopicId || !$jsTopicId || !$phpTopicId) {
            $this->command->warn('Required users or topics not found. Skipping FeedbackSeeder.');
            return;
        }

        // Insert feedbacks
        DB::table('feedbacks')->insert([
            [
                'feedback_id' => (string) Str::uuid(),
                'student_id' => $studentCharlieId,
                'teacher_id' => $teacherAliceId,
                'topic_id' => $htmlTopicId,
                'title' => 'HTML Quiz',
                'comment' => 'Please redo the quiz.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'feedback_id' => (string) Str::uuid(),
                'student_id' => $studentDianaId,
                'teacher_id' => $teacherBobId,
                'topic_id' => $cssTopicId,
                'title' => 'CSS Notes',
                'comment' => 'Please study your CSS notes.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'feedback_id' => (string) Str::uuid(),
                'student_id' => $studentCharlieId,
                'teacher_id' => $teacherBobId,
                'topic_id' => $jsTopicId,
                'title' => 'Javascript Quiz',
                'comment' => 'Please complete the Javascript quiz before the next class',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'feedback_id' => (string) Str::uuid(),
                'student_id' => $studentDianaId,
                'teacher_id' => $teacherAliceId,
                'topic_id' => $htmlTopicId,
                'title' => 'HTML Notes',
                'comment' => 'Please study your notes.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'feedback_id' => (string) Str::uuid(),
                'student_id' => $studentCharlieId,
                'teacher_id' => $teacherBobId,
                'topic_id' => $phpTopicId,
                'title' => 'PHP Notes',
                'comment' => 'Please study your php notes.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
