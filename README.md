# Veterinaria Huellitas

**Integrantes:**

- 24410214 - Joselyn Contreras Bustillos
- 21410488 - Joel Eduardo Herrera Sánchez
- 24410173 - Omar Ali Loya Reyes

---

## 1. Idea general

Veterinaria Huellitas será una aplicación web para organizar la atención de mascotas y la administración de una veterinaria. Permitirá reunir en un mismo sistema los datos de los clientes y sus mascotas, los veterinarios, los servicios, las citas, las consultas médicas, los diagnósticos, las recetas y los pagos.

La problemática que busca resolver es la dispersión de la información cuando estos registros se mantienen en libretas, hojas de cálculo o archivos independientes. Esta situación dificulta recuperar el historial de una mascota, consultar citas pendientes, identificar los servicios realizados y conocer los pagos recibidos. También puede ocasionar registros duplicados o citas que coincidan en el horario de un mismo veterinario.

El sistema estará dirigido a dos tipos de usuarios: **Administrador** y **Cliente**. El Administrador gestionará la operación de la veterinaria y registrará la información de las atenciones. El Cliente podrá administrar sus datos y sus mascotas, solicitar citas y consultar la información médica y los pagos que le correspondan.

**Objetivo general:** desarrollar una aplicación web que centralice la información de Veterinaria Huellitas en una base de datos MySQL, controle el acceso mediante roles y permita generar cuatro tipos de reportes parametrizables en PDF.

### Alcance

La primera versión permitirá:

- Iniciar y cerrar sesión con una cuenta de Administrador o Cliente.
- Registrar y administrar clientes y mascotas.
- Registrar veterinarios y asignarlos a las citas.
- Mantener los catálogos de servicios, diagnósticos y medicamentos.
- Solicitar, confirmar, consultar y cancelar citas.
- Registrar consultas médicas con síntomas, peso, temperatura y recomendaciones.
- Asociar uno o varios diagnósticos con una consulta.
- Elaborar recetas con medicamentos, dosis, frecuencia, duración e indicaciones.
- Registrar pagos y permitir que cada cliente consulte los suyos.
- Mostrar un panel de inicio diferente para cada rol.
- Generar reportes PDF de citas, mascotas atendidas, consultas médicas e ingresos.

El proyecto se enfocará en una sola sucursal y en la atención ambulatoria. El catálogo de medicamentos servirá para elaborar recetas; no incluirá inventario ni venta de medicamentos. La primera versión tampoco incluirá hospitalización, facturación fiscal, pagos en línea ni abonos parciales.

**El veterinario no será un rol de acceso.** Sus datos se almacenarán en una tabla independiente y el Administrador lo asignará a las citas. El veterinario aparecerá como responsable de la atención en las citas, consultas y recetas, pero no tendrá credenciales ni un panel propio. El Administrador capturará la información clínica proporcionada por el profesional; el sistema no realizará diagnósticos automáticos.

## 2. Descripción de tablas

La base de datos se llamará `veterinaria_huellitas` y contará con **13 tablas relacionadas**. Las claves primarias identificarán los registros y las claves foráneas conservarán sus relaciones.

**Convenciones:** PK = clave primaria, FK = clave foránea y UQ = valor o combinación de valores que no se puede repetir. Los identificadores serán enteros; los importes se almacenarán con `DECIMAL`, y las fechas y horas con los tipos correspondientes de MySQL.

