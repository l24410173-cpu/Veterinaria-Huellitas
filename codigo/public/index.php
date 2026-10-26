<?php
declare(strict_types=1);
session_start();
require_once dirname(__DIR__) . '/config/Database.php';

function e(string $value): string { return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'); }
function go(string $path): never { header('Location: ' . $path); exit; }
function requireRole(array $roles): void {
    if (empty($_SESSION['user'])) go('/');
    if (!in_array($_SESSION['user']['rol'], $roles, true)) {
        http_response_code(403);
        echo pageStart('Acceso denegado'), '<main class="panel"><h1>403 · Acceso denegado</h1><p>No tienes permisos para consultar esta pantalla.</p><a href="/?page=dashboard">Volver al inicio</a></main>', pageEnd();
        exit;
    }
}
function pageStart(string $title): string {
    return '<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'.e($title).' · Huellitas</title><link rel="stylesheet" href="/assets/style.css"></head><body>';
}
function pageEnd(): string { return '</body></html>'; }
$error = '';
$page = $_GET['page'] ?? 'login';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'login') {
    $email = trim((string)($_POST['correo'] ?? ''));
    $password = (string)($_POST['password'] ?? '');
    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || $password === '') {
        $error = 'Escribe un correo válido y tu contraseña.';
    } else {
        try {
            $stmt = Database::connection()->prepare('SELECT id, nombre, correo, password_hash, rol, activo FROM usuarios WHERE correo = :correo LIMIT 1');
            $stmt->execute(['correo' => $email]);
            $user = $stmt->fetch();
            if ($user && (int)$user['activo'] === 1 && password_verify($password, $user['password_hash'])) {
                session_regenerate_id(true);
                $_SESSION['user'] = ['id'=>(int)$user['id'], 'nombre'=>$user['nombre'], 'correo'=>$user['correo'], 'rol'=>$user['rol']];
                go('/?page=dashboard');
            }
            $error = 'No fue posible iniciar sesión. Verifica tus datos o contacta al administrador.';
        } catch (Throwable $ex) {
    $error = 'ERROR REAL: ' . $ex->getMessage();
}
    }
}
if ($page === 'logout') {
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'], $params['secure'], $params['httponly']);
    }
    session_destroy();
    go('/');
}

if ($page === 'clientes') {
    requireRole(['administrador']);

    try {
        $pdo = Database::connection();
        $stmt = $pdo->query(
            'SELECT c.id, u.nombre, u.correo, u.activo,
                    c.telefono, c.direccion, c.ciudad
             FROM clientes c
             INNER JOIN usuarios u ON u.id = c.usuario_id
             ORDER BY u.nombre'
        );
        $clientes = $stmt->fetchAll();
    } catch (Throwable $ex) {
        $clientes = [];
        $errorClientes = 'No fue posible cargar la lista de clientes.';
    }

    echo pageStart('Clientes');
    echo '<header class="topbar">
            <div class="brand">Veterinaria Huellitas</div>
            <div><a class="logout" href="/?page=dashboard">Volver al panel</a></div>
          </header>';
    echo '<main class="container">
            <section class="welcome">
              <p class="eyebrow">ADMINISTRACIÓN</p>
              <h1>Clientes</h1>
              <p>Consulta los propietarios registrados en el sistema.</p>
            </section>
            <section class="panel">';

    if (isset($errorClientes)) {
        echo '<p class="alert">' . e($errorClientes) . '</p>';
    } elseif (!$clientes) {
        echo '<p>No hay clientes registrados.</p>';
    } else {
        echo '<div style="overflow-x:auto"><table>
                <thead><tr>
                  <th>Nombre</th><th>Correo</th><th>Teléfono</th>
                  <th>Ciudad</th><th>Dirección</th>
                </tr></thead><tbody>';

        foreach ($clientes as $cliente) {
            echo '<tr>
                    <td>' . e($cliente['nombre']) . '</td>
                    <td>' . e($cliente['correo']) . '</td>
                    <td>' . e($cliente['telefono'] ?? '') . '</td>
                    <td>' . e($cliente['ciudad'] ?? '') . '</td>
                    <td>' . e($cliente['direccion'] ?? '') . '</td>
                  </tr>';
        }

        echo '</tbody></table></div>';
    }

    echo '</section></main>', pageEnd();
    exit;
}

