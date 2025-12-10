<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create a teacher
        $teacher = User::create([
            'user_id' => (string) Str::uuid7(),
            'name' => 'Teacher One',
            'email' => 'teacher@example.com',
            'phone_no' => '1234567890',
            'address' => '123 School St',
            'gender' => 'Male',
            'password' => bcrypt('password'),
            'account_status' => 'active',
            'role_id' => null, // Will be set after role is fetched
        ]);

        // Create students
        for ($i = 1; $i <= 5; $i++) {
            User::create([
                'user_id' => (string) Str::uuid7(),
                'name' => "Student $i",
                'email' => "student$i@example.com",
                'phone_no' => "123456789$i",
                'address' => "123 Student St $i",
                'gender' => $i % 2 == 0 ? 'Female' : 'Male',
                'password' => bcrypt('password'),
                'account_status' => 'active',
                'role_id' => null,
            ]);
        }

        // Assign roles if they exist
        $teacherRole = \DB::table('roles')->where('role_name', 'Teacher')->first();
        $studentRole = \DB::table('roles')->where('role_name', 'Student')->first();

        if ($teacherRole) {
            $teacher->update(['role_id' => $teacherRole->role_id]);
        }

        if ($studentRole) {
            User::where('email', '!=', 'teacher@example.com')->update(['role_id' => $studentRole->role_id]);
        }
    }
}
