drop database if exists smart_grid;
create database smart_grid;
use smart_grid;

-- 1. infraestructura y topologia
create table subestacion (
    id_subestacion int auto_increment primary key,
    nombre varchar(100) not null unique,
    ciudad varchar(100) not null,
    direccion varchar(255) not null,
    capacidad_maxima decimal(10,2) not null check (capacidad_maxima > 0)
);

create table zona (
    id_zona int auto_increment primary key,
    nombre varchar(100) not null,
    id_subestacion int not null,
    foreign key (id_subestacion) references subestacion(id_subestacion) on delete restrict
);

create table barrio (
    id_barrio int auto_increment primary key,
    nombre varchar(100) not null,
    id_zona int not null,
    foreign key (id_zona) references zona(id_zona) on delete restrict,
    unique (nombre, id_zona)
);

create table transformador (
    id_transformador int auto_increment primary key,
    id_subestacion int not null,
    codigo varchar(50) not null unique,
    capacidad_kva decimal(10,2) not null check (capacidad_kva > 0),
    nivel_aceite decimal(5,2) check (nivel_aceite between 0 and 100),
    estado_operativo enum('activo', 'inactivo', 'mantenimiento', 'falla') default 'activo',
    foreign key (id_subestacion) references subestacion(id_subestacion) on delete restrict
);

-- 2. clientes y equipos
create table tarifa (
    id_tarifa int auto_increment primary key,
    tipo_cliente enum('residencial', 'comercial', 'industrial') not null,
    costo_por_kwh decimal(10,4) not null check (costo_por_kwh >= 0),
    fecha_inicio_vigencia date not null
);

create table cliente (
    id_cliente int auto_increment primary key,
    nombre varchar(150) not null,
    documento varchar(20) not null unique,
    telefono varchar(20),
    correo varchar(100),
    direccion varchar(255) not null,
    id_tarifa int not null,
    id_barrio int not null,
    foreign key (id_tarifa) references tarifa(id_tarifa),
    foreign key (id_barrio) references barrio(id_barrio)
);

create table medidor (
    id_medidor int auto_increment primary key,
    codigo_serial varchar(100) not null unique,
    tipo enum('monofasico', 'bifasico', 'trifasico') not null,
    fecha_instalacion date not null,
    estado enum('activo', 'inactivo', 'suspendido') default 'activo',
    id_cliente int,
    id_transformador int not null,
    foreign key (id_cliente) references cliente(id_cliente) on delete set null,
    foreign key (id_transformador) references transformador(id_transformador)
);

-- 3. mantenimiento y cuadrillas
create table cuadrilla (
    id_cuadrilla int auto_increment primary key,
    nombre varchar(100) not null unique,
    estado enum('disponible', 'ocupada', 'en ruta', 'fuera de servicio') default 'disponible'
);

create table tecnico (
    id_tecnico int auto_increment primary key,
    nombre varchar(150) not null,
    especialidad varchar(100) not null,
    telefono varchar(20)
);

create table cuadrilla_tecnico (
    id_cuadrilla int not null,
    id_tecnico int not null,
    fecha_asignacion date not null,
    primary key (id_cuadrilla, id_tecnico),
    foreign key (id_cuadrilla) references cuadrilla(id_cuadrilla),
    foreign key (id_tecnico) references tecnico(id_tecnico)
);

create table mantenimiento (
    id_mantenimiento int auto_increment primary key,
    id_transformador int not null,
    id_cuadrilla int not null,
    fecha_inicio datetime not null,
    fecha_fin datetime,
    tipo enum('preventivo', 'correctivo', 'emergencia') not null,
    descripcion text,
    constraint chk_fechas_mantenimiento check (fecha_fin is null or fecha_fin >= fecha_inicio),
    foreign key (id_transformador) references transformador(id_transformador),
    foreign key (id_cuadrilla) references cuadrilla(id_cuadrilla)
);

-- 4. eventos y alertas
create table falla (
    id_falla int auto_increment primary key,
    id_transformador int not null,
    fecha_hora datetime not null,
    descripcion text not null,
    gravedad enum('baja', 'media', 'alta', 'critica') not null,
    foreign key (id_transformador) references transformador(id_transformador)
);

create table alerta (
    id_alerta int auto_increment primary key,
    id_transformador int not null,
    id_falla int null,
    fecha_hora datetime not null,
    descripcion text not null,
    tipo_alerta varchar(50) not null,
    nivel_criticidad enum('baja', 'media', 'alta', 'critica') not null,
    estado enum('activa', 'en proceso', 'resuelta') default 'activa',
    foreign key (id_transformador) references transformador(id_transformador),
    foreign key (id_falla) references falla(id_falla)
);

-- 5. medidas e historicos
create table consumo (
    id_consumo bigint auto_increment primary key,
    id_medidor int not null,
    fecha_hora datetime not null,
    valor_kwh decimal(12,4) not null check (valor_kwh >= 0),
    voltaje decimal(6,2) check (voltaje >= 0),
    corriente decimal(6,2) check (corriente >= 0),
    temperatura_ambiente decimal(3,1),
    foreign key (id_medidor) references medidor(id_medidor),
    index idx_medidor_fecha (id_medidor, fecha_hora)
);

