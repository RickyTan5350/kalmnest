# Class Diagram Design Guide

This guide shows how to design the class diagram with **Admin**, **Teacher**, and **Student** as separate classes inheriting from **User**.

## Inheritance Structure

```
        ┌─────────────┐
        │    User     │  (Base Class)
        │             │
        │ Common      │
        │ Attributes  │
        │ & Methods   │
        └──────┬──────┘
               │
       ┌───────┼───────┐
       │       │       │
       ▼       ▼       ▼
   ┌──────┐ ┌──────┐ ┌──────┐
   │Admin │ │Teacher│ │Student│
   └──────┘ └──────┘ └──────┘
```

## How to Draw Inheritance in draw.io

1. **Draw the base User class** at the top
2. **Draw Admin, Teacher, Student** below User
3. **Connect with inheritance arrows**:
   - Use **hollow triangle arrow** (inheritance/generalization)
   - Point FROM child classes (Admin, Teacher, Student) TO parent class (User)
   - Style: `endArrow=block;endSize=12;endFill=0;strokeColor=#6c8ebf;`

## Complete Relationship Map

### 1. Inheritance Relationships (Hollow Triangle Arrows)
```
Admin ──▷ User
Teacher ──▷ User
Student ──▷ User
```

### 2. Admin Relationships

**Admin → Class** (One-to-Many)
- **From:** Admin
- **To:** Class
- **Label:** `admin_id` (creates/manages)
- **Style:** Solid arrow
- **Cardinality:** 1 (Admin) to * (Classes)

**Admin → User** (One-to-Many)
- **From:** Admin
- **To:** User (creates users)
- **Label:** `created_by`
- **Style:** Solid arrow
- **Cardinality:** 1 (Admin) to * (Users)

### 3. Teacher Relationships

**Teacher → Class** (One-to-Many)
- **From:** Teacher
- **To:** Class
- **Label:** `teacher_id` (teaches)
- **Style:** Solid arrow
- **Cardinality:** 1 (Teacher) to * (Classes)

**Teacher → Note** (One-to-Many)
- **From:** Teacher
- **To:** Note
- **Label:** `created_by`
- **Style:** Solid arrow
- **Cardinality:** 1 (Teacher) to * (Notes)

**Teacher → Level** (One-to-Many)
- **From:** Teacher
- **To:** Level
- **Label:** `created_by`
- **Style:** Solid arrow
- **Cardinality:** 1 (Teacher) to * (Levels)

**Teacher → Achievement** (One-to-Many)
- **From:** Teacher
- **To:** Achievement
- **Label:** `created_by`
- **Style:** Solid arrow
- **Cardinality:** 1 (Teacher) to * (Achievements)

**Teacher → Feedback** (One-to-Many)
- **From:** Teacher
- **To:** Feedback
- **Label:** `teacher_id` (gives feedback)
- **Style:** Solid arrow
- **Cardinality:** 1 (Teacher) to * (Feedbacks)

### 4. Student Relationships

**Student → Feedback** (One-to-Many)
- **From:** Student
- **To:** Feedback
- **Label:** `student_id` (receives feedback)
- **Style:** Solid arrow
- **Cardinality:** 1 (Student) to * (Feedbacks)

**Student → ClassStudent** (Many-to-Many)
- **From:** Student
- **To:** ClassStudent
- **Label:** `student_id`
- **Style:** Solid line
- **Cardinality:** * (Students) to * (Classes via ClassStudent)

**Student → AchievementUser** (Many-to-Many)
- **From:** Student
- **To:** AchievementUser
- **Label:** `user_id`
- **Style:** Solid line
- **Cardinality:** * (Students) to * (Achievements via AchievementUser)

### 5. Class Relationships

**Class → ClassStudent** (Many-to-Many)
- **From:** Class
- **To:** ClassStudent
- **Label:** `class_id`
- **Style:** Solid line
- **Cardinality:** * (Classes) to * (Students via ClassStudent)

**Class → ClassLevel** (Many-to-Many)
- **From:** Class
- **To:** ClassLevel
- **Label:** `class_id`
- **Style:** Solid line
- **Cardinality:** * (Classes) to * (Levels via ClassLevel)

### 6. Other Core Relationships

**Topic → Note** (One-to-Many)
- **From:** Topic
- **To:** Note
- **Label:** `topic_id`
- **Style:** Solid arrow
- **Cardinality:** 1 (Topic) to * (Notes)

**File → Note** (One-to-Many)
- **From:** File
- **To:** Note
- **Label:** `file_id`
- **Style:** Solid arrow
- **Cardinality:** 1 (File) to * (Notes)

**LevelType → Level** (One-to-Many)
- **From:** LevelType
- **To:** Level
- **Label:** `level_type_id`
- **Style:** Solid arrow
- **Cardinality:** 1 (LevelType) to * (Levels)

**Level → ClassLevel** (Many-to-Many)
- **From:** Level
- **To:** ClassLevel
- **Label:** `level_id`
- **Style:** Solid line
- **Cardinality:** * (Levels) to * (Classes via ClassLevel)

**Achievement → AchievementUser** (Many-to-Many)
- **From:** Achievement
- **To:** AchievementUser
- **Label:** `achievement_id`
- **Style:** Solid line
- **Cardinality:** * (Achievements) to * (Users via AchievementUser)

**Note → NoteFile** (Many-to-Many)
- **From:** Note
- **To:** NoteFile
- **Label:** `note_id`
- **Style:** Solid line
- **Cardinality:** * (Notes) to * (Files via NoteFile)

