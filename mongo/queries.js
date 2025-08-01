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

// --- Task 6: MongoDB Queries ---

print("\n--- Query 6a: Comprehensive Commit Details (Multi-Join Equivalent) ---");
const query6a_result = db.repositories.aggregate([
  // Deconstruct the commits array
  { $unwind: "$commits" },
  // Filter for commits with more than one changed file
  { $match: { "commits.changed_files.1": { $exists: true } } },
  // Join with users collection to get author's username
  {
    $lookup: {
      from: "users",
      localField: "commits.author_id",
      foreignField: "_id",
      as: "author_details"
    }
  },
  // Deconstruct the author_details array (it will only have one element)
  { $unwind: "$author_details" },
  // Reshape the output
  {
    $project: {
      _id: 0,
      repository_name: "$name",
      commit_hash: "$commits.commit_hash",
      commit_message: "$commits.message",
      author_username: "$author_details.username",
      timestamp: "$commits.timestamp"
    }
  }
]).toArray();

printjson(query6a_result);

print("\n--- Query 6b: Active Users (Set Operator Equivalent) ---");
// Get distinct user IDs from commit authors
const commit_authors = db.repositories.aggregate([
  { $unwind: "$commits" },
  { $group: { _id: "$commits.author_id" } }
]).toArray().map(u => u._id);

// Get distinct user IDs from bug reporters
const bug_reporters = db.repositories.aggregate([
  { $unwind: "$issues" },
  { $match: { "issues.issue_type": "bug" } },
  { $group: { _id: "$issues.reporter_id" } }
]).toArray().map(u => u._id);

// Combine and get unique IDs
const active_user_ids = [...new Set([...commit_authors, ...bug_reporters])];

// Fetch the full user documents for the active users
const query6b_result = db.users.find(
  { _id: { $in: active_user_ids } },
  { _id: 0, username: 1, email: 1 }
).toArray();

printjson(query6b_result);



