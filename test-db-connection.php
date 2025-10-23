<?php
// MySQL Database Connection Test
// This script tests the connection from the web container to the MySQL container

// Load environment variables
$envFile = __DIR__ . '/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos($line, '=') !== false && strpos($line, '#') !== 0) {
            list($key, $value) = explode('=', $line, 2);
            $_ENV[trim($key)] = trim($value);
        }
    }
}

// Database configuration
$host = 'mysql'; // Docker service name
$port = 3306;
$database = $_ENV['MYSQL_DATABASE'] ?? 'manogama';
$username = $_ENV['MYSQL_USER'] ?? 'manogama_user';
$password = $_ENV['MYSQL_PASSWORD'] ?? 'manogama_password';

echo "<h1>🗄️ MySQL Database Connection Test</h1>\n";
echo "<h2>Connection Details</h2>\n";
echo "<ul>\n";
echo "<li><strong>Host:</strong> $host</li>\n";
echo "<li><strong>Port:</strong> $port</li>\n";
echo "<li><strong>Database:</strong> $database</li>\n";
echo "<li><strong>Username:</strong> $username</li>\n";
echo "<li><strong>Password:</strong> " . str_repeat('*', strlen($password)) . "</li>\n";
echo "</ul>\n";

// Test 1: Check MySQL extensions
echo "<h2>📋 PHP MySQL Extensions</h2>\n";
$extensions = ['mysqli', 'pdo', 'pdo_mysql'];
foreach ($extensions as $ext) {
    $status = extension_loaded($ext) ? '✅ Loaded' : '❌ Not loaded';
    echo "<p><strong>$ext:</strong> $status</p>\n";
}

// Test 2: Test MySQLi connection
echo "<h2>🔌 MySQLi Connection Test</h2>\n";
try {
    $mysqli = new mysqli($host, $username, $password, $database, $port);
    
    if ($mysqli->connect_error) {
        echo "<p style='color: red;'>❌ MySQLi connection failed: " . $mysqli->connect_error . "</p>\n";
    } else {
        echo "<p style='color: green;'>✅ MySQLi connection successful!</p>\n";
        
        // Test query
        $result = $mysqli->query("SELECT VERSION() as version");
        if ($result) {
            $row = $result->fetch_assoc();
            echo "<p><strong>MySQL Version:</strong> " . $row['version'] . "</p>\n";
        }
        
        // Test table query
        $result = $mysqli->query("SHOW TABLES");
        if ($result) {
            echo "<p><strong>Tables in database:</strong></p>\n";
            echo "<ul>\n";
            while ($row = $result->fetch_array()) {
                echo "<li>" . $row[0] . "</li>\n";
            }
            echo "</ul>\n";
        }
        
        $mysqli->close();
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ MySQLi connection error: " . $e->getMessage() . "</p>\n";
}

// Test 3: Test PDO connection
echo "<h2>🔌 PDO Connection Test</h2>\n";
try {
    $dsn = "mysql:host=$host;port=$port;dbname=$database;charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    
    echo "<p style='color: green;'>✅ PDO connection successful!</p>\n";
    
    // Test query
    $stmt = $pdo->query("SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = '$database'");
    $row = $stmt->fetch();
    echo "<p><strong>Table count:</strong> " . $row['table_count'] . "</p>\n";
    
    // Test sample data
    $stmt = $pdo->query("SELECT COUNT(*) as user_count FROM users");
    $row = $stmt->fetch();
    echo "<p><strong>Users in database:</strong> " . $row['user_count'] . "</p>\n";
    
} catch (PDOException $e) {
    echo "<p style='color: red;'>❌ PDO connection error: " . $e->getMessage() . "</p>\n";
}

// Test 4: Test MySQL client command line
echo "<h2>💻 MySQL Client Test</h2>\n";
$mysqlCommand = "mysql -h $host -P $port -u $username -p$password $database -e 'SELECT 1 as test' 2>&1";
$output = shell_exec($mysqlCommand);

if (strpos($output, 'test') !== false) {
    echo "<p style='color: green;'>✅ MySQL client command successful!</p>\n";
    echo "<pre>" . htmlspecialchars($output) . "</pre>\n";
} else {
    echo "<p style='color: red;'>❌ MySQL client command failed</p>\n";
    echo "<pre>" . htmlspecialchars($output) . "</pre>\n";
}

echo "<h2>🎉 Connection Test Complete</h2>\n";
echo "<p>If all tests show ✅, then MySQL is properly accessible from the web container!</p>\n";
?>
