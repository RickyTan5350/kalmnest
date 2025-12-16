<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TopicSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('topics')->insert([
            [
                'topic_id' => (string) Str::uuid7(),
                'topic_name' => 'HTML',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'topic_id' => (string) Str::uuid7(),
                'topic_name' => 'CSS',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'topic_id' => (string) Str::uuid7(),
                'topic_name' => 'JS',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'topic_id' => (string) Str::uuid7(),
                'topic_name' => 'PHP',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            
        ]);
    }
}