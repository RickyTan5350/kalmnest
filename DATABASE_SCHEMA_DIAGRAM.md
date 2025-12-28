# Database Schema Documentation & Class Diagram

This document provides a complete analysis of all database tables, their attributes, and relationships in the Kalmnest application.

---

## Table of Contents

1. [Database Tables Overview](#database-tables-overview)
2. [Detailed Table Structures](#detailed-table-structures)
3. [Relationships Summary](#relationships-summary)
4. [Mermaid Class Diagram](#mermaid-class-diagram)
5. [Entity Relationship Details](#entity-relationship-details)

---

## Database Tables Overview

The database consists of **15 main tables** and **3 pivot/junction tables**:

### Core Tables:
1. **roles** - User roles (Admin, Teacher, Student)
2. **users** - All system users
3. **classes** - Class/Subject management
4. **topics** - Learning topics
5. **notes** - Educational notes
6. **files** - File attachments
7. **level_types** - Game level types (HTML, CSS, JS, PHP)
8. **levels** - Game/Quiz levels
9. **achievements** - Achievement system
10. **feedbacks** - Student feedback from teachers
11. **chatbot_sessions** - AI chatbot sessions
12. **chatbot_messages** - AI chatbot messages

### Pivot/Junction Tables:
13. **class_student** - Many-to-many: Classes ↔ Students
14. **class_levels** - Many-to-many: Classes ↔ Levels (with visibility)
15. **achievement_user** - Many-to-many: Users ↔ Achievements
16. **note_files** - Many-to-many: Notes ↔ Files

---

## Detailed Table Structures

### 1. roles
**Primary Key:** `role_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| role_id | UUID | PRIMARY KEY | Unique role identifier |
| role_name | String | NOT NULL | Role name (Admin, Teacher, Student) |

---

### 2. users
**Primary Key:** `user_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| user_id | UUID | PRIMARY KEY | Unique user identifier |
| name | String | NOT NULL | User's full name |
| email | String | UNIQUE, NOT NULL | User's email address |
| phone_no | String | NOT NULL | Phone number |
| address | Text | NOT NULL | Physical address |
| gender | String | NOT NULL | Gender |
| password | String | NOT NULL | Hashed password |
| account_status | Enum | NOT NULL | 'active' or 'inactive' |
| role_id | UUID | FOREIGN KEY → roles | User's role |
| remember_token | String | NULLABLE | Remember me token |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `role_id` → `roles.role_id` (ON DELETE SET NULL)

---

### 3. classes
**Primary Key:** `class_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| class_id | UUID | PRIMARY KEY | Unique class identifier |
| class_name | String(100) | NOT NULL | Class name |
| teacher_id | UUID | FOREIGN KEY → users, NOT NULL | Assigned teacher |
| description | Text | NULLABLE | Class description |
| admin_id | UUID | FOREIGN KEY → users, NULLABLE | Admin who created class |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `teacher_id` → `users.user_id` (ON DELETE CASCADE)
- `admin_id` → `users.user_id` (ON DELETE SET NULL)

---

### 4. topics
**Primary Key:** `topic_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| topic_id | UUID | PRIMARY KEY | Unique topic identifier |
| topic_name | String | NOT NULL | Topic name |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

---

### 5. notes
**Primary Key:** `note_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| note_id | UUID | PRIMARY KEY | Unique note identifier |
| title | String | NOT NULL | Note title |
| visibility | Boolean | NOT NULL | Public/Private visibility |
| file_id | UUID | FOREIGN KEY → files, NULLABLE | Primary file attachment |
| topic_id | UUID | FOREIGN KEY → topics, NULLABLE | Associated topic |
| created_by | UUID | FOREIGN KEY → users, NULLABLE | Creator (Admin/Teacher) |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `file_id` → `files.file_id` (ON DELETE SET NULL)
- `topic_id` → `topics.topic_id` (ON DELETE SET NULL)
- `created_by` → `users.user_id` (ON DELETE SET NULL)

---

### 6. files
**Primary Key:** `file_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| file_id | UUID | PRIMARY KEY | Unique file identifier |
| file_path | String | NOT NULL | File storage path |
| type | String | NOT NULL | File type (pdf, video, png, etc.) |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

---

### 7. level_types
**Primary Key:** `level_type_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| level_type_id | UUID | PRIMARY KEY | Unique level type identifier |
| level_type_name | String | NOT NULL | Type name (HTML, CSS, JS, PHP) |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

---

### 8. levels
**Primary Key:** `level_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| level_id | UUID | PRIMARY KEY | Unique level identifier |
| level_name | String | NOT NULL | Level/Game name |
| level_type_id | UUID | FOREIGN KEY → level_types, NULLABLE | Level type |
| level_data | JSON | NOT NULL | Game level data (JSON) |
| win_condition | JSON | NOT NULL | Win condition data (JSON) |
| created_by | UUID | FOREIGN KEY → users, NULLABLE | Creator (Teacher) |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `level_type_id` → `level_types.level_type_id` (ON DELETE SET NULL)
- `created_by` → `users.user_id` (ON DELETE SET NULL)

---

### 9. achievements
**Primary Key:** `achievement_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| achievement_id | UUID | PRIMARY KEY | Unique achievement identifier |
| achievement_name | String | NOT NULL | Achievement name |
| title | String | NOT NULL | Achievement title |
| description | Text | NOT NULL | Achievement description |
| associated_level | UUID | NULLABLE | Related level (optional) |
| created_by | UUID | FOREIGN KEY → users, NULLABLE | Creator (Admin/Teacher) |
| icon | String | NULLABLE | Icon identifier/path |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `created_by` → `users.user_id` (ON DELETE SET NULL)

**Note:** `associated_level` references `levels.level_id` but no foreign key constraint exists.

---

### 10. feedbacks
**Primary Key:** `feedback_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| feedback_id | UUID | PRIMARY KEY | Unique feedback identifier |
| student_id | UUID | FOREIGN KEY → users, NOT NULL | Student receiving feedback |
| teacher_id | UUID | FOREIGN KEY → users, NOT NULL | Teacher giving feedback |
| topic | String | NOT NULL | Feedback topic |
| comment | Text | NOT NULL | Feedback comment |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `student_id` → `users.user_id` (ON DELETE CASCADE)
- `teacher_id` → `users.user_id` (ON DELETE CASCADE)

---

### 11. chatbot_sessions
**Primary Key:** `id` (Auto-increment)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| id | BigInt | PRIMARY KEY, AUTO_INCREMENT | Session identifier |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Note:** This table appears to be a placeholder with minimal structure.

---

### 12. chatbot_messages
**Primary Key:** `id` (Auto-increment)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| id | BigInt | PRIMARY KEY, AUTO_INCREMENT | Message identifier |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Note:** This table appears to be a placeholder with minimal structure.

---

### 13. class_student (Pivot Table)
**Primary Key:** Composite (`class_id`, `student_id`)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| class_id | UUID | FOREIGN KEY → classes, PRIMARY KEY | Class identifier |
| student_id | UUID | FOREIGN KEY → users, PRIMARY KEY | Student identifier |
| enrolled_at | Timestamp | DEFAULT CURRENT_TIMESTAMP | Enrollment timestamp |

**Foreign Keys:**
- `class_id` → `classes.class_id` (ON DELETE CASCADE)
- `student_id` → `users.user_id` (ON DELETE CASCADE)

**Relationship:** Many-to-Many between Classes and Students

---

### 14. class_levels (Pivot Table)
**Primary Key:** `class_level_id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| class_level_id | UUID | PRIMARY KEY | Unique assignment identifier |
| class_id | UUID | FOREIGN KEY → classes, UNIQUE(class_id, level_id) | Class identifier |
| level_id | UUID | FOREIGN KEY → levels, UNIQUE(class_id, level_id) | Level identifier |
| is_private | Boolean | DEFAULT false | Visibility flag (private/public) |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `class_id` → `classes.class_id` (ON DELETE CASCADE)
- `level_id` → `levels.level_id` (ON DELETE CASCADE)

**Unique Constraint:** (`class_id`, `level_id`) - Prevents duplicate assignments

**Relationship:** Many-to-Many between Classes and Levels with additional metadata

---

### 15. achievement_user (Pivot Table)
**Primary Key:** `id` (UUID)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique assignment identifier |
| user_id | UUID | FOREIGN KEY → users | User identifier |
| achievement_id | UUID | FOREIGN KEY → achievements | Achievement identifier |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `user_id` → `users.user_id`
- `achievement_id` → `achievements.achievement_id`

**Relationship:** Many-to-Many between Users and Achievements

---

### 16. note_files (Pivot Table)
**Primary Key:** `id` (Auto-increment)

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| id | BigInt | PRIMARY KEY, AUTO_INCREMENT | Unique assignment identifier |
| note_id | UUID | FOREIGN KEY → notes | Note identifier |
| file_id | UUID | FOREIGN KEY → files | File identifier |
| created_at | Timestamp | | Record creation time |
| updated_at | Timestamp | | Record update time |

**Foreign Keys:**
- `note_id` → `notes.note_id` (ON DELETE CASCADE)
- `file_id` → `files.file_id` (ON DELETE CASCADE)

**Relationship:** Many-to-Many between Notes and Files

---

## Relationships Summary

### One-to-Many Relationships:
1. **Role → Users** (1:N)
   - One role can have many users
   - Foreign Key: `users.role_id` → `roles.role_id`

2. **User → Achievements (Created)** (1:N)
   - One user can create many achievements
   - Foreign Key: `achievements.created_by` → `users.user_id`

3. **User → Notes (Created)** (1:N)
   - One user can create many notes
   - Foreign Key: `notes.created_by` → `users.user_id`

4. **User → Levels (Created)** (1:N)
   - One user can create many levels
   - Foreign Key: `levels.created_by` → `users.user_id`

5. **User → Feedbacks (As Student)** (1:N)
   - One student can receive many feedbacks
   - Foreign Key: `feedbacks.student_id` → `users.user_id`

6. **User → Feedbacks (As Teacher)** (1:N)
   - One teacher can give many feedbacks
   - Foreign Key: `feedbacks.teacher_id` → `users.user_id`

7. **User → Classes (As Teacher)** (1:N)
   - One teacher can teach many classes
   - Foreign Key: `classes.teacher_id` → `users.user_id`

8. **User → Classes (As Admin)** (1:N)
   - One admin can create many classes
   - Foreign Key: `classes.admin_id` → `users.user_id`

9. **Topic → Notes** (1:N)
   - One topic can have many notes
   - Foreign Key: `notes.topic_id` → `topics.topic_id`

10. **File → Notes (Primary)** (1:N)
    - One file can be primary attachment for many notes
    - Foreign Key: `notes.file_id` → `files.file_id`

11. **Level Type → Levels** (1:N)
    - One level type can have many levels
    - Foreign Key: `levels.level_type_id` → `level_types.level_type_id`

### Many-to-Many Relationships:
1. **Users ↔ Achievements** (N:M)
   - Pivot Table: `achievement_user`
   - Users can earn many achievements
   - Achievements can be earned by many users

2. **Classes ↔ Students** (N:M)
   - Pivot Table: `class_student`
   - Classes can have many students
   - Students can enroll in many classes

3. **Classes ↔ Levels** (N:M)
   - Pivot Table: `class_levels`
   - Classes can have many levels/quizzes
   - Levels can be assigned to many classes
   - Additional attribute: `is_private` (visibility control)

4. **Notes ↔ Files** (N:M)
   - Pivot Table: `note_files`
   - Notes can have many file attachments
   - Files can be attached to many notes

### Optional Relationships:
- **Achievement → Level** (N:1, Optional)
  - `achievements.associated_level` → `levels.level_id` (No FK constraint)

---

## Mermaid Class Diagram

```mermaid
classDiagram
    %% Core Entity Classes
    class Role {
        +UUID role_id PK
        +String role_name
    }

    class User {
        +UUID user_id PK
        +String name
        +String email UK
        +String phone_no
        +Text address
        +String gender
        +String password
        +Enum account_status
        +UUID role_id FK
        +String remember_token
        +DateTime created_at
        +DateTime updated_at
    }

    class Class {
        +UUID class_id PK
        +String class_name
        +UUID teacher_id FK
        +Text description
        +UUID admin_id FK
        +DateTime created_at
        +DateTime updated_at
    }

    class Topic {
        +UUID topic_id PK
        +String topic_name
        +DateTime created_at
        +DateTime updated_at
    }

    class Note {
        +UUID note_id PK
        +String title
        +Boolean visibility
        +UUID file_id FK
        +UUID topic_id FK
        +UUID created_by FK
        +DateTime created_at
        +DateTime updated_at
    }

    class File {
        +UUID file_id PK
        +String file_path
        +String type
        +DateTime created_at
        +DateTime updated_at
    }

    class LevelType {
        +UUID level_type_id PK
        +String level_type_name
        +DateTime created_at
        +DateTime updated_at
    }

    class Level {
        +UUID level_id PK
        +String level_name
        +UUID level_type_id FK
        +JSON level_data
        +JSON win_condition
        +UUID created_by FK
        +DateTime created_at
        +DateTime updated_at
    }

    class Achievement {
        +UUID achievement_id PK
        +String achievement_name
        +String title
        +Text description
        +UUID associated_level
        +UUID created_by FK
        +String icon
        +DateTime created_at
        +DateTime updated_at
    }

    class Feedback {
        +UUID feedback_id PK
        +UUID student_id FK
        +UUID teacher_id FK
        +String topic
        +Text comment
        +DateTime created_at
        +DateTime updated_at
    }

    %% Pivot/Junction Tables
    class ClassStudent {
        +UUID class_id PK,FK
        +UUID student_id PK,FK
        +DateTime enrolled_at
    }

    class ClassLevel {
        +UUID class_level_id PK
        +UUID class_id FK
        +UUID level_id FK
        +Boolean is_private
        +DateTime created_at
        +DateTime updated_at
    }

    class AchievementUser {
        +UUID id PK
        +UUID user_id FK
        +UUID achievement_id FK
        +DateTime created_at
        +DateTime updated_at
    }

    class NoteFile {
        +BigInt id PK
        +UUID note_id FK
        +UUID file_id FK
        +DateTime created_at
        +DateTime updated_at
    }

    %% Relationships - One to Many
    Role ||--o{ User : "has"
    User ||--o{ Class : "teaches (teacher_id)"
    User ||--o{ Class : "creates (admin_id)"
    User ||--o{ Note : "creates"
    User ||--o{ Level : "creates"
    User ||--o{ Achievement : "creates"
    User ||--o{ Feedback : "receives (student_id)"
    User ||--o{ Feedback : "gives (teacher_id)"
    Topic ||--o{ Note : "categorizes"
    File ||--o{ Note : "attaches (primary)"
    LevelType ||--o{ Level : "types"

    %% Relationships - Many to Many
    Class }o--o{ User : "enrolls (ClassStudent)"
    Class }o--o{ Level : "assigns (ClassLevel)"
    User }o--o{ Achievement : "earns (AchievementUser)"
    Note }o--o{ File : "attaches (NoteFile)"

    %% Optional Relationship (No FK constraint)
    Level ..> Achievement : "associated_level (optional)"
```

---

## Entity Relationship Details

### User Management
- **Users** belong to a **Role** (Admin, Teacher, Student)
- Users can create **Classes** (as Admin or Teacher)
- Users can create **Notes** (as Admin or Teacher)
- Users can create **Levels** (as Teacher)
- Users can create **Achievements** (as Admin or Teacher)
- Users can give/receive **Feedbacks** (as Teacher/Student)

### Class Management
- **Classes** are created by **Admins** and assigned to **Teachers**
- **Classes** have many **Students** (many-to-many via `class_student`)
- **Classes** have many **Levels/Quizzes** (many-to-many via `class_levels`)
- **Class-Level assignments** can be private (`is_private = true`) or public

### Content Management
- **Notes** belong to a **Topic** and are created by **Users** (Admin/Teacher)
- **Notes** can have a primary **File** attachment
- **Notes** can have multiple **File** attachments (via `note_files`)
- **Files** store file paths and types

### Game/Level System
- **Levels** belong to a **Level Type** (HTML, CSS, JS, PHP)
- **Levels** are created by **Users** (Teachers)
- **Levels** contain JSON data for game configuration
- **Levels** can be assigned to multiple **Classes**

### Achievement System
- **Achievements** are created by **Users** (Admin/Teacher)
- **Achievements** can optionally be associated with a **Level**
- **Users** can earn multiple **Achievements** (many-to-many via `achievement_user`)

### Feedback System
- **Feedbacks** link **Students** and **Teachers**
- **Feedbacks** contain topic and comment information

---

## Key Design Patterns

1. **UUID Primary Keys**: All main entities use UUIDs for primary keys
2. **Soft Deletes**: Some relationships use `ON DELETE SET NULL` to preserve data
3. **Cascade Deletes**: Critical relationships use `ON DELETE CASCADE`
4. **Pivot Tables with Metadata**: `class_levels` includes `is_private` for additional relationship data
5. **JSON Storage**: `levels` table stores game data as JSON
6. **Enum Types**: `users.account_status` uses enum for data integrity

---

## Notes on Implementation

- **Chatbot tables** (`chatbot_sessions`, `chatbot_messages`) appear to be placeholders with minimal structure
- **Achievement → Level** relationship exists but without a foreign key constraint
- **File → Note** has both a direct relationship (`notes.file_id`) and a many-to-many relationship (`note_files`)
- All timestamps are managed by Laravel's `timestamps()` method

---

**Last Updated:** Based on migration files and model definitions as of December 2025

