# Makefile para Docker Compose Stack
.PHONY: help build up down restart logs shell db-shell redis-shell clean

# Variables
COMPOSE_FILE=docker-compose.yml
SERVICES=aplicacion_web base_datos cache_redis proxy_nginx

# Ayuda por defecto
help: ## Mostrar ayuda
	@echo "Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Comandos principales
build: ## Construir todas las imágenes
	docker-compose -f $(COMPOSE_FILE) build

up: ## Levantar todos los servicios
	docker-compose -f $(COMPOSE_FILE) up -d

down: ## Parar y eliminar todos los servicios
	docker-compose -f $(COMPOSE_FILE) down

restart: ## Reiniciar todos los servicios
	docker-compose -f $(COMPOSE_FILE) restart

# Logs y monitoreo
logs: ## Ver logs de todos los servicios
	docker-compose -f $(COMPOSE_FILE) logs -f

logs-app: ## Ver logs de la aplicación
	docker-compose -f $(COMPOSE_FILE) logs -f aplicacion_web

logs-db: ## Ver logs de la base de datos
	docker-compose -f $(COMPOSE_FILE) logs -f base_datos

status: ## Ver estado de los servicios
	docker-compose -f $(COMPOSE_FILE) ps

# Shells interactivos
shell: ## Acceder al shell de la aplicación
	docker-compose -f $(COMPOSE_FILE) exec aplicacion_web bash

db-shell: ## Acceder al shell de PostgreSQL
	docker-compose -f $(COMPOSE_FILE) exec base_datos psql -U usuario_db -d mi_base_datos

redis-shell: ## Acceder al shell de Redis
	docker-compose -f $(COMPOSE_FILE) exec cache_redis redis-cli

# Base de datos
db-backup: ## Hacer backup de la base de datos
	docker-compose -f $(COMPOSE_FILE) exec base_datos pg_dump -U usuario_db mi_base_datos > backup_$(shell date +%Y%m%d_%H%M%S).sql

# Desarrollo
dev: ## Levantar en modo desarrollo con logs
	docker-compose -f $(COMPOSE_FILE) up --build

# Limpieza
clean: ## Limpiar contenedores, imágenes y volúmenes no utilizados
	docker-compose -f $(COMPOSE_FILE) down -v
	docker system prune -f

clean-all: ## Limpiar todo (¡CUIDADO! Elimina volúmenes)
	docker-compose -f $(COMPOSE_FILE) down -v --rmi all
	docker system prune -af --volumes

# Testing
test: ## Ejecutar tests de la aplicación
	docker-compose -f $(COMPOSE_FILE) exec aplicacion_web python -m pytest

health: ## Verificar salud de los servicios
	@echo "Verificando salud de los servicios..."
	@curl -f http://localhost:8080/salud || echo "❌ Aplicación no responde"
	@docker-compose -f $(COMPOSE_FILE) exec base_datos pg_isready -U usuario_db || echo "❌ PostgreSQL no disponible"
	@docker-compose -f $(COMPOSE_FILE) exec cache_redis redis-cli ping || echo "❌ Redis no disponible"
