# Game Visibility and Filtering System

## Overview

This document explains the game visibility and filtering system implemented for the Kalmnest application. The system controls who can see which games based on user roles (Student, Teacher, Admin) and game visibility settings (Public/Private).

---

## Summary (Simplified)

### What Was Implemented

1. **Visibility Filter for Teachers**: Teachers can filter games by "All", "Public", or "Private" in the game page
2. **Student Access Control**: Students can only see public games in the game page; private games are only accessible through their enrolled classes
3. **Auto-Refresh System**: Games automatically refresh when created, updated, or when users navigate to the game page

### Key Rules

- **Students**: See only public games in game page; private games accessible only through enrolled classes
- **Teachers**: See public games + private games they created; can filter by visibility
- **Admins**: See all games (no restrictions)
- **Private Games**: Only visible to the creating teacher and students enrolled in classes where the game is assigned
- **Public Games**: Visible to everyone in the game page

---

## How It Works

### 1. Backend Filtering Logic

**File**: `backend_services/app/Http/Controllers/LevelController.php`

The backend filters games based on user role:

#### For Students:

```php
// Students: ONLY see public games in game page
// Private games only accessible through class
$query->whereDoesntHave('classes', function($subQ) {
    $subQ->where('class_levels.is_private', true);
});
```

**What this means**: Students see games that are NOT assigned as private to any class.

#### For Teachers:

```php
// Teachers: See public games OR private games they created
$query->where(function($q) use ($user) {
    // Public games (not assigned as private)
    $q->whereDoesntHave('classes', function($subQ) {
        $subQ->where('class_levels.is_private', true);
    })
    // OR private games created by this teacher
    ->orWhere(function($orQ) use ($user) {
        $orQ->where('created_by', $user->user_id)
            ->whereHas('classes', function($subQ) {
                $subQ->where('class_levels.is_private', true);
            });
    });
});
```

**What this means**: Teachers see:

- All public games (not assigned as private)
- Private games they created themselves

#### For Admins:

- No filtering applied - see all games

### 2. Frontend Filtering (Teachers Only)

**File**: `flutter_codelab/lib/pages/game_page.dart`

Teachers and admins see additional filter chips:

- **All**: Shows all games (public + private they created)
- **Public**: Shows only public games
- **Private**: Shows only private games they created

```dart
// Visibility filter (only for teachers/admins)
final List<String> _visibilityFilters = ['All', 'Public', 'Private'];
String _selectedVisibility = 'All';
```

### 3. Cache Management

**File**: `flutter_codelab/lib/api/game_api.dart`

#### Per-User Caching

- Each user has their own cache (based on token)
- Prevents cross-user cache contamination
- Cache is cleared when:
  - Game is created
  - Game is updated
  - Game is deleted
  - User explicitly refreshes

#### Cache Clearing

```dart
static void clearCache() {
  _cachedLevelsByUser.clear();
}
```

Called automatically after:

- `createLevel()` - when new game is created
- `updateLevel()` - when game is updated
- `deleteLevel()` - when game is deleted

### 4. Auto-Refresh System

**File**: `flutter_codelab/lib/pages/game_page.dart` & `flutter_codelab/lib/main.dart`

#### Refresh Triggers:

1. **On Tab Navigation**: When user clicks on "Game" tab
2. **After Game Creation**: When teacher creates a new game
3. **After Game Edit**: When game is modified
4. **After Game Deletion**: When game is removed
5. **Manual Refresh**: When user clicks refresh button

#### Implementation:

```dart
// Global key for external refresh
final GlobalKey<_GamePageState> gamePageGlobalKey = GlobalKey<_GamePageState>();

// Refresh when navigating to game tab
if (index == 1) {
  gamePageGlobalKey.currentState?.refresh();
}
```

---

## Rules and Access Control

### Game Visibility Rules

| User Role   | Public Games            | Private Games (Own)         | Private Games (Others)      |
| ----------- | ----------------------- | --------------------------- | --------------------------- |
| **Student** | ✅ Visible in game page | ❌ Not visible in game page | ❌ Not visible in game page |
| **Teacher** | ✅ Visible in game page | ✅ Visible in game page     | ❌ Not visible in game page |
| **Admin**   | ✅ Visible in game page | ✅ Visible in game page     | ✅ Visible in game page     |

### Private Game Access Rules

1. **For Students**:

   - Private games are **NOT** visible in the game page
   - Private games are **ONLY** accessible through enrolled classes
   - Students see private games in their class's quiz list

2. **For Teachers**:

   - Can see private games they created in the game page
   - Can see public games in the game page
   - Can assign public games to classes (as public or private)
   - Can create new games and assign them as public or private

3. **For Admins**:
   - Can see all games (public and private)
   - No restrictions

### Game Creation Flow

1. Teacher clicks "Create Quiz" in a class
2. Dialog appears: "How should this new quiz be visible?"
   - **Private**: Only visible to this class
   - **Public**: Visible to everyone
3. Teacher selects visibility
4. Unity game creation page opens
5. After game is created, it's automatically assigned to the class with selected visibility
6. Game page refreshes to show the new game

---

## Database Structure

### Key Tables

1. **`levels` table**:

   - `level_id` (UUID, Primary Key)
   - `level_name`
   - `created_by` (UUID, Foreign Key to `users.user_id`)
   - Other game fields...

