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
CREATE TABLE comments (
    comment_id SERIAL PRIMARY KEY,
    text TEXT NOT NULL,
    comment_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    author_id INT NOT NULL,
    issue_id INT,
    commit_id TEXT,
    FOREIGN KEY (author_id) REFERENCES users(user_id),
    FOREIGN KEY (issue_id) REFERENCES issues(issue_id),
    FOREIGN KEY (commit_id) REFERENCES commits(commit_id),
    CONSTRAINT chk_comment_parent CHECK (
        (issue_id IS NOT NULL AND commit_id IS NULL) OR
        (issue_id IS NULL AND commit_id IS NOT NULL)
    )
);

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