| No. | Tabla | Descripción | Campos principales |
| --- | --- | --- | --- |
| 1 | `usuarios` | Almacena las cuentas de acceso y los datos de identidad de Administradores y Clientes. | `id_usuario` (PK), `nombre`, `apellido`, `usuario` (UQ), `contrasena_hash`, `correo` (UQ), `rol`, `fecha_registro`, `activo`. |
| 2 | `clientes` | Completa el perfil del propietario de las mascotas con sus datos de contacto. | `id_cliente` (PK), `id_usuario` (FK, UQ), `telefono`, `direccion`. |
| 3 | `mascotas` | Registra las mascotas y las relaciona con el cliente responsable. | `id_mascota` (PK), `id_cliente` (FK), `nombre`, `raza`, `sexo`, `fecha_nacimiento`, `peso_inicial`, `color`, `foto`, `activo`. |
| 4 | `veterinarios` | Guarda la información de los profesionales que pueden atender las citas. | `id_veterinario` (PK), `nombre`, `apellido`, `cedula_profesional` (UQ), `especialidad`, `telefono`, `correo`, `activo`. |
| 5 | `servicios` | Define los servicios ofrecidos por la veterinaria y su precio vigente. | `id_servicio` (PK), `nombre`, `descripcion`, `precio`, `activo`. |
| 6 | `citas` | Relaciona una mascota con un veterinario y un servicio en una fecha y horario determinados. | `id_cita` (PK), `id_mascota` (FK), `id_veterinario` (FK), `id_servicio` (FK), `fecha`, `hora`, `hora_fin`, `precio_aplicado`, `estado`, `motivo`. |
| 7 | `consultas` | Almacena los datos clínicos de la atención correspondiente a una cita. | `id_consulta` (PK), `id_cita` (FK, UQ), `fecha`, `sintomas`, `peso`, `temperatura`, `recomendaciones`. |
| 8 | `diagnosticos` | Mantiene el catálogo de diagnósticos que pueden asociarse con las consultas. | `id_diagnostico` (PK), `nombre`, `descripcion`, `activo`. |
| 9 | `consulta_diagnostico` | Resuelve la relación muchos a muchos entre consultas y diagnósticos. | `id_consulta_diagnostico` (PK), `id_consulta` (FK), `id_diagnostico` (FK). UQ: (`id_consulta`, `id_diagnostico`). |
| 10 | `medicamentos` | Guarda los medicamentos disponibles en el catálogo para elaborar recetas. | `id_medicamento` (PK), `nombre`, `presentacion`, `laboratorio`, `descripcion`, `activo`. |
| 11 | `recetas` | Registra la receta asociada con una consulta y sus indicaciones generales. | `id_receta` (PK), `id_consulta` (FK, UQ), `fecha`, `indicaciones_generales`. |
| 12 | `detalle_receta` | Almacena los medicamentos y las instrucciones particulares de cada receta. | `id_detalle` (PK), `id_receta` (FK), `id_medicamento` (FK), `dosis`, `frecuencia`, `duracion`, `indicaciones`. |
| 13 | `pagos` | Registra el cobro de una cita y su estado. El cliente se identifica mediante la mascota de la cita. | `id_pago` (PK), `id_cita` (FK, UQ), `fecha`, `monto`, `concepto`, `metodo_pago`, `estado`. |


## 3. Tipos de usuario (roles)

Veterinaria Huellitas tendrá **dos roles de usuario**, con permisos y pantallas diferentes. El servidor comprobará tanto el rol como la propiedad de los registros antes de permitir cualquier operación.

**Administrador**
Es el encargado de gestionar la operación completa de la veterinaria.

Funciones:
- Gestionar clientes.
- Gestionar mascotas.
- Registrar y gestionar veterinarios.
- Gestionar servicios.
- Gestionar citas.
- Registrar consultas médicas.
- Registrar diagnósticos.
- Gestionar medicamentos.
- Elaborar recetas y tratamientos.
- Registrar y consultar pagos.
- Consultar toda la información del sistema.
- Generar cuatro tipos de reportes PDF.

**Cliente**
Es el propietario de una o varias mascotas.

Funciones:
- Consultar y modificar sus propios datos.
- Registrar sus mascotas.
- Consultar sus mascotas.
- Modificar la información básica de sus mascotas.
- Solicitar citas para sus mascotas.
- Consultar sus citas.
- Cancelar sus citas cuando corresponda.
- Consultar el historial médico de sus mascotas.
- Consultar diagnósticos.
- Consultar recetas y tratamientos.
- Consultar sus pagos e historial de pagos.
El cliente no puede modificar información médica ni administrar información de otros clientes.


