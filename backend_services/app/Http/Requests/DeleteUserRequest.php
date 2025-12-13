<?php

namespace App\Http\Requests;

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeleteUserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     * Logic: Only Admin can delete another user.
     */
    public function authorize(): bool
    {
        // 1. Check if user is logged in
        if (!Auth::check()) {
            return false;
        }

        // 2. Verify Admin Role
        $userRoleName = DB::table('users')
                            ->join('roles', 'users.role_id', '=', 'roles.role_id')
                            ->where('users.user_id', Auth::id())
                            ->value('roles.role_name');

        $isAdmin = $userRoleName === 'Admin';
        $isSelfDeletion = $this->route('user')->user_id === Auth::id();

        // Admin can delete any user, but not themselves.
        $canDelete = $isAdmin && !$isSelfDeletion;

        if ($isAdmin && $isSelfDeletion) {
             Log::warning('USER_DELETE_AUTH_FAIL: Admin ' . Auth::id() . ' attempted self-deletion.');
        }

        return $canDelete;
    }

protected function failedAuthorization()
    {
        Log::warning('USER_DELETE_AUTH_FAIL: Unauthorized attempt by User ' . (Auth::id() ?? 'Guest'));
        
        // This clear message explains both rules: Admin-only AND no self-deletion.
        throw new AuthorizationException('Forbidden: Only Admins can delete other user accounts, and an Admin cannot delete their own account.');
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [];
    }
}