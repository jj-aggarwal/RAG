# University database — schema context

Postgres schema `public`. Three tables: `courses`, `students`, `attendance`.
`courses` is the parent table; `students` and `attendance` both hang off it, and `attendance` also hangs off `students`.

## courses

Reference table of degree programs. One row per course.

- **course_id** — integer, primary key, surrogate key for the table.
- **course_code** — varchar(255), unique, natural key for the course, e.g. `CS101`.
- **course_name** — varchar(255), e.g. `Computer Science`.
- **department** — varchar(255), e.g. `Computing`.
- **duration_years** — integer, 3 or 4.
- **total_credits** — integer, equal to duration_years × 30.

## students

One row per student. Denormalized: each student's enrolled course and up to three subject results are stored inline on the row rather than in a separate enrollments table.

- **student_id** — integer, primary key.
- **student_number** — varchar(255), the student's institutional record identifier, e.g. `STU0001`. Not the same as student_id and not used for joins.
- **first_name** — varchar(255).
- **last_name** — varchar(255).
- **date_of_birth** — date.
- **gender** — varchar(255), values: `Male` or `Female`.
- **email** — varchar(255).
- **phone** — varchar(255).
- **address** — varchar(255).
- **city** — varchar(255).
- **postal_code** — varchar(255).
- **country** — varchar(255).
- **course_code** — varchar(255), foreign key referencing courses.course_code; the student's program.
- **course_name** — varchar(255), a denormalized copy of courses.course_name — always resolve course details via course_code, not this column.
- **subject1** — varchar(255), the first of the student's three subjects.
- **marks1** — integer, 0–100, marks for subject1.
- **grade1** — varchar(255), grade for subject1, derived from marks1.
- **subject2** — varchar(255), the second of the student's three subjects.
- **marks2** — integer, 0–100, marks for subject2.
- **grade2** — varchar(255), grade for subject2, derived from marks2.
- **subject3** — varchar(255), the third of the student's three subjects.
- **marks3** — integer, 0–100, marks for subject3.
- **grade3** — varchar(255), grade for subject3, derived from marks3.
- **overall_result** — varchar(255), values: `Pass` or `Fail`. Fail if any of marks1/marks2/marks3 is below 40, otherwise Pass.

Grade bands used when deriving grade1–3 from marks: A+ ≥90, A ≥80, B ≥70, C ≥60, D ≥50, E ≥40, F <40.

## attendance

One row per student per tracked semester (currently 1:1 with students, but the design allows more).

- **attendance_id** — integer, primary key.
- **student_id** — integer, foreign key referencing students.student_id, ON DELETE CASCADE.
- **course_code** — varchar(255), foreign key referencing courses.course_code, ON DELETE SET NULL.
- **semester** — varchar(50), e.g. `Fall 2024`.
- **total_classes** — integer, total classes held.
- **classes_attended** — integer, classes the student attended; always ≤ total_classes.
- **attendance_percentage** — numeric(5,2), equal to classes_attended ÷ total_classes × 100.

## Relationships

- `courses.course_code` (1) → `students.course_code` (many): each course has many students; each student belongs to one course.
- `students.student_id` (1) → `attendance.student_id` (many): each student has one or more attendance records.
- `courses.course_code` (1) → `attendance.course_code` (many): redundant path, kept so attendance can be queried/filtered by course without joining through students.

## Join paths

- Student ↔ course: `students.course_code = courses.course_code`
- Student ↔ attendance: `students.student_id = attendance.student_id`
- Course ↔ attendance: `courses.course_code = attendance.course_code`
- Full three-way join: `students s JOIN courses c ON s.course_code = c.course_code JOIN attendance a ON a.student_id = s.student_id`

## Data facts (current seed data)

- 100 rows in `students`, one per `student_id` 1–100.
- 12 rows in `courses`, 100 rows in `attendance` (one per student).

**Courses present in the data:**
- `CS101` — Computer Science (Computing)
- `CS201` — Software Engineering (Computing)
- `MATH101` — Mathematics (Sciences)
- `PHY101` — Physics (Sciences)
- `BIO101` — Biology (Sciences)
- `CHEM101` — Chemistry (Sciences)
- `BUS101` — Business Administration (Business)
- `ECON101` — Economics (Business)
- `PSY101` — Psychology (Social Sciences)
- `HIST101` — History (Social Sciences)
- `ENG101` — English Literature (Arts)
- `ME101` — Mechanical Engineering (Engineering)

**Countries present:** Australia, Canada, Germany, India, UK, USA — the dataset is not limited to a single country.

**Gender values:** `Male`, `Female` only.

**overall_result values:** `Pass`, `Fail` only. A student is `Fail` if any of marks1/marks2/marks3 is below 40; otherwise `Pass`.

**Grade values (grade1/grade2/grade3):** `A+`, `A`, `B`, `C`, `D`, `E`, `F` — derived from marks as: A+ ≥90, A ≥80, B ≥70, C ≥60, D ≥50, E ≥40, F <40.

**Semesters present in attendance:** `Fall 2024`, `Spring 2025` only — no other semester values exist yet.

**total_classes range:** 60–90 per student; `classes_attended` is always ≤ `total_classes`.

## Important data relationships

- `student_id` identifies each student and is the primary key of `students`.
- `student_number` is a separate institutional record identifier (e.g. `STU0001`) — do not confuse it with `student_id`; it is not a numeric join key.
- `course_code` corresponds 1:1 with `course_name` in `courses`; `students.course_name` is a denormalized copy and should not be treated as an independent source of truth — always resolve course details via `course_code`.
- Each student has exactly three subjects, each with its own marks and grade column. These triplets are aligned by position and must not be mixed across positions:
  - `subject1` ↔ `marks1` ↔ `grade1`
  - `subject2` ↔ `marks2` ↔ `grade2`
  - `subject3` ↔ `marks3` ↔ `grade3`
- `overall_result` is a derived summary of the three marks columns, not an independently entered value — treat it as the authoritative pass/fail outcome rather than recomputing it differently in a query.
- `attendance.course_code` can be `NULL` if the referenced course was deleted (`ON DELETE SET NULL`); `students.course_code` cannot be null in current data but the constraint allows it after a course deletion. When course context matters, prefer joining through `students.course_code` rather than relying on `attendance.course_code` alone.

## Query guidelines

- Use `students` as the table name for anything about an individual student's identity, demographics, program, or academic results.
- Use `student_id` as the primary identifier for joins and lookups; do not use `student_number` for joins.
- Use `course_code` when grouping or filtering by academic program; use `courses.department` when grouping or filtering at the department level.
- Use `marks1`, `marks2`, `marks3` for numerical academic analysis (averages, totals, ranking).
- Use `grade1`, `grade2`, `grade3` for grade-based analysis (counts, distributions) — do not average or sum these; they are categorical, not numeric.
- To calculate a student's average marks: average `marks1`, `marks2`, `marks3` together.
- To calculate a student's total marks: `marks1 + marks2 + marks3`.
- When a question refers to "a subject's marks" or "a subject's grade," always resolve which subject slot (1, 2, or 3) it maps to for that student before selecting the corresponding marks/grade column — a subject name is not guaranteed to sit in the same slot across different students or courses.
- Do not compute `overall_result` from marks in a query if it's already available on the row — read it directly to stay consistent with how it was derived.
- When filtering or grouping by geography, remember the dataset spans six countries (see Data facts) — do not assume all students are from one country unless the question specifies it.
- Attendance analysis should use `attendance_percentage` directly rather than recomputing from `classes_attended`/`total_classes`, unless the question specifically asks for raw class counts.
