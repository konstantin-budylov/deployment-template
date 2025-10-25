<?php
// PHP Information Page
// This file displays comprehensive PHP configuration and environment details

// Redis Connection Test (via TCP socket)
$redisStatus = [
    'connected' => false,
    'error' => null,
    'version' => null,
    'info' => []
];

try {
    // Set shorter timeout for Redis connection
    $context = stream_context_create([
        'socket' => [
            'connect_timeout' => 2,
            'read_timeout' => 2
        ]
    ]);
    
    $redisHost = getenv('REDIS_HOST') ?: 'redis';
    $redisPort = getenv('REDIS_PORT') ?: '6379';
    
    // Try to connect via TCP socket with timeout
    $redisSocket = @stream_socket_client("tcp://$redisHost:$redisPort", $errno, $errstr, 2, STREAM_CLIENT_CONNECT, $context);
    
    if ($redisSocket) {
        $redisStatus['connected'] = true;
        
        // Send PING command
        @fwrite($redisSocket, "PING\r\n");
        $response = @fread($redisSocket, 512);
        
        if ($response === false) {
            $redisStatus['error'] = 'Failed to read from Redis';
        } else {
            // Try to get version via INFO command
            @fwrite($redisSocket, "INFO server\r\n");
            stream_set_timeout($redisSocket, 2);
            
            $info = '';
            $timeout = microtime(true) + 2;
            while (!feof($redisSocket) && microtime(true) < $timeout) {
                $chunk = @fread($redisSocket, 1024);
                if ($chunk === false) break;
                $info .= $chunk;
            }
            
            // Parse version from INFO
            if (preg_match('/redis_version:(\S+)/', $info, $matches)) {
                $redisStatus['version'] = $matches[1];
            }
            
            if (preg_match('/db0:keys=(\d+)/', $info, $matches)) {
                $redisStatus['info']['keys'] = $matches[1];
            }
        }
        
        @fclose($redisSocket);
    } else {
        $redisStatus['error'] = $errstr ?: 'Could not connect to Redis';
    }
} catch (Exception $e) {
    $redisStatus['error'] = $e->getMessage();
}

// MySQL Connection Test
$mysqlStatus = [
    'connected' => false,
    'error' => null,
    'version' => null,
    'databases' => []
];

try {
    // Read MySQL credentials from environment variables with fallbacks
    $mysqlHost = getenv('MYSQL_HOST') ?: 'mysql';
    $mysqlPort = getenv('MYSQL_PORT') ?: '3306';
    $mysqlUser = getenv('MYSQL_USER') ?: 'root';
    $mysqlPassword = getenv('MYSQL_ROOT_PASSWORD') ?: (getenv('MYSQL_PASSWORD') ?: 'root');
    $mysqlDatabase = getenv('MYSQL_DATABASE') ?: 'test'; // Use test database
    
    // Attempt connection (connect without database first to show all databases)
    $mysqli = new mysqli($mysqlHost, $mysqlUser, $mysqlPassword, '', $mysqlPort);
    
    if (!$mysqli->connect_error) {
        $mysqlStatus['connected'] = true;
        $mysqlStatus['version'] = $mysqli->server_info;
        
        // Get list of databases
        $result = $mysqli->query("SHOW DATABASES");
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $mysqlStatus['databases'][] = $row['Database'];
            }
            $result->free();
        }
        $mysqli->close();
    } else {
        $mysqlStatus['error'] = $mysqli->connect_error;
    }
} catch (Exception $e) {
    $mysqlStatus['error'] = $e->getMessage();
}

