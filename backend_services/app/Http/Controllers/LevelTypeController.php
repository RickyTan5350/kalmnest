<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Str;
use App\Models\level_type;

class LevelTypeController extends Controller
{
    /**
     * Handle the POST request for creating a new achievement.
     */
    public function store(Request $request)
    {
        // =================================================================
        // 1. DEBUG LINE: Dump the entire request body and stop execution.
        // This outputs an HTML view of the body to the client (Postman/cURL/Browser).
        // COMMENT OUT OR REMOVE THIS LINE AFTER DEBUGGING!
        // =================================================================


        // 2. Your actual logic (which will not run while dd() is active):
        $validatedData = $request->validate([
            'level_type_name' => 'required'
        ]);

        $validatedData['level_type_id'] = str::uuid7();
        $levelTypeData = level_type::create($validatedData);

        return response()->json($levelTypeData, 201);
    }
    
    // You can keep the index method, but it is not necessary for this debug task.
    // public function index() { ... }
}