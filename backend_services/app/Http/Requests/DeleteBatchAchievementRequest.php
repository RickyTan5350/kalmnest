<?php

namespace App\Http\Requests;

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeleteBatchAchievementRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     * Logic: Only Admin or Teacher can delete.
     */
    public function authorize(): bool
    {
        if (!Auth::check()) return false;

        $userRoleName = DB::table('users')
                            ->join('roles', 'users.role_id', '=', 'roles.role_id')
                            ->where('users.user_id', Auth::id())
                            ->value('roles.role_name');

        return $userRoleName === 'Admin' || $userRoleName === 'Teacher';
    }

    protected function failedAuthorization()
    {
        // 1. Log the attempt
        Log::warning('ACHIEVEMENT_AUTH_FAIL: Unauthorized attempt by User ' . (Auth::id() ?? 'Guest'));

        // 2. Throw the standard exception (which triggers the 403)
        throw new AuthorizationException('You do not have permission to perform this action.');
    }

    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'ids'   => ['required', 'array', 'min:1'], // Must be an array with at least 1 item
            'ids.*' => ['required', 'string'], // Ensure every item in the array is a string (UUID)
        ];
    }

    public function messages(): array
    {
        return [
            'ids.required' => 'You must select at least one achievement to delete.',
            'ids.array'    => 'Invalid data format. Expected a list of IDs.',
        ];
    }
}