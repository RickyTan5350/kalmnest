# Game Module & Quiz Integration Analysis

## Executive Summary

This document analyzes the feasibility of integrating the Unity game module with the quiz pages (Teacher View Quiz Page and Student View Quiz Page). The analysis covers database schema, current implementation, limitations, and integration options.

---

## 1. Current System Architecture

### 1.1 Database Schema

#### Levels Table (`levels`)

- `level_id` (UUID, Primary Key)
- `level_name` (String)
- `level_type_id` (UUID, Foreign Key → `level_types`)
- `level_data` (JSON) - Contains game data for HTML, CSS, JS, PHP
- `win_condition` (JSON) - Contains win conditions for HTML, CSS, JS, PHP
- `timestamps`

#### Level Types Table (`level_types`)

- `level_type_id` (UUID, Primary Key)
- `level_type_name` (String) - e.g., "HTML", "CSS", "JS", "PHP"
- `timestamps`

**Key Observation:** There is NO separate "quizzes" table. The quiz pages currently display hardcoded/mock data.

### 1.2 Unity Game Integration

**Current Implementation:**

- Unity WebGL build is hosted at `/unity_build/index.html`
- Flutter uses `InAppWebView` to embed Unity games
- Unity receives parameters via URL query: `?role={role}&level={levelId}`
- Level data is passed to Unity via JSON files in `StreamingAssets/{type}/levelData.json`
- Win conditions in `StreamingAssets/{type}/winData.json`

**Communication Flow:**

1. Flutter → Unity: URL parameters (`role`, `level`)
2. Backend → Unity: JSON files (levelData.json, winData.json)
3. Unity reads JSON files from StreamingAssets folder
4. Unity executes game logic based on level data

### 1.3 Quiz Pages Current State

**Teacher View Quiz Page (`teacher_view_quiz_page.dart`):**

- Shows hardcoded quiz items (e.g., "Chapter 5: Integration Techniques")
- Displays mock metadata: "15 Questions • 23 Attempts • Uploaded: Nov 26, 2025"
- Has "Upload Quiz" button (not implemented)
- Search functionality (not connected to backend)
- Pagination UI (not functional)

**Student View Quiz Page (`student_view_quiz_page.dart`):**

- Similar hardcoded quiz items
- Shows "15 Questions • Uploaded: Nov 26, 2025" (no attempts count)
- Search functionality (not connected to backend)
- Pagination UI (not functional)

---

## 2. Critical Limitations Identified

### 2.1 Database Schema Limitations

#### ❌ **NOT POSSIBLE (Not in Level Table):**

1. **Question Count** - The level table has NO field for number of questions

   - Current quiz UI shows: "15 Questions", "20 Questions", "12 Questions"
   - **Solution Required:** Add `question_count` field OR calculate from `level_data` JSON

2. **Attempts Count** - No tracking of student attempts

   - Current quiz UI shows: "23 Attempts", "18 Attempts"
   - **Solution Required:** Create `quiz_attempts` table OR use existing achievement/level completion tracking

3. **Upload Date** - Level table has `created_at`, but quiz pages show "Uploaded: Nov 26, 2025"

   - **Solution:** Use `created_at` timestamp from levels table

4. **Quiz Status** - No "Published/Draft" status field

   - Current quiz UI shows: "Published", "Draft"
   - **Solution Required:** Add `status` field to levels table OR use `level_data` JSON

5. **Class Association** - Levels are NOT linked to classes

   - Quiz pages are class-specific, but levels are global
   - **Solution Required:** Create `class_levels` pivot table OR add `class_id` to levels table

6. **Quiz Metadata** - No fields for:
   - Quiz description
   - Time limit
   - Passing score
   - Total points

### 2.2 Unity Game Limitations

#### ⚠️ **POTENTIALLY POSSIBLE (Requires Unity Changes):**

1. **Question-Based Gameplay** - Unity currently uses level_data JSON structure

   - Need to verify if Unity can handle question-answer format
   - May require Unity game logic changes

2. **Score Tracking** - Unity can send results back via JavaScript bridge

   - Current implementation doesn't show evidence of score tracking
   - Would need to implement JavaScript message passing

3. **Attempt Tracking** - Would require backend API to record attempts
   - No current API endpoint for quiz attempts

---

## 3. Integration Options

### Option 1: Use Levels as Quizzes (Minimal Changes) ⭐ RECOMMENDED

**Approach:** Treat each Level as a Quiz, extend the levels table minimally.

**Pros:**

- Reuses existing Unity integration
- Minimal database changes
- Quick to implement

**Cons:**

