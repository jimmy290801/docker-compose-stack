# 🚀 Docker Compose Stack

Stack de desarrollo profesional con Docker Compose que incluye aplicación web Python, base de datos PostgreSQL, caché Redis y proxy Nginx.

## 📋 Servicios Incluidos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **Aplicación Web** | 8000 | API REST con FastAPI |
| **PostgreSQL** | 5432 | Base de datos principal |
| **Redis** | 6379 | Sistema de caché |
| **Nginx** | 80, 443 | Proxy reverso y balanceador |

## 🏗️ Arquitectura

```
Internet
    │
    ▼
┌─────────────┐
│    Nginx    │ (Puerto 80/443)
│ Proxy/Load  │
└─────────────┘
    │
    ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Aplicación  │────│ PostgreSQL  │    │    Redis    │
│    Web      │    │ Base Datos  │    │    Cache    │
│  FastAPI    │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

## 🚀 Inicio Rápido

### Prerrequisitos
- Docker (versión 20.10+)
- Docker Compose (versión 2.0+)

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/docker-compose-stack.git
cd docker-compose-stack
```

### 2. Levantar el stack completo
```bash
# Construir e iniciar todos los servicios
docker-compose up -d --build

# Ver logs de todos los servicios
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f aplicacion_web
```

### 3. Verificar que todo funciona
```bash
# Verificar estado de los servicios
docker-compose ps

# Verificar salud de la aplicación
curl http://localhost/salud

# Acceder a la documentación interactiva
# Ir a: http://localhost/documentacion
```

## 🔧 Configuración

### Variables de Entorno

Las siguientes variables se pueden configurar en el archivo `docker-compose.yml`:

```yaml
# Aplicación
ENTORNO=desarrollo
PUERTO_APLICACION=8000

# Base de Datos
POSTGRES_USER=usuario_db
POSTGRES_PASSWORD=clave_segura
POSTGRES_DB=mi_base_datos

# URLs de conexión
URL_BASE_DATOS=postgresql://usuario_db:clave_segura@base_datos:5432/mi_base_datos
URL_REDIS=redis://cache_redis:6379
```

### Configuración de Producción

Para producción, modifica las siguientes configuraciones:

1. **Cambiar credenciales de base de datos**
2. **Configurar HTTPS en Nginx**
3. **Activar autenticación en Redis**
4. **Configurar variables de entorno seguras**

## 📁 Estructura del Proyecto

```
docker-compose-stack/
├── docker-compose.yml          # Configuración principal de servicios
├── app/                        # Aplicación web Python
│   ├── main.py                 # Código principal FastAPI
│   ├── requirements.txt        # Dependencias Python
│   └── Dockerfile              # Imagen de la aplicación
├── db/                         # Configuración base de datos
│   └── init.sql                # Script de inicialización
├── cache/                      # Configuración Redis
│   └── redis.conf              # Configuración personalizada
├── nginx/                      # Configuración Nginx
│   └── nginx.conf              # Configuración del proxy
└── README.md                   # Documentación del proyecto
```

## 🛠️ Comandos Útiles

### Gestión del Stack
```bash
# Iniciar servicios
docker-compose up -d

# Parar servicios
docker-compose down

# Reiniciar un servicio específico
docker-compose restart aplicacion_web

# Ver logs en tiempo real
docker-compose logs -f aplicacion_web

# Ejecutar comando en contenedor
docker-compose exec aplicacion_web bash
docker-compose exec base_datos psql -U usuario_db -d mi_base_datos
```

### Base de Datos
```bash
# Conectar a PostgreSQL
docker-compose exec base_datos psql -U usuario_db -d mi_base_datos

# Hacer backup de la base de datos
docker-compose exec base_datos pg_dump -U usuario_db mi_base_datos > backup.sql

# Restaurar backup
docker-compose exec -T base_datos psql -U usuario_db -d mi_base_datos < backup.sql

# Ver tablas creadas
docker-compose exec base_datos psql -U usuario_db -d mi_base_datos -c "\dt"
```

### Redis
```bash
# Conectar a Redis CLI
docker-compose exec cache_redis redis-cli

# Monitorear comandos Redis
docker-compose exec cache_redis redis-cli monitor

# Ver información del servidor Redis
docker-compose exec cache_redis redis-cli info
```

## 📊 API Endpoints

La aplicación FastAPI expone los siguientes endpoints:

### Endpoints Principales
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Página de bienvenida |
| GET | `/salud` | Estado de salud del sistema |
| GET | `/documentacion` | Documentación Swagger UI |