El menú del **Administrador** incluirá Inicio, Clientes, Mascotas, Veterinarios, Servicios, Citas, Consultas Médicas, Diagnósticos, Medicamentos, Recetas, Pagos y Reportes.

El menú del **Cliente** incluirá Inicio, Mi perfil, Mis mascotas, Mis citas, Historial médico y Mis pagos. En el historial médico podrá consultar sus consultas, diagnósticos y recetas.

El rol Veterinario no existirá como cuenta de acceso. La tabla `veterinarios` será un registro de los profesionales que prestan la atención y permitirá asignar a uno de ellos a cada cita.

## 4. Arquitectura

Veterinaria Huellitas será desarrollada como una **aplicación web bajo una arquitectura cliente-servidor de tres capas: presentación, lógica de aplicación y datos**.

La capa de presentación estará compuesta por las interfaces web destinadas a los usuarios Administrador y Cliente. La capa de lógica de aplicación gestionará la autenticación, los permisos, las validaciones, las operaciones del sistema y la generación de reportes. Finalmente, la capa de datos utilizará una base de datos MySQL para almacenar y relacionar la información.

| Capa | Responsabilidad | Tecnologías propuestas |
| --- | --- | --- |
| **Presentación** | Mostrar los paneles, formularios, listados y consultas de información correspondientes a cada rol. | HTML5, CSS3 y JavaScript. |
| **Lógica de aplicación** | Procesar las solicitudes, verificar sesiones y permisos, validar datos, aplicar las reglas del sistema y generar archivos PDF. | PHP, PDO para la conexión y consultas preparadas, y una biblioteca de generación de PDF como FPDF. |
| **Datos** | Almacenar las 13 tablas, aplicar restricciones de integridad y ejecutar las transacciones necesarias. | MySQL con tablas InnoDB y claves foráneas. |

Todos los módulos utilizarán la misma base de datos `veterinaria_huellitas`. El navegador enviará solicitudes al servidor Apache; PHP verificará la sesión, los permisos y los datos recibidos antes de consultar o modificar MySQL. El servidor devolverá la página solicitada o el reporte PDF. El navegador no se conectará directamente a la base de datos.

### Lenguajes y entorno de desarrollo

- **HTML5 y CSS3:** estructura y presentación visual de las pantallas.
- **JavaScript:** interacciones de la interfaz y validaciones de apoyo en el navegador.
- **PHP:** lógica del servidor, autenticación, validaciones y generación de reportes.
- **SQL:** definición y consulta de la base de datos MySQL.
- **Visual Studio Code:** edición y organización del código fuente.
- **Apache:** servidor web durante el desarrollo local.
- **XAMPP:** apoyo para instalar y ejecutar Apache y PHP. Se configurará la conexión hacia una instancia MySQL para cumplir con el gestor solicitado en la actividad.
- **Git y GitHub:** control de versiones y trabajo del equipo en un repositorio privado.

### Módulos del sistema

