-- Drop table users
DROP TABLE users;
-- Create a table for users
CREATE TABLE users (
    user_id serial PRIMARY KEY,
    username VARCHAR (50) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL
);

-- Insert some data
INSERT INTO users (username, created_at) VALUES ('alice', NOW());
INSERT INTO users (username, created_at) VALUES ('bob', NOW());

-- Select the data to see the result
SELECT * FROM users;
