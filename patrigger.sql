delimiter //

-- 1. subestacion

-- PA: guarda una nueva subestacion
create procedure sp_registrar_subestacion(
    in p_nombre varchar(100),
    in p_ciudad varchar(100),
    in p_direccion varchar(255),
    in p_capacidad decimal(10,2)
)
begin
    insert into subestacion (nombre, ciudad, direccion, capacidad_maxima)
    values (p_nombre, p_ciudad, p_direccion, p_capacidad);
end //

-- TRIGGER: revisa que la capacidad no sea 0 o negativa antes de guardar
create trigger trg_subestacion_insert
before insert on subestacion
for each row
begin
    if new.capacidad_maxima <= 0 then
        signal sqlstate '45000'
        set message_text = 'error: la capacidad maxima de la subestacion debe ser mayor a cero';
    end if;
end //

-- 2. zona

-- PA: registra una zona nueva
create procedure sp_registrar_zona(
    in p_nombre varchar(100),
    in p_id_subestacion int
)
begin
    insert into zona (nombre, id_subestacion)
    values (p_nombre, p_id_subestacion);
end //

-- TRIGGER: no deja meter dos zonas con el mismo nombre en la misma subestacion
create trigger trg_zona_insert
before insert on zona
for each row
begin
    if exists (select 1 from zona where nombre = new.nombre and id_subestacion = new.id_subestacion) then
        signal sqlstate '45000'
        set message_text = 'error: ya existe esa zona en la subestacion indicada';
    end if;
end //

-- 3. barrio

-- PA: registra un barrio en una zona
create procedure sp_registrar_barrio(
    in p_nombre varchar(100),
    in p_id_zona int
)
begin
    insert into barrio (nombre, id_zona)
    values (p_nombre, p_id_zona);
end //

-- TRIGGER: evita que se repita el barrio dentro de la misma zona
create trigger trg_barrio_insert
before insert on barrio
for each row
begin
    if exists (select 1 from barrio where nombre = new.nombre and id_zona = new.id_zona) then
        signal sqlstate '45000'
        set message_text = 'error: el barrio ya se encuentra registrado en esa zona';
    end if;
end //

-- 4. transformador

-- PA: registra un transformador nuevo
create procedure sp_registrar_transformador(
    in p_id_subestacion int,
    in p_codigo varchar(50),
    in p_capacidad decimal(10,2),
    in p_nivel_aceite decimal(5,2)
)
begin
    insert into transformador (id_subestacion, codigo, capacidad_kva, nivel_aceite)
    values (p_id_subestacion, p_codigo, p_capacidad, p_nivel_aceite);
end //

-- TRIGGER: valida que la capacidad sea mayor a 0 y el aceite este entre 0 y 100
create trigger trg_transformador_insert
before insert on transformador
for each row
begin
    if new.capacidad_kva <= 0 then
        signal sqlstate '45000'
        set message_text = 'error: la capacidad del transformador debe ser mayor que cero';
    end if;

    if new.nivel_aceite is not null and (new.nivel_aceite < 0 or new.nivel_aceite > 100) then
        signal sqlstate '45000'
        set message_text = 'error: el nivel de aceite debe estar entre 0 y 100';
    end if;
end //

-- 5. tarifa

-- PA: actualiza el precio del kwh de una tarifa
create procedure sp_actualizar_tarifa(
    in p_id_tarifa int,
    in p_nuevo_costo decimal(10,4)
)
begin
    update tarifa
    set costo_por_kwh = p_nuevo_costo
    where id_tarifa = p_id_tarifa;
end //

-- TRIGGER: bloquea el cambio si el precio nuevo es 0 o negativo
create trigger trg_tarifa_update
before update on tarifa
for each row
begin
    if new.costo_por_kwh <= 0 then
        signal sqlstate '45000'
        set message_text = 'error: el costo por kwh debe ser mayor que cero';
    end if;
end //

-- 6. cliente

