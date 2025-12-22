<?php

namespace App\Imports;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class UsersImport implements ToModel, WithHeadingRow
{
    /**
     * @param array $row
     *
     * @return \Illuminate\Database\Eloquent\Model|null
     */
    public function model(array $row)
    {
        // Skip row if 'email' is empty
        if (empty($row['email'])) {
            return null;
        }

        // Check if user already exists
        $user = User::where('email', $row['email'])->first();

        // If user exists, skip creation
        if ($user) {
            // Option: If you want to update existing users instead of skipping:
            // $user->update([
            //     'name' => $row['name'],
            //     'role_id' => $row['role_id'],
            // ]);
            return null; // Skip creation
        }

        // Generate a temporary password if none is provided in the file
        $password = $row['password'] ?? Str::random(10); 

        // Resolve Role ID
        $roleId = 3; // Default to Student
        
        // 1. Check if 'role' or 'role_name' is provided in the row (prioritize explicit 'role_id' if present, though user asked for name)
        if (isset($row['role_id'])) {
             $roleId = $row['role_id'];
        } elseif (isset($row['role']) || isset($row['role_name'])) {
            $roleNameInput = $row['role'] ?? $row['role_name'];
            
            // Try to find the role in the DB (case-insensitive search)
            $roleRecord = DB::table('roles')
                ->whereRaw('LOWER(role_name) = ?', [strtolower($roleNameInput)])
                ->first();

            if ($roleRecord) {
                $roleId = $roleRecord->role_id;
            }
        }

        return new User([
            'name'     => $row['name'] ?? 'Imported User',
            'email'    => $row['email'],
            'password' => Hash::make($password),
            'role_id'  => $roleId, 
            'user_id' => (string) Str::uuid7(), // Ensure UUID is generated
            'account_status' => 'active', // Default status
            'phone_no' => $row['phone_no'] ?? '-', // Mandatory field fallback
            'address' => $row['address'] ?? '-', // Mandatory field fallback
            'gender' => $row['gender'] ?? '-', // Mandatory field fallback
        ]);
    }
}