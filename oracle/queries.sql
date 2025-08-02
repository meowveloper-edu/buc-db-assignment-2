-- =============================================================================
-- Task 2: Oracle Object-Relational Database Implementation
-- =============================================================================
-- This script creates the complete object-relational schema for the case study,
-- including types, tables, constraints, and sample data insertion.

-- Set server output on to see results from procedures, etc.
SET SERVEROUTPUT ON;

-- -----------------------------------------------------------------------------
-- Drop existing objects to ensure a clean slate for recreation.
-- The order is important: drop tables first, then the types they depend on.
-- The BEGIN...END blocks handle errors if the objects don't exist.
-- -----------------------------------------------------------------------------

-- Drop Tables
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE users PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

-- Drop Types
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE user_t FORCE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -4043 THEN
            RAISE;
        END IF;
END;
/


-- -----------------------------------------------------------------------------
-- Create User-Defined Object Types
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TYPE user_t AS OBJECT (
    user_id     NUMBER,
    username    VARCHAR2(50),
    email       VARCHAR2(100),
    created_at  TIMESTAMP
)
/


-- -----------------------------------------------------------------------------
-- Create Object Tables
-- -----------------------------------------------------------------------------

CREATE TABLE users OF user_t (
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_email UNIQUE (email)
);

PROMPT Schema for users created successfully.