-- PA: guarda un cliente nuevo
create procedure sp_registrar_cliente(
    in p_nombre varchar(150),
    in p_documento varchar(20),
    in p_telefono varchar(20),
    in p_correo varchar(100),
    in p_direccion varchar(255),
    in p_id_tarifa int,
    in p_id_barrio int
)
begin
    insert into cliente (nombre, documento, telefono, correo, direccion, id_tarifa, id_barrio)
    values (p_nombre, p_documento, p_telefono, p_correo, p_direccion, p_id_tarifa, p_id_barrio);
end //

-- TRIGGER: revisa que la cedula no venga vacia ni este repetida
create trigger trg_cliente_insert
before insert on cliente
for each row
begin
    if trim(new.documento) = '' then
        signal sqlstate '45000'
        set message_text = 'error: el documento del cliente no puede estar vacio';
    end if;

    if exists (select 1 from cliente where documento = new.documento) then
        signal sqlstate '45000'
        set message_text = 'error: ya existe un cliente registrado con ese documento';
    end if;
end //

-- 7. medidor

-- PA: registra un medidor y lo asocia al cliente y transformador
create procedure sp_registrar_medidor(
    in p_codigo varchar(100),
    in p_tipo varchar(20),
    in p_fecha date,
    in p_id_cliente int,
    in p_id_transformador int
)
begin
    insert into medidor (codigo_serial, tipo, fecha_instalacion, id_cliente, id_transformador)
    values (p_codigo, p_tipo, p_fecha, p_id_cliente, p_id_transformador);
end //

-- TRIGGER: evita que se registre un serial de medidor que ya existe
create trigger trg_medidor_insert
before insert on medidor
for each row
begin
    if exists (select 1 from medidor where codigo_serial = new.codigo_serial) then
        signal sqlstate '45000'
        set message_text = 'error: el codigo serial del medidor ya existe';
    end if;
end //

-- 8. cuadrilla

-- PA: crea una cuadrilla de trabajo
create procedure sp_registrar_cuadrilla(
    in p_nombre varchar(100)
)
begin
    insert into cuadrilla (nombre)
    values (p_nombre);
end //

-- TRIGGER: no deja crear cuadrillas sin nombre o con nombre repetido
create trigger trg_cuadrilla_insert
before insert on cuadrilla
for each row
begin
    if trim(new.nombre) = '' or exists (select 1 from cuadrilla where nombre = new.nombre) then
        signal sqlstate '45000'
        set message_text = 'error: nombre de cuadrilla invalido o ya existente';
    end if;
end //

-- 9. tecnico

-- PA: guarda un tecnico nuevo
create procedure sp_registrar_tecnico(
    in p_nombre varchar(150),
    in p_especialidad varchar(100),
    in p_telefono varchar(20)
)
begin
    insert into tecnico (nombre, especialidad, telefono)
    values (p_nombre, p_especialidad, p_telefono);
end //

-- TRIGGER: verifica que el nombre y la especialidad no esten en blanco
create trigger trg_tecnico_insert
before insert on tecnico
for each row
begin
    if trim(new.nombre) = '' or trim(new.especialidad) = '' then
        signal sqlstate '45000'
        set message_text = 'error: el nombre y la especialidad del tecnico son obligatorios';
    end if;
end //

-- 10. cuadrilla_tecnico

-- PA: mete un tecnico dentro de una cuadrilla
create procedure sp_asignar_tecnico(
    in p_id_cuadrilla int,
    in p_id_tecnico int,
    in p_fecha date
)
begin
    insert into cuadrilla_tecnico (id_cuadrilla, id_tecnico, fecha_asignacion)
    values (p_id_cuadrilla, p_id_tecnico, p_fecha);
end //

-- TRIGGER: evita meter al mismo tecnico dos veces en la misma cuadrilla
create trigger trg_cuadrilla_tecnico_insert
before insert on cuadrilla_tecnico
for each row
begin
    if exists (
        select 1 from cuadrilla_tecnico
        where id_cuadrilla = new.id_cuadrilla and id_tecnico = new.id_tecnico
    ) then
        signal sqlstate '45000'
        set message_text = 'error: el tecnico ya pertenece a esta cuadrilla';
    end if;
end //

-- 11. mantenimiento (inicio)

