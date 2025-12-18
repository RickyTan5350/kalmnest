<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ClassLevelSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get existing classes
        $classes = DB::table('classes')->get();
        
        // Get existing levels
        $levels = DB::table('levels')->get();

        if ($classes->isEmpty() || $levels->isEmpty()) {
            $this->command->warn('No classes or levels found. Please run ClassSeeder and LevelSeeder first.');
            return;
        }

        $classLevels = [];

        // Get level type IDs
        $htmlTypeId = DB::table('level_types')->where('level_type_name', 'HTML')->value('level_type_id');
        $cssTypeId = DB::table('level_types')->where('level_type_name', 'CSS')->value('level_type_id');

        // Filter levels by type
        $htmlLevels = $levels->filter(function($level) use ($htmlTypeId) {
            return $level->level_type_id === $htmlTypeId;
        });
        
        $cssLevels = $levels->filter(function($level) use ($cssTypeId) {
            return $level->level_type_id === $cssTypeId;
        });

        // Assign levels to classes
        // Class 1 (PHP Programming) - assign HTML levels
        if ($classes->count() > 0 && $htmlLevels->count() > 0) {
            $class1 = $classes[0];
            foreach ($htmlLevels->take(2) as $level) {
                $classLevels[] = [
                    'class_level_id' => (string) Str::uuid(),
                    'class_id' => $class1->class_id,
                    'level_id' => $level->level_id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        // Class 2 (JavaScript Programming) - assign CSS levels
        if ($classes->count() > 1 && $cssLevels->count() > 0) {
            $class2 = $classes[1];
            foreach ($cssLevels->take(1) as $level) {
                $classLevels[] = [
                    'class_level_id' => (string) Str::uuid(),
                    'class_id' => $class2->class_id,
                    'level_id' => $level->level_id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        // Class 3 (HTML Fundamentals) - assign HTML levels
        if ($classes->count() > 2 && $htmlLevels->count() > 0) {
            $class3 = $classes[2];
            foreach ($htmlLevels->take(2) as $level) {
                $classLevels[] = [
                    'class_level_id' => (string) Str::uuid(),
                    'class_id' => $class3->class_id,
                    'level_id' => $level->level_id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        // Class 4 (CSS Styling) - assign CSS levels
        if ($classes->count() > 3 && $cssLevels->count() > 0) {
            $class4 = $classes[3];
            foreach ($cssLevels->take(1) as $level) {
                $classLevels[] = [
                    'class_level_id' => (string) Str::uuid(),
                    'class_id' => $class4->class_id,
                    'level_id' => $level->level_id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        if (!empty($classLevels)) {
            DB::table('class_levels')->insert($classLevels);
            $this->command->info('Class-levels relationships seeded successfully!');
        } else {
            $this->command->warn('No class-levels relationships created.');
        }
    }
}
