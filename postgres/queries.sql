-- Task 2: PostgreSQL Object-Relational Implementation
-- Full script to create the database schema and insert sample data.

-- Drop existing tables and types to ensure a clean slate
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS commits CASCADE;
DROP TABLE IF EXISTS bugs CASCADE;
DROP TABLE IF EXISTS feature_requests CASCADE;
DROP TABLE IF EXISTS issues CASCADE;
DROP TABLE IF EXISTS repositories CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TYPE IF EXISTS issue_type CASCADE;

-- Create custom types
-- Although we use inheritance for Bug/FeatureRequest, a type for the issue itself is useful.
-- We'll use this to distinguish between issue types in queries.
CREATE TYPE issue_type AS ENUM ('Bug', 'FeatureRequest');

-- Table for Users
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table for Repositories
CREATE TABLE repositories (
    repo_id SERIAL PRIMARY KEY,
    owner_id INT NOT NULL REFERENCES users(user_id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (owner_id, name)
);

-- Parent Table for Issues (acts as an abstract class)
CREATE TABLE issues (
    issue_id SERIAL PRIMARY KEY,
    repo_id INT NOT NULL REFERENCES repositories(repo_id),
    reporter_id INT NOT NULL REFERENCES users(user_id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'Open',
    issue_kind issue_type NOT NULL, -- Discriminator column
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Child table for Bugs, inheriting from Issues
CREATE TABLE bugs (
    severity VARCHAR(50) NOT NULL,
    CHECK (issue_kind = 'Bug') -- Enforce the correct type
) INHERITS (issues);

-- Child table for Feature Requests, inheriting from Issues
CREATE TABLE feature_requests (
    priority INT NOT NULL DEFAULT 0,
    target_version VARCHAR(50),
    CHECK (issue_kind = 'FeatureRequest') -- Enforce the correct type
) INHERITS (issues);

-- Table for Commits
CREATE TABLE commits (
    commit_hash CHAR(40) PRIMARY KEY,
    repo_id INT NOT NULL REFERENCES repositories(repo_id),
    author_id INT NOT NULL REFERENCES users(user_id),
    message TEXT NOT NULL,
    changed_files TEXT[] NOT NULL, -- Array of file paths
    committed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table for Comments
-- A comment can be on an issue or a commit, but not both.
CREATE TABLE comments (
    comment_id SERIAL PRIMARY KEY,
    issue_id INT REFERENCES issues(issue_id),
    commit_hash CHAR(40) REFERENCES commits(commit_hash),
    author_id INT NOT NULL REFERENCES users(user_id),
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT chk_comment_target CHECK (
        (issue_id IS NOT NULL AND commit_hash IS NULL) OR
        (issue_id IS NULL AND commit_hash IS NOT NULL)
    )
);

-- --- Sample Data Insertion ---

DO $
DECLARE
    -- User IDs
    alice_id INT;
    bob_id INT;

    -- Repo IDs
    phoenix_repo_id INT;
    pipeline_repo_id INT;

    -- Issue IDs
    bug_issue_id INT;
    feature_req_issue_id INT;

    -- Commit Hashes
    commit1_hash CHAR(40) := 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
    commit2_hash CHAR(40) := 'f0e9d8c7b6a5f0e9d8c7b6a5f0e9d8c7b6a5f0e9';
    commit3_hash CHAR(40) := '1234567890abcdef1234567890abcdef12345678';

BEGIN
    -- Insert Users and get their IDs
    INSERT INTO users (username, email) VALUES ('alice', 'alice@example.com') RETURNING user_id INTO alice_id;
    INSERT INTO users (username, email) VALUES ('bob', 'bob@example.com') RETURNING user_id INTO bob_id;

    -- Insert Repositories and get their IDs
    INSERT INTO repositories (owner_id, name, description) VALUES (alice_id, 'project-phoenix', 'A revolutionary new framework.') RETURNING repo_id INTO phoenix_repo_id;
    INSERT INTO repositories (owner_id, name, description) VALUES (bob_id, 'data-pipeline', 'ETL scripts for data warehousing.') RETURNING repo_id INTO pipeline_repo_id;

    -- Insert Commits
    INSERT INTO commits (commit_hash, repo_id, author_id, message, changed_files) VALUES
    (commit1_hash, phoenix_repo_id, alice_id, 'Initial commit', ARRAY['README.md', 'src/main.js']),
    (commit2_hash, phoenix_repo_id, alice_id, 'Add feature X', ARRAY['src/featureX.js', 'tests/test_featureX.js']),
    (commit3_hash, pipeline_repo_id, bob_id, 'Setup initial data pipeline', ARRAY['scripts/extract.py', 'config.yaml']);

    -- Insert a Bug and get its issue_id
    INSERT INTO bugs (repo_id, reporter_id, title, description, issue_kind, severity) VALUES
    (phoenix_repo_id, bob_id, 'UI crashes on button click', 'The main application crashes when the "Submit" button is clicked on the login form.', 'Bug', 'Critical')
    RETURNING issue_id INTO bug_issue_id;

    -- Insert a Feature Request and get its issue_id
    INSERT INTO feature_requests (repo_id, reporter_id, title, description, issue_kind, priority, target_version) VALUES
    (phoenix_repo_id, alice_id, 'Add dark mode', 'The users have requested a dark mode option for the UI.', 'FeatureRequest', 2, 'v2.1.0')
    RETURNING issue_id INTO feature_req_issue_id;

    -- Insert Comments on the Bug using the captured issue_id
    INSERT INTO comments (issue_id, author_id, body) VALUES
    (bug_issue_id, alice_id, 'Thanks for reporting, Bob. I am looking into this now.'),
    (bug_issue_id, bob_id, 'No problem, let me know if you need logs.');

    -- Insert a comment on a commit
    INSERT INTO comments (commit_hash, author_id, body) VALUES
    (commit1_hash, bob_id, 'This initial commit looks good.');

END;
$;