<?php

namespace App\Http\Controllers;

use App\Models\ClassModel;
use App\Models\User;
use App\Models\Level;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class ClassController extends Controller
{
    /**
     * Display a listing of classes with pagination
     * Admin: sees all classes
     * Teacher: sees only assigned classes
     * Student: sees only enrolled classes
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }
        
        /** @var User $user */
        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $perPage = $request->get('per_page', 10);
        $page = $request->get('page', 1);

        try {
            // Debug logging
            Log::info('Class index request', [
                'user_id' => $user->user_id,
                'role_name' => $user->role?->role_name ?? 'null',
                'role_name_lowercase' => $roleName,
                'total_classes_before_filter' => ClassModel::count(),
            ]);

            $query = ClassModel::with(['teacher', 'admin', 'students']);

            // Role-based filtering (case-insensitive)
            // If role is empty or null, default to showing all classes (admin view)
            if (empty($roleName)) {
                Log::warning('Empty role name detected - showing all classes', [
                    'user_id' => $user->user_id,
                    'role_object' => $user->role ? 'exists' : 'null',
                ]);
                // No filter - show all classes
            } elseif ($roleName === 'teacher') {
                // Teacher sees only classes assigned to them
                $query->where('teacher_id', $user->user_id);
                Log::info('Teacher filter applied', [
                    'teacher_id' => $user->user_id,
                    'classes_with_this_teacher' => ClassModel::where('teacher_id', $user->user_id)->count(),
                ]);
            } elseif ($roleName === 'student') {
                // Student sees only classes they're enrolled in
                $query->whereHas('students', function ($q) use ($user) {
                    $q->where('users.user_id', $user->user_id);
                });
                Log::info('Student filter applied', [
                    'student_id' => $user->user_id,
                ]);
            } else {
                // Admin or unknown role - show all classes
                Log::info('Admin or unknown role - showing all classes', [
                    'role_name' => $roleName,
                    'original_role_name' => $user->role?->role_name ?? 'null',
                ]);
                // No filter - show all classes
            }

            $totalBeforePagination = $query->count();
            Log::info('Query before pagination', [
                'total_count' => $totalBeforePagination,
            ]);

            $classes = $query->orderBy('created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            // Ensure the response has the correct structure
            return response()->json([
                'current_page' => $classes->currentPage(),
                'data' => $classes->items(),
                'first_page_url' => $classes->url(1),
                'from' => $classes->firstItem(),
                'last_page' => $classes->lastPage(),
                'last_page_url' => $classes->url($classes->lastPage()),
                'next_page_url' => $classes->nextPageUrl(),
                'path' => $classes->path(),
                'per_page' => $classes->perPage(),
                'prev_page_url' => $classes->previousPageUrl(),
                'to' => $classes->lastItem(),
                'total' => $classes->total(),
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching classes', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => $user->user_id,
                'role' => $roleName
            ]);
            
            // Return empty paginated response on error
            return response()->json([
                'current_page' => 1,
                'data' => [],
                'first_page_url' => null,
                'from' => null,
                'last_page' => 1,
                'last_page_url' => null,
                'next_page_url' => null,
                'path' => $request->url(),
                'per_page' => $perPage,
                'prev_page_url' => null,
                'to' => null,
                'total' => 0,
            ], 200);
        }
    }

    /**
     * Store a newly created class
     * Only Admin can create classes
     */
    public function store(Request $request): JsonResponse
    {
        $user = Auth::user();
        
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }
        
        /** @var User $user */
        $user->load('role');
        
        // Debug: Log role information
        Log::info('User role check', [
            'user_id' => $user->user_id,
            'role_loaded' => $user->relationLoaded('role'),
            'role_name' => $user->role?->role_name ?? 'null',
        ]);
        
        // Check if user is admin (case-insensitive check)
        $roleName = strtolower(trim($user->role?->role_name ?? ''));
        if ($roleName !== 'admin') {
            return response()->json([
                'message' => 'Unauthorized. Only admins can create classes.',
                'debug' => [
                    'user_role' => $user->role?->role_name ?? 'null',
                    'expected' => 'admin'
                ]
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'class_name' => 'required|string|max:100|unique:classes,class_name',
            'teacher_id' => 'nullable|string|exists:users,user_id',
            'description' => 'nullable|string',
            'admin_id' => 'nullable|string|exists:users,user_id',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'string|exists:users,user_id',
        ], [
            'class_name.unique' => 'A class with this name already exists. Please choose a different name.',
            'class_name.required' => 'Class name is required.',
            'class_name.max' => 'Class name cannot exceed 100 characters.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();

            // Create the class (teacher_id can now be null after migration)
            $class = ClassModel::create([
                'class_id' => (string) Str::uuid(),
                'class_name' => $request->class_name,
                'teacher_id' => $request->teacher_id, // optional, can be null
                'description' => $request->description,
                'admin_id' => $request->admin_id ?? $user->user_id, // Default to current admin
            ]);

            // Enroll students if provided (optional, can be empty)
            if ($request->has('student_ids') && is_array($request->student_ids)) {
                $studentIds = array_filter($request->student_ids); // Remove null values
                if (!empty($studentIds)) {
                    $class->students()->attach($studentIds);
                }
                // If empty array or null, no students are enrolled (nullable)
            }

            DB::commit();

            // Load relationships for response
            $class->refresh();
            $class->load(['teacher', 'admin', 'students']);

            return response()->json([
                'message' => 'Class created successfully',
                'data' => $class
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Failed to create class',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified class
     */
    public function show(string $id): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }
        
        /** @var User $user */
        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $class = ClassModel::with(['teacher', 'admin', 'students'])
            ->find($id);

        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        // Role-based access control (case-insensitive)
        if ($roleName === 'teacher') {
            // Teacher can only see classes assigned to them
            if ($class->teacher_id !== $user->user_id) {
                return response()->json([
                    'message' => 'Unauthorized'
                ], 403);
            }
        } elseif ($roleName === 'student') {
            // Student can only see classes they're enrolled in
            $isEnrolled = $class->students()->where('users.user_id', $user->user_id)->exists();
            if (!$isEnrolled) {
                return response()->json([
                    'message' => 'Unauthorized'
                ], 403);
            }
        }
        // Admin can see all classes

        return response()->json([
            'data' => $class
        ]);
    }

    /**
     * Update the specified class
     * Only Admin can update classes
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }
        
        /** @var User $user */
        $user->load('role');
        
        // Check if user is admin (case-insensitive check)
        $roleName = strtolower(trim($user->role?->role_name ?? ''));
        if ($roleName !== 'admin') {
            return response()->json([
                'message' => 'Unauthorized. Only admins can update classes.'
            ], 403);
        }

        $class = ClassModel::find($id);
        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'class_name' => [
                'sometimes',
                'required',
                'string',
                'max:100',
                'unique:classes,class_name,' . $id . ',class_id'
            ],
            'teacher_id' => 'sometimes|nullable|string|exists:users,user_id',
            'description' => 'nullable|string',
            'admin_id' => 'nullable|string|exists:users,user_id',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'string|exists:users,user_id',
        ], [
            'class_name.unique' => 'A class with this name already exists. Please choose a different name.',
            'class_name.required' => 'Class name is required.',
            'class_name.max' => 'Class name cannot exceed 100 characters.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();

            // Update class fields (teacher_id can now be null to remove teacher assignment)
            $class->update($request->only(['class_name', 'teacher_id', 'description', 'admin_id']));

            // Update enrolled students if provided (can be empty array to clear all)
            if ($request->has('student_ids')) {
                $studentIds = is_array($request->student_ids) 
                    ? array_filter($request->student_ids) // Remove null values
                    : [];
                $class->students()->sync($studentIds); // Empty array clears all enrollments
            }

            DB::commit();

            // Reload relationships
            $class->refresh();
            $class->load(['teacher', 'admin', 'students']);

            return response()->json([
                'message' => 'Class updated successfully',
                'data' => $class
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Failed to update class',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified class
     * Only Admin can delete classes
     */
    public function destroy(string $id): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }
        
        /** @var User $user */
        $user->load('role');
        
        // Check if user is admin (case-insensitive check)
        $roleName = strtolower(trim($user->role?->role_name ?? ''));
        if ($roleName !== 'admin') {
            return response()->json([
                'message' => 'Unauthorized. Only admins can delete classes.'
            ], 403);
        }

        $class = ClassModel::find($id);
        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        try {
            $class->delete();

            return response()->json([
                'message' => 'Class deleted successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to delete class',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get total class count (for statistics)
     */
    public function getCount(): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }
        
        /** @var User $user */
        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $query = ClassModel::query();

        // Role-based filtering (case-insensitive)
        if ($roleName === 'teacher') {
            $query->where('teacher_id', $user->user_id);
        } elseif ($roleName === 'student') {
            $query->whereHas('students', function ($q) use ($user) {
                $q->where('users.user_id', $user->user_id);
            });
        }

        $totalClasses = $query->count();

        return response()->json([
            'total_classes' => $totalClasses
        ]);
    }

    /**
     * Get aggregated class statistics
     * - total_classes
     * - total_assigned_teachers (classes that have a teacher_id)
     * - total_enrolled_students (count of class_student rows)
     */
    public function getStats(): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }
        
        /** @var User $user */
        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $classQuery = ClassModel::query();

        // Role-based filtering (case-insensitive)
        if ($roleName === 'teacher') {
            $classQuery->where('teacher_id', $user->user_id);
        } elseif ($roleName === 'student') {
            $classQuery->whereHas('students', function ($q) use ($user) {
                $q->where('users.user_id', $user->user_id);
            });
        }

        $totalClasses = $classQuery->count();

        // assigned teacher: classes with teacher_id not null
        $assignedTeachers = (clone $classQuery)->whereNotNull('teacher_id')->count();

        // enrolled students: count pivot rows filtered by role scope
        $classIds = (clone $classQuery)->pluck('class_id');
        $enrolledStudents = DB::table('class_student')
            ->whereIn('class_id', $classIds)
            ->count();

        return response()->json([
            'total_classes' => $totalClasses,
            'total_assigned_teachers' => $assignedTeachers,
            'total_enrolled_students' => $enrolledStudents,
        ]);
    }

    /**
     * Get quiz count for a specific class
     */
    public function getQuizCount(string $id): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }

        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $class = ClassModel::find($id);
        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        // Access control: Verify user has permission to view this class's quizzes
        if ($roleName === 'teacher') {
            if ($class->teacher_id !== $user->user_id) {
                return response()->json([
                    'message' => 'Unauthorized'
                ], 403);
            }
        } elseif ($roleName === 'student') {
            $isEnrolled = $class->students()->where('users.user_id', $user->user_id)->exists();
            if (!$isEnrolled) {
                return response()->json([
                    'message' => 'Unauthorized'
                ], 403);
            }
        }

        $quizCount = DB::table('class_levels')
            ->where('class_id', $id)
            ->count();

        return response()->json([
            'total_quizzes' => $quizCount
        ]);
    }

    /**
     * Get all quizzes (levels) assigned to a class
     * Access Control:
     * - Admin: Can see quizzes for any class
     * - Teacher: Can only see quizzes for classes they teach
     * - Student: Can only see quizzes for classes they're enrolled in
     */
    public function getQuizzes(string $id): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }

        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $class = ClassModel::find($id);
        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        // Access control: Verify user has permission to view this class's quizzes
        if ($roleName === 'teacher') {
            // Teacher can only see quizzes for classes they teach
            if ($class->teacher_id !== $user->user_id) {
                return response()->json([
                    'message' => 'Unauthorized. You can only view quizzes for classes you teach.'
                ], 403);
            }
        } elseif ($roleName === 'student') {
            // Student can only see quizzes for classes they're enrolled in
            $isEnrolled = $class->students()->where('users.user_id', $user->user_id)->exists();
            if (!$isEnrolled) {
                return response()->json([
                    'message' => 'Unauthorized. You can only view quizzes for classes you are enrolled in.'
                ], 403);
            }
        }
        // Admin can see quizzes for any class (no check needed)

        // Get levels assigned to this class via pivot table
        $quizzes = DB::table('class_levels')
            ->join('levels', 'class_levels.level_id', '=', 'levels.level_id')
            ->leftJoin('level_types', 'levels.level_type_id', '=', 'level_types.level_type_id')
            ->where('class_levels.class_id', $id)
            ->select(
                'levels.level_id',
                'levels.level_name',
                'levels.created_at',
                'levels.updated_at',
                'level_types.level_type_id',
                'level_types.level_type_name'
            )
            ->orderBy('levels.created_at', 'desc')
            ->get()
            ->map(function ($quiz) {
                return [
                    'level_id' => $quiz->level_id,
                    'level_name' => $quiz->level_name,
                    'level_type' => $quiz->level_type_id ? [
                        'level_type_id' => $quiz->level_type_id,
                        'level_type_name' => $quiz->level_type_name,
                    ] : null,
                    'created_at' => $quiz->created_at,
                    'updated_at' => $quiz->updated_at,
                ];
            });

        return response()->json([
            'data' => $quizzes
        ]);
    }

    /**
     * Assign a quiz (level) to a class
     */
    public function assignQuiz(Request $request, string $id): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }

        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        // Only teachers and admins can assign quizzes
        if ($roleName !== 'teacher' && $roleName !== 'admin') {
            return response()->json([
                'message' => 'Unauthorized. Only teachers and admins can assign quizzes.'
            ], 403);
        }

        $class = ClassModel::find($id);
        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        // Check if teacher owns this class
        if ($roleName === 'teacher' && $class->teacher_id !== $user->user_id) {
            return response()->json([
                'message' => 'Unauthorized. You can only assign quizzes to your own classes.'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'level_id' => 'required|string|exists:levels,level_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // Check if already assigned
        $exists = DB::table('class_levels')
            ->where('class_id', $id)
            ->where('level_id', $request->level_id)
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'Quiz is already assigned to this class'
            ], 422);
        }

        try {
            DB::table('class_levels')->insert([
                'class_level_id' => (string) Str::uuid(),
                'class_id' => $id,
                'level_id' => $request->level_id,
                'is_private' => false, // Default to false (all quizzes are public)
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return response()->json([
                'message' => 'Quiz assigned successfully'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to assign quiz',
                'error' => $e->getMessage()
            ], 500);
        }
    }


    /**
     * Remove a quiz (level) from a class
     */
    public function removeQuiz(string $classId, string $levelId): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'message' => 'Unauthenticated.'
            ], 401);
        }

        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        // Only teachers and admins can remove quizzes
        if ($roleName !== 'teacher' && $roleName !== 'admin') {
            return response()->json([
                'message' => 'Unauthorized. Only teachers and admins can remove quizzes.'
            ], 403);
        }

        $class = ClassModel::find($classId);
        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        // Check if teacher owns this class
        if ($roleName === 'teacher' && $class->teacher_id !== $user->user_id) {
            return response()->json([
                'message' => 'Unauthorized. You can only remove quizzes from your own classes.'
            ], 403);
        }

        $deleted = DB::table('class_levels')
            ->where('class_id', $classId)
            ->where('level_id', $levelId)
            ->delete();

        if ($deleted) {
            return response()->json([
                'message' => 'Quiz removed successfully'
            ]);
        } else {
            return response()->json([
                'message' => 'Quiz not found in this class'
            ], 404);
        }
    }
}

