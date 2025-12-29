# Class & Game Module Integration - Implementation Plan

## Analysis Summary

### Current State

1. **Students can create games** - `game_page.dart` shows "Add Level" button for all non-students, but students can still access create game through main.dart (case 1)
2. **Game visibility** - All games are public, shown to everyone in game page
3. **Private/Public logic exists** - `class_levels` table has `is_private` field, but not fully implemented
4. **No creator tracking** - Levels table doesn't track who created the game
5. **No visibility filtering** - Game page shows all levels without filtering by private/public status

### Requirements

1. ✅ **Block students from creating games** - Students should not access create game function
2. ✅ **Teacher can create private games in class** - When creating game in class context, teacher can choose private/public
3. ✅ **Private game visibility**:
   - Only visible to teacher who created it (in game page with status indicator)
   - Students can only access through their enrolled class
   - Not visible to admin, other teachers, or other students
4. ✅ **Public game visibility**:
   - Visible to everyone in game page
   - Can be assigned to multiple classes

---

## Implementation Plan

### Phase 1: Database Changes

#### 1.1 Add `created_by` to `levels` table

**Purpose**: Track which teacher created the game

```php
// Migration: add_created_by_to_levels_table.php
Schema::table('levels', function (Blueprint $table) {
    $table->uuid('created_by')->nullable()->after('level_type_id');
    $table->foreign('created_by')
          ->references('user_id')
          ->on('users')
          ->onDelete('set null');
});
```

#### 1.2 Verify `is_private` exists in `class_levels`

**Check**: Migration should already exist from previous implementation

- If exists: ✅ Good
- If not: Create migration to add `is_private` boolean field

---

### Phase 2: Backend API Changes

#### 2.1 Update `LevelController::store()`

**File**: `backend_services/app/Http/Controllers/LevelController.php`

**Changes**:

- Add `created_by` field when creating level
- Get current user from auth
- Only allow teachers/admins to create

```php
public function store(Request $request)
{
    $user = Auth::user();
    if (!$user) {
        return response()->json(['error' => 'Unauthenticated'], 401);
    }

    $user->load('role');
    $roleName = strtolower(trim($user->role?->role_name ?? ''));

    // Only teachers and admins can create games
    if ($roleName !== 'teacher' && $roleName !== 'admin') {
        return response()->json(['error' => 'Unauthorized. Only teachers and admins can create games.'], 403);
    }

    // ... existing validation ...

    $dataToBePassed = [
        'level_name' => $request->level_name,
        'level_type_id' => $levelType->level_type_id,
        'level_data' => json_encode($finalLevelData, JSON_PRETTY_PRINT),
        'win_condition' => json_encode($finalWinData, JSON_PRETTY_PRINT),
        'created_by' => $user->user_id, // Add this
    ];

    // ... rest of the code ...
}
```

#### 2.2 Update `LevelController::index()` - Filter by Visibility

**File**: `backend_services/app/Http/Controllers/LevelController.php`

**Changes**:

- Filter levels based on user role and visibility
- Return visibility status for each level

```php
public function index(Request $request)
{
    $user = Auth::user();
    $topic = $request->query('topic');

    $user->load('role');
    $roleName = strtolower(trim($user->role?->role_name ?? ''));

    $query = Level::with(['level_type', 'classes' => function($q) {
        $q->select('class_levels.level_id', 'class_levels.is_private', 'classes.class_id');
    }]);

    if ($topic && $topic != 'All') {
        $query->whereHas('level_type', function ($q) use ($topic) {
            $q->where('level_type_name', $topic);
        });
    }

    // Filter based on role and visibility
    if ($roleName === 'student') {
        // Students: Only see public games OR private games from their enrolled classes
        $query->where(function($q) use ($user) {
            // Public games (not in any class_levels with is_private=true)
            $q->whereDoesntHave('classes', function($subQ) {
                $subQ->where('class_levels.is_private', true);
            })
            // OR private games from enrolled classes
            ->orWhereHas('classes', function($subQ) use ($user) {
                $subQ->where('class_levels.is_private', true)
                      ->whereHas('students', function($studentQ) use ($user) {
                          $studentQ->where('users.user_id', $user->user_id);
                      });
            });
        });
    } elseif ($roleName === 'teacher') {
        // Teachers: See public games OR private games they created
        $query->where(function($q) use ($user) {
            // Public games
            $q->whereDoesntHave('classes', function($subQ) {
                $subQ->where('class_levels.is_private', true);
            })
            // OR private games created by this teacher
            ->orWhere('created_by', $user->user_id);
        });
    }
    // Admin: See all games (no filter)

    $levels = $query->get()->map(function ($level) use ($user) {
        // Determine if this level is private
        $isPrivate = $level->classes->where('is_private', true)->isNotEmpty();
        $isCreatedByMe = $level->created_by === $user->user_id;

        return [
            'level_id' => $level->level_id,
            'level_name' => $level->level_name,
            'level_type' => $level->level_type ? [
                'level_type_id' => $level->level_type->level_type_id,
                'level_type_name' => $level->level_type->level_type_name,
            ] : null,
            'is_private' => $isPrivate,
            'is_created_by_me' => $isCreatedByMe,
            'status' => $isPrivate ? 'private' : 'public', // For frontend display
        ];
    });

    return response()->json($levels);
}
```