-- ============================================================================
-- datos de ejemplo (insert)
-- ============================================================================

-- 1. subestacion
insert into subestacion (nombre, ciudad, direccion, capacidad_maxima) values
('subestacion sincelejo norte', 'sincelejo', 'troncal de occidente km 2', 15000.00),
('subestacion boston', 'sincelejo', 'calle 28 # 14-50', 10000.00);

-- 2. zona
insert into zona (nombre, id_subestacion) values
('zona centro', 1),
('zona sur', 2);

-- 3. barrio
insert into barrio (nombre, id_zona) values
('majagual', 1),
('la ford', 1),
('boston', 2);

-- 4. transformador
insert into transformador (id_subestacion, codigo, capacidad_kva, nivel_aceite, estado_operativo) values
(1, 'tr-sin-001', 250.00, 88.5, 'activo'),
(1, 'tr-sin-002', 500.00, 76.0, 'activo'),
(2, 'tr-bos-001', 150.00, 62.0, 'mantenimiento');

-- 5. tarifa
insert into tarifa (tipo_cliente, costo_por_kwh, fecha_inicio_vigencia) values
('residencial', 780.5000, '2026-01-01'),
('comercial', 920.0000, '2026-01-01'),
('industrial', 850.7500, '2026-01-01');

-- 6. cliente
insert into cliente (nombre, documento, telefono, correo, direccion, id_tarifa, id_barrio) values
('carlos mendoza', '1102845123', '3004567890', 'cmendoza@gmail.com', 'calle 20 # 18-30', 1, 1),
('supermercado el ahorro', '900456123-1', '3109876543', 'contacto@elahorro.com', 'carrera 19 # 22-15', 2, 2),
('laura paternina', '1102899321', '3152345678', 'laura.pat@hotmail.com', 'calle 30 # 12-45', 1, 3);

-- 7. medidor
insert into medidor (codigo_serial, tipo, fecha_instalacion, estado, id_cliente, id_transformador) values
('med-sin-1001', 'monofasico', '2025-06-15', 'activo', 1, 1),
('med-sin-1002', 'trifasico', '2025-08-20', 'activo', 2, 2),
('med-sin-1003', 'bifasico', '2025-11-10', 'activo', 3, 3);

-- 8. cuadrilla
insert into cuadrilla (nombre, estado) values
('cuadrilla alfa - redes', 'disponible'),
('cuadrilla beta - emergencias', 'ocupada');

-- 9. tecnico
insert into tecnico (nombre, especialidad, telefono) values
('jorge vergara', 'liniero alta tension', '3015551122'),
('andres bertel', 'protecciones y transformadores', '3024443322'),
('mario salgado', 'medicion inteligente', '3147778899');

-- 10. cuadrilla_tecnico
insert into cuadrilla_tecnico (id_cuadrilla, id_tecnico, fecha_asignacion) values
(1, 1, '2026-01-10'),
(1, 3, '2026-01-10'),
(2, 2, '2026-02-01');

-- 11. mantenimiento
insert into mantenimiento (id_transformador, id_cuadrilla, fecha_inicio, fecha_fin, tipo, descripcion) values
(1, 1, '2026-03-10 08:00:00', '2026-03-10 12:30:00', 'preventivo', 'limpieza de bornes y revision de nivel de aceite'),
(3, 2, '2026-11-17 09:00:00', null, 'correctivo', 'cambio de empaques y filtrado de aceite dielectrico');

-- 12. falla
insert into falla (id_transformador, fecha_hora, descripcion, gravedad) values
(2, '2026-11-15 14:20:00', 'fluctuacion de voltaje en fase b', 'media'),
(3, '2026-11-17 07:45:00', 'sobrecalentamiento por sobrecarga en hora pico', 'critica');

-- 13. alerta
insert into alerta (id_transformador, id_falla, fecha_hora, descripcion, tipo_alerta, nivel_criticidad, estado) values
(2, 1, '2026-11-15 14:21:00', 'desbalance de tension detectado', 'voltaje', 'media', 'resuelta'),
(3, 2, '2026-11-17 07:46:00', 'temperatura critica en transformador tr-bos-001', 'falla electrica', 'critica', 'activa');

-- 14. consumo
insert into consumo (id_medidor, fecha_hora, valor_kwh, voltaje, corriente, temperatura_ambiente) values
(1, '2026-11-01 18:00:00', 145.5000, 120.20, 12.40, 31.5),
(1, '2026-11-15 18:00:00', 162.3000, 119.80, 13.10, 32.0),
(2, '2026-11-01 18:00:00', 890.0000, 220.50, 45.20, 30.8),
(2, '2026-11-15 18:00:00', 940.7500, 219.90, 48.00, 31.2),
(3, '2026-11-10 18:00:00', 210.4000, 121.00, 15.60, 29.5);
