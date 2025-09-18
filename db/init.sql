-- Script de inicialización de la base de datos
-- Se ejecuta automáticamente al crear el contenedor de PostgreSQL

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(50) UNIQUE NOT NULL,
    correo_electronico VARCHAR(100) UNIQUE NOT NULL,
    nombre_completo VARCHAR(150),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_usuarios_nombre_usuario ON usuarios(nombre_usuario);
CREATE INDEX IF NOT EXISTS idx_usuarios_correo ON usuarios(correo_electronico);
CREATE INDEX IF NOT EXISTS idx_usuarios_fecha_creacion ON usuarios(fecha_creacion);

-- Tabla de sesiones de usuario
CREATE TABLE IF NOT EXISTS sesiones_usuario (
    id_sesion UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_usuario INTEGER REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    token_sesion VARCHAR(255) UNIQUE NOT NULL,
    fecha_inicio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP WITH TIME ZONE NOT NULL,
    direccion_ip INET,
    activa BOOLEAN DEFAULT true
);

-- Índices para sesiones
CREATE INDEX IF NOT EXISTS idx_sesiones_token ON sesiones_usuario(token_sesion);
CREATE INDEX IF NOT EXISTS idx_sesiones_usuario ON sesiones_usuario(id_usuario);
CREATE INDEX IF NOT EXISTS idx_sesiones_activas ON sesiones_usuario(activa) WHERE activa = true;

-- Tabla de logs de actividad
CREATE TABLE IF NOT EXISTS logs_actividad (
    id_log SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    tipo_accion VARCHAR(50) NOT NULL,
    descripcion TEXT,
    datos_adicionales JSONB,
    direccion_ip INET,
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para logs
CREATE INDEX IF NOT EXISTS idx_logs_usuario ON logs_actividad(id_usuario);
CREATE INDEX IF NOT EXISTS idx_logs_fecha ON logs_actividad(fecha_registro);
CREATE INDEX IF NOT EXISTS idx_logs_tipo_accion ON logs_actividad(tipo_accion);

-- Función para actualizar fecha_actualizacion
CREATE OR REPLACE FUNCTION actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar automáticamente fecha_actualizacion
CREATE TRIGGER trigger_actualizar_fecha_usuarios
    BEFORE UPDATE ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_modificacion();

-- Datos de ejemplo para testing
INSERT INTO usuarios (nombre_usuario, correo_electronico, nombre_completo) VALUES
    ('admin', 'admin@miempresa.com', 'Administrador del Sistema'),
    ('usuario_demo', 'demo@miempresa.com', 'Usuario de Demostración'),
    ('desarrollador', 'dev@miempresa.com', 'Desarrollador Principal')
ON CONFLICT (nombre_usuario) DO NOTHING;

-- Vista para estadísticas básicas
CREATE OR REPLACE VIEW vista_estadisticas_usuarios AS
SELECT 
    COUNT(*) as total_usuarios,
    COUNT(*) FILTER (WHERE fecha_creacion >= CURRENT_DATE) as usuarios_hoy,
    COUNT(*) FILTER (WHERE fecha_creacion >= CURRENT_DATE - INTERVAL '7 days') as usuarios_semana,
    COUNT(*) FILTER (WHERE fecha_creacion >= CURRENT_DATE - INTERVAL '30 days') as usuarios_mes
FROM usuarios;

-- Función para limpiar sesiones expiradas
CREATE OR REPLACE FUNCTION limpiar_sesiones_expiradas()
RETURNS INTEGER AS $$
DECLARE
    sesiones_eliminadas INTEGER;
BEGIN
    DELETE FROM sesiones_usuario 
    WHERE fecha_expiracion < CURRENT_TIMESTAMP OR activa = false;
    
    GET DIAGNOSTICS sesiones_eliminadas = ROW_COUNT;
    RETURN sesiones_eliminadas;
END;
$$ LANGUAGE plpgsql;

-- Comentarios en las tablas
COMMENT ON TABLE usuarios IS 'Tabla principal de usuarios del sistema';
COMMENT ON TABLE sesiones_usuario IS 'Registro de sesiones activas de usuarios';
COMMENT ON TABLE logs_actividad IS 'Registro de actividades y auditoría del sistema';

COMMENT ON COLUMN usuarios.id_usuario IS 'Identificador único del usuario';
COMMENT ON COLUMN usuarios.nombre_usuario IS 'Nombre de usuario único para login';
COMMENT ON COLUMN usuarios.correo_electronico IS 'Correo electrónico único del usuario';

-- Verificar que todo se creó correctamente
DO $$
BEGIN
    RAISE NOTICE 'Base de datos inicializada correctamente';
    RAISE NOTICE 'Tablas creadas: usuarios, sesiones_usuario, logs_actividad';
    RAISE NOTICE 'Usuarios de ejemplo insertados: %, %, %', 
        (SELECT COUNT(*) FROM usuarios WHERE nombre_usuario = 'admin'),
        (SELECT COUNT(*) FROM usuarios WHERE nombre_usuario = 'usuario_demo'),
        (SELECT COUNT(*) FROM usuarios WHERE nombre_usuario = 'desarrollador');
END $$;
