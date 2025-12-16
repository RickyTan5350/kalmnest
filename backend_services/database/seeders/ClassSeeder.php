<?php

namespace Database\Seeders;

use App\Models\ClassModel;
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

        // Check if we have required users
        if (!$admin) {
            $this->command->warn('No admin user found. Please run UserSeeder first.');
            return;
        }

        if ($teachers->isEmpty()) {
            $this->command->warn('No teachers found. Please run UserSeeder first.');
            return;
        }

        if ($students->isEmpty()) {
            $this->command->warn('No students found. Please run UserSeeder first.');
            return;
        }

        // Create classes
        $classes = [];

        // Class 1: Mathematics with Teacher Alice
        $class1Id = (string) Str::uuid();
        $classes[] = [
            'class_id' => $class1Id,
            'class_name' => 'Mathematics 101',
            'teacher_id' => $teachers[0]->user_id,
            'description' => 'Introduction to basic mathematics concepts and problem-solving techniques.',
            'admin_id' => $admin->user_id,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        // Class 2: Science with Teacher Bob (if exists)
        $class2Id = (string) Str::uuid();
        if ($teachers->count() > 1) {
            $classes[] = [
                'class_id' => $class2Id,
                'class_name' => 'Science Fundamentals',
                'teacher_id' => $teachers[1]->user_id,
                'description' => 'Exploring the fundamentals of physics, chemistry, and biology.',
                'admin_id' => $admin->user_id,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        } else {
            // If only one teacher, assign to same teacher
            $classes[] = [
                'class_id' => $class2Id,
                'class_name' => 'Science Fundamentals',
                'teacher_id' => $teachers[0]->user_id,
                'description' => 'Exploring the fundamentals of physics, chemistry, and biology.',
                'admin_id' => $admin->user_id,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        // Class 3: Programming with Teacher Alice
        $class3Id = (string) Str::uuid();
        $classes[] = [
            'class_id' => $class3Id,
            'class_name' => 'Programming Basics',
            'teacher_id' => $teachers[0]->user_id,
            'description' => 'Learn programming fundamentals and best practices.',
            'admin_id' => $admin->user_id,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        // Class 4: English (no teacher assigned - nullable)
        $class4Id = (string) Str::uuid();
        $classes[] = [
            'class_id' => $class4Id,
            'class_name' => 'English Literature',
            'teacher_id' => $teachers[0]->user_id, // Assign to first teacher since migration requires it
            'description' => 'Study of classic and modern English literature.',
            'admin_id' => $admin->user_id,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        // Insert classes
        DB::table('classes')->insert($classes);

        // Enroll students in classes
        $enrollments = [];

        // Class 1: Enroll all students
        foreach ($students as $student) {
            $enrollments[] = [
                'class_id' => $class1Id,
                'student_id' => $student->user_id,
                'enrolled_at' => now(),
            ];
        }

        // Class 2: Enroll first 2 students
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

        // Class 3: Enroll first student only
        if ($students->count() >= 1) {
            $enrollments[] = [
                'class_id' => $class3Id,
                'student_id' => $students[0]->user_id,
                'enrolled_at' => now(),
            ];
        }

        // Class 4: Enroll last student (if exists)
        if ($students->count() >= 3) {
            $enrollments[] = [
                'class_id' => $class4Id,
                'student_id' => $students[2]->user_id,
                'enrolled_at' => now(),
            ];
        } elseif ($students->count() >= 1) {
            // If less than 3 students, enroll the first one
            $enrollments[] = [
                'class_id' => $class4Id,
                'student_id' => $students[0]->user_id,
                'enrolled_at' => now(),
            ];
        }

        // Insert enrollments
        if (!empty($enrollments)) {
            DB::table('class_student')->insert($enrollments);
        }

        $this->command->info('Classes seeded successfully!');
        $this->command->info('Created ' . count($classes) . ' classes with ' . count($enrollments) . ' student enrollments.');
    }
}