**File → NoteFile** (Many-to-Many)
- **From:** File
- **To:** NoteFile
- **Label:** `file_id`
- **Style:** Solid line
- **Cardinality:** * (Files) to * (Notes via NoteFile)

**Level → Achievement** (Optional)
- **From:** Level
- **To:** Achievement
- **Label:** `associated_level` (optional)
- **Style:** Dashed arrow
- **Cardinality:** 1 (Level) to * (Achievements)

## Visual Layout Suggestion

```
                    ┌─────────┐
                    │   User  │
                    └────┬────┘
                         │
            ┌─────────┬──┴──┬─────────┐
            │         │      │         │
            ▼         ▼      ▼         ▼
        ┌──────┐  ┌──────┐ ┌──────┐  ┌──────┐
        │Admin │  │Teacher│ │Student│  │ Role │
        └──┬───┘  └───┬───┘ └───┬───┘  └──┬───┘
           │          │         │         │
           │          │         │         │
           ▼          ▼         ▼         ▼
        ┌──────┐   ┌──────┐  ┌──────┐  ┌──────┐
        │Class │   │ Note │  │Feedback│ │Level │
        └──────┘   └──────┘  └──────┘  └──────┘
```

## Step-by-Step Drawing Instructions

### Step 1: Draw Base Classes
1. Draw **User** at the top center
2. Draw **Role** to the right of User
3. Draw **Admin**, **Teacher**, **Student** below User in a row

### Step 2: Draw Inheritance
1. Connect Admin → User (hollow triangle arrow)
2. Connect Teacher → User (hollow triangle arrow)
3. Connect Student → User (hollow triangle arrow)

### Step 3: Draw Core Entities
1. Draw **Class**, **Note**, **Level**, **Achievement**, **Feedback** in the middle
2. Draw **Topic**, **File**, **LevelType** on the sides
3. Draw pivot tables: **ClassStudent**, **ClassLevel**, **AchievementUser**, **NoteFile** at the bottom

### Step 4: Connect Admin Relationships
- Admin → Class (admin_id)
- Admin → User (creates users)

### Step 5: Connect Teacher Relationships
- Teacher → Class (teacher_id)
- Teacher → Note (created_by)
- Teacher → Level (created_by)
- Teacher → Achievement (created_by)
- Teacher → Feedback (teacher_id)

### Step 6: Connect Student Relationships
- Student → Feedback (student_id)
- Student → ClassStudent (student_id)
- Student → AchievementUser (user_id)

### Step 7: Connect Other Relationships
- Class → ClassStudent (class_id)
- Class → ClassLevel (class_id)
- Topic → Note (topic_id)
- File → Note (file_id)
- File → NoteFile (file_id)
- LevelType → Level (level_type_id)
- Level → ClassLevel (level_id)
- Level → Achievement (associated_level, dashed)
- Achievement → AchievementUser (achievement_id)
- Note → NoteFile (note_id)

## Arrow Types and Styles

### Inheritance (Generalization)
- **Type:** Hollow triangle arrow
- **Style:** `endArrow=block;endSize=12;endFill=0;strokeColor=#6c8ebf;strokeWidth=2;`
- **Direction:** Child → Parent

### Association (One-to-Many)
- **Type:** Solid arrow
- **Style:** `endArrow=blockThin;endFill=1;strokeColor=#6c8ebf;strokeWidth=2;dashed=0;`
- **Direction:** Many → One

### Optional Association
- **Type:** Dashed arrow
- **Style:** `endArrow=blockThin;endFill=1;strokeColor=#6c8ebf;strokeWidth=2;dashed=1;`
- **Direction:** Many → One

### Many-to-Many (via Pivot)
- **Type:** Solid line (no arrow, or arrow to pivot)
- **Style:** `endArrow=blockThin;endFill=1;strokeColor=#d6b656;strokeWidth=2;dashed=0;`
- **Direction:** Entity → Pivot Table

## Color Coding

- **User Classes:** Light Blue (#dae8fc)
- **Core Entities:** Medium Blue (#b3d9ff)
- **Pivot Tables:** Yellow (#fff2cc)
- **Supporting Entities:** Light Green (#d5e8d4)

## Cardinality Labels

Add cardinality labels to relationships:
- **1** = One
- **\*** = Many
- **0..1** = Zero or One
- **1..\*** = One or Many

Example: `1 ──▷ *` means "one to many"

## Complete Relationship Summary

```
Inheritance:
Admin ──▷ User
Teacher ──▷ User  
Student ──▷ User

Admin Relationships:
Admin (1) ──▷ (*) Class (admin_id)
Admin (1) ──▷ (*) User (creates)

Teacher Relationships:
Teacher (1) ──▷ (*) Class (teacher_id)
Teacher (1) ──▷ (*) Note (created_by)
Teacher (1) ──▷ (*) Level (created_by)
Teacher (1) ──▷ (*) Achievement (created_by)
Teacher (1) ──▷ (*) Feedback (teacher_id)

Student Relationships:
Student (1) ──▷ (*) Feedback (student_id)
Student (*) ── ClassStudent ── (*) Class
Student (*) ── AchievementUser ── (*) Achievement

Other Relationships:
Topic (1) ──▷ (*) Note
File (1) ──▷ (*) Note
LevelType (1) ──▷ (*) Level
Class (*) ── ClassLevel ── (*) Level
Note (*) ── NoteFile ── (*) File
Level (1) ──▷ (*) Achievement (optional, dashed)
```

This design makes it much clearer to see the different user types and their specific relationships! 🎨