#### 2.3 Update `ClassController::assignQuiz()` - Accept `is_private` Parameter

**File**: `backend_services/app/Http/Controllers/ClassController.php`

**Changes**:

- Accept `is_private` parameter in request
- Store it in `class_levels` table

```php
public function assignQuiz(Request $request, string $id): JsonResponse
{
    // ... existing validation ...

    $validator = Validator::make($request->all(), [
        'level_id' => 'required|string|exists:levels,level_id',
        'is_private' => 'boolean', // Add this
    ]);

    // ... existing checks ...

    try {
        DB::table('class_levels')->insert([
            'class_level_id' => (string) Str::uuid(),
            'class_id' => $id,
            'level_id' => $request->level_id,
            'is_private' => $request->input('is_private', false), // Use request value
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // ... rest of code ...
    }
}
```

#### 2.4 Add Relationship to Level Model

**File**: `backend_services/app/Models/level.php`

```php
// Add to Level model
public function classes()
{
    return $this->belongsToMany(ClassModel::class, 'class_levels', 'level_id', 'class_id')
                ->withPivot('is_private', 'created_at', 'updated_at')
                ->withTimestamps();
}

public function creator()
{
    return $this->belongsTo(User::class, 'created_by', 'user_id');
}
```

---

### Phase 3: Frontend Changes

#### 3.1 Block Student Access to Create Game

**File**: `flutter_codelab/lib/main.dart`

**Change**: Add role check before showing create game page

```dart
case 1:
  // Block students from creating games
  if (widget.currentUser.isStudent) {
    _showSnackBar(
      context,
      'Students cannot create games. This is for Teachers and Admins only.',
      Theme.of(context).colorScheme.error,
    );
  } else {
    showCreateGamePage(
      context: context,
      showSnackBar: _showSnackBar,
      userRole: widget.currentUser.roleName,
    );
  }
  break;
```

**File**: `flutter_codelab/lib/pages/game_page.dart`

**Change**: Already has check `if (!isStudent)` for Add Level button - ✅ Good

#### 3.2 Update Game Page - Show Status Badge

**File**: `flutter_codelab/lib/pages/game_page.dart`

**Changes**:

- Display status badge (Private/Public) for each game
- Show private games at top with indicator

```dart
// In ListTile, add status badge
Row(
  children: [
    Expanded(
      child: Text(level.levelName ?? ''),
    ),
    // Add status badge
    if (level.isPrivate ?? false)
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 14, color: Colors.orange),
            SizedBox(width: 4),
            Text('Private', style: TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        ),
      )
    else
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, size: 14, color: Colors.blue),
            SizedBox(width: 4),
            Text('Public', style: TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
      ),
  ],
)
```

#### 3.3 Update Level Model

**File**: `flutter_codelab/lib/models/level.dart`

**Add fields**:

```dart
final bool? isPrivate;
final bool? isCreatedByMe;
final String? status; // 'private' or 'public'

LevelModel({
  // ... existing fields ...
  this.isPrivate,
  this.isCreatedByMe,
  this.status,
});

// Update fromJson
factory LevelModel.fromJson(Map<String, dynamic> json) {
  return LevelModel(
    // ... existing fields ...
    isPrivate: json['is_private'] as bool?,
    isCreatedByMe: json['is_created_by_me'] as bool?,
    status: json['status'] as String?,
  );
}
```

#### 3.4 Update Teacher Quiz Page - Add Private/Public Selection

**File**: `flutter_codelab/lib/admin_teacher/widgets/class/teacher_view_quiz_page.dart`

**Changes**:

- When assigning quiz, ask teacher: "Private or Public?"
- Pass `is_private` parameter to API

```dart
Future<void> _handleAssignQuiz() async {
  // ... existing code to select level ...

  if (selectedLevel != null) {
    // Ask teacher: Private or Public?
    final isPrivate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiz Visibility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How should this quiz be visible?'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.orange),
              title: Text('Private'),
              subtitle: Text('Only visible to this class'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: Icon(Icons.public, color: Colors.blue),
              title: Text('Public'),
              subtitle: Text('Visible to everyone, can be assigned to other classes'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (isPrivate == null) return; // User cancelled

    final result = await ClassApi.assignQuizToClass(
      classId: widget.classId,
      levelId: selectedLevel.levelId!,
      isPrivate: isPrivate, // Pass this parameter
    );

    // ... rest of code ...
  }
}
```

