<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class LevelTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('level_types')->insert([
            [
                'level_type_id' => Str::uuid7(),
                'level_type_name' => 'HTML',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'level_type_id' => Str::uuid7(),
                'level_type_name' => 'CSS',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'level_type_id' => Str::uuid7(),
                'level_type_name' => 'JS',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'level_type_id' => Str::uuid7(),
                'level_type_name' => 'PHP',
                'created_at' => now(),
                'updated_at' => now(),
            ],

            [
                'level_type_id' => Str::uuid7(),
                'level_type_name' => 'Quiz',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
