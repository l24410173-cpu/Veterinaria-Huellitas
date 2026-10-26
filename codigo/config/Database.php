<?php
declare(strict_types=1);

final class Database
{
    private static ?PDO $connection = null;

    public static function connection(): PDO
    {
        if (self::$connection instanceof PDO) {
            return self::$connection;
        }

        $envPath = dirname(__DIR__) . DIRECTORY_SEPARATOR . '.env';
        if (!is_file($envPath)) {
            throw new RuntimeException('No se encontró codigo/.env. Copia .env.example y configura MySQL.');
        }

        $settings = [];
        foreach (file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
                continue;
            }
            [$key, $value] = explode('=', $line, 2);
            $settings[trim($key)] = trim(trim($value), "\"'");
        }

        $host = $settings['DB_HOST'] ?? '127.0.0.1';
        $port = $settings['DB_PORT'] ?? '3306';
        $name = $settings['DB_NAME'] ?? 'veterinaria_huellitas';
        $user = $settings['DB_USER'] ?? 'root';
        $pass = $settings['DB_PASS'] ?? '';
        $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";

        self::$connection = new PDO($dsn, $user, $pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
	        \Pdo\Mysql::ATTR_INIT_COMMAND => "SET NAMES utf8mb4",
        ]);
        return self::$connection;
    }
}