2. **`class_levels` pivot table**:

   - `class_id` (Foreign Key)
   - `level_id` (Foreign Key)
   - `is_private` (Boolean) - Determines if this assignment is private
   - `created_at`, `updated_at`

3. **`users` table**:
   - `user_id` (UUID, Primary Key)
   - Role information...

### Relationships

- **Level → Classes**: Many-to-Many (via `class_levels`)
- **Level → Creator**: Many-to-One (via `created_by`)
- **Class → Students**: Many-to-Many (via enrollment)

---

## Files Modified

### Backend Files

1. **`backend_services/app/Http/Controllers/LevelController.php`**
   - Updated `index()` method to filter games based on role
   - Students: Only public games
   - Teachers: Public games + their private games
   - Admins: All games

### Frontend Files

1. **`flutter_codelab/lib/pages/game_page.dart`**

   - Added visibility filter chips (All/Public/Private) for teachers
   - Added `GlobalKey` for external refresh
   - Added `refresh()` method
   - Added `_applyFilters()` method for client-side filtering
   - Removed unused `_openUnityWebView` method

2. **`flutter_codelab/lib/main.dart`**

   - Added `gamePageGlobalKey` import
   - Added refresh trigger when navigating to game tab (index 1)
   - Connected GamePage with GlobalKey

3. **`flutter_codelab/lib/api/game_api.dart`**
   - Implemented per-user caching system
   - Added `clearCache()` method
   - Added cache clearing in `createLevel()`, `updateLevel()`, `deleteLevel()`
   - Improved cache key generation using user token

---

## User Experience Flow

### Scenario 1: Teacher Creates Private Game

1. Teacher opens a class
2. Clicks "Create Quiz"
3. Selects "Private" in dialog
4. Unity game creation page opens
5. Teacher creates the game
6. Game is automatically assigned to class as private
7. Teacher navigates to Game page
8. Sees the new game with "Private" badge
9. Can filter to see only "Private" games

### Scenario 2: Student Views Games

1. Student opens Game page
2. Sees only public games (no private games visible)
3. Student opens a class they're enrolled in
4. Sees private games assigned to that class
5. Can access private games through the class

### Scenario 3: Teacher Filters Games

1. Teacher opens Game page
2. Sees all games (public + their private games)
3. Clicks "Public" filter chip
4. Only public games are shown
5. Clicks "Private" filter chip
6. Only private games they created are shown
7. Clicks "All" filter chip
8. All games are shown again

### Scenario 4: Multiple Users

1. Teacher A creates a private game
2. Teacher A sees it in their game page
3. Teacher B logs in and does NOT see Teacher A's private game
4. Student logs in and does NOT see any private games in game page
5. Student enrolls in Teacher A's class
6. Student can now see Teacher A's private game in the class

---

## Technical Details

### Cache Strategy

**Problem**: Different users might see cached data from other users

**Solution**: Per-user caching using token prefix as cache key

```dart
static Map<String, List<LevelModel>?> _cachedLevelsByUser = {};

static Future<String?> _getCacheKey() async {
  final token = await AuthApi.getToken();
  if (token == null) return null;
  return token.substring(0, math.min(20, token.length));
}
```

### Refresh Strategy

**Problem**: Games don't refresh after creation or when switching users

**Solution**:

1. GlobalKey for external refresh control
2. Auto-refresh on tab navigation
3. Cache clearing on create/update/delete
4. Force refresh flag in API calls

### Filtering Strategy

**Backend Filtering**:

- Applied at database query level
- More efficient, reduces data transfer
- Ensures security (can't bypass with frontend manipulation)

**Frontend Filtering**:

- Additional filtering for teachers (All/Public/Private)
- Applied on already-filtered backend results
- Fast, no additional API calls

---

## Testing Checklist

- [ ] Student can see public games in game page
- [ ] Student cannot see private games in game page
- [ ] Student can access private games through enrolled class
- [ ] Teacher can see public games in game page
- [ ] Teacher can see their private games in game page
- [ ] Teacher cannot see other teachers' private games
- [ ] Teacher can filter by "All", "Public", "Private"
- [ ] Admin can see all games
- [ ] Games refresh after creation
- [ ] Games refresh when navigating to game tab
- [ ] Games refresh after edit/delete
- [ ] Different users see correct games (no cache contamination)

---

## Future Enhancements (Optional)

1. **Search within filtered results**: Add search functionality that works with visibility filters
2. **Bulk operations**: Allow teachers to change visibility of multiple games
3. **Analytics**: Track which games are most accessed (public vs private)
4. **Notifications**: Notify students when a private game is assigned to their class
5. **Expiration**: Add ability to set expiration dates for private game assignments

---

## Troubleshooting

### Issue: Games not refreshing after creation

**Solution**: Check that `clearCache()` is called in `createLevel()`, `updateLevel()`, and `deleteLevel()`

### Issue: Student sees private games in game page

**Solution**: Verify backend filtering in `LevelController.php` - students should only see games without private assignments

### Issue: Teacher cannot see their private games

**Solution**: Check that `created_by` field is set correctly when creating games

### Issue: Cache shows wrong user's games

**Solution**: Verify per-user cache key generation uses unique token prefix

---

## Conclusion

This system provides a secure and user-friendly way to manage game visibility based on user roles and game privacy settings. The implementation ensures that:

- Students have appropriate access to games
- Teachers can manage their private and public games
- Admins have full visibility
- The system automatically refreshes to show the latest data
- Performance is optimized through intelligent caching

All changes are backward compatible and don't affect existing functionality.
