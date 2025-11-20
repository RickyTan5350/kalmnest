<?php
namespace App\Http\Controllers;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use App\Models\ClassModel;
use Illuminate\Validation\ValidationException;

class ClassController extends Controller
{
    // existing web methods (index, create, store) can remain for Blade usage

    // -------- API methods (JSON) --------
 public function indexApi(Request $request)
{
    // number of items per page
    $perPage = $request->input('per_page', 5);   // default = 5

    // paginate results
    $classes = ClassModel::paginate($perPage);

    return response()->json($classes, 200);
}


    public function showApi($id)
    {
        $class = ClassModel::find($id);
        if (!$class) {
            return response()->json(['message' => 'Not found'], 404);
        }
        return response()->json(['data' => $class], 200);
    }

   public function storeApi(Request $request)
{
    // DEBUG LOGS
    Log::info('🔥 storeApi called');
    Log::info('Incoming API data: ' . json_encode($request->all()));

    $validated = $request->validate([
        'class_name' => 'required|string|max:100',
        'teacher_id' => 'required|integer',
        'description' => 'nullable|string',
        'admin_id'   => 'required|integer',
    ]);

    try {
        $newClass = ClassModel::create($validated);

        Log::info('✔️ Class created: ' . json_encode($newClass));

        return response()->json([
            'message' => 'Class created successfully',
            'data' => $newClass
        ], 201);
        
    } catch (\Exception $e) {
        Log::error('❌ Class store error: '.$e->getMessage());
        return response()->json(['message' => 'Server error'], 500);
    }
}

    public function updateApi(Request $request, $id)
    {
        $class = ClassModel::find($id);
        if (!$class) return response()->json(['message' => 'Not found'], 404);

        $validated = $request->validate([
            'class_name' => 'sometimes|required|string|max:100',
            'teacher_id' => 'sometimes|required|integer',
            'description' => 'nullable|string',
            'admin_id' => 'sometimes|required|integer',
        ]);

        $class->update($validated);
        return response()->json(['message' => 'Updated', 'data' => $class], 200);
    }

    public function destroyApi($id)
    {
        $class = ClassModel::find($id);
        if (!$class) return response()->json(['message' => 'Not found'], 404);

        $class->delete();
        return response()->json(['message' => 'Deleted'], 200);
    }
}