| Módulo | Función | Acceso del Administrador | Acceso del Cliente |
| --- | --- | --- | --- |
| **Inicio** | Mostrar indicadores y accesos a las operaciones del sistema. | Panel general de la veterinaria. | Panel con sus mascotas, citas y pagos. |
| **Clientes** | Administrar cuentas y datos de contacto. | Registrar, consultar, actualizar y desactivar clientes. | Consultar y editar su propio perfil. |
| **Mascotas** | Registrar y administrar los datos de las mascotas. | Gestionar las mascotas de todos los clientes. | Registrar y editar los datos básicos de las suyas. |
| **Veterinarios** | Administrar los datos de los profesionales. | Registrar, consultar, actualizar y desactivar veterinarios. | Consultar los datos mostrados del veterinario asignado a sus citas. |
| **Servicios** | Mantener los servicios y precios vigentes. | Registrar, consultar, actualizar y desactivar servicios. | Consultar los servicios disponibles al solicitar una cita. |
| **Citas** | Organizar solicitudes, horarios y estados. | Gestionar la agenda completa y confirmar solicitudes. | Solicitar, consultar y cancelar sus propias citas bajo las reglas definidas. |
| **Consultas Médicas** | Registrar la atención y mantener el historial clínico. | Registrar, consultar y actualizar las consultas. | Consultar las atenciones de sus mascotas. |
| **Diagnósticos** | Mantener el catálogo y asociarlo con las consultas. | Administrar diagnósticos y registrar los de cada atención. | Consultar los diagnósticos de sus mascotas. |
| **Medicamentos** | Mantener el catálogo utilizado en las recetas. | Registrar, consultar, actualizar y desactivar medicamentos. | Consultar los medicamentos incluidos en sus recetas. |
| **Recetas** | Registrar medicamentos e instrucciones de tratamiento. | Elaborar, consultar y actualizar recetas. | Consultar las recetas y tratamientos de sus mascotas. |
| **Pagos** | Registrar los cobros y su estado. | Registrar, consultar y actualizar los pagos. | Consultar sus pagos e historial de pagos. |
| **Reportes** | Aplicar filtros y generar los PDF. | Generar todos los reportes. | Sin acceso al módulo administrativo de reportes. |

Las contraseñas se almacenarán mediante hashes y las validaciones definitivas se ejecutarán en PHP. Las operaciones que involucren varios registros, como crear un cliente con su cuenta o guardar una receta con sus detalles, se realizarán mediante transacciones. La reserva de horarios validará y bloqueará los registros del veterinario y de la mascota dentro de una transacción para evitar cruces ante solicitudes simultáneas.

## 5. Reportes

El Administrador podrá generar **cuatro tipos de reportes parametrizables en formato PDF**. Cada reporte contará con una pantalla para seleccionar sus filtros antes de descargarlo.

| ID | Reporte | Contenido | Parámetros obligatorios | Parámetros opcionales |
| --- | --- | --- | --- | --- |
| **REP-01** | **Citas** | Fecha, horario, mascota, cliente, veterinario, servicio, motivo y estado. Se ordenará por fecha y hora e incluirá el número de citas por estado. | Fecha inicial y fecha final de la cita. | Veterinario, servicio y estado. |
| **REP-02** | **Mascotas atendidas** | Mascotas que tengan consultas registradas en el periodo, con nombre, raza, sexo, cliente responsable, cantidad de atenciones y fechas de primera y última atención dentro del periodo. Cada mascota aparecerá una sola vez. | Fecha inicial y fecha final de atención. | Cliente, veterinario y servicio. |
| **REP-03** | **Consultas médicas** | Consultas del periodo con fecha, mascota, cliente, veterinario, servicio, síntomas, peso, temperatura, diagnósticos y recomendaciones. Se ordenará por fecha y número de consulta. | Fecha inicial y fecha final de la consulta. | Mascota, veterinario y diagnóstico. |
| **REP-04** | **Ingresos** | Pagos realizados con fecha, cliente, mascota, servicio, concepto, método y monto. Incluirá el total del periodo y el desglose por método de pago. | Fecha inicial y fecha final del pago. | Cliente, servicio y método de pago. |

### Reglas de generación