### Gestión de Usuarios
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/usuarios` | Crear nuevo usuario |
| GET | `/usuarios` | Listar todos los usuarios |

### Estadísticas
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/estadisticas` | Estadísticas del sistema (con caché) |

### Ejemplos de Uso

```bash
# Crear un usuario
curl -X POST "http://localhost/usuarios" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre_usuario": "juan_perez",
    "correo_electronico": "juan@ejemplo.com",
    "nombre_completo": "Juan Pérez García"
  }'

# Listar usuarios
curl "http://localhost/usuarios"

# Ver estadísticas
curl "http://localhost/estadisticas"

# Verificar salud del sistema
curl "http://localhost/salud"
```

## 🔍 Monitoreo y Logs

### Logs de Aplicación
```bash
# Ver todos los logs
docker-compose logs

# Logs de un servicio específico
docker-compose logs aplicacion_web
docker-compose logs base_datos
docker-compose logs cache_redis
docker-compose logs proxy_nginx

# Seguir logs en tiempo real
docker-compose logs -f --tail=100 aplicacion_web
```

### Métricas de Sistema
```bash
# Uso de recursos
docker stats

# Información de contenedores
docker-compose ps -a

# Información de volúmenes
docker volume ls
```

## 🐛 Solución de Problemas

### Problemas Comunes

**1. Error de conexión a la base de datos**
```bash
# Verificar que PostgreSQL esté ejecutándose
docker-compose ps base_datos

# Ver logs de PostgreSQL
docker-compose logs base_datos

# Reiniciar servicio de base de datos
docker-compose restart base_datos
```

**2. Error de conexión a Redis**
```bash
# Verificar estado de Redis
docker-compose exec cache_redis redis-cli ping

# Ver configuración de Redis
docker-compose exec cache_redis redis-cli config get "*"
```

**3. Aplicación no responde**
```bash
# Verificar logs de la aplicación
docker-compose logs aplicacion_web

# Reiniciar aplicación
docker-compose restart aplicacion_web

# Verificar puertos
netstat -tulpn | grep :8000
```

**4. Nginx no proxy correctamente**
```bash
# Verificar configuración de Nginx
docker-compose exec proxy_nginx nginx -t

# Recargar configuración
docker-compose exec proxy_nginx nginx -s reload
```

### Limpieza del Sistema
```bash
# Limpiar contenedores parados
docker container prune

# Limpiar imágenes no utilizadas
docker image prune

# Limpiar volúmenes no utilizados
docker volume prune

# Limpiar todo el sistema Docker
docker system prune -a --volumes
```

## 🔐 Seguridad

### Recomendaciones para Producción

1. **Cambiar credenciales por defecto**
   - Modificar contraseñas de PostgreSQL
   - Configurar autenticación Redis
   - Usar variables de entorno seguras

2. **Configurar HTTPS**
   - Obtener certificados SSL/TLS
   - Configurar redireccionamiento HTTP → HTTPS
   - Implementar HSTS headers

3. **Configurar firewall**
   - Exponer solo puertos necesarios
   - Usar redes Docker privadas
   - Configurar iptables

4. **Monitoreo y logs**
   - Implementar sistema de logs centralizado
   - Configurar alertas de seguridad
   - Monitorear recursos del sistema

## 🚀 Despliegue en Producción

### Usando Docker Swarm
```bash
# Inicializar swarm
docker swarm init

# Desplegar stack
docker stack deploy -c docker-compose.yml mi-stack

# Ver servicios del stack
docker stack services mi-stack
```

### Usando Kubernetes
```bash
# Convertir docker-compose a Kubernetes
kompose convert

# Aplicar manifiestos
kubectl apply -f .
```

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abrir Pull Request

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 📞 Soporte

Si tienes problemas o preguntas:

1. Revisar la sección de [Solución de Problemas](#-solución-de-problemas)
2. Buscar en los [Issues existentes](https://github.com/tu-usuario/docker-compose-stack/issues)
3. Crear un nuevo [Issue](https://github.com/tu-usuario/docker-compose-stack/issues/new)

## ✨ Características Implementadas

- ✅ API REST con FastAPI y documentación automática
- ✅ Base de datos PostgreSQL con inicialización automática
- ✅ Sistema de caché Redis con configuración optimizada
- ✅ Proxy reverso Nginx con configuración de seguridad
- ✅ Gestión de usuarios con validaciones
- ✅ Sistema de estadísticas con caché inteligente
- ✅ Logs estructurados y monitoreo de salud
- ✅ Configuración para desarrollo y producción
- ✅ Documentación completa y ejemplos de uso

---

**¡Gracias por usar este stack de Docker Compose!** 🎉
