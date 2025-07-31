-- Drop existing functions and procedures to avoid dependency errors.
DROP FUNCTION IF EXISTS get_bugs_for_repository(INT);
DROP PROCEDURE IF EXISTS get_comprehensive_commit_details();
DROP PROCEDURE IF EXISTS get_active_users();

-- Drop existing tables and types to ensure a clean slate.
-- The order is important to avoid foreign key constraint errors.
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS bugs CASCADE;
DROP TABLE IF EXISTS feature_requests CASCADE;
DROP TABLE IF EXISTS issues CASCADE;
DROP TABLE IF EXISTS commits CASCADE;
DROP TABLE IF EXISTS repositories CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop any user-defined types that might exist.
DROP TYPE IF EXISTS issue_status;


-- Create user-defined types
CREATE TYPE issue_status AS ENUM ('Open', 'In Progress', 'Closed');


-- Create tables for the source code repository system

-- Users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    creation_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Repositories table
CREATE TABLE repositories (
    repo_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    creation_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    owner_id INT NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES users(user_id)
);

-- Commits table
-- The commit_id is TEXT because it represents a cryptographic hash (like SHA-1)
-- rather than a sequential integer, mirroring real-world version control systems like Git.
CREATE TABLE commits (
    commit_id TEXT PRIMARY KEY,
    message TEXT NOT NULL,
    commit_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    changed_files TEXT[],
    author_id INT NOT NULL,
    repo_id INT NOT NULL,
    FOREIGN KEY (author_id) REFERENCES users(user_id),
    FOREIGN KEY (repo_id) REFERENCES repositories(repo_id)
);

-- Issues table (Parent table for Bugs and Feature Requests)
CREATE TABLE issues (
    issue_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status issue_status DEFAULT 'Open',
    creation_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reporter_id INT NOT NULL,
    repo_id INT NOT NULL,
    FOREIGN KEY (reporter_id) REFERENCES users(user_id),
    FOREIGN KEY (repo_id) REFERENCES repositories(repo_id)
);

-- Bugs table (inherits from Issues)
CREATE TABLE bugs (
    steps_to_reproduce TEXT,
    expected_behavior TEXT,
    actual_behavior TEXT
) INHERITS (issues);

-- Feature Requests table (inherits from Issues)
CREATE TABLE feature_requests (
    feature_description TEXT,
    acceptance_criteria TEXT
) INHERITS (issues);

-- Comments table
-- A comment can be linked to an issue OR a commit, but not both.
-- The FOREIGN KEY to issues is handled by a trigger because of inheritance.
CREATE TABLE comments (
    comment_id SERIAL PRIMARY KEY,
    text TEXT NOT NULL,
    comment_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    author_id INT NOT NULL,
    issue_id INT,
    commit_id TEXT,
    FOREIGN KEY (author_id) REFERENCES users(user_id),
    FOREIGN KEY (commit_id) REFERENCES commits(commit_id),
    CONSTRAINT chk_comment_parent CHECK (
        (issue_id IS NOT NULL AND commit_id IS NULL) OR
        (issue_id IS NULL AND commit_id IS NOT NULL)
    )
);

-- Trigger function to validate the foreign key to the issues table manually.
CREATE OR REPLACE FUNCTION check_issue_exists()
RETURNS TRIGGER AS $FUNCTION$
BEGIN
    IF NEW.issue_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM issues WHERE issue_id = NEW.issue_id) THEN
            RAISE EXCEPTION 'Foreign key violation: issue_id % not found in issues hierarchy', NEW.issue_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$FUNCTION$ LANGUAGE plpgsql;

-- Trigger to enforce the check on the comments table.
CREATE TRIGGER trg_check_comment_issue
BEFORE INSERT OR UPDATE ON comments
FOR EACH ROW EXECUTE FUNCTION check_issue_exists();

-- Insert sample data

-- Users
INSERT INTO users (username, email) VALUES
('alice', 'alice@example.com'),
('bob', 'bob@example.com'),
('charlie', 'charlie@example.com'),
('david', 'david@example.com'),
('eve', 'eve@example.com'),
('frank', 'frank@example.com'),
('grace', 'grace@example.com'),
('heidi', 'heidi@example.com'),
('ivan', 'ivan@example.com'),
('judy', 'judy@example.com');

