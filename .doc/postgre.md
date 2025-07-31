# PostgreSQL Script Explanation (`queries.sql`)

This document provides a detailed explanation of the object-relational features and advanced queries used in the `postgres/queries.sql` script.

---

## 1. Object-Relational Concepts

The database was designed using PostgreSQL's object-relational features to create a more structured and robust schema.

### User-Defined Types (`CREATE TYPE`)

A user-defined `ENUM` type called `issue_status` was created to ensure that the `status` column in the `issues` table can only contain specific, predefined values.

```sql
CREATE TYPE issue_status AS ENUM ('Open', 'In Progress', 'Closed');
```

- **Benefit:** This enforces data integrity at the database level, preventing invalid status strings and making the data more consistent and reliable than a simple `VARCHAR` would.

### Table Inheritance (`INHERITS`)

Table inheritance is a key object-relational feature used to model the "is-a" relationship between `Issue`, `Bug`, and `FeatureRequest`.

```sql
-- Parent table
CREATE TABLE issues (...);

-- Child tables
CREATE TABLE bugs (...) INHERITS (issues);
CREATE TABLE feature_requests (...) INHERITS (issues);
```

- **How it Works:** The `bugs` and `feature_requests` tables automatically inherit all columns from the `issues` table (e.g., `issue_id`, `title`, `status`). When you query the parent `issues` table, the results include rows from both child tables.
- **Benefit:** This avoids data redundancy by defining common columns in one place while allowing child tables to have their own specialized columns.

### Array Data Type (`TEXT[]`)

The `commits` table uses an array of text (`TEXT[]`) to store the list of files changed in a single commit.

```sql
CREATE TABLE commits (
    ...
    changed_files TEXT[],
    ...
);
```

- **Benefit:** This allows us to store a variable-length list of related items within a single column, which is a more flexible and efficient approach than creating a separate "many-to-many" table for something as simple as a list of file paths.

---

## 2. Data Integrity Mechanisms

### Triggers for Foreign Key on Inherited Tables

A standard `FOREIGN KEY` constraint cannot be used to reference an `issue_id` in the `comments` table because the `issues` table is a parent in an inheritance hierarchy and doesn't physically contain the data rows.

To solve this, a **trigger** was implemented.

1.  **The Trigger Function (`check_issue_exists`)**: This function is defined to run before any `INSERT` or `UPDATE` on the `comments` table. It manually checks if the `NEW.issue_id` (the value being inserted) actually exists in the `issues` hierarchy. If it doesn't, it raises an exception, effectively simulating a foreign key constraint.

    ```sql
    CREATE OR REPLACE FUNCTION check_issue_exists()
    RETURNS TRIGGER AS $FUNCTION$
    BEGIN
        IF NEW.issue_id IS NOT NULL THEN
            IF NOT EXISTS (SELECT 1 FROM issues WHERE issue_id = NEW.issue_id) THEN
                RAISE EXCEPTION 'Foreign key violation...';
            END IF;
        END IF;
        RETURN NEW;
    END;
    $FUNCTION$ LANGUAGE plpgsql;
    ```

2.  **The Trigger (`trg_check_comment_issue`)**: This trigger binds the function to the `comments` table, ensuring it executes for each row before an insert or update.

    ```sql
    CREATE TRIGGER trg_check_comment_issue
    BEFORE INSERT OR UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION check_issue_exists();
    ```

---

## 3. Stored Procedures & Functions (Task 5)

To satisfy the assignment requirements and for good design, some queries were wrapped in procedures and functions.

### Difference Between Procedures and Functions

-   **Function**: Its main purpose is to compute and **return a value** (like a number, string, or a table of data). It is called inside another query (e.g., `SELECT * FROM my_function();`).
-   **Procedure**: Its main purpose is to **perform an action** or a series of actions (e.g., modifying data, creating tables). It does not return a value directly and is called with the `CALL` command. To return data, it typically uses temporary tables as a "staging area" for the results.

### Query 5a: `get_comprehensive_commit_details()` (Procedure)

This procedure retrieves detailed information about commits that changed more than one file.

-   **Joins**: It uses `INNER JOIN` to link users, commits, and repositories, and a `LEFT JOIN` to include comments, ensuring that commits without comments are still listed.
-   **Array Logic**: The `WHERE array_length(c.changed_files, 1) > 1` clause filters for commits that affected multiple files.
-   **Temporary Table**: Because it's a procedure, it inserts its results into a `TEMP TABLE` named `comprehensive_commit_details`, which is then queried separately.

### Query 5b: `get_active_users()` (Procedure)

This procedure returns a unique list of users who are active as either commit authors or bug reporters.

-   **Set Operator (`UNION`)**: It uses `UNION` to combine the results of two separate `SELECT` statements. `UNION` automatically removes duplicate usernames, giving a clean, distinct list. This satisfies the requirement for a query involving a set operator on multiple tables.

### Query 5c: `get_bugs_for_repository()` (Function)

This function returns all bug reports for a specific repository and was chosen to fulfill the "stored function" requirement.

-   **`RETURNS TABLE`**: This is a perfect use case for a function, as its sole purpose is to return a result set. This allows it to be called directly in a `SELECT` statement.
-   **Inheritance Query**: It queries the `bugs` table directly, demonstrating a query on a child table in an inheritance hierarchy.
-   **Temporal Function (`AGE`)**: It uses `AGE(CURRENT_TIMESTAMP, b.creation_date)` to calculate the interval since the bug was created, fulfilling a temporal query feature.

---

## 4. Advanced Queries (Task 5)

### Query 5d: Temporal Query

This query finds pairs of commits made in rapid succession.

-   **Self-Join**: It joins the `commits` table to itself (`c1` and `c2`) on the same `repo_id`.
-   **Interval Logic**: The `WHERE` clause `c2.commit_timestamp - c1.commit_timestamp BETWEEN INTERVAL '0 seconds' AND INTERVAL '5 minutes'` is a powerful temporal operation that calculates the difference between two timestamps and compares it to a fixed interval.
-   **De-duplication**: The `c1.commit_id < c2.commit_id` condition is a clever way to prevent a commit from being matched with itself and to ensure that each pair is listed only once.

### Query 5e: OLAP Query (`ROLLUP`)

This query generates a summary report of issue counts.

-   **`GROUP BY ROLLUP`**: This is an OLAP (Online Analytical Processing) feature that extends `GROUP BY`. `ROLLUP(r.name, i.status)` generates not only the standard groupings by `(repository, status)` but also adds:
    1.  Sub-total rows for each repository (across all statuses).
    2.  A grand-total row for all repositories.
-   **`COALESCE`**: This function is used for presentation. It replaces the `NULL` values generated by `ROLLUP` in the sub-total and grand-total rows with more descriptive text like "All Repositories", making the report much easier to read.
