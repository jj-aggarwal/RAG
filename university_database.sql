-- ============================================================
-- University Database (PostgreSQL)
-- Tables: public.students, public.courses, public.attendance
-- Students: 100 rows | Courses: 12 rows | Attendance: 100 rows
-- students.course_code -> courses.course_code (FK)
-- attendance.student_id -> students.student_id (FK)
-- attendance.course_code -> courses.course_code (FK)
-- ============================================================

DROP TABLE IF EXISTS public.attendance;
DROP TABLE IF EXISTS public.students;
DROP TABLE IF EXISTS public.courses;

CREATE TABLE IF NOT EXISTS public.courses
(
    course_id integer NOT NULL,
    course_code character varying(255) COLLATE pg_catalog."default" NOT NULL,
    course_name character varying(255) COLLATE pg_catalog."default",
    department character varying(255) COLLATE pg_catalog."default",
    duration_years integer,
    total_credits integer,
    CONSTRAINT courses_pkey PRIMARY KEY (course_id),
    CONSTRAINT courses_course_code_key UNIQUE (course_code)
);

CREATE TABLE IF NOT EXISTS public.students
(
    student_id integer NOT NULL,
    student_number character varying(255) COLLATE pg_catalog."default",
    first_name character varying(255) COLLATE pg_catalog."default",
    last_name character varying(255) COLLATE pg_catalog."default",
    date_of_birth date,
    gender character varying(255) COLLATE pg_catalog."default",
    email character varying(255) COLLATE pg_catalog."default",
    phone character varying(255) COLLATE pg_catalog."default",
    address character varying(255) COLLATE pg_catalog."default",
    city character varying(255) COLLATE pg_catalog."default",
    postal_code character varying(255) COLLATE pg_catalog."default",
    country character varying(255) COLLATE pg_catalog."default",
    course_code character varying(255) COLLATE pg_catalog."default",
    course_name character varying(255) COLLATE pg_catalog."default",
    subject1 character varying(255) COLLATE pg_catalog."default",
    marks1 integer,
    grade1 character varying(255) COLLATE pg_catalog."default",
    subject2 character varying(255) COLLATE pg_catalog."default",
    marks2 integer,
    grade2 character varying(255) COLLATE pg_catalog."default",
    subject3 character varying(255) COLLATE pg_catalog."default",
    marks3 integer,
    grade3 character varying(255) COLLATE pg_catalog."default",
    overall_result character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT students_pkey PRIMARY KEY (student_id),
    CONSTRAINT students_course_code_fkey FOREIGN KEY (course_code)
        REFERENCES public.courses (course_code) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public.attendance
(
    attendance_id integer NOT NULL,
    student_id integer NOT NULL,
    course_code character varying(255) COLLATE pg_catalog."default",
    semester character varying(50) COLLATE pg_catalog."default",
    total_classes integer,
    classes_attended integer,
    attendance_percentage numeric(5,2),
    CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id),
    CONSTRAINT attendance_student_id_fkey FOREIGN KEY (student_id)
        REFERENCES public.students (student_id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT attendance_course_code_fkey FOREIGN KEY (course_code)
        REFERENCES public.courses (course_code) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- ---------------- INSERT: courses (12 rows) ----------------
INSERT INTO public.courses (course_id, course_code, course_name, department, duration_years, total_credits) VALUES
(1, 'CS101', 'Computer Science', 'Computing', 4, 120),
(2, 'CS201', 'Software Engineering', 'Computing', 3, 90),
(3, 'MATH101', 'Mathematics', 'Sciences', 4, 120),
(4, 'PHY101', 'Physics', 'Sciences', 3, 90),
(5, 'BIO101', 'Biology', 'Sciences', 3, 90),
(6, 'CHEM101', 'Chemistry', 'Sciences', 3, 90),
(7, 'BUS101', 'Business Administration', 'Business', 4, 120),
(8, 'ECON101', 'Economics', 'Business', 3, 90),
(9, 'PSY101', 'Psychology', 'Social Sciences', 3, 90),
(10, 'HIST101', 'History', 'Social Sciences', 3, 90),
(11, 'ENG101', 'English Literature', 'Arts', 3, 90),
(12, 'ME101', 'Mechanical Engineering', 'Engineering', 4, 120);

-- ---------------- INSERT: students (100 rows) ----------------
INSERT INTO public.students
(student_id, student_number, first_name, last_name, date_of_birth, gender, email, phone, address, city, postal_code, country,
 course_code, course_name, subject1, marks1, grade1, subject2, marks2, grade2, subject3, marks3, grade3, overall_result) VALUES
(1, 'STU0001', 'Jennifer', 'Thomas', '2000-09-10', 'Female', 'jennifer.thomas1@university.edu', '+1-292-764-7955', '127 Elm St', 'Austin', '73301', 'USA', 'HIST101', 'History', 'Ancient History', 85, 'A', 'Modern History', 41, 'E', 'World Politics', 63, 'C', 'Pass'),
(2, 'STU0002', 'Andrew', 'Rodriguez', '2002-01-10', 'Male', 'andrew.rodriguez2@university.edu', '+1-496-629-3363', '585 Pine Ave', 'Berlin', '10115', 'Germany', 'CS201', 'Software Engineering', 'Data Structures', 59, 'D', 'Software Design', 82, 'A', 'Web Development', 47, 'E', 'Pass'),
(3, 'STU0003', 'Joshua', 'Brown', '2005-03-22', 'Male', 'joshua.brown3@university.edu', '+1-833-410-9133', '796 River Rd', 'Delhi', '110001', 'India', 'HIST101', 'History', 'Ancient History', 93, 'A+', 'Modern History', 81, 'A', 'World Politics', 73, 'B', 'Pass'),
(4, 'STU0004', 'Jason', 'Lopez', '2005-07-20', 'Male', 'jason.lopez4@university.edu', '+1-915-998-4999', '308 Park Lane', 'Austin', '73301', 'USA', 'CHEM101', 'Chemistry', 'Organic Chemistry', 92, 'A+', 'Inorganic Chemistry', 71, 'B', 'Physical Chemistry', 44, 'E', 'Pass'),
(5, 'STU0005', 'Paul', 'Clark', '2000-11-13', 'Male', 'paul.clark5@university.edu', '+1-368-975-6604', '432 Maple St', 'Manchester', 'M11AE', 'UK', 'PSY101', 'Psychology', 'Cognitive Psychology', 75, 'B', 'Developmental Psychology', 78, 'B', 'Social Psychology', 79, 'B', 'Pass'),
(6, 'STU0006', 'Emily', 'Robinson', '2003-06-22', 'Female', 'emily.robinson6@university.edu', '+1-270-295-5422', '63 Willow Way', 'Sydney', '2000', 'Australia', 'ENG101', 'English Literature', 'Poetry', 92, 'A+', 'Drama', 71, 'B', 'Prose Fiction', 84, 'A', 'Pass'),
(7, 'STU0007', 'Mary', 'Robinson', '2003-03-23', 'Female', 'mary.robinson7@university.edu', '+1-563-372-2918', '224 Birch St', 'Sydney', '2000', 'Australia', 'MATH101', 'Mathematics', 'Calculus', 66, 'C', 'Linear Algebra', 85, 'A', 'Statistics', 85, 'A', 'Pass'),
(8, 'STU0008', 'Jennifer', 'Hernandez', '2003-02-14', 'Female', 'jennifer.hernandez8@university.edu', '+1-659-611-5552', '885 Park Lane', 'Manchester', 'M11AE', 'UK', 'ME101', 'Mechanical Engineering', 'Thermodynamics', 88, 'A', 'Fluid Mechanics', 80, 'A', 'Machine Design', 83, 'A', 'Pass'),
(9, 'STU0009', 'William', 'Garcia', '2002-01-16', 'Male', 'william.garcia9@university.edu', '+1-380-354-4800', '13 Highland Dr', 'Mumbai', '400001', 'India', 'BIO101', 'Biology', 'Cell Biology', 71, 'B', 'Genetics', 35, 'F', 'Ecology', 53, 'D', 'Fail'),
(10, 'STU0010', 'Kimberly', 'White', '2000-08-09', 'Female', 'kimberly.white10@university.edu', '+1-824-779-6220', '880 Park Lane', 'Leeds', 'LS11UR', 'UK', 'ECON101', 'Economics', 'Microeconomics', 85, 'A', 'Macroeconomics', 85, 'A', 'Econometrics', 86, 'A', 'Pass'),
(11, 'STU0011', 'Linda', 'Walker', '2001-10-26', 'Female', 'linda.walker11@university.edu', '+1-849-610-2019', '214 Highland Dr', 'London', 'EC1A1BB', 'UK', 'CS201', 'Software Engineering', 'Data Structures', 78, 'B', 'Software Design', 41, 'E', 'Web Development', 48, 'E', 'Pass'),
(12, 'STU0012', 'Joshua', 'Martinez', '2002-05-01', 'Male', 'joshua.martinez12@university.edu', '+1-749-303-6957', '73 Meadow Ln', 'Berlin', '10115', 'Germany', 'HIST101', 'History', 'Ancient History', 83, 'A', 'Modern History', 54, 'D', 'World Politics', 67, 'C', 'Pass'),
(13, 'STU0013', 'Donna', 'White', '2003-07-01', 'Female', 'donna.white13@university.edu', '+1-685-325-2889', '492 Highland Dr', 'Melbourne', '3000', 'Australia', 'CS201', 'Software Engineering', 'Data Structures', 53, 'D', 'Software Design', 48, 'E', 'Web Development', 78, 'B', 'Pass'),
(14, 'STU0014', 'Ashley', 'Hernandez', '2000-04-20', 'Female', 'ashley.hernandez14@university.edu', '+1-728-223-4362', '151 Willow Way', 'Munich', '80331', 'Germany', 'PSY101', 'Psychology', 'Cognitive Psychology', 73, 'B', 'Developmental Psychology', 46, 'E', 'Social Psychology', 68, 'C', 'Pass'),
(15, 'STU0015', 'Cynthia', 'Hernandez', '2002-03-10', 'Female', 'cynthia.hernandez15@university.edu', '+1-564-990-4650', '652 Elm St', 'Munich', '80331', 'Germany', 'PHY101', 'Physics', 'Mechanics', 86, 'A', 'Electromagnetism', 64, 'C', 'Thermodynamics', 60, 'C', 'Pass'),
(16, 'STU0016', 'Lisa', 'Johnson', '2003-11-11', 'Female', 'lisa.johnson16@university.edu', '+1-228-486-8737', '710 Church St', 'Toronto', 'M5H2N2', 'Canada', 'ECON101', 'Economics', 'Microeconomics', 79, 'B', 'Macroeconomics', 81, 'A', 'Econometrics', 45, 'E', 'Pass'),
(17, 'STU0017', 'Michael', 'Anderson', '2000-01-08', 'Male', 'michael.anderson17@university.edu', '+1-681-401-6533', '640 Church St', 'Manchester', 'M11AE', 'UK', 'ECON101', 'Economics', 'Microeconomics', 79, 'B', 'Macroeconomics', 45, 'E', 'Econometrics', 50, 'D', 'Pass'),
(18, 'STU0018', 'Stephanie', 'Gonzalez', '2004-06-09', 'Female', 'stephanie.gonzalez18@university.edu', '+1-689-382-8109', '89 Birch St', 'Delhi', '110001', 'India', 'ECON101', 'Economics', 'Microeconomics', 86, 'A', 'Macroeconomics', 45, 'E', 'Econometrics', 55, 'D', 'Pass'),
(19, 'STU0019', 'William', 'Johnson', '2005-04-26', 'Male', 'william.johnson19@university.edu', '+1-354-804-8624', '627 Meadow Ln', 'Mumbai', '400001', 'India', 'ENG101', 'English Literature', 'Poetry', 79, 'B', 'Drama', 54, 'D', 'Prose Fiction', 51, 'D', 'Pass'),
(20, 'STU0020', 'James', 'Miller', '2002-05-14', 'Male', 'james.miller20@university.edu', '+1-739-967-3281', '846 Meadow Ln', 'Sydney', '2000', 'Australia', 'CS101', 'Computer Science', 'Programming Fundamentals', 67, 'C', 'Databases', 62, 'C', 'Computer Networks', 72, 'B', 'Pass'),
(21, 'STU0021', 'Ronald', 'Nguyen', '2003-12-20', 'Male', 'ronald.nguyen21@university.edu', '+1-533-465-9918', '63 Willow Way', 'Sydney', '2000', 'Australia', 'ECON101', 'Economics', 'Microeconomics', 88, 'A', 'Macroeconomics', 99, 'A+', 'Econometrics', 51, 'D', 'Pass'),
(22, 'STU0022', 'Paul', 'Allen', '2001-09-05', 'Male', 'paul.allen22@university.edu', '+1-219-650-4000', '795 Birch St', 'Berlin', '10115', 'Germany', 'MATH101', 'Mathematics', 'Calculus', 53, 'D', 'Linear Algebra', 95, 'A+', 'Statistics', 50, 'D', 'Pass'),
(23, 'STU0023', 'Daniel', 'King', '2002-02-22', 'Male', 'daniel.king23@university.edu', '+1-743-768-8905', '59 Elm St', 'Austin', '73301', 'USA', 'BIO101', 'Biology', 'Cell Biology', 40, 'E', 'Genetics', 47, 'E', 'Ecology', 99, 'A+', 'Pass'),
(24, 'STU0024', 'Kimberly', 'Johnson', '2005-01-26', 'Female', 'kimberly.johnson24@university.edu', '+1-978-264-8262', '710 Pine Ave', 'Toronto', 'M5H2N2', 'Canada', 'PSY101', 'Psychology', 'Cognitive Psychology', 96, 'A+', 'Developmental Psychology', 99, 'A+', 'Social Psychology', 66, 'C', 'Pass'),
(25, 'STU0025', 'Cynthia', 'Scott', '2003-07-18', 'Female', 'cynthia.scott25@university.edu', '+1-407-658-3246', '402 Highland Dr', 'Sydney', '2000', 'Australia', 'CS201', 'Software Engineering', 'Data Structures', 65, 'C', 'Software Design', 89, 'A', 'Web Development', 44, 'E', 'Pass'),
(26, 'STU0026', 'Brian', 'Martin', '2001-07-16', 'Male', 'brian.martin26@university.edu', '+1-325-995-3530', '147 Pine Ave', 'Delhi', '110001', 'India', 'ECON101', 'Economics', 'Microeconomics', 63, 'C', 'Macroeconomics', 47, 'E', 'Econometrics', 85, 'A', 'Pass'),
(27, 'STU0027', 'Barbara', 'Anderson', '2002-03-12', 'Female', 'barbara.anderson27@university.edu', '+1-365-923-8070', '348 Sunset Blvd', 'Munich', '80331', 'Germany', 'CHEM101', 'Chemistry', 'Organic Chemistry', 75, 'B', 'Inorganic Chemistry', 46, 'E', 'Physical Chemistry', 81, 'A', 'Pass'),
(28, 'STU0028', 'Daniel', 'Scott', '2003-04-25', 'Male', 'daniel.scott28@university.edu', '+1-669-651-1296', '530 Church St', 'Melbourne', '3000', 'Australia', 'PSY101', 'Psychology', 'Cognitive Psychology', 43, 'E', 'Developmental Psychology', 49, 'E', 'Social Psychology', 64, 'C', 'Pass'),
(29, 'STU0029', 'Robert', 'Taylor', '2002-11-25', 'Male', 'robert.taylor29@university.edu', '+1-478-240-3974', '840 Sunset Blvd', 'Toronto', 'M5H2N2', 'Canada', 'BUS101', 'Business Administration', 'Accounting', 54, 'D', 'Marketing', 100, 'A+', 'Management', 98, 'A+', 'Pass'),
(30, 'STU0030', 'Jennifer', 'Moore', '2000-12-28', 'Female', 'jennifer.moore30@university.edu', '+1-258-904-4003', '276 Maple St', 'Sydney', '2000', 'Australia', 'BIO101', 'Biology', 'Cell Biology', 45, 'E', 'Genetics', 63, 'C', 'Ecology', 43, 'E', 'Pass'),
(31, 'STU0031', 'Laura', 'Davis', '2001-06-13', 'Female', 'laura.davis31@university.edu', '+1-664-211-6556', '949 Pine Ave', 'Munich', '80331', 'Germany', 'CS101', 'Computer Science', 'Programming Fundamentals', 65, 'C', 'Databases', 49, 'E', 'Computer Networks', 55, 'D', 'Pass'),
(32, 'STU0032', 'Patricia', 'Lopez', '2005-08-10', 'Female', 'patricia.lopez32@university.edu', '+1-406-519-5997', '297 Highland Dr', 'Berlin', '10115', 'Germany', 'ENG101', 'English Literature', 'Poetry', 57, 'D', 'Drama', 69, 'C', 'Prose Fiction', 79, 'B', 'Pass'),
(33, 'STU0033', 'Thomas', 'Williams', '2002-10-03', 'Male', 'thomas.williams33@university.edu', '+1-215-218-9284', '527 Highland Dr', 'Berlin', '10115', 'Germany', 'ECON101', 'Economics', 'Microeconomics', 48, 'E', 'Macroeconomics', 90, 'A+', 'Econometrics', 98, 'A+', 'Pass'),
(34, 'STU0034', 'Dorothy', 'Martin', '2001-07-26', 'Female', 'dorothy.martin34@university.edu', '+1-904-420-4761', '853 Willow Way', 'Toronto', 'M5H2N2', 'Canada', 'BUS101', 'Business Administration', 'Accounting', 79, 'B', 'Marketing', 41, 'E', 'Management', 51, 'D', 'Pass'),
(35, 'STU0035', 'Robert', 'Ramirez', '2003-02-28', 'Male', 'robert.ramirez35@university.edu', '+1-367-256-2384', '892 Park Lane', 'Delhi', '110001', 'India', 'HIST101', 'History', 'Ancient History', 66, 'C', 'Modern History', 72, 'B', 'World Politics', 40, 'E', 'Pass'),
(36, 'STU0036', 'Barbara', 'Hernandez', '2003-08-18', 'Female', 'barbara.hernandez36@university.edu', '+1-475-656-1059', '985 River Rd', 'Vancouver', 'V6B1A1', 'Canada', 'PHY101', 'Physics', 'Mechanics', 39, 'F', 'Electromagnetism', 74, 'B', 'Thermodynamics', 62, 'C', 'Fail'),
(37, 'STU0037', 'Barbara', 'Smith', '2002-04-03', 'Female', 'barbara.smith37@university.edu', '+1-543-590-2374', '515 Main St', 'Melbourne', '3000', 'Australia', 'PHY101', 'Physics', 'Mechanics', 99, 'A+', 'Electromagnetism', 35, 'F', 'Thermodynamics', 46, 'E', 'Fail'),
(38, 'STU0038', 'Rebecca', 'Garcia', '2002-08-11', 'Female', 'rebecca.garcia38@university.edu', '+1-347-609-1682', '307 Pine Ave', 'Sydney', '2000', 'Australia', 'CS201', 'Software Engineering', 'Data Structures', 54, 'D', 'Software Design', 84, 'A', 'Web Development', 76, 'B', 'Pass'),
(39, 'STU0039', 'Elizabeth', 'Jackson', '2004-10-24', 'Female', 'elizabeth.jackson39@university.edu', '+1-941-833-3371', '914 Park Lane', 'Austin', '73301', 'USA', 'ME101', 'Mechanical Engineering', 'Thermodynamics', 99, 'A+', 'Fluid Mechanics', 52, 'D', 'Machine Design', 99, 'A+', 'Pass'),
(40, 'STU0040', 'Edward', 'Nguyen', '2004-01-17', 'Male', 'edward.nguyen40@university.edu', '+1-928-899-4767', '43 Cedar Rd', 'New York', '10001', 'USA', 'CS201', 'Software Engineering', 'Data Structures', 83, 'A', 'Software Design', 92, 'A+', 'Web Development', 41, 'E', 'Pass'),
(41, 'STU0041', 'Kevin', 'Wright', '2000-10-14', 'Male', 'kevin.wright41@university.edu', '+1-897-450-9016', '468 Birch St', 'Toronto', 'M5H2N2', 'Canada', 'ME101', 'Mechanical Engineering', 'Thermodynamics', 99, 'A+', 'Fluid Mechanics', 46, 'E', 'Machine Design', 43, 'E', 'Pass'),
(42, 'STU0042', 'Sarah', 'Jones', '2005-07-16', 'Female', 'sarah.jones42@university.edu', '+1-471-440-4362', '666 Highland Dr', 'Leeds', 'LS11UR', 'UK', 'BUS101', 'Business Administration', 'Accounting', 44, 'E', 'Marketing', 96, 'A+', 'Management', 71, 'B', 'Pass'),
(43, 'STU0043', 'Kenneth', 'Gonzalez', '2003-05-31', 'Male', 'kenneth.gonzalez43@university.edu', '+1-279-814-3415', '668 Willow Way', 'Vancouver', 'V6B1A1', 'Canada', 'HIST101', 'History', 'Ancient History', 52, 'D', 'Modern History', 36, 'F', 'World Politics', 96, 'A+', 'Fail'),
(44, 'STU0044', 'Steven', 'Moore', '2005-10-16', 'Male', 'steven.moore44@university.edu', '+1-888-301-4566', '298 Willow Way', 'Delhi', '110001', 'India', 'BIO101', 'Biology', 'Cell Biology', 94, 'A+', 'Genetics', 94, 'A+', 'Ecology', 94, 'A+', 'Pass'),
(45, 'STU0045', 'Ryan', 'Scott', '2000-11-09', 'Male', 'ryan.scott45@university.edu', '+1-404-519-2406', '297 Highland Dr', 'Sydney', '2000', 'Australia', 'PSY101', 'Psychology', 'Cognitive Psychology', 92, 'A+', 'Developmental Psychology', 69, 'C', 'Social Psychology', 84, 'A', 'Pass'),
(46, 'STU0046', 'Jacob', 'Wilson', '2004-01-12', 'Male', 'jacob.wilson46@university.edu', '+1-276-795-2479', '537 Pine Ave', 'Leeds', 'LS11UR', 'UK', 'MATH101', 'Mathematics', 'Calculus', 100, 'A+', 'Linear Algebra', 70, 'B', 'Statistics', 49, 'E', 'Pass'),
(47, 'STU0047', 'Jessica', 'Young', '2005-01-20', 'Female', 'jessica.young47@university.edu', '+1-697-603-1406', '973 Highland Dr', 'London', 'EC1A1BB', 'UK', 'BUS101', 'Business Administration', 'Accounting', 73, 'B', 'Marketing', 53, 'D', 'Management', 88, 'A', 'Pass'),
(48, 'STU0048', 'Margaret', 'Lee', '2001-05-06', 'Female', 'margaret.lee48@university.edu', '+1-323-539-1028', '860 Sunset Blvd', 'Vancouver', 'V6B1A1', 'Canada', 'PHY101', 'Physics', 'Mechanics', 36, 'F', 'Electromagnetism', 72, 'B', 'Thermodynamics', 67, 'C', 'Fail'),
(49, 'STU0049', 'Jennifer', 'Sanchez', '2000-07-16', 'Female', 'jennifer.sanchez49@university.edu', '+1-599-803-2251', '774 Pine Ave', 'Vancouver', 'V6B1A1', 'Canada', 'BIO101', 'Biology', 'Cell Biology', 48, 'E', 'Genetics', 41, 'E', 'Ecology', 71, 'B', 'Pass'),
(50, 'STU0050', 'Joseph', 'Moore', '2000-04-28', 'Male', 'joseph.moore50@university.edu', '+1-646-723-6170', '804 Sunset Blvd', 'Manchester', 'M11AE', 'UK', 'ENG101', 'English Literature', 'Poetry', 86, 'A', 'Drama', 61, 'C', 'Prose Fiction', 45, 'E', 'Pass'),
(51, 'STU0051', 'Jacob', 'Clark', '2001-06-05', 'Male', 'jacob.clark51@university.edu', '+1-661-829-3270', '498 Maple St', 'Delhi', '110001', 'India', 'MATH101', 'Mathematics', 'Calculus', 95, 'A+', 'Linear Algebra', 88, 'A', 'Statistics', 78, 'B', 'Pass'),
(52, 'STU0052', 'Karen', 'Taylor', '2004-06-03', 'Female', 'karen.taylor52@university.edu', '+1-956-956-5262', '309 Highland Dr', 'Sydney', '2000', 'Australia', 'CS201', 'Software Engineering', 'Data Structures', 56, 'D', 'Software Design', 55, 'D', 'Web Development', 44, 'E', 'Pass'),
(53, 'STU0053', 'Paul', 'Young', '2002-02-27', 'Male', 'paul.young53@university.edu', '+1-763-425-8421', '438 Cedar Rd', 'Vancouver', 'V6B1A1', 'Canada', 'PHY101', 'Physics', 'Mechanics', 46, 'E', 'Electromagnetism', 57, 'D', 'Thermodynamics', 78, 'B', 'Pass'),
(54, 'STU0054', 'Daniel', 'Thomas', '2004-04-17', 'Male', 'daniel.thomas54@university.edu', '+1-577-464-4311', '892 Sunset Blvd', 'Austin', '73301', 'USA', 'BUS101', 'Business Administration', 'Accounting', 61, 'C', 'Marketing', 83, 'A', 'Management', 69, 'C', 'Pass'),
(55, 'STU0055', 'Deborah', 'Brown', '2002-06-03', 'Female', 'deborah.brown55@university.edu', '+1-710-484-6900', '516 Park Lane', 'Leeds', 'LS11UR', 'UK', 'CS201', 'Software Engineering', 'Data Structures', 69, 'C', 'Software Design', 66, 'C', 'Web Development', 84, 'A', 'Pass'),
(56, 'STU0056', 'Michelle', 'Lewis', '2005-04-22', 'Female', 'michelle.lewis56@university.edu', '+1-642-519-1357', '436 Willow Way', 'London', 'EC1A1BB', 'UK', 'HIST101', 'History', 'Ancient History', 97, 'A+', 'Modern History', 35, 'F', 'World Politics', 44, 'E', 'Fail'),
(57, 'STU0057', 'Cynthia', 'King', '2005-11-09', 'Female', 'cynthia.king57@university.edu', '+1-679-659-5070', '159 Cedar Rd', 'New York', '10001', 'USA', 'ENG101', 'English Literature', 'Poetry', 48, 'E', 'Drama', 93, 'A+', 'Prose Fiction', 45, 'E', 'Pass'),
(58, 'STU0058', 'James', 'Rodriguez', '2002-10-28', 'Male', 'james.rodriguez58@university.edu', '+1-438-783-1615', '986 Cedar Rd', 'Delhi', '110001', 'India', 'PSY101', 'Psychology', 'Cognitive Psychology', 90, 'A+', 'Developmental Psychology', 49, 'E', 'Social Psychology', 47, 'E', 'Pass'),
(59, 'STU0059', 'Charles', 'King', '2000-01-05', 'Male', 'charles.king59@university.edu', '+1-796-396-7358', '810 Church St', 'Toronto', 'M5H2N2', 'Canada', 'CS101', 'Computer Science', 'Programming Fundamentals', 73, 'B', 'Databases', 93, 'A+', 'Computer Networks', 70, 'B', 'Pass'),
(60, 'STU0060', 'Michelle', 'Thomas', '2003-06-13', 'Female', 'michelle.thomas60@university.edu', '+1-686-738-4846', '30 Sunset Blvd', 'Berlin', '10115', 'Germany', 'CS101', 'Computer Science', 'Programming Fundamentals', 37, 'F', 'Databases', 59, 'D', 'Computer Networks', 98, 'A+', 'Fail'),
(61, 'STU0061', 'Jennifer', 'Taylor', '2003-10-16', 'Female', 'jennifer.taylor61@university.edu', '+1-433-883-7952', '505 Maple St', 'Toronto', 'M5H2N2', 'Canada', 'ME101', 'Mechanical Engineering', 'Thermodynamics', 88, 'A', 'Fluid Mechanics', 81, 'A', 'Machine Design', 85, 'A', 'Pass'),
(62, 'STU0062', 'James', 'Jackson', '2003-06-30', 'Male', 'james.jackson62@university.edu', '+1-956-716-2104', '994 Elm St', 'Manchester', 'M11AE', 'UK', 'PHY101', 'Physics', 'Mechanics', 64, 'C', 'Electromagnetism', 94, 'A+', 'Thermodynamics', 63, 'C', 'Pass'),
(63, 'STU0063', 'Deborah', 'Jackson', '2005-06-09', 'Female', 'deborah.jackson63@university.edu', '+1-311-838-9122', '918 Elm St', 'Berlin', '10115', 'Germany', 'BUS101', 'Business Administration', 'Accounting', 42, 'E', 'Marketing', 53, 'D', 'Management', 85, 'A', 'Pass'),
(64, 'STU0064', 'Richard', 'Johnson', '2004-05-30', 'Male', 'richard.johnson64@university.edu', '+1-810-345-7805', '62 Cedar Rd', 'Austin', '73301', 'USA', 'ECON101', 'Economics', 'Microeconomics', 75, 'B', 'Macroeconomics', 49, 'E', 'Econometrics', 45, 'E', 'Pass'),
(65, 'STU0065', 'Daniel', 'Gonzalez', '2004-03-30', 'Male', 'daniel.gonzalez65@university.edu', '+1-389-868-9598', '33 Pine Ave', 'Delhi', '110001', 'India', 'CHEM101', 'Chemistry', 'Organic Chemistry', 77, 'B', 'Inorganic Chemistry', 91, 'A+', 'Physical Chemistry', 56, 'D', 'Pass'),
(66, 'STU0066', 'James', 'Garcia', '2002-04-29', 'Male', 'james.garcia66@university.edu', '+1-486-282-6758', '575 Birch St', 'Sydney', '2000', 'Australia', 'BUS101', 'Business Administration', 'Accounting', 80, 'A', 'Marketing', 74, 'B', 'Management', 90, 'A+', 'Pass'),
(67, 'STU0067', 'John', 'Walker', '2005-04-27', 'Male', 'john.walker67@university.edu', '+1-400-581-9872', '332 River Rd', 'Sydney', '2000', 'Australia', 'CS101', 'Computer Science', 'Programming Fundamentals', 87, 'A', 'Databases', 66, 'C', 'Computer Networks', 86, 'A', 'Pass'),
(68, 'STU0068', 'Anthony', 'Williams', '2003-10-20', 'Male', 'anthony.williams68@university.edu', '+1-675-264-2015', '766 Oak Ave', 'Toronto', 'M5H2N2', 'Canada', 'CHEM101', 'Chemistry', 'Organic Chemistry', 69, 'C', 'Inorganic Chemistry', 77, 'B', 'Physical Chemistry', 40, 'E', 'Pass'),
(69, 'STU0069', 'Melissa', 'Lee', '2002-08-15', 'Female', 'melissa.lee69@university.edu', '+1-482-504-1061', '25 Meadow Ln', 'Mumbai', '400001', 'India', 'CS201', 'Software Engineering', 'Data Structures', 95, 'A+', 'Software Design', 94, 'A+', 'Web Development', 84, 'A', 'Pass'),
(70, 'STU0070', 'Cynthia', 'Ramirez', '2003-05-27', 'Female', 'cynthia.ramirez70@university.edu', '+1-705-335-9135', '822 Willow Way', 'London', 'EC1A1BB', 'UK', 'ME101', 'Mechanical Engineering', 'Thermodynamics', 54, 'D', 'Fluid Mechanics', 65, 'C', 'Machine Design', 76, 'B', 'Pass'),
(71, 'STU0071', 'Sandra', 'White', '2002-10-09', 'Female', 'sandra.white71@university.edu', '+1-810-280-9386', '771 Cedar Rd', 'Manchester', 'M11AE', 'UK', 'BUS101', 'Business Administration', 'Accounting', 43, 'E', 'Marketing', 39, 'F', 'Management', 96, 'A+', 'Fail'),
(72, 'STU0072', 'Barbara', 'Ramirez', '2004-09-20', 'Female', 'barbara.ramirez72@university.edu', '+1-307-273-5339', '214 Oak Ave', 'Berlin', '10115', 'Germany', 'ECON101', 'Economics', 'Microeconomics', 92, 'A+', 'Macroeconomics', 57, 'D', 'Econometrics', 64, 'C', 'Pass'),
(73, 'STU0073', 'Mark', 'Robinson', '2003-04-18', 'Male', 'mark.robinson73@university.edu', '+1-835-890-4849', '799 Meadow Ln', 'Mumbai', '400001', 'India', 'BIO101', 'Biology', 'Cell Biology', 70, 'B', 'Genetics', 69, 'C', 'Ecology', 82, 'A', 'Pass'),
(74, 'STU0074', 'Melissa', 'Taylor', '2003-02-26', 'Female', 'melissa.taylor74@university.edu', '+1-403-649-5053', '242 Cedar Rd', 'London', 'EC1A1BB', 'UK', 'HIST101', 'History', 'Ancient History', 59, 'D', 'Modern History', 76, 'B', 'World Politics', 43, 'E', 'Pass'),
(75, 'STU0075', 'Sarah', 'Thomas', '2000-05-31', 'Female', 'sarah.thomas75@university.edu', '+1-719-738-4790', '670 Highland Dr', 'Mumbai', '400001', 'India', 'CS201', 'Software Engineering', 'Data Structures', 35, 'F', 'Software Design', 95, 'A+', 'Web Development', 64, 'C', 'Fail'),
(76, 'STU0076', 'Cynthia', 'White', '2002-03-06', 'Female', 'cynthia.white76@university.edu', '+1-241-500-4815', '195 Church St', 'New York', '10001', 'USA', 'CS201', 'Software Engineering', 'Data Structures', 82, 'A', 'Software Design', 100, 'A+', 'Web Development', 57, 'D', 'Pass'),
(77, 'STU0077', 'Donna', 'Taylor', '2003-12-03', 'Female', 'donna.taylor77@university.edu', '+1-993-996-1103', '611 Willow Way', 'Austin', '73301', 'USA', 'PHY101', 'Physics', 'Mechanics', 39, 'F', 'Electromagnetism', 82, 'A', 'Thermodynamics', 78, 'B', 'Fail'),
(78, 'STU0078', 'John', 'Wilson', '2004-03-02', 'Male', 'john.wilson78@university.edu', '+1-461-239-4333', '419 Main St', 'Chicago', '60601', 'USA', 'MATH101', 'Mathematics', 'Calculus', 74, 'B', 'Linear Algebra', 44, 'E', 'Statistics', 61, 'C', 'Pass'),
(79, 'STU0079', 'Jason', 'Young', '2001-09-25', 'Male', 'jason.young79@university.edu', '+1-761-695-2036', '815 Sunset Blvd', 'Sydney', '2000', 'Australia', 'ENG101', 'English Literature', 'Poetry', 46, 'E', 'Drama', 55, 'D', 'Prose Fiction', 85, 'A', 'Pass'),
(80, 'STU0080', 'Betty', 'Jackson', '2004-01-03', 'Female', 'betty.jackson80@university.edu', '+1-883-514-7845', '764 Church St', 'Chicago', '60601', 'USA', 'BUS101', 'Business Administration', 'Accounting', 88, 'A', 'Marketing', 37, 'F', 'Management', 81, 'A', 'Fail'),
(81, 'STU0081', 'Anthony', 'Sanchez', '2001-01-05', 'Male', 'anthony.sanchez81@university.edu', '+1-408-206-8113', '117 Meadow Ln', 'Manchester', 'M11AE', 'UK', 'BUS101', 'Business Administration', 'Accounting', 81, 'A', 'Marketing', 93, 'A+', 'Management', 55, 'D', 'Pass'),
(82, 'STU0082', 'James', 'Brown', '2005-08-28', 'Male', 'james.brown82@university.edu', '+1-764-345-7499', '638 River Rd', 'Austin', '73301', 'USA', 'MATH101', 'Mathematics', 'Calculus', 53, 'D', 'Linear Algebra', 79, 'B', 'Statistics', 71, 'B', 'Pass'),
(83, 'STU0083', 'Paul', 'Hernandez', '2000-06-27', 'Male', 'paul.hernandez83@university.edu', '+1-268-311-7287', '309 Cedar Rd', 'Sydney', '2000', 'Australia', 'ECON101', 'Economics', 'Microeconomics', 75, 'B', 'Macroeconomics', 41, 'E', 'Econometrics', 84, 'A', 'Pass'),
(84, 'STU0084', 'Ryan', 'Flores', '2002-03-14', 'Male', 'ryan.flores84@university.edu', '+1-904-364-4638', '630 Meadow Ln', 'Munich', '80331', 'Germany', 'ECON101', 'Economics', 'Microeconomics', 58, 'D', 'Macroeconomics', 62, 'C', 'Econometrics', 40, 'E', 'Pass'),
(85, 'STU0085', 'Dorothy', 'Hernandez', '2002-02-27', 'Female', 'dorothy.hernandez85@university.edu', '+1-592-567-3016', '994 Willow Way', 'London', 'EC1A1BB', 'UK', 'CS101', 'Computer Science', 'Programming Fundamentals', 39, 'F', 'Databases', 76, 'B', 'Computer Networks', 50, 'D', 'Fail'),
(86, 'STU0086', 'Donna', 'Robinson', '2002-10-17', 'Female', 'donna.robinson86@university.edu', '+1-763-842-6017', '316 Church St', 'Delhi', '110001', 'India', 'BUS101', 'Business Administration', 'Accounting', 84, 'A', 'Marketing', 82, 'A', 'Management', 92, 'A+', 'Pass'),
(87, 'STU0087', 'Barbara', 'Johnson', '2005-02-20', 'Female', 'barbara.johnson87@university.edu', '+1-203-833-9019', '458 Birch St', 'Sydney', '2000', 'Australia', 'MATH101', 'Mathematics', 'Calculus', 95, 'A+', 'Linear Algebra', 86, 'A', 'Statistics', 48, 'E', 'Pass'),
(88, 'STU0088', 'William', 'Thompson', '2001-06-17', 'Male', 'william.thompson88@university.edu', '+1-640-574-2502', '42 Main St', 'Sydney', '2000', 'Australia', 'CS201', 'Software Engineering', 'Data Structures', 75, 'B', 'Software Design', 100, 'A+', 'Web Development', 45, 'E', 'Pass'),
(89, 'STU0089', 'Ronald', 'Allen', '2001-03-24', 'Male', 'ronald.allen89@university.edu', '+1-586-868-3231', '629 Willow Way', 'New York', '10001', 'USA', 'PHY101', 'Physics', 'Mechanics', 51, 'D', 'Electromagnetism', 97, 'A+', 'Thermodynamics', 71, 'B', 'Pass'),
(90, 'STU0090', 'Brian', 'Anderson', '2003-01-31', 'Male', 'brian.anderson90@university.edu', '+1-267-559-5132', '919 Church St', 'Manchester', 'M11AE', 'UK', 'ECON101', 'Economics', 'Microeconomics', 53, 'D', 'Macroeconomics', 67, 'C', 'Econometrics', 99, 'A+', 'Pass'),
(91, 'STU0091', 'Susan', 'Nguyen', '2002-03-25', 'Female', 'susan.nguyen91@university.edu', '+1-469-830-9290', '382 Maple St', 'Manchester', 'M11AE', 'UK', 'MATH101', 'Mathematics', 'Calculus', 86, 'A', 'Linear Algebra', 55, 'D', 'Statistics', 70, 'B', 'Pass'),
(92, 'STU0092', 'Sharon', 'Harris', '2004-01-13', 'Female', 'sharon.harris92@university.edu', '+1-372-470-2885', '652 Meadow Ln', 'Berlin', '10115', 'Germany', 'ECON101', 'Economics', 'Microeconomics', 48, 'E', 'Macroeconomics', 67, 'C', 'Econometrics', 85, 'A', 'Pass'),
(93, 'STU0093', 'Sarah', 'Harris', '2004-12-16', 'Female', 'sarah.harris93@university.edu', '+1-577-791-3395', '783 Oak Ave', 'Vancouver', 'V6B1A1', 'Canada', 'PHY101', 'Physics', 'Mechanics', 57, 'D', 'Electromagnetism', 41, 'E', 'Thermodynamics', 72, 'B', 'Pass'),
(94, 'STU0094', 'Karen', 'Nguyen', '2003-04-06', 'Female', 'karen.nguyen94@university.edu', '+1-879-520-1029', '227 Cedar Rd', 'Mumbai', '400001', 'India', 'HIST101', 'History', 'Ancient History', 90, 'A+', 'Modern History', 88, 'A', 'World Politics', 100, 'A+', 'Pass'),
(95, 'STU0095', 'Sharon', 'Brown', '2000-01-11', 'Female', 'sharon.brown95@university.edu', '+1-335-700-4723', '23 Maple St', 'Berlin', '10115', 'Germany', 'HIST101', 'History', 'Ancient History', 80, 'A', 'Modern History', 73, 'B', 'World Politics', 48, 'E', 'Pass'),
(96, 'STU0096', 'Kimberly', 'Anderson', '2005-04-29', 'Female', 'kimberly.anderson96@university.edu', '+1-623-797-5934', '210 River Rd', 'Berlin', '10115', 'Germany', 'MATH101', 'Mathematics', 'Calculus', 52, 'D', 'Linear Algebra', 36, 'F', 'Statistics', 66, 'C', 'Fail'),
(97, 'STU0097', 'Donald', 'Miller', '2002-12-18', 'Male', 'donald.miller97@university.edu', '+1-265-853-3370', '412 Birch St', 'Delhi', '110001', 'India', 'CS101', 'Computer Science', 'Programming Fundamentals', 42, 'E', 'Databases', 79, 'B', 'Computer Networks', 91, 'A+', 'Pass'),
(98, 'STU0098', 'Jessica', 'Hernandez', '2002-08-31', 'Female', 'jessica.hernandez98@university.edu', '+1-200-245-2008', '416 Cedar Rd', 'Berlin', '10115', 'Germany', 'MATH101', 'Mathematics', 'Calculus', 42, 'E', 'Linear Algebra', 48, 'E', 'Statistics', 36, 'F', 'Fail'),
(99, 'STU0099', 'William', 'Clark', '2001-12-16', 'Male', 'william.clark99@university.edu', '+1-404-730-9305', '833 Church St', 'Delhi', '110001', 'India', 'PSY101', 'Psychology', 'Cognitive Psychology', 74, 'B', 'Developmental Psychology', 43, 'E', 'Social Psychology', 73, 'B', 'Pass'),
(100, 'STU0100', 'Ryan', 'Walker', '2000-11-25', 'Male', 'ryan.walker100@university.edu', '+1-932-751-1104', '764 Highland Dr', 'Melbourne', '3000', 'Australia', 'ME101', 'Mechanical Engineering', 'Thermodynamics', 92, 'A+', 'Fluid Mechanics', 57, 'D', 'Machine Design', 63, 'C', 'Pass');

-- ---------------- INSERT: attendance (100 rows) ----------------
INSERT INTO public.attendance (attendance_id, student_id, course_code, semester, total_classes, classes_attended, attendance_percentage) VALUES
(1, 1, 'HIST101', 'Fall 2024', 63, 47, 74.6),
(2, 2, 'CS201', 'Fall 2024', 80, 42, 52.5),
(3, 3, 'HIST101', 'Fall 2024', 70, 51, 72.86),
(4, 4, 'CHEM101', 'Spring 2025', 68, 61, 89.71),
(5, 5, 'PSY101', 'Fall 2024', 69, 47, 68.12),
(6, 6, 'ENG101', 'Fall 2024', 88, 76, 86.36),
(7, 7, 'MATH101', 'Fall 2024', 65, 48, 73.85),
(8, 8, 'ME101', 'Fall 2024', 86, 55, 63.95),
(9, 9, 'BIO101', 'Fall 2024', 83, 61, 73.49),
(10, 10, 'ECON101', 'Spring 2025', 88, 68, 77.27),
(11, 11, 'CS201', 'Spring 2025', 79, 54, 68.35),
(12, 12, 'HIST101', 'Spring 2025', 89, 84, 94.38),
(13, 13, 'CS201', 'Fall 2024', 75, 70, 93.33),
(14, 14, 'PSY101', 'Spring 2025', 87, 44, 50.57),
(15, 15, 'PHY101', 'Spring 2025', 90, 59, 65.56),
(16, 16, 'ECON101', 'Spring 2025', 85, 55, 64.71),
(17, 17, 'ECON101', 'Fall 2024', 79, 76, 96.2),
(18, 18, 'ECON101', 'Fall 2024', 78, 49, 62.82),
(19, 19, 'ENG101', 'Fall 2024', 61, 31, 50.82),
(20, 20, 'CS101', 'Spring 2025', 63, 41, 65.08),
(21, 21, 'ECON101', 'Fall 2024', 64, 33, 51.56),
(22, 22, 'MATH101', 'Fall 2024', 61, 38, 62.3),
(23, 23, 'BIO101', 'Fall 2024', 82, 45, 54.88),
(24, 24, 'PSY101', 'Fall 2024', 62, 54, 87.1),
(25, 25, 'CS201', 'Fall 2024', 86, 77, 89.53),
(26, 26, 'ECON101', 'Fall 2024', 88, 68, 77.27),
(27, 27, 'CHEM101', 'Fall 2024', 67, 46, 68.66),
(28, 28, 'PSY101', 'Fall 2024', 63, 33, 52.38),
(29, 29, 'BUS101', 'Fall 2024', 90, 85, 94.44),
(30, 30, 'BIO101', 'Spring 2025', 86, 83, 96.51),
(31, 31, 'CS101', 'Fall 2024', 75, 43, 57.33),
(32, 32, 'ENG101', 'Spring 2025', 63, 44, 69.84),
(33, 33, 'ECON101', 'Spring 2025', 70, 56, 80.0),
(34, 34, 'BUS101', 'Spring 2025', 68, 35, 51.47),
(35, 35, 'HIST101', 'Fall 2024', 68, 52, 76.47),
(36, 36, 'PHY101', 'Spring 2025', 82, 64, 78.05),
(37, 37, 'PHY101', 'Spring 2025', 84, 80, 95.24),
(38, 38, 'CS201', 'Fall 2024', 87, 61, 70.11),
(39, 39, 'ME101', 'Fall 2024', 85, 68, 80.0),
(40, 40, 'CS201', 'Fall 2024', 73, 69, 94.52),
(41, 41, 'ME101', 'Fall 2024', 71, 65, 91.55),
(42, 42, 'BUS101', 'Fall 2024', 77, 74, 96.1),
(43, 43, 'HIST101', 'Spring 2025', 82, 46, 56.1),
(44, 44, 'BIO101', 'Fall 2024', 65, 59, 90.77),
(45, 45, 'PSY101', 'Spring 2025', 76, 50, 65.79),
(46, 46, 'MATH101', 'Fall 2024', 84, 45, 53.57),
(47, 47, 'BUS101', 'Fall 2024', 71, 66, 92.96),
(48, 48, 'PHY101', 'Spring 2025', 75, 48, 64.0),
(49, 49, 'BIO101', 'Spring 2025', 78, 61, 78.21),
(50, 50, 'ENG101', 'Spring 2025', 78, 49, 62.82),
(51, 51, 'MATH101', 'Fall 2024', 86, 56, 65.12),
(52, 52, 'CS201', 'Fall 2024', 75, 47, 62.67),
(53, 53, 'PHY101', 'Fall 2024', 90, 85, 94.44),
(54, 54, 'BUS101', 'Fall 2024', 75, 72, 96.0),
(55, 55, 'CS201', 'Spring 2025', 80, 60, 75.0),
(56, 56, 'HIST101', 'Spring 2025', 63, 56, 88.89),
(57, 57, 'ENG101', 'Spring 2025', 88, 49, 55.68),
(58, 58, 'PSY101', 'Fall 2024', 88, 85, 96.59),
(59, 59, 'CS101', 'Spring 2025', 71, 48, 67.61),
(60, 60, 'CS101', 'Fall 2024', 68, 61, 89.71),
(61, 61, 'ME101', 'Spring 2025', 72, 50, 69.44),
(62, 62, 'PHY101', 'Spring 2025', 64, 34, 53.12),
(63, 63, 'BUS101', 'Fall 2024', 78, 59, 75.64),
(64, 64, 'ECON101', 'Spring 2025', 87, 71, 81.61),
(65, 65, 'CHEM101', 'Spring 2025', 65, 61, 93.85),
(66, 66, 'BUS101', 'Fall 2024', 82, 57, 69.51),
(67, 67, 'CS101', 'Spring 2025', 64, 53, 82.81),
(68, 68, 'CHEM101', 'Fall 2024', 80, 55, 68.75),
(69, 69, 'CS201', 'Fall 2024', 68, 53, 77.94),
(70, 70, 'ME101', 'Fall 2024', 83, 50, 60.24),
(71, 71, 'BUS101', 'Spring 2025', 83, 61, 73.49),
(72, 72, 'ECON101', 'Spring 2025', 65, 47, 72.31),
(73, 73, 'BIO101', 'Spring 2025', 90, 57, 63.33),
(74, 74, 'HIST101', 'Fall 2024', 90, 51, 56.67),
(75, 75, 'CS201', 'Fall 2024', 90, 87, 96.67),
(76, 76, 'CS201', 'Fall 2024', 66, 57, 86.36),
(77, 77, 'PHY101', 'Spring 2025', 64, 51, 79.69),
(78, 78, 'MATH101', 'Fall 2024', 73, 53, 72.6),
(79, 79, 'ENG101', 'Spring 2025', 63, 37, 58.73),
(80, 80, 'BUS101', 'Spring 2025', 66, 57, 86.36),
(81, 81, 'BUS101', 'Spring 2025', 61, 30, 49.18),
(82, 82, 'MATH101', 'Fall 2024', 87, 70, 80.46),
(83, 83, 'ECON101', 'Spring 2025', 76, 56, 73.68),
(84, 84, 'ECON101', 'Spring 2025', 60, 34, 56.67),
(85, 85, 'CS101', 'Fall 2024', 79, 64, 81.01),
(86, 86, 'BUS101', 'Spring 2025', 83, 56, 67.47),
(87, 87, 'MATH101', 'Spring 2025', 82, 77, 93.9),
(88, 88, 'CS201', 'Fall 2024', 87, 57, 65.52),
(89, 89, 'PHY101', 'Fall 2024', 81, 51, 62.96),
(90, 90, 'ECON101', 'Spring 2025', 74, 64, 86.49),
(91, 91, 'MATH101', 'Spring 2025', 68, 40, 58.82),
(92, 92, 'ECON101', 'Fall 2024', 67, 58, 86.57),
(93, 93, 'PHY101', 'Spring 2025', 68, 61, 89.71),
(94, 94, 'HIST101', 'Spring 2025', 74, 38, 51.35),
(95, 95, 'HIST101', 'Spring 2025', 76, 49, 64.47),
(96, 96, 'MATH101', 'Spring 2025', 84, 42, 50.0),
(97, 97, 'CS101', 'Fall 2024', 86, 74, 86.05),
(98, 98, 'MATH101', 'Fall 2024', 61, 46, 75.41),
(99, 99, 'PSY101', 'Spring 2025', 65, 44, 67.69),
(100, 100, 'ME101', 'Fall 2024', 63, 60, 95.24);

-- ============================================================
-- Example JOIN queries
-- ============================================================

-- 1) Student roster with course info
SELECT s.student_number, s.first_name, s.last_name, s.course_code, c.course_name, c.department
FROM public.students s
JOIN public.courses c ON s.course_code = c.course_code
ORDER BY s.last_name;

-- 2) Number of students enrolled per course
SELECT c.course_code, c.course_name, COUNT(s.student_id) AS num_students
FROM public.courses c
LEFT JOIN public.students s ON c.course_code = s.course_code
GROUP BY c.course_code, c.course_name
ORDER BY num_students DESC;

-- 3) Students with attendance below 75%, alongside their course and overall result
SELECT s.student_number, s.first_name, s.last_name, c.course_name,
       a.attendance_percentage, s.overall_result
FROM public.attendance a
JOIN public.students s ON a.student_id = s.student_id
JOIN public.courses c  ON s.course_code = c.course_code
WHERE a.attendance_percentage < 75
ORDER BY a.attendance_percentage;

-- 4) Average marks per subject slot, by department
SELECT c.department,
       ROUND(AVG(s.marks1), 1) AS avg_subject1,
       ROUND(AVG(s.marks2), 1) AS avg_subject2,
       ROUND(AVG(s.marks3), 1) AS avg_subject3
FROM public.students s
JOIN public.courses c ON s.course_code = c.course_code
GROUP BY c.department
ORDER BY c.department;
