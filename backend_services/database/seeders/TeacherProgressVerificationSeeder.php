<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\ClassModel;
use App\Models\Achievement;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class TeacherProgressVerificationSeeder extends Seeder
{
    public function run()
    {
        try {
            DB::beginTransaction();

            $password = Hash::make('password');
            $timestamp = now()->timestamp; // Unique identifier for this run

            // 1. Get Role IDs
            $teacherRoleId = DB::table('roles')->where('role_name', 'Teacher')->value('role_id');
            $studentRoleId = DB::table('roles')->where('role_name', 'Student')->value('role_id');

            // 2. Get Existing Teachers from UserSeeder
            $alice = User::where('email', 'alice@example.com')->first();
            $bob = User::where('email', 'bob@example.com')->first();

            if (!$alice || !$bob) {
                $this->command->error("Existing teachers not found! Please run UserSeeder first.");
                return;
            }

            $aliceEmail = $alice->email;
            $bobEmail = $bob->email;

            // 3. Create Students (Unique)
            $students = [];
            foreach (['A', 'B', 'C', 'D'] as $letter) {
                $students[$letter] = User::create([
                    'user_id' => Str::uuid(),
                    'name' => "Student $letter $timestamp",
                    'email' => "student_{$letter}_{$timestamp}@test.com",
                    'password' => $password,
                    'role_id' => $studentRoleId,
                    'account_status' => 'active',
                    'phone_no' => '5555555555',
                    'address' => "789 Student $letter Rd",
                    'gender' => 'Other',
                ]);
            }

            // 4. Create Classes
            $aliceClass = ClassModel::create([
                'class_id' => Str::uuid(),
                'class_name' => "Alice's Class $timestamp",
                'teacher_id' => $alice->user_id,
                'description' => 'Test Class for Alice',
            ]);

            $bobClass = ClassModel::create([
                'class_id' => Str::uuid(),
                'class_name' => "Bob's Class $timestamp",
                'teacher_id' => $bob->user_id,
                'description' => 'Test Class for Bob',
            ]);

            // 5. Enroll Students
            // Alice gets A, B, C
            foreach (['A', 'B', 'C'] as $letter) {
                DB::table('class_student')->insert([
                    'class_id' => $aliceClass->class_id,
                    'student_id' => $students[$letter]->user_id,
                    'enrolled_at' => now(),
                ]);
            }

            // Bob gets D
            DB::table('class_student')->insert([
                'class_id' => $bobClass->class_id,
                'student_id' => $students['D']->user_id,
                'enrolled_at' => now(),
            ]);

            // 6. Create & Unlock Achievement
            $achievement = Achievement::create([
                'achievement_id' => Str::uuid(),
                'achievement_name' => 'progress_test_ach_' . $timestamp,
                'title' => 'Progress Test Achievement ' . $timestamp,
                'description' => 'Achievement to test teacher view filtering',
                'icon' => 'html',
                'created_by' => $alice->user_id,
            ]);

            // Unlock for ALL students (A, B, C, D)
            foreach ($students as $student) {
                DB::table('achievement_user')->insert([
                    'id' => Str::uuid(),
                    'achievement_id' => $achievement->achievement_id,
                    'user_id' => $student->user_id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            DB::commit();

            $this->command->info("Seeding Complete!");
            $this->command->info("Teacher Alice: $aliceEmail / password");
            $this->command->info("Teacher Bob: $bobEmail / password");
            $this->command->info("Alice should see 3/3 students unlocked.");
            $this->command->info("Bob should see 1/1 students unlocked.");

        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Seeding Failed: " . $e->getMessage());
            $this->command->error("Line: " . $e->getLine());
        }
    }
}
