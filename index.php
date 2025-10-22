<?php
echo "<h1>Welcome to Manogama!</h1>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server: " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p>Current Time: " . date('Y-m-d H:i:s') . "</p>";

// Test PHP extensions
echo "<h2>PHP Extensions:</h2>";
$extensions = ['mysqli', 'pdo', 'json', 'curl', 'mbstring', 'xml', 'zip', 'gd', 'opcache'];
foreach ($extensions as $ext) {
    echo "<p>" . $ext . ": " . (extension_loaded($ext) ? "✓ Loaded" : "✗ Not loaded") . "</p>";
}
?>
