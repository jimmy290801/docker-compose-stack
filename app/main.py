#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Aplicación Web Principal - Stack Docker Compose
Autor: Germán
Descripción: API REST con FastAPI, PostgreSQL y Redis
"""

import os
import json
import logging
from datetime import datetime
from typing import Optional, List

import redis
import psycopg2
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Variables de configuración
PUERTO_APLICACION = int(os.getenv('PUERTO_APLICACION', 8000))
URL_BASE_DATOS = os.getenv('URL_BASE_DATOS', 'postgresql://usuario_db:clave_segura@localhost:5432/mi_base_datos')
URL_REDIS = os.getenv('URL_REDIS', 'redis://localhost:6379')
ENTORNO = os.getenv('ENTORNO', 'desarrollo')

# Inicializar FastAPI
aplicacion = FastAPI(
    title="Mi Stack Docker Compose",
    description="API REST con PostgreSQL y Redis",
    version="1.0.0",
    docs_url="/documentacion" if ENTORNO == 'desarrollo' else None,
    redoc_url="/redoc" if ENTORNO == 'desarrollo' else None
)

# Configurar CORS
aplicacion.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if ENTORNO == 'desarrollo' else ["https://dominio.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelos Pydantic
class Usuario(BaseModel):
    nombre_usuario: str
    correo_electronico: str
    nombre_completo: Optional[str] = None

class UsuarioRespuesta(BaseModel):
    id_usuario: int
    nombre_usuario: str
    correo_electronico: str
    nombre_completo: Optional[str]
    fecha_creacion: datetime

class EstadisticasSistema(BaseModel):
    total_usuarios: int
    estado_cache: str
    estado_base_datos: str
    timestamp: datetime

# Conexiones a servicios
def obtener_conexion_redis():
    """Obtiene conexión a Redis"""
    try:
        cliente_redis = redis.from_url(URL_REDIS, decode_responses=True)
        cliente_redis.ping()
        return cliente_redis
    except Exception as error:
        logger.error(f"Error conectando a Redis: {error}")
        return None

def obtener_conexion_postgres():
    """Obtiene conexión a PostgreSQL"""
    try:
        conexion = psycopg2.connect(URL_BASE_DATOS)
        return conexion
    except Exception as error:
        logger.error(f"Error conectando a PostgreSQL: {error}")
        return None

# Dependencias
async def obtener_cliente_redis():
    cliente = obtener_conexion_redis()
    if not cliente:
        raise HTTPException(status_code=503, detail="Servicio de caché no disponible")
    return cliente

# Endpoints de la API
@aplicacion.get("/")
async def ruta_principal():
    """Endpoint principal de bienvenida"""
    return {
        "mensaje": "¡Bienvenido al Stack Docker Compose!",
        "version": "1.0.0",
        "entorno": ENTORNO,
        "timestamp": datetime.now().isoformat()
    }

@aplicacion.get("/salud")
async def verificar_salud():
    """Endpoint de verificación de salud del sistema"""
    estado_redis = "activo"
    estado_postgres = "activo"
    
    # Verificar Redis
    try:
        cliente_redis = obtener_conexion_redis()
        if cliente_redis:
            cliente_redis.ping()
        else:
            estado_redis = "inactivo"
    except Exception:
        estado_redis = "error"
    
    # Verificar PostgreSQL
    try:
        conexion_pg = obtener_conexion_postgres()
        if conexion_pg:
            cursor = conexion_pg.cursor()
            cursor.execute("SELECT 1")
            conexion_pg.close()
        else:
            estado_postgres = "inactivo"
    except Exception:
        estado_postgres = "error"
    
    return {
        "estado": "saludable" if estado_redis == "activo" and estado_postgres == "activo" else "degradado",
        "servicios": {
            "redis": estado_redis,
            "postgresql": estado_postgres
        },
        "timestamp": datetime.now().isoformat()
    }

@aplicacion.post("/usuarios", response_model=UsuarioRespuesta)
async def crear_usuario(datos_usuario: Usuario):
    """Crear un nuevo usuario"""
    try:
        conexion = obtener_conexion_postgres()
        if not conexion:
            raise HTTPException(status_code=503, detail="Base de datos no disponible")
        
        cursor = conexion.cursor()
        query_insertar = """
            INSERT INTO usuarios (nombre_usuario, correo_electronico, nombre_completo, fecha_creacion)
            VALUES (%s, %s, %s, %s)
            RETURNING id_usuario, fecha_creacion
        """
        fecha_actual = datetime.now()
        
        cursor.execute(query_insertar, (
            datos_usuario.nombre_usuario,
            datos_usuario.correo_electronico,
            datos_usuario.nombre_completo,
            fecha_actual
        ))
        
        resultado = cursor.fetchone()
        conexion.commit()
        
        # Invalidar caché
        try:
            cliente_redis = obtener_conexion_redis()
            if cliente_redis:
                cliente_redis.delete("estadisticas_sistema")
        except Exception as error:
            logger.warning(f"No se pudo invalidar caché: {error}")
        
        conexion.close()
        
        return UsuarioRespuesta(
            id_usuario=resultado[0],
            nombre_usuario=datos_usuario.nombre_usuario,
            correo_electronico=datos_usuario.correo_electronico,
            nombre_completo=datos_usuario.nombre_completo,
            fecha_creacion=resultado[1]
        )
        
    except psycopg2.IntegrityError:
        raise HTTPException(status_code=400, detail="El usuario ya existe")
    except Exception as error:
        logger.error(f"Error creando usuario: {error}")
        raise HTTPException(status_code=500, detail="Error interno del servidor")

@aplicacion.get("/usuarios", response_model=List[UsuarioRespuesta])
async def listar_usuarios():
    """Obtener lista de todos los usuarios"""
    try:
        conexion = obtener_conexion_postgres()
        if not conexion:
            raise HTTPException(status_code=503, detail="Base de datos no disponible")
        
        cursor = conexion.cursor()
        cursor.execute("""
            SELECT id_usuario, nombre_usuario, correo_electronico, 
                   nombre_completo, fecha_creacion 
            FROM usuarios 
            ORDER BY fecha_creacion DESC
        """)
        
        usuarios = []
        for fila in cursor.fetchall():
            usuarios.append(UsuarioRespuesta(
                id_usuario=fila[0],
                nombre_usuario=fila[1],
                correo_electronico=fila[2],
                nombre_completo=fila[3],
                fecha_creacion=fila[4]
            ))
        
        conexion.close()
        return usuarios
        
    except Exception as error:
        logger.error(f"Error obteniendo usuarios: {error}")
        raise HTTPException(status_code=500, detail="Error interno del servidor")

@aplicacion.get("/estadisticas", response_model=EstadisticasSistema)
async def obtener_estadisticas(cliente_redis=Depends(obtener_cliente_redis)):
    """Obtener estadísticas del sistema con caché"""
    clave_cache = "estadisticas_sistema"
    
    # Intentar obtener del caché
    try:
        datos_cache = cliente_redis.get(clave_cache)
        if datos_cache:
            estadisticas_cache = json.loads(datos_cache)
            return EstadisticasSistema(**estadisticas_cache)
    except Exception as error:
        logger.warning(f"Error leyendo caché: {error}")
    
    # Si no está en caché, calcular estadísticas
    try:
        conexion = obtener_conexion_postgres()
        if not conexion:
            raise HTTPException(status_code=503, detail="Base de datos no disponible")
        
        cursor = conexion.cursor()
        cursor.execute("SELECT COUNT(*) FROM usuarios")
        total_usuarios = cursor.fetchone()[0]
        conexion.close()
        
        estadisticas = EstadisticasSistema(
            total_usuarios=total_usuarios,
            estado_cache="activo",
            estado_base_datos="activo",
            timestamp=datetime.now()
        )
        
        # Guardar en caché por 5 minutos
        try:
            cliente_redis.setex(
                clave_cache, 
                300, 
                json.dumps(estadisticas.dict(), default=str)
            )
        except Exception as error:
            logger.warning(f"Error guardando en caché: {error}")
        
        return estadisticas
        
    except Exception as error:
        logger.error(f"Error obteniendo estadísticas: {error}")
        raise HTTPException(status_code=500, detail="Error interno del servidor")

if __name__ == "__main__":
    logger.info(f"Iniciando aplicación en puerto {PUERTO_APLICACION}")
    uvicorn.run(
        "main:aplicacion",
        host="0.0.0.0",
        port=PUERTO_APLICACION,
        reload=ENTORNO == 'desarrollo'
    )