-- Repositories
INSERT INTO repositories (name, description, owner_id) VALUES
('Project Phoenix', 'A revolutionary new framework for modern web development.', 1),
('Data-Visualizer', 'A tool for visualizing complex datasets and generating insightful charts.', 2),
('Code-Linter', 'A static analysis tool to enforce coding standards.', 3),
('Game-Engine', 'A lightweight 2D game engine written in C++.', 1),
('Mobile-App', 'A cross-platform mobile application for task management.', 4);

-- Commits
INSERT INTO commits (commit_id, message, changed_files, author_id, repo_id) VALUES
('a1b2c3d4', 'Initial commit for Project Phoenix', ARRAY['README.md', 'src/main.js'], 1, 1),
('e5f6g7h8', 'Add user authentication to Phoenix', ARRAY['src/auth.js', 'tests/auth.test.js'], 2, 1),
('i9j0k1l2', 'Fix off-by-one error in chart rendering for Data-Visualizer', ARRAY['src/chart.js'], 2, 2),
('m3n4o5p6', 'Implement basic linting rules for Code-Linter', ARRAY['rules/naming.js', 'rules/spacing.js'], 3, 3),
('q7r8s9t0', 'Add sprite rendering to Game-Engine', ARRAY['src/renderer.cpp', 'include/renderer.h'], 5, 4),
('u1v2w3x4', 'Refactor database connection for Mobile-App', ARRAY['lib/db.dart'], 4, 5),
('y5z6a7b8', 'Update documentation for Project Phoenix', ARRAY['README.md', 'docs/getting_started.md'], 1, 1);

-- Issues (Bugs and Feature Requests)
-- Note: We insert into the specific child tables (bugs, feature_requests)
INSERT INTO bugs (title, description, status, reporter_id, repo_id, steps_to_reproduce, expected_behavior, actual_behavior) VALUES
('UI Glitch on Login', 'The login button is misaligned on mobile.', 'Open', 1, 1, '1. Open on mobile.\n2. Navigate to login page.', 'Button is centered.', 'Button is off to the left.'),
('Chart data not updating', 'The chart does not reflect new data points added in real-time.', 'In Progress', 2, 2, '1. Load the dashboard.\n2. Add a new data point via the API.\n3. Observe the chart.', 'Chart updates automatically.', 'Chart remains static.'),
('Incorrect linting error', 'The linter incorrectly flags valid ES6 syntax.', 'Closed', 3, 3, '1. Write an arrow function.\n2. Run the linter.', 'No error is reported.', 'Linter reports a syntax error.');

INSERT INTO feature_requests (title, description, status, reporter_id, repo_id, feature_description, acceptance_criteria) VALUES
('Add Dark Mode', 'Implement a dark mode for the UI.', 'In Progress', 2, 1, 'A new theme that uses a darker color palette.', '1. User can toggle dark mode.\n2. All components render correctly.'),
('Export chart to PNG', 'Allow users to export their created charts as PNG images.', 'Open', 5, 2, 'A button to download the current chart view as a PNG file.', '1. Button is visible.\n2. Clicking downloads a valid PNG file.'),
('Support for TypeScript', 'Add support for linting TypeScript files.', 'Open', 6, 3, 'The linter should be able to parse and apply rules to .ts files.', '1. Linter runs on .ts files without crashing.\n2. TypeScript-specific rules can be configured.');

-- Comments
-- A comment on an issue
INSERT INTO comments (text, author_id, issue_id) VALUES
('I can confirm this bug on my device as well.', 2, 1),
('Working on this now, should have a PR ready by tomorrow.', 1, 4),
('This is a critical feature for our team. Any ETA?', 7, 5);

-- A comment on a commit
INSERT INTO comments (text, author_id, commit_id) VALUES
('Good catch! This was a tricky one.', 1, 'i9j0k1l2'),
('Why did we choose to use this library? Seems a bit heavy.', 8, 'e5f6g7h8'),
('This change looks good to me. Approved.', 9, 'y5z6a7b8');

--
-- SQL Queries (Task 5)
--

