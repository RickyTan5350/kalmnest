<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ClassSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Ensure users exist
        $userCount = DB::table('users')->count();
        if ($userCount === 0) {
            $this->call(UserSeeder::class);
        }

        // Get users by role
        $roles = DB::table('roles')->pluck('role_id', 'role_name');

        $admin = DB::table('users')
            ->where('role_id', $roles['Admin'])
            ->first();

        $teachers = DB::table('users')
            ->where('role_id', $roles['Teacher'])
            ->get();

        $students = DB::table('users')
            ->where('role_id', $roles['Student'])
            ->get();

        if (!$admin || $teachers->isEmpty() || $students->isEmpty()) {
            $this->command->warn('Required users not found. Please run UserSeeder first.');
            return;
        }

        $classes = [];

       // Class 1: 5 HIKMAH
$class1Id = (string) Str::uuid();
$classes[] = [
    'class_id' => $class1Id,
    'class_name' => '5 HIKMAH',
    'teacher_id' => $teachers[0]->user_id,
    'description' => 'This class focuses on learning HTML fundamentals, including page structure, semantic elements, and basic web layout.',
    'admin_id' => $admin->user_id,
    'created_at' => now(),
    'updated_at' => now(),
];

// Class 2: 5 AMANAH
$class2Id = (string) Str::uuid();
$classes[] = [
    'class_id' => $class2Id,
    'class_name' => '5 AMANAH',
    'teacher_id' => $teachers->count() > 1 ? $teachers[1]->user_id : $teachers[0]->user_id,
    'description' => 'Students learn HTML and CSS to build well-structured and visually styled web pages, including layouts and responsive design.',
    'admin_id' => $admin->user_id,
    'created_at' => now(),
    'updated_at' => now(),
];

// Class 3: 5 ARIF
$class3Id = (string) Str::uuid();
$classes[] = [
    'class_id' => $class3Id,
    'class_name' => '5 ARIF',
    'teacher_id' => $teachers[0]->user_id,
    'description' => 'This class covers HTML, CSS, and JavaScript, focusing on interactive web pages, DOM manipulation, and basic frontend logic.',
    'admin_id' => $admin->user_id,
    'created_at' => now(),
    'updated_at' => now(),
];

// Class 4: 5 BESTARI
$class4Id = (string) Str::uuid();
$classes[] = [
    'class_id' => $class4Id,
    'class_name' => '5 BESTARI',
    'teacher_id' => $teachers[0]->user_id,
    'description' => 'An advanced class that teaches full web development using HTML, CSS, JavaScript, and PHP, including backend concepts and databases.',
    'admin_id' => $admin->user_id,
    'created_at' => now(),
    'updated_at' => now(),
];


        DB::table('classes')->insert($classes);

        // Enroll students
        $enrollments = [];

        foreach ($students as $student) {
            $enrollments[] = [
                'class_id' => $class1Id,
                'student_id' => $student->user_id,
                'enrolled_at' => now(),
            ];
        }

        if ($students->count() >= 2) {
            $enrollments[] = [
                'class_id' => $class2Id,
                'student_id' => $students[0]->user_id,
                'enrolled_at' => now(),
            ];
            $enrollments[] = [
                'class_id' => $class2Id,
                'student_id' => $students[1]->user_id,
                'enrolled_at' => now(),
            ];
        }

        if ($students->count() >= 1) {
            $enrollments[] = [
                'class_id' => $class3Id,
                'student_id' => $students[0]->user_id,
                'enrolled_at' => now(),
            ];
        }

        if ($students->count() >= 3) {
            $enrollments[] = [
                'class_id' => $class4Id,
                'student_id' => $students[2]->user_id,
                'enrolled_at' => now(),
            ];
        } else {
            $enrollments[] = [
                'class_id' => $class4Id,
                'student_id' => $students[0]->user_id,
                'enrolled_at' => now(),
            ];
        }

        DB::table('class_student')->insert($enrollments);

        $this->command->info('Programming classes seeded successfully!');
    }
}
