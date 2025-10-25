-- PostgreSQL initialization script
-- Create test database
CREATE DATABASE test;

-- Connect to test database
\c test;

-- Create test user with password
CREATE USER test WITH PASSWORD 'test123';

-- Grant privileges to test user
GRANT ALL PRIVILEGES ON DATABASE test TO test;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO test;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO test;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO test;