-- PA: abre una orden de mantenimiento para un transformador
create procedure sp_registrar_mantenimiento(
    in p_id_transformador int,
    in p_id_cuadrilla int,
    in p_fecha_inicio datetime,
    in p_tipo varchar(20),
    in p_descripcion text
)
begin
    insert into mantenimiento (id_transformador, id_cuadrilla, fecha_inicio, tipo, descripcion)
    values (p_id_transformador, p_id_cuadrilla, p_fecha_inicio, p_tipo, p_descripcion);
end //

-- TRIGGER: cambia solo el estado del transformador a mantenimiento
create trigger trg_mantenimiento_insert
after insert on mantenimiento
for each row
begin
    update transformador
    set estado_operativo = 'mantenimiento'
    where id_transformador = new.id_transformador;
end //

-- 12. mantenimiento (cierre)

-- PA: pone fecha de fin para cerrar el mantenimiento
create procedure sp_finalizar_mantenimiento(
    in p_id_mantenimiento int,
    in p_fecha_fin datetime
)
begin
    update mantenimiento
    set fecha_fin = p_fecha_fin
    where id_mantenimiento = p_id_mantenimiento
      and fecha_fin is null;
end //

-- TRIGGER: vuelve a poner el transformador en activo cuando termina el trabajo
create trigger trg_mantenimiento_update
after update on mantenimiento
for each row
begin
    if old.fecha_fin is null and new.fecha_fin is not null then
        update transformador
        set estado_operativo = 'activo'
        where id_transformador = new.id_transformador
          and estado_operativo = 'mantenimiento';
    end if;
end //

-- 13. falla

-- PA: reporta una falla en un transformador
create procedure sp_registrar_falla(
    in p_id_transformador int,
    in p_fecha datetime,
    in p_descripcion text,
    in p_gravedad varchar(20)
)
begin
    insert into falla (id_transformador, fecha_hora, descripcion, gravedad)
    values (p_id_transformador, p_fecha, p_descripcion, p_gravedad);
end //

-- TRIGGER: si la falla es alta o critica crea una alerta sola
create trigger trg_falla_insert
after insert on falla
for each row
begin
    if new.gravedad in ('alta', 'critica') then
        insert into alerta (id_transformador, id_falla, fecha_hora, descripcion, tipo_alerta, nivel_criticidad, estado)
        values (new.id_transformador, new.id_falla, new.fecha_hora, new.descripcion, 'falla electrica', new.gravedad, 'activa');
    end if;
end //

-- 14. alerta

-- PA: marca una alerta como resuelta
create procedure sp_resolver_alerta(
    in p_id_alerta int
)
begin
    update alerta
    set estado = 'resuelta'
    where id_alerta = p_id_alerta;
end //

-- TRIGGER: no deja volver a activar una alerta que ya estaba resuelta
create trigger trg_alerta_update
before update on alerta
for each row
begin
    if old.estado = 'resuelta' and new.estado = 'activa' then
        signal sqlstate '45000'
        set message_text = 'error: no se puede reabrir una alerta ya resuelta';
    end if;
end //

-- 15. consumo

-- PA: guarda la lectura de consumo de un medidor
create procedure sp_registrar_consumo(
    in p_id_medidor int,
    in p_fecha datetime,
    in p_kwh decimal(12,4),
    in p_voltaje decimal(6,2),
    in p_corriente decimal(6,2),
    in p_temperatura decimal(3,1)
)
begin
    insert into consumo (id_medidor, fecha_hora, valor_kwh, voltaje, corriente, temperatura_ambiente)
    values (p_id_medidor, p_fecha, p_kwh, p_voltaje, p_corriente, p_temperatura);
end //

-- TRIGGER: bloquea valores negativos y no deja guardar si el medidor no esta activo
create trigger trg_consumo_insert
before insert on consumo
for each row
begin
    declare v_estado varchar(20);

    if new.valor_kwh < 0 or (new.voltaje is not null and new.voltaje < 0) or (new.corriente is not null and new.corriente < 0) then
        signal sqlstate '45000'
        set message_text