// Set page title and basic HTML structure
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deployment Template - PHP Information</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 8px;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
        }
        .header p {
            margin: 10px 0 0 0;
            font-size: 1.2em;
            opacity: 0.9;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .info-card h3 {
            margin: 0 0 15px 0;
            color: #333;
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            margin: 8px 0;
            padding: 5px 0;
            border-bottom: 1px solid #eee;
        }
        .info-label {
            font-weight: bold;
            color: #555;
        }
        .info-value {
            color: #666;
        }
        .phpinfo {
            background: white;
            border: 1px solid #ddd;
            border-radius: 8px;
            overflow: hidden;
        }
        .phpinfo table {
            width: 100%;
            border-collapse: collapse;
        }
        .phpinfo th, .phpinfo td {
            padding: 8px 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        .phpinfo th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        .phpinfo tr:nth-child(even) {
            background-color: #f8f9fa;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🐘 Deployment Template PHP Environment</h1>
            <p>PHP Development Environment with Docker</p>
        </div>

        <div class="info-grid">
            <div class="info-card">
                <h3>🚀 Environment</h3>
                <div class="info-item">
                    <span class="info-label">PHP Version:</span>
                    <span class="info-value"><?php echo phpversion(); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Server Software:</span>
                    <span class="info-value"><?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Nginx + PHP-FPM'; ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Document Root:</span>
                    <span class="info-value"><?php echo $_SERVER['DOCUMENT_ROOT'] ?? '/var/www/html'; ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Current Time:</span>
                    <span class="info-value"><?php echo date('Y-m-d H:i:s T'); ?></span>
                </div>
            </div>

            <div class="info-card">
                <h3>🔧 Configuration</h3>
                <div class="info-item">
                    <span class="info-label">Memory Limit:</span>
                    <span class="info-value"><?php echo ini_get('memory_limit'); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Max Execution Time:</span>
                    <span class="info-value"><?php echo ini_get('max_execution_time'); ?>s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Upload Max Filesize:</span>
                    <span class="info-value"><?php echo ini_get('upload_max_filesize'); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Post Max Size:</span>
                    <span class="info-value"><?php echo ini_get('post_max_size'); ?></span>
                </div>
            </div>

            <div class="info-card">
                <h3>🔌 Extensions</h3>
                <?php
                $extensions = ['mysqli', 'pdo', 'json', 'curl', 'mbstring', 'xml', 'zip', 'gd', 'opcache', 'xdebug'];
                foreach ($extensions as $ext) {
                    $status = extension_loaded($ext) ? '✅' : '❌';
                    echo "<div class='info-item'><span class='info-label'>$ext:</span><span class='info-value'>$status</span></div>";
                }
                ?>
            </div>

            <div class="info-card">
                <h3>🐛 Debugging</h3>
                <div class="info-item">
                    <span class="info-label">Xdebug:</span>
                    <span class="info-value"><?php echo extension_loaded('xdebug') ? '✅ Loaded' : '❌ Not loaded'; ?></span>
                </div>
                <?php if (extension_loaded('xdebug')): ?>
                <div class="info-item">
                    <span class="info-label">Xdebug Version:</span>
                    <span class="info-value"><?php echo phpversion('xdebug'); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Xdebug Mode:</span>
                    <span class="info-value"><?php echo ini_get('xdebug.mode'); ?></span>
                </div>
                <?php endif; ?>
            </div>

            <div class="info-card">
                <h3>⚡ Redis Connection</h3>
                <div class="info-item">
                    <span class="info-label">Status:</span>
                    <span class="info-value"><?php echo $redisStatus['connected'] ? '✅ Connected' : '❌ Failed'; ?></span>
                </div>
                <?php if ($redisStatus['connected']): ?>
                <?php if ($redisStatus['version']): ?>
                <div class="info-item">
                    <span class="info-label">Version:</span>
                    <span class="info-value"><?php echo htmlspecialchars($redisStatus['version']); ?></span>
                </div>
                <?php endif; ?>
                <div class="info-item">
                    <span class="info-label">Keys:</span>
                    <span class="info-value"><?php echo $redisStatus['info']['keys'] ?? '0'; ?></span>
                </div>
                <?php else: ?>
                <div class="info-item">
                    <span class="info-label">Error:</span>
                    <span class="info-value" style="color: #dc3545;"><?php echo htmlspecialchars($redisStatus['error'] ?? 'Unknown error'); ?></span>
                </div>
                <?php endif; ?>
            </div>

            <div class="info-card">
                <h3>🗄️ MySQL Connection</h3>
                <div class="info-item">
                    <span class="info-label">Status:</span>
                    <span class="info-value"><?php echo $mysqlStatus['connected'] ? '✅ Connected' : '❌ Failed'; ?></span>
                </div>
                <?php if ($mysqlStatus['connected']): ?>
                <div class="info-item">
                    <span class="info-label">Version:</span>
                    <span class="info-value"><?php echo htmlspecialchars($mysqlStatus['version']); ?></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Databases:</span>
                    <span class="info-value"><?php echo count($mysqlStatus['databases']); ?></span>
                </div>
                <?php if (!empty($mysqlStatus['databases'])): ?>
                <div class="info-item" style="flex-direction: column; align-items: flex-start;">
                    <span class="info-label" style="margin-bottom: 5px;">Database List:</span>
                    <span class="info-value" style="font-size: 0.9em;"><?php echo htmlspecialchars(implode(', ', $mysqlStatus['databases'])); ?></span>
                </div>
                <?php endif; ?>
                <?php else: ?>
                <div class="info-item">
                    <span class="info-label">Error:</span>
                    <span class="info-value" style="color: #dc3545;"><?php echo htmlspecialchars($mysqlStatus['error'] ?? 'Unknown error'); ?></span>
                </div>
                <?php endif; ?>
            </div>
        </div>

        <div class="phpinfo">
            <h2 style="padding: 20px; margin: 0; background: #f8f9fa; border-bottom: 1px solid #ddd;">📋 Complete PHP Configuration</h2>
            <?php phpinfo(); ?>
        </div>
    </div>
</body>
</html>