if ($page === 'dashboard') {
    requireRole(['administrador','cliente','veterinario']);
    $user = $_SESSION['user'];
    $dbError = '';
    $counts = [];
    try {
        $pdo = Database::connection();
        if ($user['rol'] === 'administrador') {
            foreach (['clientes'=>'SELECT COUNT(*) FROM clientes','mascotas'=>'SELECT COUNT(*) FROM mascotas','veterinarios'=>'SELECT COUNT(*) FROM veterinarios','citas'=>'SELECT COUNT(*) FROM citas','pagos'=>'SELECT COUNT(*) FROM pagos'] as $label=>$sql) {
                $counts[$label] = (int)$pdo->query($sql)->fetchColumn();
            }
        } elseif ($user['rol'] === 'cliente') {
            $q = $pdo->prepare('SELECT id FROM clientes WHERE usuario_id = ?');
            $q->execute([$user['id']]); $clientId = $q->fetchColumn();
            if ($clientId) {
                $q = $pdo->prepare('SELECT COUNT(*) FROM mascotas WHERE cliente_id = ?'); $q->execute([$clientId]); $counts['mascotas'] = (int)$q->fetchColumn();
                $q = $pdo->prepare('SELECT COUNT(*) FROM citas c JOIN mascotas m ON m.id=c.mascota_id WHERE m.cliente_id = ?'); $q->execute([$clientId]); $counts['citas'] = (int)$q->fetchColumn();
                $q = $pdo->prepare('SELECT COUNT(*) FROM pagos p JOIN citas c ON c.id=p.cita_id JOIN mascotas m ON m.id=c.mascota_id WHERE m.cliente_id = ?'); $q->execute([$clientId]); $counts['pagos'] = (int)$q->fetchColumn();
            }
        } else {
            $q = $pdo->prepare('SELECT id FROM veterinarios WHERE usuario_id = ?');
            $q->execute([$user['id']]); $vetId = $q->fetchColumn();
            if ($vetId) {
                $q = $pdo->prepare('SELECT COUNT(*) FROM citas WHERE veterinario_id = ?'); $q->execute([$vetId]); $counts['citas asignadas'] = (int)$q->fetchColumn();
                $q = $pdo->prepare("SELECT COUNT(*) FROM citas WHERE veterinario_id = ? AND estado = 'Programada'"); $q->execute([$vetId]); $counts['citas programadas'] = (int)$q->fetchColumn();
                $q = $pdo->prepare('SELECT COUNT(*) FROM consultas co JOIN citas c ON c.id=co.cita_id WHERE c.veterinario_id = ?'); $q->execute([$vetId]); $counts['consultas'] = (int)$q->fetchColumn();
            }
        }
    } catch (Throwable $ex) { $dbError = 'No fue posible cargar los indicadores desde MySQL. Revisa codigo/.env y ejecuta el script SQL.'; }
    echo pageStart('Panel principal');
    echo '<header class="topbar"><div class="brand">🐾 Veterinaria Huellitas</div><div>'.e($user['nombre']).' <span class="role">'.e(ucfirst($user['rol'])).'</span> <a class="logout" href="/?page=logout">Cerrar sesión</a></div></header><main class="container"><section class="welcome"><p class="eyebrow">PANEL PRINCIPAL</p><h1>¡Hola, '.e($user['nombre']).'!</h1><p>Bienvenido al sistema de gestión veterinaria.</p></section>';
    if ($dbError) echo '<p class="alert">'.e($dbError).'</p>';
    echo '<section class="stats">';
    foreach ($counts as $label=>$number) echo '<article class="stat"><span>'.e(ucfirst($label)).'</span><strong>'.(int)$number.'</strong></article>';
    if (!$counts && !$dbError) echo '<p>Tu perfil está activo. No hay indicadores disponibles para esta cuenta.</p>';
    echo '</section><section class="panel"><h2>'.($user['rol']==='administrador'?'Accesos administrativos':($user['rol']==='cliente'?'Tus servicios':'Área veterinaria')).'</h2><div class="cards">';
    $items = match ($user['rol']) {
        'administrador' => [['Clientes','Gestión de propietarios'],['Mascotas','Expedientes de pacientes'],['Veterinarios','Personal y perfiles'],['Citas','Agenda y asignaciones'],['Atención clínica','Consultas y diagnósticos'],['Catálogos','Servicios y medicamentos'],['Pagos','Cobros registrados'],['Reportes','Citas, atención, consultas e ingresos']],
        'cliente' => [['Mis mascotas','Consulta de tus pacientes'],['Mis citas','Solicitudes y próximas citas'],['Historial médico','Consultas y recetas'],['Mis pagos','Estado de tus pagos']],
        default => [['Mi agenda','Citas asignadas'],['Consultas','Atenciones médicas'],['Diagnósticos','Registro clínico'],['Recetas','Tratamientos indicados']]
    };
    
foreach ($items as [$name, $desc]) {
    $url = ($name === 'Clientes' && $user['rol'] === 'administrador')
        ? '/?page=clientes'
        : '#';

    echo '<article class="module"><span class="paw">🐾</span><h3>';

    if ($url !== '#') {
        echo '<a href="' . e($url) . '">' . e($name) . '</a>';
    } else {
        echo e($name);
    }

    echo '</h3><p>' . e($desc) . '</p></article>';
}
    echo '</div><p class="note"></p></section></main>', pageEnd();
    exit;
}
if (!empty($_SESSION['user'])) go('/?page=dashboard');
echo pageStart('Inicio de sesión');
echo '<main class="login-wrap"><section class="login-card"><div class="logo">🐾</div><p class="eyebrow">SISTEMA WEB DE GESTIÓN</p><h1>Veterinaria Huellitas</h1><p class="muted">Inicia sesión para continuar</p>';
if ($error !== '') echo '<div class="alert">'.e($error).'</div>';
echo '<form method="post" action="/"><input type="hidden" name="action" value="login"><label for="correo">Correo electrónico</label><input id="correo" name="correo" type="email" autocomplete="username" required placeholder="usuario@huellitas.test"><label for="password">Contraseña</label><input id="password" name="password" type="password" autocomplete="current-password" required placeholder="Ingresa tu contraseña"><button type="submit">Iniciar sesión</button></form><div class="demo"><strong>Cuentas de demostración</strong><p>admin@huellitas.test · cliente@huellitas.test · veterinario@huellitas.test</p><p>Contraseña para todas: <code>Huellitas123*</code></p></div></section></main>', pageEnd();
