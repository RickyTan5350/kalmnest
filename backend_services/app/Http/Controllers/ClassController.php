<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreClassRequest;
use App\Http\Requests\UpdateClassRequest;
use App\Models\ClassModel;
use App\Models\User;
use App\Models\Level;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
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
    public function store(StoreClassRequest $request): JsonResponse
    {
        $user = Auth::user();
        
        try {
            DB::beginTransaction();

            // Create the class (teacher_id can now be null after migration)
            $class = ClassModel::create([
                'class_id' => (string) Str::uuid(),
                'class_name' => $request->class_name,
                'teacher_id' => !empty($request->teacher_id) ? $request->teacher_id : null,
                'description' => $request->description,
                'admin_id' => $request->admin_id ?? $user->user_id,
                'focus' => $request->focus ?? null,
            ]);

            // Enroll students if provided (optional, can be empty)
            if ($request->has('student_ids') && is_array($request->student_ids)) {
                $studentIds = array_filter($request->student_ids);
                if (!empty($studentIds)) {
                    $class->students()->attach($studentIds);
                }
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
            
            Log::error('Error creating class', [
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
                'trace' => $e->getTraceAsString(),
                'request_data' => $request->all(),
            ]);
            
            // Check if it's a unique constraint violation
            $errorCode = $e->getCode();
            $errorMessage = strtolower($e->getMessage());
            
            if ($errorCode == 23000 || 
                (str_contains($errorMessage, 'duplicate entry') && str_contains($errorMessage, 'class_name')) ||
                (str_contains($errorMessage, '1062') && str_contains($errorMessage, 'class_name'))) {
                return response()->json([
                    'message' => 'Validation failed',
                    'errors' => [
                        'class_name' => ['The classname is already exist. Please choose a different name.']
                    ]
                ], 422);
            }
            
            return response()->json([
                'message' => 'Failed to create class',
                'error' => $e->getMessage(),
                'debug' => config('app.debug') ? [
                    'code' => $e->getCode(),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                ] : null
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
    public function update(UpdateClassRequest $request, string $id): JsonResponse
    {
        $class = ClassModel::find($id);
        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        try {
            DB::beginTransaction();

            // Update class fields (only update provided fields)
            $updateData = [];
            
            if ($request->has('class_name')) {
                $updateData['class_name'] = $request->class_name;
            }
            
            if ($request->has('description')) {
                $updateData['description'] = $request->description;
            }
            
            if ($request->has('admin_id')) {
                $updateData['admin_id'] = $request->admin_id;
            }
            
            if ($request->has('focus')) {
                $updateData['focus'] = !empty($request->focus) ? $request->focus : null;
            }
            
            if ($request->has('teacher_id')) {
                $updateData['teacher_id'] = !empty($request->teacher_id) ? $request->teacher_id : null;
            }
            
            if (!empty($updateData)) {
                $class->update($updateData);
            }

            // Update enrolled students if provided (can be empty array to clear all)
            if ($request->has('student_ids')) {
                $studentIds = is_array($request->student_ids) 
                    ? array_filter($request->student_ids)
                    : [];
                $class->students()->sync($studentIds);
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
            
            Log::error('Error updating class', [
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
                'trace' => $e->getTraceAsString(),
                'class_id' => $id,
                'request_data' => $request->all(),
            ]);
            
            // Check if it's a unique constraint violation
            $errorCode = $e->getCode();
            $errorMessage = strtolower($e->getMessage());
            
            if ($errorCode == 23000 || 
                (str_contains($errorMessage, 'duplicate entry') && str_contains($errorMessage, 'class_name')) ||
                (str_contains($errorMessage, '1062') && str_contains($errorMessage, 'class_name'))) {
                return response()->json([
                    'message' => 'Validation failed',
                    'errors' => [
                        'class_name' => ['The classname is already exist. Please choose a different name.']
                    ]
                ], 422);
            }
            
            return response()->json([
                'message' => 'Failed to update class',
                'error' => $e->getMessage(),
                'debug' => config('app.debug') ? [
                    'code' => $e->getCode(),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                ] : null
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
 /** @var User $user */
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
 /** @var User $user */
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
                'levels.created_by',
                'class_levels.is_private',
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
                    'is_private' => (bool) $quiz->is_private,
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
 /** @var User $user */
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
            'is_private' => 'sometimes|boolean', // Optional: only when creating new quiz
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
            // Determine is_private value:
            // - If is_private is provided (creating new quiz), use it
            // - If not provided (assigning existing quiz), default to false (public)
            $isPrivate = $request->has('is_private') 
                ? (bool) $request->input('is_private', false)
                : false; // Default to public when assigning existing quiz
            
            DB::table('class_levels')->insert([
                'class_level_id' => (string) Str::uuid(),
                'class_id' => $id,
                'level_id' => $request->level_id,
                'is_private' => $isPrivate,
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
 /** @var User $user */
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

    /**
     * Get student completion data for a class
     * Returns completion statistics for all students in the class
     */
    public function getStudentCompletion(string $classId): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }
 /** @var User $user */
        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $class = ClassModel::find($classId);
        if (!$class) {
            return response()->json(['message' => 'Class not found'], 404);
        }

        // Access control: Teacher can only see their own classes, Admin can see all
        if ($roleName === 'teacher' && $class->teacher_id !== $user->user_id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        // Get all quizzes assigned to this class
        $assignedQuizzes = DB::table('class_levels')
            ->where('class_id', $classId)
            ->pluck('level_id')
            ->toArray();

        // Get all students in this class
        $studentsInClass = DB::table('class_student')
            ->where('class_id', $classId)
            ->pluck('student_id')
            ->toArray();

        $completionData = [];
        foreach ($studentsInClass as $studentId) {
            // Count distinct quizzes completed by this student
            $completedQuizzes = DB::table('achievement_user')
                ->join('achievements', 'achievement_user.achievement_id', '=', 'achievements.achievement_id')
                ->where('achievement_user.user_id', $studentId)
                ->whereIn('achievements.associated_level', $assignedQuizzes)
                ->distinct('achievements.associated_level')
                ->count('achievements.associated_level');

            $totalAssignedQuizzes = count($assignedQuizzes);
            $completionPercentage = $totalAssignedQuizzes > 0
                ? ($completedQuizzes / $totalAssignedQuizzes) * 100
                : 0;

            $completionData[] = [
                'user_id' => $studentId,
                'completed_quizzes' => $completedQuizzes,
                'total_quizzes' => $totalAssignedQuizzes,
                'completion_percentage' => round($completionPercentage, 2),
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $completionData,
            'total_quizzes_assigned' => count($assignedQuizzes),
        ]);
    }

    /**
     * Get student's quiz completion status for all quizzes in a class
     * Returns list of quizzes with completion status for a specific student
     */
    public function getStudentQuizzes(string $classId, string $studentId): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }
 /** @var User $user */
        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $class = ClassModel::find($classId);
        if (!$class) {
            return response()->json(['message' => 'Class not found'], 404);
        }

        // Access control: Teacher can only see their own classes, Admin can see all
        if ($roleName === 'teacher' && $class->teacher_id !== $user->user_id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        // Verify student is enrolled in this class
        $isEnrolled = DB::table('class_student')
            ->where('class_id', $classId)
            ->where('student_id', $studentId)
            ->exists();

        if (!$isEnrolled) {
            return response()->json(['message' => 'Student not enrolled in this class'], 404);
        }

        // Get all quizzes assigned to this class
        $quizzes = DB::table('class_levels')
            ->join('levels', 'class_levels.level_id', '=', 'levels.level_id')
            ->leftJoin('level_types', 'levels.level_type_id', '=', 'level_types.level_type_id')
            ->where('class_levels.class_id', $classId)
            ->select(
                'levels.level_id',
                'levels.level_name',
                'levels.created_at',
                'levels.updated_at',
                'class_levels.is_private',
                'level_types.level_type_id',
                'level_types.level_type_name'
            )
            ->orderBy('levels.created_at', 'desc')
            ->get();

        // Get all achievements (completed quizzes) for this student
        $completedLevelIds = DB::table('achievement_user')
            ->join('achievements', 'achievement_user.achievement_id', '=', 'achievements.achievement_id')
            ->where('achievement_user.user_id', $studentId)
            ->whereNotNull('achievements.associated_level')
            ->pluck('achievements.associated_level')
            ->toArray();

        // Map quizzes with completion status
        $quizData = $quizzes->map(function ($quiz) use ($completedLevelIds, $studentId) {
            $isCompleted = in_array($quiz->level_id, $completedLevelIds);
            
            // Get completion date if completed
            $completionDate = null;
            if ($isCompleted) {
                $achievement = DB::table('achievement_user')
                    ->join('achievements', 'achievement_user.achievement_id', '=', 'achievements.achievement_id')
                    ->where('achievement_user.user_id', $studentId)
                    ->where('achievements.associated_level', $quiz->level_id)
                    ->orderBy('achievement_user.created_at', 'desc')
                    ->first();
                
                if ($achievement) {
                    $completionDate = $achievement->created_at;
                }
            }

            return [
                'level_id' => $quiz->level_id,
                'level_name' => $quiz->level_name,
                'level_type' => $quiz->level_type_id ? [
                    'level_type_id' => $quiz->level_type_id,
                    'level_type_name' => $quiz->level_type_name,
                ] : null,
                'is_private' => (bool) $quiz->is_private,
                'created_at' => $quiz->created_at,
                'updated_at' => $quiz->updated_at,
                'is_completed' => $isCompleted,
                'completion_date' => $completionDate,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $quizData,
            'total_quizzes' => $quizData->count(),
            'completed_quizzes' => $quizData->where('is_completed', true)->count(),
        ]);
    }

    /**
     * Get quiz's student completion status for all students in a class
     * Returns list of students with completion status for a specific quiz
     */
    public function getQuizStudents(string $classId, string $levelId): JsonResponse
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }
 /** @var User $user */
        $user->load('role');
        $roleName = strtolower(trim($user->role?->role_name ?? ''));

        $class = ClassModel::find($classId);
        if (!$class) {
            return response()->json(['message' => 'Class not found'], 404);
        }

        // Access control: Teacher can only see their own classes, Admin can see all
        if ($roleName === 'teacher' && $class->teacher_id !== $user->user_id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        // Verify quiz is assigned to this class
        $isAssigned = DB::table('class_levels')
            ->where('class_id', $classId)
            ->where('level_id', $levelId)
            ->exists();

        if (!$isAssigned) {
            return response()->json(['message' => 'Quiz not assigned to this class'], 404);
        }

        // Get quiz info
        $quiz = DB::table('levels')
            ->leftJoin('level_types', 'levels.level_type_id', '=', 'level_types.level_type_id')
            ->where('levels.level_id', $levelId)
            ->select(
                'levels.level_id',
                'levels.level_name',
                'levels.created_at',
                'levels.updated_at',
                'level_types.level_type_id',
                'level_types.level_type_name'
            )
            ->first();

        if (!$quiz) {
            return response()->json(['message' => 'Quiz not found'], 404);
        }

        // Get all students in this class
        $students = DB::table('class_student')
            ->join('users', 'class_student.student_id', '=', 'users.user_id')
            ->where('class_student.class_id', $classId)
            ->select(
                'users.user_id',
                'users.name',
                'users.email',
                'users.phone_no'
            )
            ->orderBy('users.name')
            ->get();

        // Get all students who completed this quiz
        $completedStudentIds = DB::table('achievement_user')
            ->join('achievements', 'achievement_user.achievement_id', '=', 'achievements.achievement_id')
            ->where('achievements.associated_level', $levelId)
            ->pluck('achievement_user.user_id')
            ->toArray();

        // Map students with completion status
        $studentData = $students->map(function ($student) use ($completedStudentIds, $levelId) {
            $isCompleted = in_array($student->user_id, $completedStudentIds);
            
            // Get completion date if completed
            $completionDate = null;
            if ($isCompleted) {
                $achievement = DB::table('achievement_user')
                    ->join('achievements', 'achievement_user.achievement_id', '=', 'achievements.achievement_id')
                    ->where('achievement_user.user_id', $student->user_id)
                    ->where('achievements.associated_level', $levelId)
                    ->orderBy('achievement_user.created_at', 'desc')
                    ->first();
                
                if ($achievement) {
                    $completionDate = $achievement->created_at;
                }
            }

            return [
                'user_id' => $student->user_id,
                'name' => $student->name,
                'email' => $student->email,
                'phone_no' => $student->phone_no,
                'is_completed' => $isCompleted,
                'completion_date' => $completionDate,
            ];
        });

        return response()->json([
            'success' => true,
            'quiz' => [
                'level_id' => $quiz->level_id,
                'level_name' => $quiz->level_name,
                'level_type' => $quiz->level_type_id ? [
                    'level_type_id' => $quiz->level_type_id,
                    'level_type_name' => $quiz->level_type_name,
                ] : null,
                'created_at' => $quiz->created_at,
                'updated_at' => $quiz->updated_at,
            ],
            'data' => $studentData,
            'total_students' => $studentData->count(),
            'completed_students' => $studentData->where('is_completed', true)->count(),
        ]);
    }

    /**
     * Check if class name exists (case-insensitive)
     * Used for real-time validation in frontend
     */
    public function checkClassNameExists(Request $request): JsonResponse
    {
        $className = $request->input('class_name');
        
        if (empty($className)) {
            return response()->json([
                'exists' => false,
                'message' => 'Class name is required'
            ], 400);
        }

        // Check if class name exists (case-insensitive)
        $exists = ClassModel::whereRaw('LOWER(class_name) = LOWER(?)', [trim($className)])
            ->exists();

        return response()->json([
            'exists' => $exists,
            'class_name' => $className
        ]);
    }

    /**
     * Bulk delete classes
     * Only Admin can delete classes
     */
    public function bulkDelete(Request $request): JsonResponse
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

        $validator = Validator::make($request->all(), [
            'class_ids' => 'required|array|min:1',
            'class_ids.*' => 'required|string|exists:classes,class_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $classIds = $request->input('class_ids', []);
        $deletedCount = 0;
        $failedIds = [];

        try {
            foreach ($classIds as $classId) {
                $class = ClassModel::find($classId);
                if ($class) {
                    $class->delete();
                    $deletedCount++;
                } else {
                    $failedIds[] = $classId;
                }
            }

            return response()->json([
                'message' => "Successfully deleted $deletedCount class(es)",
                'deleted_count' => $deletedCount,
                'failed_ids' => $failedIds,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to delete classes',
                'error' => $e->getMessage(),
                'deleted_count' => $deletedCount,
                'failed_ids' => $failedIds,
            ], 500);
        }
    }

    /**
     * Update class focus (Teacher only - can only update focus)
     */
    public function updateClassFocus(Request $request, string $id): JsonResponse
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
        
        // Only teachers can update focus
        if ($roleName !== 'teacher') {
            return response()->json([
                'message' => 'Unauthorized. Only teachers can update class focus.'
            ], 403);
        }

        $class = ClassModel::find($id);
        if (!$class) {
            return response()->json([
                'message' => 'Class not found'
            ], 404);
        }

        // Check if teacher owns this class
        if ($class->teacher_id !== $user->user_id) {
            return response()->json([
                'message' => 'Unauthorized. You can only update focus for your own classes.'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'focus' => 'nullable|string|in:HTML,CSS,JavaScript,PHP',
        ], [
            'focus.in' => 'Focus must be one of: HTML, CSS, JavaScript, PHP.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $class->focus = $request->focus ?? null;
            $class->save();

            // Reload relationships
            $class->refresh();
            $class->load(['teacher', 'admin', 'students']);

            return response()->json([
                'message' => 'Class focus updated successfully',
                'data' => $class
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to update class focus',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