- Levels were designed for games, not quizzes
- May need to restructure level_data JSON format
- Limited quiz-specific features

**Required Changes:**

1. **Database Migration:**

```php
// Add to levels table
Schema::table('levels', function (Blueprint $table) {
    $table->integer('question_count')->nullable();
    $table->enum('status', ['draft', 'published'])->default('draft');
    $table->uuid('class_id')->nullable();
    $table->foreign('class_id')->references('class_id')->on('classes')->onDelete('cascade');
});
```

2. **Backend API:**

- Create endpoint: `GET /api/classes/{classId}/quizzes` - Returns levels for a class
- Create endpoint: `POST /api/quizzes/{levelId}/attempts` - Record quiz attempt
- Modify LevelController to filter by class_id

3. **Frontend Changes:**

- Connect quiz pages to real API endpoints
- Replace hardcoded data with API calls
- Add "Play Quiz" button that opens Unity WebView with level_id

4. **Unity Changes:**

- Ensure Unity can handle question-based gameplay
- May need to modify level_data JSON structure

**Implementation Complexity:** Medium
**Time Estimate:** 2-3 days

---

### Option 2: Create Separate Quizzes Table (Clean Separation)

**Approach:** Create a new `quizzes` table, link quizzes to levels.

**Pros:**

- Clean separation of concerns
- Quiz-specific fields (question_count, time_limit, etc.)
- Better data model for quiz features

**Cons:**

- More database changes
- Need to maintain relationship between quizzes and levels
- More complex queries

**Required Changes:**

1. **Database Migration:**

```php
Schema::create('quizzes', function (Blueprint $table) {
    $table->uuid('quiz_id')->primary();
    $table->string('quiz_name');
    $table->uuid('class_id');
    $table->foreign('class_id')->references('class_id')->on('classes');
    $table->uuid('level_id')->nullable(); // Link to Unity level
    $table->foreign('level_id')->references('level_id')->on('levels')->onDelete('set null');
    $table->integer('question_count');
    $table->enum('status', ['draft', 'published'])->default('draft');
    $table->integer('time_limit_minutes')->nullable();
    $table->integer('passing_score')->nullable();
    $table->text('description')->nullable();
    $table->timestamps();
});

Schema::create('quiz_attempts', function (Blueprint $table) {
    $table->uuid('attempt_id')->primary();
    $table->uuid('quiz_id');
    $table->foreign('quiz_id')->references('quiz_id')->on('quizzes');
    $table->uuid('student_id');
    $table->foreign('student_id')->references('user_id')->on('users');
    $table->integer('score')->nullable();
    $table->boolean('passed')->default(false);
    $table->timestamp('started_at');
    $table->timestamp('completed_at')->nullable();
    $table->timestamps();
});
```

2. **Backend API:**

- Create QuizController with full CRUD
- Create QuizAttemptController
- Link quizzes to Unity levels via level_id

3. **Frontend Changes:**

- Create Quiz model
- Update quiz pages to use Quiz API
- Add quiz creation/editing pages
- Connect "Play Quiz" to Unity via linked level_id

**Implementation Complexity:** High
**Time Estimate:** 5-7 days

---

### Option 3: Hybrid Approach (Quizzes with Optional Unity Link)

**Approach:** Create quizzes table, but make Unity level optional. Some quizzes can be Unity-based, others can be traditional.

**Pros:**

- Maximum flexibility
- Can have both Unity and non-Unity quizzes
- Future-proof for different quiz types

**Cons:**

- Most complex implementation
- Need to handle multiple quiz types in UI

**Required Changes:**

- Same as Option 2, but add `quiz_type` enum: ['unity', 'traditional', 'mixed']
- UI needs to handle different quiz types differently

**Implementation Complexity:** Very High
**Time Estimate:** 7-10 days

---

## 4. Recommended Approach: Option 1 (Extended Levels)

### Why Option 1?

1. **Faster Implementation** - Reuses existing Unity integration
2. **Less Database Changes** - Only adds necessary fields
3. **Maintains Unity Connection** - Direct link between quiz and Unity level
4. **Sufficient for MVP** - Can add more features later

### Implementation Plan

#### Phase 1: Database & Backend (Day 1)

1. Add fields to levels table: `question_count`, `status`, `class_id`
2. Create migration for class-levels relationship
3. Update LevelController to:
   - Filter by class_id
   - Return question_count and status
   - Support quiz-specific queries

#### Phase 2: API Endpoints (Day 1-2)

