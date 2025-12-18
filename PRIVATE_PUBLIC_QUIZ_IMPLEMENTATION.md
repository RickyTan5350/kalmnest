# Private/Public Quiz Implementation

## Overview

The quiz system now supports two types of quizzes:
- **Private Quizzes**: Created specifically for a class, only visible to students in that class
- **Public Quizzes**: Existing quizzes that can be assigned to multiple classes

## Database Changes

### Migration: `add_is_private_to_class_levels_table`
- Added `is_private` boolean field to `class_levels` table
- Default value: `false` (public)
- `true` = private (class-specific)
- `false` = public (can be assigned to multiple classes)

## Backend API Changes

### 1. Updated `assignQuiz` Method
- Now accepts `is_private` parameter (optional, defaults to `false`)
- When assigning existing quiz, teacher can choose private or public

### 2. New `createAndAssignQuiz` Method
- Creates and assigns a quiz as private in one step
- Endpoint: `POST /api/classes/{classId}/quizzes/create`
- Automatically sets `is_private = true`

### 3. Updated `getQuizzes` Method
- Returns `is_private` field in quiz data
- Access control still enforced (students only see quizzes for their enrolled classes)

### 4. New `getQuizCount` Method
- Returns total quiz count for a class
- Endpoint: `GET /api/classes/{classId}/quizzes/count`
- Used for statistics display

## Frontend Implementation

### Teacher Quiz Page
1. **Create Quiz Button**:
   - Opens Unity create game page
   - After creation, teacher manually assigns it
   - When assigning, teacher chooses private or public

2. **Assign Quiz Button**:
   - Shows dialog to select existing quiz
   - After selection, asks: "Private or Public?"
   - Private = only this class
   - Public = can be assigned to other classes

3. **Quiz Display**:
   - Shows badge indicating Private (🔒) or Public (🌐)
   - Private quizzes: Orange badge with lock icon
   - Public quizzes: Blue badge with public icon

### Class Detail Pages
- **Statistics Section**: Now shows real quiz count from API
- Fetches quiz count using `ClassApi.getClassQuizCount()`

## How It Works

### Creating a Private Quiz
1. Teacher clicks "Create Quiz" → Opens Unity WebView
2. Teacher designs quiz in Unity
3. Teacher clicks "Create Level" → Level is created
4. Teacher uses "Assign Quiz" → Selects the newly created level
5. Teacher chooses "Private" → Quiz is assigned as private
6. Quiz is now only visible to students in that class

### Assigning a Public Quiz
1. Teacher clicks "Assign Quiz"
2. Teacher selects an existing quiz from the list
3. Teacher chooses "Public"
4. Quiz is assigned to the class as public
5. Same quiz can be assigned to other classes

### Student View
- Students only see quizzes assigned to their enrolled classes
- They don't see the private/public distinction (it's transparent to them)
- Private quizzes from other classes are not visible
- Public quizzes from other classes are not visible (unless assigned to their class)

## Access Control

The access control remains the same:
- **Students**: Can only see quizzes for classes they're enrolled in
- **Teachers**: Can only see/manage quizzes for classes they teach
- **Admins**: Can see/manage quizzes for all classes

The `is_private` field doesn't change access control - it only affects visibility across classes:
- Private quiz in Class A → Only visible in Class A
- Public quiz → Can be assigned to Class A, Class B, Class C, etc.

## API Endpoints

```
GET    /api/classes/{classId}/quizzes           - Get all quizzes for a class
POST   /api/classes/{classId}/quizzes           - Assign existing quiz (public or private)
POST   /api/classes/{classId}/quizzes/create    - Create and assign as private
DELETE /api/classes/{classId}/quizzes/{levelId} - Remove quiz from class
GET    /api/classes/{classId}/quizzes/count     - Get quiz count for statistics
```

## Example Usage

### Scenario 1: Create Private Quiz
```
1. Teacher creates quiz "Math Quiz 1" in Unity
2. Teacher assigns it to "Class A" as Private
3. Only students in Class A can see "Math Quiz 1"
4. Students in Class B cannot see it
```

### Scenario 2: Assign Public Quiz
```
1. Teacher has existing quiz "HTML Basics"
2. Teacher assigns it to "Class A" as Public
3. Teacher assigns same quiz to "Class B" as Public
4. Both Class A and Class B students can see "HTML Basics"
```

## Visual Indicators

- **Private Quiz**: 🔒 Orange badge with "Private" label
- **Public Quiz**: 🌐 Blue badge with "Public" label
- Displayed in quiz list items in teacher view

