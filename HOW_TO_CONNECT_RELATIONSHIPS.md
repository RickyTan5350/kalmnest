# How to Connect Relationships in draw.io

After importing `database_uml_classes.csv`, follow this guide to connect the relationships manually.

## Step 1: Import the CSV

1. Open draw.io/diagrams.net (https://app.diagrams.net)
2. Go to **File** → **Import From** → **Device**
3. Select `database_uml_classes.csv`
4. All classes will appear on the canvas

## Step 2: Understanding Relationship Types

### One-to-Many Relationships (1:N)
- One class connects to many instances of another class
- Use a **solid line with arrow** pointing to the "one" side
- Label shows the foreign key name

### Many-to-Many Relationships (N:M)
- Two classes connect through a pivot table
- Connect both classes to the pivot table
- Use **solid lines** for both connections

## Step 3: Connection Guide

### Core Relationships to Connect:

#### 1. Role → User (One-to-Many)
- **From:** Role
- **To:** User
- **Label:** `role_id`
- **Line Style:** Solid arrow (→)
- **Arrow at:** User side (pointing to Role)

#### 2. User → Class (One-to-Many) - Teacher
- **From:** User
- **To:** Class
- **Label:** `teacher_id`
- **Line Style:** Solid arrow
- **Arrow at:** Class side

#### 3. User → Class (One-to-Many) - Admin
- **From:** User
- **To:** Class
- **Label:** `admin_id`
- **Line Style:** Dashed arrow (optional, since nullable)
- **Arrow at:** Class side

#### 4. User → Note (One-to-Many)
- **From:** User
- **To:** Note
- **Label:** `created_by`
- **Line Style:** Solid arrow
- **Arrow at:** Note side

#### 5. User → Level (One-to-Many)
- **From:** User
- **To:** Level
- **Label:** `created_by`
- **Line Style:** Solid arrow
- **Arrow at:** Level side

#### 6. User → Achievement (One-to-Many)
- **From:** User
- **To:** Achievement
- **Label:** `created_by`
- **Line Style:** Solid arrow
- **Arrow at:** Achievement side

#### 7. User → Feedback (One-to-Many) - Student
- **From:** User
- **To:** Feedback
- **Label:** `student_id`
- **Line Style:** Solid arrow
- **Arrow at:** Feedback side

#### 8. User → Feedback (One-to-Many) - Teacher
- **From:** User
- **To:** Feedback
- **Label:** `teacher_id`
- **Line Style:** Solid arrow
- **Arrow at:** Feedback side

#### 9. Topic → Note (One-to-Many)
- **From:** Topic
- **To:** Note
- **Label:** `topic_id`
- **Line Style:** Solid arrow
- **Arrow at:** Note side

#### 10. File → Note (One-to-Many)
- **From:** File
- **To:** Note
- **Label:** `file_id`
- **Line Style:** Solid arrow
- **Arrow at:** Note side

#### 11. LevelType → Level (One-to-Many)
- **From:** LevelType
- **To:** Level
- **Label:** `level_type_id`
- **Line Style:** Solid arrow
- **Arrow at:** Level side

#### 12. Class ↔ User (Many-to-Many via ClassStudent)
- **From:** Class
- **To:** ClassStudent
- **Label:** `class_id`
- **Line Style:** Solid line (no arrow)
- **From:** User
- **To:** ClassStudent
- **Label:** `student_id`
- **Line Style:** Solid line (no arrow)

#### 13. Class ↔ Level (Many-to-Many via ClassLevel)
- **From:** Class
- **To:** ClassLevel
- **Label:** `class_id`
- **Line Style:** Solid line (no arrow)
- **From:** Level
- **To:** ClassLevel
- **Label:** `level_id`
- **Line Style:** Solid line (no arrow)

#### 14. User ↔ Achievement (Many-to-Many via AchievementUser)
- **From:** User
- **To:** AchievementUser
- **Label:** `user_id`
- **Line Style:** Solid line (no arrow)
- **From:** Achievement
- **To:** AchievementUser
- **Label:** `achievement_id`
- **Line Style:** Solid line (no arrow)

#### 15. Note ↔ File (Many-to-Many via NoteFile)
- **From:** Note
- **To:** NoteFile
- **Label:** `note_id`
- **Line Style:** Solid line (no arrow)
- **From:** File
- **To:** NoteFile
- **Label:** `file_id`
- **Line Style:** Solid line (no arrow)

#### 16. Level → Achievement (Optional - No FK)
- **From:** Level
- **To:** Achievement
- **Label:** `associated_level` (optional)
- **Line Style:** Dashed arrow (since no FK constraint)
- **Arrow at:** Achievement side

## Step 4: How to Draw Connections in draw.io

### For One-to-Many Relationships:

1. Click on the **Connector** tool (or press `Ctrl+Shift+3`)
2. Click on the "many" side class (e.g., User)
3. Drag to the "one" side class (e.g., Role)
4. The arrow should point **TO** the "one" side
5. Double-click the line to add a label
6. Type the foreign key name (e.g., `role_id`)

### For Many-to-Many Relationships:

1. Connect Class → ClassStudent (no arrow, or arrow pointing to pivot)
2. Connect User → ClassStudent (no arrow, or arrow pointing to pivot)
3. Add labels: `class_id` and `student_id`

### Styling Tips:

- **Solid lines** = Required relationships (NOT NULL foreign keys)
- **Dashed lines** = Optional relationships (nullable foreign keys)
- **Arrows** = Point to the "one" side in one-to-many relationships
- **No arrows** = Many-to-many relationships (or use arrows pointing to pivot table)

## Step 5: Line Style Settings

Right-click on a connection line → **Edit Style** to customize:

### For Required Relationships (NOT NULL):
```
endArrow=blockThin;endFill=1;strokeColor=#6c8ebf;strokeWidth=2;dashed=0;
```

### For Optional Relationships (NULLABLE):
```
endArrow=blockThin;endFill=1;strokeColor=#6c8ebf;strokeWidth=2;dashed=1;
```

### For Many-to-Many (Pivot Tables):
```
endArrow=blockThin;endFill=1;strokeColor=#d6b656;strokeWidth=2;dashed=0;
```

## Step 6: Cardinality Labels (Optional)

You can add cardinality labels:
- **1** on the "one" side
- **1..*** or **N** on the "many" side

To add cardinality:
1. Right-click the connection
2. Select **Edit Style**
3. Add: `startLabel=1;endLabel=N;`

## Quick Reference: All Relationships

```
Role (1) ──role_id──> (N) User
User (1) ──teacher_id──> (N) Class
User (1) ──admin_id──> (N) Class (dashed)
User (1) ──created_by──> (N) Note
User (1) ──created_by──> (N) Level
User (1) ──created_by──> (N) Achievement
User (1) ──student_id──> (N) Feedback
User (1) ──teacher_id──> (N) Feedback
Topic (1) ──topic_id──> (N) Note
File (1) ──file_id──> (N) Note
LevelType (1) ──level_type_id──> (N) Level
Class (N) ──class_id── ClassStudent ──student_id── (N) User
Class (N) ──class_id── ClassLevel ──level_id── (N) Level
User (N) ──user_id── AchievementUser ──achievement_id── (N) Achievement
Note (N) ──note_id── NoteFile ──file_id── (N) File
Level (1) ──associated_level──> (N) Achievement (dashed, optional)
```

## Tips

1. **Organize Layout First**: Use **Arrange** → **Layout** to auto-arrange classes
2. **Group Related Classes**: Use containers or swimlanes to group related entities
3. **Color Code**: 
   - Blue = Core tables
   - Yellow = Pivot tables
4. **Use Layers**: Create separate layers for different relationship types
5. **Save Frequently**: As you add connections, save your work

## Example Visual Layout

```
┌─────────┐
│  Role   │
└────┬────┘
     │ role_id
     │
┌────▼────┐
│  User  │
└───┬─────┘
    │ teacher_id
    │
┌───▼────┐
│ Class  │
└────────┘
```

Good luck with your diagram! 🎨

