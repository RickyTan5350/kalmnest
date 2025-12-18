# Quiz Access Control Implementation

## Overview

Quizzes in a class are only accessible to students who are enrolled in that class. This document explains how access control is implemented.

## Access Control Rules

### 1. **Admin**
- ✅ Can view quizzes for **any class**
- ✅ Can assign/remove quizzes from **any class**
- ✅ No restrictions

### 2. **Teacher**
- ✅ Can view quizzes only for **classes they teach** (where `teacher_id` matches their `user_id`)
- ✅ Can assign/remove quizzes only from **classes they teach**
- ❌ Cannot access quizzes for classes they don't teach

### 3. **Student**
- ✅ Can view quizzes only for **classes they are enrolled in** (via `class_student` pivot table)
- ✅ Can play quizzes only for **classes they are enrolled in**
- ❌ Cannot access quizzes for classes they are not enrolled in

## Implementation Details

### Backend Access Control (`ClassController::getQuizzes`)

The access control is enforced in the backend API endpoint `GET /api/classes/{classId}/quizzes`:

```php
public function getQuizzes(string $id): JsonResponse
{
    $user = Auth::user();
    $user->load('role');
    $roleName = strtolower(trim($user->role?->role_name ?? ''));

    $class = ClassModel::find($id);
    
    // Access control checks:
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
    
    // Return quizzes if access is granted
    // ...
}
```

### How It Works

1. **Authentication**: User must be authenticated (has valid token)
2. **Role Check**: System checks the user's role (admin, teacher, or student)
3. **Permission Verification**:
   - **Teacher**: Checks if `class.teacher_id === user.user_id`
   - **Student**: Checks if student exists in `class_student` pivot table for this class
   - **Admin**: No check needed (full access)
4. **Response**: 
   - If authorized: Returns quiz list (HTTP 200)
   - If unauthorized: Returns error message (HTTP 403)

### Frontend Implementation

The frontend quiz list sections automatically fetch quizzes from the API:

```dart
// In QuizListSection widget
Future<void> _fetchQuizzes() async {
  final quizzes = await ClassApi.getClassQuizzes(widget.classId);
  // If student is not enrolled, API returns 403 error
  // Frontend handles error gracefully
}
```

### Security Layers

1. **Backend API**: Primary security layer - enforces access control
2. **Frontend**: Secondary layer - only shows classes/quizzes user has access to
3. **Database**: Foreign key constraints ensure data integrity

## Example Scenarios

### Scenario 1: Student Enrolled in Class
- Student A is enrolled in Class X
- Student A can view and play quizzes in Class X ✅
- API returns quiz list successfully

### Scenario 2: Student NOT Enrolled in Class
- Student B is NOT enrolled in Class Y
- Student B tries to access quizzes in Class Y
- Backend returns HTTP 403 (Forbidden)
- Frontend shows error or empty state

### Scenario 3: Teacher Teaching Class
- Teacher C teaches Class Z
- Teacher C can view, create, assign, and remove quizzes in Class Z ✅
- API returns quiz list successfully

### Scenario 4: Teacher NOT Teaching Class
- Teacher D does NOT teach Class W
- Teacher D tries to access quizzes in Class W
- Backend returns HTTP 403 (Forbidden)
- Frontend shows error message

## Database Structure

The access control relies on these database relationships:

1. **Classes Table** (`classes`)
   - `class_id` (primary key)
   - `teacher_id` (foreign key to `users.user_id`)

2. **Class-Student Pivot Table** (`class_student`)
   - `class_id` (foreign key to `classes.class_id`)
   - `student_id` (foreign key to `users.user_id`)

3. **Class-Levels Pivot Table** (`class_levels`)
   - `class_id` (foreign key to `classes.class_id`)
   - `level_id` (foreign key to `levels.level_id`)

## Testing Access Control

To test access control:

1. **As Student**:
   - Try accessing a class you're enrolled in → Should work ✅
   - Try accessing a class you're NOT enrolled in → Should return 403 ❌

2. **As Teacher**:
   - Try accessing a class you teach → Should work ✅
   - Try accessing a class you don't teach → Should return 403 ❌

3. **As Admin**:
   - Try accessing any class → Should work ✅

## Important Notes

- Access control is enforced at the **API level**, not just the frontend
- Even if someone bypasses the frontend, the backend will reject unauthorized requests
- The `class_student` pivot table is the source of truth for student enrollment
- The `classes.teacher_id` field is the source of truth for teacher assignment

