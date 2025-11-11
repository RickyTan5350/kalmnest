<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateAchievementRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'achievement_name' => ['required', 'string', 'max:100'],
            'title'            => ['required', 'string', 'max:255'],
            'description'      => ['required', 'string'],
            
            // Optional field. Must be a valid UUID or NULL.
            // Assuming your 'levels' table has a 'level_id' column for the UUID check.
            'associated_level' => ['nullable', 'uuid', 'exists:levels,level_id']
        ];
    }

        public function messages(): array
        {
            return [
                'achievement_name.required' => 'The Achievement Name field is required.',
                'title.required'            => 'A short Title for the achievement is required.',
                'description.required'      => 'A detailed Description of the achievement is required.',
                'associated_level.uuid'     => 'The associated level must be a valid ID format.',
                'associated_level.exists'   => 'The selected associated level ID does not exist in the system.',
            ];
        }
}
