CREATE DATABASE IF NOT EXISTS veterinaria_huellitas CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE veterinaria_huellitas;
SET NAMES utf8mb4;
CREATE TABLE usuarios (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL,
 correo VARCHAR(190) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 rol ENUM('administrador','cliente','veterinario') NOT NULL,
 activo TINYINT(1) NOT NULL DEFAULT 1,
 creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE clientes (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 usuario_id INT UNSIGNED NOT NULL UNIQUE,
 telefono VARCHAR(25),
 direccion VARCHAR(180),
 ciudad VARCHAR(100),
 CONSTRAINT fk_clientes_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;
CREATE TABLE veterinarios (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 usuario_id INT UNSIGNED NOT NULL UNIQUE,
 cedula_profesional VARCHAR(60) NOT NULL UNIQUE,
 especialidad VARCHAR(120),
 telefono VARCHAR(25),
 activo TINYINT(1) NOT NULL DEFAULT 1,
 CONSTRAINT fk_veterinarios_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;
CREATE TABLE mascotas (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 cliente_id INT UNSIGNED NOT NULL,
 nombre VARCHAR(100) NOT NULL,
 especie VARCHAR(50) NOT NULL,
 raza VARCHAR(100),
 fecha_nacimiento DATE,
 peso DECIMAL(6,2),
 sexo ENUM('Macho','Hembra','No especificado') NOT NULL DEFAULT 'No especificado',
 notas TEXT,
 CONSTRAINT fk_mascotas_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) ENGINE=InnoDB;
CREATE TABLE servicios (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(120) NOT NULL UNIQUE,
 descripcion TEXT,
 precio DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (precio >= 0),
 duracion_minutos SMALLINT UNSIGNED NOT NULL DEFAULT 30,
 activo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;
CREATE TABLE citas (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 mascota_id INT UNSIGNED NOT NULL,
 veterinario_id INT UNSIGNED NOT NULL,
 servicio_id INT UNSIGNED NOT NULL,
 fecha_hora DATETIME NOT NULL,
 estado ENUM('Programada','Confirmada','En atención','Atendida','Cancelada','No asistió') NOT NULL DEFAULT 'Programada',
 motivo TEXT,
 creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_citas_mascota FOREIGN KEY (mascota_id) REFERENCES mascotas(id),
 CONSTRAINT fk_citas_veterinario FOREIGN KEY (veterinario_id) REFERENCES veterinarios(id),
 CONSTRAINT fk_citas_servicio FOREIGN KEY (servicio_id) REFERENCES servicios(id),
 INDEX idx_citas_fecha (fecha_hora), INDEX idx_citas_estado (estado)
) ENGINE=InnoDB;
CREATE TABLE consultas (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 cita_id INT UNSIGNED NOT NULL UNIQUE,
 sintomas TEXT,
 observaciones TEXT,
 tratamiento TEXT,
 fecha_consulta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_consultas_cita FOREIGN KEY (cita_id) REFERENCES citas(id)
) ENGINE=InnoDB;
CREATE TABLE diagnosticos (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(150) NOT NULL UNIQUE,
 descripcion TEXT
) ENGINE=InnoDB;
CREATE TABLE consulta_diagnostico (
 consulta_id INT UNSIGNED NOT NULL,
 diagnostico_id INT UNSIGNED NOT NULL,
 notas TEXT,
 PRIMARY KEY (consulta_id, diagnostico_id),
 CONSTRAINT fk_cd_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(id),
 CONSTRAINT fk_cd_diagnostico FOREIGN KEY (diagnostico_id) REFERENCES diagnosticos(id)
) ENGINE=InnoDB;
CREATE TABLE medicamentos (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(150) NOT NULL,
 presentacion VARCHAR(100),
 descripcion TEXT,
 activo TINYINT(1) NOT NULL DEFAULT 1,
 INDEX idx_medicamentos_nombre (nombre)
) ENGINE=InnoDB;
CREATE TABLE recetas (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 consulta_id INT UNSIGNED NOT NULL,
 fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 indicaciones_generales TEXT,
 CONSTRAINT fk_recetas_consulta FOREIGN KEY (consulta_id) REFERENCES consultas(id)
) ENGINE=InnoDB;
CREATE TABLE detalle_receta (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 receta_id INT UNSIGNED NOT NULL,
 medicamento_id INT UNSIGNED NOT NULL,
 dosis VARCHAR(100) NOT NULL,
 frecuencia VARCHAR(100) NOT NULL,
 duracion VARCHAR(100) NOT NULL,
 cantidad INT UNSIGNED NOT NULL DEFAULT 1,
 instrucciones TEXT,
 CONSTRAINT fk_detalle_receta_receta FOREIGN KEY (receta_id) REFERENCES recetas(id),
 CONSTRAINT fk_detalle_receta_medicamento FOREIGN KEY (medicamento_id) REFERENCES medicamentos(id)
) ENGINE=InnoDB;
CREATE TABLE pagos (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 cita_id INT UNSIGNED NOT NULL,
 monto DECIMAL(10,2) NOT NULL CHECK (monto > 0),
 metodo_pago ENUM('Efectivo','Tarjeta de crédito','Tarjeta de débito','Transferencia','Otro') NOT NULL,
 estado ENUM('Pendiente','Pagado','Cancelado','Reembolsado') NOT NULL DEFAULT 'Pendiente',
 fecha_pago DATETIME NULL,
 referencia VARCHAR(120),
 CONSTRAINT fk_pagos_cita FOREIGN KEY (cita_id) REFERENCES citas(id),
 INDEX idx_pagos_estado_fecha (estado, fecha_pago)
) ENGINE=InnoDB;

-- Cuentas de demostración; contraseña inicial de las tres: Huellitas123*
INSERT INTO usuarios (id,nombre,correo,password_hash,rol,activo) VALUES
(1,'Administración Huellitas','admin@huellitas.test','$2y$12$ZWFWEfSNzegC4mW9o6GmzeoTUXqwtvYLn8f.ivsiZYAvnyl1X9obC','administrador',1),
(2,'María López García','cliente@huellitas.test','$2y$12$ZWFWEfSNzegC4mW9o6GmzeoTUXqwtvYLn8f.ivsiZYAvnyl1X9obC','cliente',1),
(3,'Dra. Ana Martínez','veterinario@huellitas.test','$2y$12$ZWFWEfSNzegC4mW9o6GmzeoTUXqwtvYLn8f.ivsiZYAvnyl1X9obC','veterinario',1),
(4,'Carlos Pérez','carlos@huellitas.test','$2y$12$ZWFWEfSNzegC4mW9o6GmzeoTUXqwtvYLn8f.ivsiZYAvnyl1X9obC','cliente',1),
(5,'Dr. Luis Ramírez','luis.vet@huellitas.test','$2y$12$ZWFWEfSNzegC4mW9o6GmzeoTUXqwtvYLn8f.ivsiZYAvnyl1X9obC','veterinario',1);
INSERT INTO clientes (id,usuario_id,telefono,direccion,ciudad) VALUES
(1,2,'614-555-0101','Calle Primavera 123','Chihuahua'),
(2,4,'614-555-0102','Av. Universidad 45','Chihuahua');
INSERT INTO veterinarios (id,usuario_id,cedula_profesional,especialidad,telefono,activo) VALUES
(1,3,'VET-CHIH-001','Medicina general','614-555-0201',1),
(2,5,'VET-CHIH-002','Dermatología veterinaria','614-555-0202',1);
INSERT INTO mascotas (id,cliente_id,nombre,especie,raza,fecha_nacimiento,peso,sexo,notas) VALUES
(1,1,'Luna','Perro','Labrador','2021-04-12',18.50,'Hembra','Vacunación al día'),
(2,1,'Michi','Gato','Europeo común','2022-08-01',4.20,'Macho','Paciente tranquilo'),
(3,2,'Rocky','Perro','Schnauzer','2020-02-20',9.80,'Macho','Revisar piel en próxima consulta');
INSERT INTO servicios (id,nombre,descripcion,precio,duracion_minutos,activo) VALUES
(1,'Consulta general','Evaluación clínica general',450.00,30,1),
(2,'Vacunación','Aplicación de vacuna según expediente',300.00,20,1),
(3,'Desparasitación','Evaluación y tratamiento antiparasitario',250.00,20,1),
(4,'Revisión dermatológica','Evaluación de piel y pelaje',550.00,40,1);
INSERT INTO citas (id,mascota_id,veterinario_id,servicio_id,fecha_hora,estado,motivo) VALUES
(1,1,1,1,'2026-10-20 10:00:00','Atendida','Revisión anual'),
(2,2,1,2,'2026-10-28 12:00:00','Confirmada','Refuerzo de vacunación'),
(3,3,2,4,'2026-10-29 15:30:00','Programada','Comezón y revisión de piel');
INSERT INTO consultas (id,cita_id,sintomas,observaciones,tratamiento,fecha_consulta) VALUES
(1,1,'Sin síntomas relevantes','Paciente estable; signos vitales dentro de rango.','Continuar calendario preventivo.','2026-10-20 10:15:00');
INSERT INTO diagnosticos (id,nombre,descripcion) VALUES
(1,'Paciente sano','Sin hallazgos clínicos relevantes'),
(2,'Dermatitis por determinar','Irritación cutánea pendiente de evaluación'),
(3,'Control preventivo','Atención preventiva de rutina');
INSERT INTO consulta_diagnostico (consulta_id,diagnostico_id,notas) VALUES (1,1,'Evaluación general sin hallazgos');
INSERT INTO medicamentos (id,nombre,presentacion,descripcion,activo) VALUES
(1,'Antiparasitario veterinario','Tabletas','Uso según indicación veterinaria',1),
(2,'Solución ótica veterinaria','Frasco','Uso veterinario',1),
(3,'Antiséptico tópico','Solución','Limpieza tópica según indicación profesional',1);
INSERT INTO recetas (id,consulta_id,fecha_emision,indicaciones_generales) VALUES
(1,1,'2026-10-20 10:20:00','Seguir las indicaciones del profesional y acudir a revisión si aparecen síntomas.');
INSERT INTO detalle_receta (id,receta_id,medicamento_id,dosis,frecuencia,duracion,cantidad,instrucciones) VALUES
(1,1,1,'Según peso y producto','Según indicación veterinaria','Según etiqueta/indicación',1,'Confirmar dosis con el veterinario antes de administrar.');
INSERT INTO pagos (id,cita_id,monto,metodo_pago,estado,fecha_pago,referencia) VALUES
(1,1,450.00,'Efectivo','Pagado','2026-10-20 10:30:00','DEMO-PAGO-0001'),
(2,2,300.00,'Transferencia','Pendiente',NULL,'DEMO-PAGO-0002'),
(3,3,550.00,'Tarjeta de débito','Pendiente',NULL,'DEMO-PAGO-0003');
