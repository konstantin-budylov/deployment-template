-- Manogama Database Initial Data
-- This script inserts initial data into the database

-- Insert default settings
INSERT INTO settings (key_name, value, description, is_public) VALUES
('app_name', 'Manogama', 'Application name', TRUE),
('app_version', '1.0.0', 'Application version', TRUE),
('app_environment', 'development', 'Application environment', FALSE),
('debug_mode', 'true', 'Debug mode enabled', FALSE),
('maintenance_mode', 'false', 'Maintenance mode status', FALSE),
('max_login_attempts', '5', 'Maximum login attempts before lockout', FALSE),
('session_timeout', '3600', 'Session timeout in seconds', FALSE),
('password_min_length', '8', 'Minimum password length', FALSE),
('email_verification_required', 'true', 'Email verification requirement', FALSE),
('created_at', NOW(), 'Database initialization timestamp', FALSE);

-- Insert sample user (password: 'admin123' - change in production!)
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active) VALUES
('admin', 'admin@manogama.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'User', TRUE),
('demo', 'demo@manogama.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Demo', 'User', TRUE);

-- Insert sample log entries
INSERT INTO logs (level, message, context, user_id, ip_address, user_agent) VALUES
('INFO', 'Database initialized successfully', '{"component": "database", "action": "init"}', 1, '127.0.0.1', 'MySQL Docker Container'),
('INFO', 'Application started', '{"component": "application", "action": "start"}', 1, '127.0.0.1', 'Docker Container'),
('DEBUG', 'Sample debug message', '{"component": "system", "action": "debug"}', NULL, '127.0.0.1', 'System');
