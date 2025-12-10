<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        
        DB::table('roles')->insert([
            [
                'role_id' => (string) Str::uuid7(),
                'role_name' => 'Admin',
            ],
            [
                'role_id' => (string) Str::uuid7(),
                'role_name' => 'Teacher',
            ],
            [
                'role_id' => (string) Str::uuid7(),
                'role_name' => 'Student',
            ]                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
        ]);
    }
}
