<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateNotesRequest extends FormRequest
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
            'topic'             => ['required', 'string', 'max:100', 'exists:topics,topic_name'],
            'title'             => ['required', 'string', 'max:255'],
            'file'              => ['required', 'file'], // Enforce file upload
            'visibility'        => ['required', 'boolean'],
        ];
    }

        public function messages(): array
        {
            return [
                'topic.required' => 'The note topic is required.',
                'title.required'            => 'The note title is required.',
                'file_path.required'            =>'The path is required.',
                'visibility.boolean'     => 'The visibility field must be true or false.',
                
            ];
    }
}