- Los cuatro reportes estarán disponibles exclusivamente para el Administrador.
- Cada PDF incluirá el nombre **Veterinaria Huellitas**, el título del reporte, los filtros aplicados, la fecha y hora de generación, el usuario emisor y los números de página.
- El sistema validará que la fecha inicial no sea posterior a la final. El rango incluirá ambos días completos.
- Los filtros opcionales podrán omitirse para consultar todos los registros del periodo permitido.
- Si no existen resultados, el archivo indicará **«Sin registros para los filtros seleccionados»**.
- El reporte de mascotas atendidas agrupará por mascota después de aplicar los filtros. Varias consultas de la misma mascota no aumentarán el número de mascotas distintas.
- En el reporte de consultas, varios diagnósticos se mostrarán dentro del detalle de una misma atención, sin contarla varias veces.
- El reporte de ingresos considerará únicamente pagos con estado **Pagado**, usando su fecha efectiva de pago. Los registros Pendientes o Cancelados no se sumarán a los ingresos.
- Los ingresos se calcularán con los montos registrados en los pagos, sin utilizar los precios actuales del catálogo ni multiplicar importes al relacionar diagnósticos o recetas.

## 6. Requerimientos funcionales

La prioridad **Imprescindible** identificará funciones necesarias para la operación y para cumplir las características obligatorias de la actividad. La prioridad **Importante** identificará funciones de apoyo que mejorarán el uso del sistema. Los cuatro reportes PDF serán imprescindibles.