1. `GET /api/classes/{classId}/quizzes` - Get all quizzes for a class
2. `GET /api/quizzes/{levelId}` - Get single quiz details
3. `POST /api/quizzes/{levelId}/attempts` - Record attempt (if tracking needed)
4. `GET /api/quizzes/{levelId}/attempts` - Get attempt history

#### Phase 3: Frontend Integration (Day 2-3)

1. Create Quiz API service in Flutter
2. Update TeacherViewQuizPage:
   - Fetch real quizzes from API
   - Display real data (question_count, status, created_at)
   - Add "Play Quiz" button → Opens Unity WebView
   - Implement search functionality
   - Remove pagination or implement properly
3. Update StudentViewQuizPage:
   - Same as teacher view
   - Show attempt count if available
4. Add quiz creation flow (optional for MVP)

#### Phase 4: Unity Verification (Day 3)

1. Verify Unity can handle question-based gameplay
2. Test level_data JSON structure for quizzes
3. Ensure win_condition works for quiz completion
4. Test JavaScript communication if score tracking needed

---

## 5. What's NOT Possible Without Major Changes

### ❌ Cannot Do (Without Schema Changes):

1. **Track Individual Question Answers** - Would need `quiz_questions` and `quiz_responses` tables
2. **Time-Limited Quizzes** - No time_limit field, would need timer in Unity
3. **Question Banks** - No support for randomizing questions
4. **Multiple Choice Questions** - Unity would need to support this format
5. **Quiz Analytics** - No detailed attempt tracking without quiz_attempts table

### ⚠️ Possible But Requires Unity Changes:

1. **Question Count Display** - Can calculate from level_data JSON if structured correctly
2. **Score Display** - Unity can send score via JavaScript, but needs implementation
3. **Completion Status** - Can track via achievements or level completion

---

## 6. Data Flow Diagram

### Current Flow (Game Module):

```
Flutter Game Page
    ↓
Select Level
    ↓
Open Unity WebView with level_id
    ↓
Unity loads levelData.json from StreamingAssets
    ↓
Unity executes game
    ↓
Unity checks win_condition.json
    ↓
Game completes (no score tracking currently)
```

### Proposed Flow (Quiz Integration):

```
Flutter Quiz Page
    ↓
Fetch quizzes for class (GET /api/classes/{classId}/quizzes)
    ↓
Display quiz list with real data
    ↓
User clicks "Play Quiz"
    ↓
Open Unity WebView with level_id (same as game)
    ↓
Unity loads levelData.json (structured as quiz questions)
    ↓
Unity executes quiz game
    ↓
Unity sends score/results via JavaScript bridge (NEW)
    ↓
Flutter records attempt (POST /api/quizzes/{levelId}/attempts) (NEW)
    ↓
Update UI with attempt count
```

---

## 7. Questions to Resolve Before Implementation

1. **Unity Game Structure:**

   - Can Unity handle question-answer format in level_data?
   - Does Unity support multiple choice questions?
   - Can Unity send score back to Flutter?

2. **Quiz Requirements:**

   - Do quizzes need to be class-specific or can they be shared?
   - Do we need attempt tracking or just completion?
   - Do we need score tracking or just pass/fail?

3. **User Experience:**
   - Should quizzes be playable multiple times?
   - Should there be a time limit?
   - Should results be shown immediately after quiz?

---

## 8. Recommendation Summary

**Recommended:** Option 1 (Extended Levels as Quizzes)

**Rationale:**

- Fastest path to working integration
- Reuses existing Unity infrastructure
- Minimal database changes
- Can evolve to Option 2 later if needed

**Next Steps:**

1. Verify Unity can handle quiz format
2. Confirm quiz requirements (attempts, scores, etc.)
3. Implement Phase 1-3 of Option 1
4. Test end-to-end flow
5. Iterate based on feedback

---

## 9. Risk Assessment

**Low Risk:**

- Database schema changes (standard migration)
- API endpoint creation (follows existing patterns)
- Frontend integration (similar to game page)

**Medium Risk:**

- Unity game structure may need modifications
- Question count calculation from JSON
- JavaScript bridge for score tracking

**High Risk:**

- If Unity cannot handle quiz format, may need Option 2
- If quiz requirements are complex, Option 1 may be insufficient

---

## Conclusion

Integration is **FEASIBLE** with Option 1, but requires:

1. Database schema extension (3-4 new fields)
2. Backend API updates (2-3 new endpoints)
3. Frontend integration (connect quiz pages to API)
4. Unity verification (ensure quiz format works)

The main limitation is that "23 questions" and similar metadata are not currently in the database, but can be added. The Unity integration path is clear and follows existing patterns.

**Decision Point:** Choose Option 1 for quick MVP, or Option 2 for long-term scalability.