-- Query 5a: Multi-Join Query
-- Natural Language: Retrieves a list of users, the commits they have authored,
-- and the repositories those commits belong to. It also includes any comments
-- made on those specific commits. The list is filtered to show only commits
-- that involved changes to more than one file. This query is embedded in a
-- stored procedure as required.
--
CREATE OR REPLACE PROCEDURE get_comprehensive_commit_details()
LANGUAGE plpgsql
AS $PROCEDURE$
BEGIN
    -- This temporary table will hold the results.
    -- It is dropped at the end of the procedure.
    CREATE TEMP TABLE comprehensive_commit_details AS
    SELECT
        u.username AS author,
        r.name AS repository_name,
        c.commit_id,
        c.message,
        com.text AS comment_text
    FROM
        users u
    INNER JOIN
        commits c ON u.user_id = c.author_id
    INNER JOIN
        repositories r ON c.repo_id = r.repo_id
    LEFT JOIN
        comments com ON c.commit_id = com.commit_id
    WHERE
        array_length(c.changed_files, 1) > 1;
END;
$PROCEDURE$;

-- Execute the procedure and display its results.
CALL get_comprehensive_commit_details();
SELECT * FROM comprehensive_commit_details;

-- Query 5b: Set Operator Query (UNION)
-- Natural Language: Creates a stored procedure that produces a single list of
-- unique usernames for all users who have either authored a commit or reported a bug.
--
CREATE OR REPLACE PROCEDURE get_active_users()
LANGUAGE plpgsql
AS $PROCEDURE$
BEGIN
    CREATE TEMP TABLE active_users AS
    (SELECT u.username
     FROM users u
     INNER JOIN commits c ON u.user_id = c.author_id)
    UNION
    (SELECT u.username
     FROM users u
     INNER JOIN bugs b ON u.user_id = b.reporter_id);
END;
$PROCEDURE$;

-- Execute the procedure and display its results.
CALL get_active_users();
SELECT * FROM active_users;

-- Query 5c: Array/Inheritance Query (using a Stored Function)
-- Natural Language: Creates a stored function that takes a repository ID as
-- input and returns a table of all bug reports for that repository, including
-- their full details and a calculated "age" (how long ago they were created).
-- This demonstrates querying an inherited table (`bugs`).
--
CREATE OR REPLACE FUNCTION get_bugs_for_repository(p_repo_id INT)
RETURNS TABLE (
    issue_id INT,
    title VARCHAR(255),
    description TEXT,
    status issue_status,
    reporter_id INT,
    repo_id INT,
    steps_to_reproduce TEXT,
    expected_behavior TEXT,
    actual_behavior TEXT,
    age INTERVAL
)
LANGUAGE plpgsql
AS $FUNCTION$
BEGIN
    RETURN QUERY
    SELECT
        b.issue_id,
        b.title,
        b.description,
        b.status,
        b.reporter_id,
        b.repo_id,
        b.steps_to_reproduce,
        b.expected_behavior,
        b.actual_behavior,
        AGE(CURRENT_TIMESTAMP, b.creation_date) AS age
    FROM
        bugs b
    WHERE
        b.repo_id = p_repo_id;
END;
$FUNCTION$;

-- Execute the function and display its results for repository 1.
SELECT * FROM get_bugs_for_repository(1);

-- Query 5d: Temporal Query
-- Natural Language: Finds all pairs of commits that were made within 5 minutes
-- of each other in the same repository. This could help identify a quick
-- succession of related changes.
--
SELECT
    c1.commit_id AS first_commit,
    c1.commit_timestamp AS first_commit_time,
    c2.commit_id AS second_commit,
    c2.commit_timestamp AS second_commit_time,
    c2.commit_timestamp - c1.commit_timestamp AS time_difference
FROM
    commits c1
INNER JOIN
    commits c2 ON c1.repo_id = c2.repo_id AND c1.commit_id < c2.commit_id
WHERE
    c2.commit_timestamp - c1.commit_timestamp BETWEEN INTERVAL '0 seconds' AND INTERVAL '5 minutes';

-- Query 5e: OLAP Query (ROLLUP)
-- Natural Language: Generates a report that counts the number of issues,
-- breaking the count down by repository and by status. It includes sub-totals
-- for each repository and a grand total for all issues.
--
SELECT
    COALESCE(r.name, 'All Repositories') AS repository_name,
    COALESCE(i.status::TEXT, 'All Statuses') AS issue_status,
    COUNT(i.issue_id) AS number_of_issues
FROM
    issues i
INNER JOIN
    repositories r ON i.repo_id = r.repo_id
GROUP BY
    ROLLUP(r.name, i.status);