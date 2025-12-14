<?php

namespace App\Http\Requests;

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class UpdateAchievementRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // 1. Check if user is logged in
        if (!Auth::check()) {
            return false;
        }

        // 2. Verify Admin or Teacher Role
        // This query matches the logic used in your Controller
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
        // Get the ID from the route parameter: /api/achievements/update/{id}
        // defined in api.php as Route::put('/update/{id}', ...)
        $achievementId = $this->route('id');

        return [
            'achievement_name' => [
                'sometimes', 
                'string', 
                'max:100',
                // Unique in 'achievements' table, but IGNORE the current record's ID
                Rule::unique('achievements', 'achievement_name')->ignore($achievementId, 'achievement_id')
            ],
            'title' => [
                'sometimes', 
                'string', 
                'max:255',
                // Unique in 'achievements' table, but IGNORE the current record's ID
                Rule::unique('achievements', 'title')->ignore($achievementId, 'achievement_id')
            ],
            'description'      => ['sometimes', 'string'],
            'icon'             => ['sometimes', 'string', 'max:255'],
            
            // Using strict validation similar to CreateRequest, but 'sometimes'
            'associated_level' => ['nullable', 'uuid', 'exists:levels,level_id'],
        ];
    }

    /**
     * Custom messages for validation errors.
     */
    public function messages(): array
    {
        return [
            'achievement_name.unique' => 'Another achievement already uses this name.',
            'title.unique'            => 'Another achievement already uses this title.',
            'associated_level.exists' => 'The selected associated level ID does not exist.',
            'associated_level.uuid'   => 'The associated level must be a valid UUID.',
        ];
    }
}