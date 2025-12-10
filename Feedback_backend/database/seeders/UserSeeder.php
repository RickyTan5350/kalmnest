<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Fetch Role IDs from the roles table using the new names
        $roles = DB::table('roles')->pluck('role_id', 'role_name');

        // Check if roles exist (optional, but good for safety)
        if ($roles->isEmpty()) {
            $this->call(RoleSeeder::class); 
            $roles = DB::table('roles')->pluck('role_id', 'role_name');
        }

        // Define the users
        $users = [
            // User 1: Admin
            [
                'user_id' => (string) Str::uuid7(),
                'role_id' => $roles['Admin'],
                'name' => 'Admin User',
                'email' => 'admin@example.com',
                'phone_no' => '0123456789',
                'address' => '123 Admin Lane',
                'gender' => 'male',
                'password' => Hash::make('password'),
                'account_status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            // User 2 & 3: Teachers
            [
                'user_id' => (string) Str::uuid7(),
                'role_id' => $roles['Teacher'],
                'name' => 'Teacher Alice',
                'email' => 'alice@example.com',
                'phone_no' => '0121111111',
                'address' => '404 Content Road',
                'gender' => 'female',
                'password' => Hash::make('password'),
                'account_status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => (string) Str::uuid7(),
                'role_id' => $roles['Teacher'],
                'name' => 'Teacher Bob',
                'email' => 'bob@example.com',
                'phone_no' => '0122222222',
                'address' => '505 Article Street',
                'gender' => 'male',
                'password' => Hash::make('password'),
                'account_status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            // User 4, 5, 6: Students
            [
                'user_id' => (string) Str::uuid7(),
                'role_id' => $roles['Student'],
                'name' => 'Student Charlie',
                'email' => 'charlie@example.com',
                'phone_no' => '0123333333',
                'address' => '606 Student Drive',
                'gender' => 'male',
                'password' => Hash::make('password'),
                'account_status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => (string) Str::uuid7(),
                'role_id' => $roles['Student'],
                'name' => 'Student Diana',
                'email' => 'diana@example.com',
                'phone_no' => '0124444444',
                'address' => '707 Class Ave',
                'gender' => 'female',
                'password' => Hash::make('password'),
                'account_status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => (string) Str::uuid7(),
                'role_id' => $roles['Student'], 
                'name' => 'Student Ethan',
                'email' => 'ethan@example.com',
                'phone_no' => '0125555555',
                'address' => '808 Study Way',
                'gender' => 'male',
                'password' => Hash::make('password'),
                'account_status' => 'inactive',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        DB::table('users')->insert($users);
    }
}