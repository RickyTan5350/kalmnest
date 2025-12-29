<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class GetGeminiResponseRequest extends FormRequest
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
     */
    public function rules(): array
    {
        return [
            'message' => 'required|string|max:1000',
            'session_id' => 'nullable|uuid',
        ];
    }
}