#### 3.5 Update ClassApi - Add `is_private` Parameter

**File**: `flutter_codelab/lib/api/class_api.dart`

**Update `assignQuizToClass` method**:

```dart
static Future<Map<String, dynamic>> assignQuizToClass({
  required String classId,
  required String levelId,
  bool isPrivate = false, // Add this parameter
}) async {
  // ... existing code ...

  final response = await http.post(
    Uri.parse('$baseUrl/classes/$classId/quizzes'),
    headers: headers,
    body: jsonEncode({
      'level_id': levelId,
      'is_private': isPrivate, // Add this
    }),
  );

  // ... rest of code ...
}
```

#### 3.6 Update Create Quiz Flow in Class Context

**File**: `flutter_codelab/lib/admin_teacher/widgets/class/teacher_view_quiz_page.dart`

**Changes**:

- After creating game, immediately ask to assign as private/public
- Streamline the flow

```dart
Future<void> _handleCreateQuiz() async {
  // Open create game page
  showCreateGamePage(
    context: context,
    userRole: widget.roleName,
    showSnackBar: _showSnackBar,
  );

  // Wait for game creation
  await Future.delayed(const Duration(seconds: 3));

  // Refresh levels
  final allLevels = await GameAPI.fetchLevels(forceRefresh: true);

  if (!mounted || allLevels.isEmpty) return;

  // Get the most recently created level (assuming it's the last one)
  final newLevel = allLevels.first;

  // Ask teacher: Assign as Private or Public?
  final isPrivate = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Assign Quiz to Class'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quiz "${newLevel.levelName}" created successfully!'),
          SizedBox(height: 16),
          Text('How should this quiz be visible?'),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.orange),
            title: Text('Private'),
            subtitle: Text('Only visible to this class'),
            onTap: () => Navigator.pop(context, true),
          ),
          ListTile(
            leading: Icon(Icons.public, color: Colors.blue),
            title: Text('Public'),
            subtitle: Text('Visible to everyone'),
            onTap: () => Navigator.pop(context, false),
          ),
        ],
      ),
    ),
  );

  if (isPrivate != null) {
    // Assign the newly created quiz
    final result = await ClassApi.assignQuizToClass(
      classId: widget.classId,
      levelId: newLevel.levelId!,
      isPrivate: isPrivate,
    );

    if (mounted) {
      if (result['success'] == true) {
        _showSnackBar(context, 'Quiz created and assigned successfully', Colors.green);
        _fetchData();
      } else {
        _showSnackBar(context, result['message'] ?? 'Failed to assign quiz', Colors.red);
      }
    }
  }
}
```

---

### Phase 4: Student Access to Private Quizzes

#### 4.1 Student View Quiz Page

**File**: `flutter_codelab/lib/student/widgets/class/student_view_quiz_page.dart`

**Current**: Students can see quizzes from their enrolled classes
**No changes needed** - Backend already filters correctly

#### 4.2 Student Game Page

**File**: `flutter_codelab/lib/pages/game_page.dart`

**Current**: Students see all public games + private games from their classes
**No changes needed** - Backend filtering handles this

---

## Implementation Checklist

### Backend

- [ ] Create migration: `add_created_by_to_levels_table.php`
- [ ] Verify migration: `add_is_private_to_class_levels_table.php` exists
- [ ] Update `LevelController::store()` - Add created_by and role check
- [ ] Update `LevelController::index()` - Filter by visibility
- [ ] Update `ClassController::assignQuiz()` - Accept is_private parameter
- [ ] Add relationships to Level model (classes, creator)
- [ ] Test API endpoints

### Frontend

- [ ] Block student access in `main.dart` (case 1)
- [ ] Update `LevelModel` to include isPrivate, isCreatedByMe, status
- [ ] Update `game_page.dart` - Show status badges
- [ ] Update `teacher_view_quiz_page.dart` - Add private/public selection dialog
- [ ] Update `ClassApi.assignQuizToClass()` - Accept isPrivate parameter
- [ ] Update `_handleCreateQuiz()` - Streamline create+assign flow
- [ ] Test all flows

### Testing

- [ ] Student cannot create games
- [ ] Teacher can create private games in class
- [ ] Private games only visible to creator in game page
- [ ] Private games accessible to students through class
- [ ] Public games visible to everyone
- [ ] Status badges display correctly

---

## Summary

This implementation will:

1. ✅ Block students from creating games
2. ✅ Allow teachers to create private games in class context
3. ✅ Show private games only to creator in game page (with status indicator)
4. ✅ Allow students to access private quizzes only through their enrolled class
5. ✅ Keep public games visible to everyone

The key changes are:

- **Database**: Track creator (`created_by`) and visibility (`is_private`)
- **Backend**: Filter games based on role and visibility
- **Frontend**: Add UI for private/public selection and status display
