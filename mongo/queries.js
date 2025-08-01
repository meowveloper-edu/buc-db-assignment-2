// Task 3: MongoDB Implementation
// Step 1: Create the users collection

// Switch to a new database (or use an existing one)
db = db.getSiblingDB('git_repo_db');

// Drop the users collection if it already exists to ensure a clean slate
print("Dropping existing 'users' collection...");
db.users.drop();

// Insert documents into the users collection
print("Creating 'users' collection and inserting data...");
db.users.insertMany([
  {
    "_id": 1,
    "username": "john_doe",
    "email": "john.doe@example.com"
  },
  {
    "_id": 2,
    "username": "jane_smith",
    "email": "jane.smith@example.com"
  },
  {
    "_id": 3,
    "username": "bob_johnson",
    "email": "bob.johnson@example.com"
  }
]);

print("Successfully created 'users' collection.");

// Step 2: Create the repositories collection with embedded documents
print("\nDropping existing 'repositories' collection...");
db.repositories.drop();

print("Creating 'repositories' collection and inserting data...");
db.repositories.insertMany([
  {
    "_id": 1,
    "name": "Web-Framework",
    "owner_id": 1,
    "created_at": new Date("2024-01-15T10:00:00Z"),
    "commits": [
      {
        "commit_hash": "a1b2c3d4",
        "author_id": 1,
        "message": "Initial commit",
        "changed_files": ["README.md", "app.js"],
        "timestamp": new Date("2024-01-15T10:00:00Z")
      },
      {
        "commit_hash": "e5f6g7h8",
        "author_id": 2,
        "message": "Add user authentication",
        "changed_files": ["auth.js", "routes.js"],
        "timestamp": new Date("2024-01-16T14:30:00Z")
      },
      {
        "commit_hash": "i9j0k1l2",
        "author_id": 1,
        "message": "Fix login bug",
        "changed_files": ["auth.js"],
        "timestamp": new Date("2024-01-16T14:34:00Z")
      }
    ],
    "issues": [
      {
        "issue_id": 1,
        "reporter_id": 2,
        "title": "UI bug on login page",
        "description": "The login button is misaligned on mobile devices.",
        "status": "open",
        "created_at": new Date("2024-02-01T11:00:00Z"),
        "issue_type": "bug",
        "severity": "medium",
        "comments": [
          {
            "comment_id": 1,
            "author_id": 1,
            "content": "I'll take a look at this.",
            "created_at": new Date("2024-02-01T12:00:00Z")
          },
          {
            "comment_id": 2,
            "author_id": 2,
            "content": "Thanks! Let me know if you need more details.",
            "created_at": new Date("2024-02-01T12:05:00Z")
          }
        ]
      },
      {
        "issue_id": 3,
        "reporter_id": 1,
        "title": "Add dark mode",
        "description": "Implement a dark mode theme for the application.",
        "status": "open",
        "created_at": new Date("2024-02-10T16:00:00Z"),
        "issue_type": "feature_request",
        "votes": 5,
        "comments": []
      }
    ]
  },
  {
    "_id": 2,
    "name": "Data-Analysis-Tool",
    "owner_id": 3,
    "created_at": new Date("2024-03-01T09:00:00Z"),
    "commits": [
      {
        "commit_hash": "m3n4o5p6",
        "author_id": 3,
        "message": "Initial commit",
        "changed_files": ["main.py", "requirements.txt"],
        "timestamp": new Date("2024-03-01T09:00:00Z")
      }
    ],
    "issues": [
      {
        "issue_id": 2,
        "reporter_id": 1,
        "title": "Error on CSV import",
        "description": "The application crashes when importing a CSV file with more than 10,000 rows.",
        "status": "closed",
        "created_at": new Date("2024-03-05T14:20:00Z"),
        "issue_type": "bug",
        "severity": "high",
        "comments": [
          {
            "comment_id": 3,
            "author_id": 3,
            "content": "This is a critical issue. I'm working on a fix.",
            "created_at": new Date("2024-03-05T15:00:00Z")
          }
        ]
      }
    ]
  }
]);

print("Successfully created 'repositories' collection.");
