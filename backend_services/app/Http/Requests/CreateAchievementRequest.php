<?php


namespace App\Http\Requests;

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Log;

class CreateAchievementRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
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
            // Added 'unique:achievements,achievement_name'
            'achievement_name' => [
                'required', 
                'string', 
                'max:100', 
                'unique:achievements,achievement_name' 
            ],
            
            // Added 'unique:achievements,title'
            'title' => [
                'required', 
                'string', 
                'max:255', 
                'unique:achievements,title'
            ],
            
            'description'      => ['required', 'string'],
            'icon'             => ['required', 'string'],
            'associated_level' => ['nullable', 'uuid', 'exists:levels,level_id']
        ];
    }

    public function messages(): array
    {
        return [
            'achievement_name.required' => 'The Achievement Name field is required.',
            'achievement_name.unique'   => 'An achievement with this name already exists.', // Custom Message
            'title.required'            => 'A short Title for the achievement is required.',
            'title.unique'              => 'An achievement with this title already exists.', // Custom Message
            'description.required'      => 'A detailed Description of the achievement is required.',
            'associated_level.uuid'     => 'The associated level must be a valid ID format.',
            'associated_level.exists'   => 'The selected associated level ID does not exist in the system.',
        ];
    }
}