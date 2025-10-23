-- Test Database User Creation
-- This script creates the test user with password

-- Create test user with password 'password'
CREATE USER IF NOT EXISTS 'test'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON test.* TO 'test'@'%';
FLUSH PRIVILEGES;