| ID | Módulo | Nombre | Rol principal | Descripción del requerimiento | Prioridad |
| --- | --- | --- | --- | --- | --- |
| **RF-01** | Seguridad | Autenticar usuario | Administrador, Cliente | El sistema permitirá iniciar sesión con nombre de usuario y contraseña, validará que la cuenta esté activa y dirigirá al usuario al panel de su rol. | Imprescindible |
| **RF-02** | Seguridad | Cerrar sesión | Administrador, Cliente | El sistema permitirá cerrar la sesión y exigirá una nueva autenticación para acceder a las páginas protegidas. | Imprescindible |
| **RF-03** | Seguridad | Validar permisos y propiedad | Administrador, Cliente | El sistema comprobará en el servidor el rol y la propiedad de cada registro. Impedirá que un Cliente consulte o modifique información de otros clientes, incluso mediante direcciones o identificadores enviados directamente. | Imprescindible |
| **RF-04** | Clientes | Registrar un cliente | Administrador | El sistema permitirá registrar la cuenta y el perfil del cliente solicitando nombre, apellido, usuario, correo, contraseña inicial y teléfono, con dirección opcional; impedirá repetir usuario o correo y guardará ambos registros en una transacción. | Imprescindible |
| **RF-05** | Clientes | Administrar clientes | Administrador | El sistema permitirá consultar y actualizar los datos de cualquier cliente y desactivar su cuenta sin eliminar sus mascotas, citas, consultas o pagos. | Imprescindible |
| **RF-06** | Clientes | Modificar el perfil propio | Cliente | El sistema permitirá al Cliente consultar y actualizar sus datos personales y de contacto y cambiar su contraseña verificando la actual; impedirá que modifique su rol o la titularidad de sus registros. | Imprescindible |
| **RF-07** | Mascotas | Gestionar mascotas | Administrador | El sistema permitirá registrar, consultar y actualizar mascotas de cualquier cliente, solicitando propietario, nombre, raza y sexo; la fecha de nacimiento, el peso inicial, el color y la fotografía serán opcionales. | Imprescindible |
| **RF-08** | Mascotas | Administrar mascotas propias | Cliente | El sistema permitirá al Cliente registrar mascotas asociándolas automáticamente con su perfil y consultar o editar sus datos básicos; impedirá cambiar el propietario, el peso clínico de consultas anteriores o cualquier otro dato médico. | Imprescindible |
| **RF-09** | Mascotas | Agregar fotografía | Administrador, Cliente | El sistema permitirá agregar o sustituir una fotografía opcional de la mascota, validando que el archivo sea una imagen; el Cliente solo podrá hacerlo en sus propias mascotas. | Importante |
| **RF-10** | Clientes y Mascotas | Buscar registros | Administrador, Cliente | El sistema permitirá buscar mascotas por nombre y consultar sus datos. El Administrador también podrá buscar clientes por nombre o teléfono; las búsquedas del Cliente se limitarán a sus mascotas. | Importante |
| **RF-11** | Veterinarios | Gestionar veterinarios | Administrador | El sistema permitirá registrar, consultar, actualizar y desactivar veterinarios con nombre, apellido, cédula profesional, especialidad y datos de contacto; rechazará cédulas repetidas y no creará cuentas de acceso para ellos. | Imprescindible |
| **RF-12** | Servicios | Gestionar servicios | Administrador | El sistema permitirá registrar, consultar, actualizar y desactivar servicios con nombre, descripción y precio positivo; conservará los precios aplicados en citas anteriores cuando cambie el catálogo. | Imprescindible |
| **RF-13** | Citas | Solicitar una cita | Cliente | El sistema permitirá solicitar una cita para una mascota propia y activa, seleccionando servicio, veterinario disponible, fecha, horario y motivo; la solicitud quedará en estado Pendiente. | Imprescindible |
| **RF-14** | Citas | Registrar citas desde la administración | Administrador | El sistema permitirá registrar una cita para la mascota de cualquier cliente activo, seleccionando un veterinario y un servicio activos, fecha, hora de inicio, hora de fin y motivo. | Imprescindible |
| **RF-15** | Citas | Validar disponibilidad de horario | Administrador, Cliente | El sistema exigirá una fecha y hora de inicio futuras y una hora de fin posterior dentro del mismo día; impedirá traslapes con citas Pendientes o Confirmadas del mismo veterinario o de la misma mascota y permitirá horarios consecutivos. | Imprescindible |
| **RF-16** | Citas | Confirmar y reprogramar citas | Administrador | El sistema permitirá confirmar solicitudes Pendientes y modificar el horario de citas Pendientes o Confirmadas, validando nuevamente la disponibilidad; impedirá reasignar mascota, veterinario o servicio cuando exista consulta o pago registrado. | Imprescindible |
| **RF-17** | Citas | Cancelar una cita | Administrador, Cliente | El sistema permitirá cancelar citas futuras Pendientes o Confirmadas que no tengan consulta ni pago Pagado; el Cliente solo podrá cancelar las suyas. Si existe un cobro Pendiente, se cancelará junto con la cita. | Imprescindible |
| **RF-18** | Citas | Consultar la agenda | Administrador, Cliente | El sistema mostrará las citas con fecha, horario, mascota, veterinario, servicio y estado. El Administrador podrá filtrar toda la agenda por fecha, estado y veterinario; el Cliente solo verá sus citas. | Imprescindible |
| **RF-19** | Consultas Médicas | Registrar una consulta | Administrador | El sistema permitirá registrar una única consulta para una cita Confirmada, con fecha de atención, síntomas, peso positivo y recomendaciones, y temperatura opcional; al guardar la atención, cambiará la cita a Atendida en la misma transacción. | Imprescindible |
| **RF-20** | Consultas Médicas | Actualizar información clínica | Administrador | El sistema permitirá consultar y corregir los datos clínicos de una consulta existente sin cambiar la cita, la mascota o el veterinario al que corresponda. El Cliente tendrá acceso de solo lectura. | Imprescindible |
| **RF-21** | Diagnósticos | Gestionar diagnósticos | Administrador | El sistema permitirá registrar, consultar, actualizar y desactivar diagnósticos del catálogo, con nombre y descripción, conservando las asociaciones con consultas anteriores. | Imprescindible |
| **RF-22** | Diagnósticos | Asociar diagnósticos con una consulta | Administrador | El sistema permitirá seleccionar uno o varios diagnósticos para una consulta y actualizar esas asociaciones, rechazando la repetición de un mismo diagnóstico en la misma atención. | Imprescindible |
| **RF-23** | Medicamentos | Gestionar medicamentos | Administrador | El sistema permitirá registrar, consultar, actualizar y desactivar medicamentos con nombre, presentación, laboratorio y descripción; conservará los detalles de las recetas en que se hayan utilizado. | Imprescindible |
| **RF-24** | Recetas | Elaborar una receta | Administrador | El sistema permitirá elaborar una receta por consulta con fecha, indicaciones generales y al menos un medicamento; cada detalle incluirá dosis, frecuencia, duración e indicaciones, y la receta completa se guardará en una transacción. | Imprescindible |
| **RF-25** | Recetas | Consultar y actualizar recetas | Administrador, Cliente | El sistema permitirá al Administrador consultar y actualizar recetas y sus detalles, manteniendo al menos un medicamento. El Cliente solo podrá consultar las recetas y tratamientos de sus propias mascotas. | Imprescindible |
| **RF-26** | Consultas Médicas | Consultar historial médico | Administrador, Cliente | El sistema mostrará las consultas de una mascota con sus diagnósticos, recomendaciones y recetas, ordenadas de la más reciente a la más antigua; el Cliente solo accederá al historial de sus mascotas. | Imprescindible |
| **RF-27** | Pagos | Registrar y actualizar cobros | Administrador | El sistema permitirá registrar un cobro por cita, con monto igual al precio aplicado y estado Pendiente, Pagado o Cancelado. Para marcarlo Pagado exigirá fecha efectiva y método de pago; no aceptará pagos de citas Canceladas ni registros duplicados. | Imprescindible |
| **RF-28** | Pagos | Consultar pagos propios | Cliente | El sistema permitirá al Cliente consultar el historial de sus pagos con fecha, cita, mascota, servicio, concepto, monto, método y estado, sin permitirle registrar o modificar cobros. | Imprescindible |
| **RF-29** | Inicio | Mostrar el panel administrativo | Administrador | El sistema mostrará citas del día y sus estados, cantidades de clientes y mascotas activos, veterinarios activos e ingresos de un periodo seleccionado, sumando únicamente pagos Pagados. | Importante |
| **RF-30** | Inicio | Mostrar el panel del cliente | Cliente | El sistema mostrará sus mascotas activas, próximas citas Pendientes o Confirmadas y el total de sus pagos Pagados, calculado exclusivamente con registros del cliente autenticado. | Importante |
| **RF-31** | Reportes | Generar reporte de citas | Administrador | El sistema generará REP-01 en PDF por rango de fechas, con filtros opcionales de veterinario, servicio y estado, mostrando las citas y su cantidad por estado. | Imprescindible |
| **RF-32** | Reportes | Generar reporte de mascotas atendidas | Administrador | El sistema generará REP-02 en PDF por rango de fechas de atención, con filtros opcionales de cliente, veterinario y servicio, mostrando una fila por mascota y la cantidad de consultas del periodo. | Imprescindible |
| **RF-33** | Reportes | Generar reporte de consultas médicas | Administrador | El sistema generará REP-03 en PDF por rango de fechas, con filtros opcionales de mascota, veterinario y diagnóstico, mostrando la información clínica sin duplicar consultas por sus diagnósticos. | Imprescindible |
| **RF-34** | Reportes | Generar reporte de ingresos | Administrador | El sistema generará REP-04 en PDF por rango de fechas de pago, con filtros opcionales de cliente, servicio y método de pago; sumará únicamente pagos Pagados y presentará el total por método. | Imprescindible |
| **RF-35** | Reportes | Validar filtros y descargar PDF | Administrador | El sistema validará los parámetros de cada reporte e incluirá nombre de la veterinaria, título, filtros, fecha de generación, usuario emisor y paginación; permitirá descargar el PDF e indicará cuando no existan resultados. | Imprescindible |
| **RF-36** | Gestión general | Conservar los antecedentes | Administrador | El sistema impedirá eliminar registros con relaciones históricas y permitirá desactivar cuentas, mascotas y catálogos. Impedirá desactivar una mascota o un veterinario con citas futuras Pendientes o Confirmadas hasta resolverlas. | Imprescindible |
