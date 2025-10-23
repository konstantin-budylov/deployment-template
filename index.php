<?php
// PHP Information Page
// This file displays comprehensive PHP configuration and environment details

// Set page title and basic HTML structure
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manogama - PHP Information</title>
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
            <h1>🐘 Manogama PHP Environment</h1>
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
        </div>

        <div class="phpinfo">
            <h2 style="padding: 20px; margin: 0; background: #f8f9fa; border-bottom: 1px solid #ddd;">📋 Complete PHP Configuration</h2>
            <?php phpinfo(); ?>
        </div>
    </div>
</body>
</html>