<?php

namespace App\Imports;

use App\Models\User;
use App\Models\Role;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;

class UsersImport implements ToModel, WithHeadingRow, WithValidation, SkipsEmptyRows
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

        // 1. Find the role by name (e.g. "Student" or "student")
        // We assume the user creates a column header 'role' in Excel
        $roleName = $row['role'] ?? $row['role_name'] ?? null;
        
        $role = Role::where('role_name', $roleName)->first();

        // If role doesn't exist, we fallback to a default (e.g., Student) or skip
        // Ideally handled by validation, but here we can be safe.
        // Let's assume Role ID 3 is Student if lookup fails, OR return null.
        if (!$role) {
             // Try to find 'Student' role as fallback
             $role = Role::where('role_name', 'Student')->first();
        }
        
        $roleId = $role ? $role->role_id : null;

        if (!$roleId) return null; // Can't create user without role

        // Generate a temporary password if none is provided in the file
        $password = $row['password'] ?? Str::random(10); 

        return new User([
            'user_id'      => (string) Str::uuid(), // Generate UUID manually
            'name'         => $row['name'],
            'email'        => $row['email'],
            'password'     => Hash::make($password),
            'role_id'      => $roleId,
            'account_status' => 'active', 
            
            // Optional fields (Must default to 'N/A' as DB columns are not nullable)
            'phone_no'     => $row['phone_no'] ?? 'N/A',
            'address'      => $row['address'] ?? 'N/A',
            'gender'       => $row['gender'] ?? 'N/A',
        ]);
    }

    public function rules(): array
    {
        return [
            'name'      => 'required',
            'email'     => 'required|email|unique:users,email',
            // 'role' validation handled in model() to avoid SQL syntax errors
        ];
    }
}