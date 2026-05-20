# Quickstart: Modernização SIFAP

**Feature**: 002-sifap-modernizacao

## Prerequisites

| Tool | Version | Check Command |
|------|---------|---------------|
| Java | 21+ | `java -version` |
| Maven | 3.9+ | `mvn -version` |
| Node.js | 20+ | `node -v` |
| Docker | 24+ | `docker --version` |
| Docker Compose | v2+ | `docker compose version` |
| Git | 2.30+ | `git --version` |

## Quick Start (Docker Compose)

```bash
# 1. Clone and enter the project
cd workshop-time-azul-2

# 2. Start all services (PostgreSQL + Backend + Frontend)
docker compose up -d

# 3. Verify services are running
docker compose ps

# 4. Access the application
# Frontend: http://localhost:3001
# Backend API: http://localhost:8080/api/v1
# PostgreSQL: localhost:5432 (user: sifap, pass: from .env)
```

## Local Development (Without Docker)

### Backend

```bash
# 1. Start PostgreSQL only
docker compose up -d postgres

# 2. Build and run backend
cd backend
mvn clean install
mvn spring-boot:run -Dspring-boot.run.profiles=local

# Backend runs on http://localhost:8080
# Swagger UI: http://localhost:8080/swagger-ui.html
```

### Frontend

```bash
# 1. Install dependencies
cd frontend
npm install

# 2. Run dev server
npm run dev

# Frontend runs on http://localhost:3000
```

## Running Tests

### Backend Tests

```bash
cd backend

# Unit tests only
mvn test

# Integration tests (requires Docker for Testcontainers)
mvn verify -P integration-test

# All tests with coverage
mvn verify -P coverage
```

### Frontend Tests

```bash
cd frontend

# Unit tests
npm test

# Watch mode
npm run test:watch

# Coverage
npm run test:coverage
```

## Database Migrations

Flyway migrations run automatically on application startup. To run manually:

```bash
cd backend
mvn flyway:migrate -Dflyway.url=jdbc:postgresql://localhost:5432/sifap
```

## Common Operations

### Reset database

```bash
docker compose down -v  # Removes volumes
docker compose up -d    # Fresh start with migrations
```

### View API documentation

Open `http://localhost:8080/swagger-ui.html` after starting the backend.

### Check application health

```bash
curl http://localhost:8080/actuator/health
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_DB` | Database name | `sifap` |
| `POSTGRES_USER` | Database user | `sifap` |
| `POSTGRES_PASSWORD` | Database password | (from .env) |
| `SPRING_PROFILES_ACTIVE` | Active Spring profile | `local` |
| `JWT_ISSUER_URI` | OAuth2 issuer URI | Gov.br endpoint |

## Project Structure

```
backend/
  src/main/java/gov/sifap/
    beneficiary/   # Bounded context: cadastro de beneficiários
    payment/       # Bounded context: ciclos de pagamento
    audit/         # Bounded context: trilha de auditoria
    admin/         # Bounded context: programas sociais
    shared/        # Cross-cutting: security, config, exceptions

frontend/
  app/
    (dashboard)/
      beneficiaries/   # CRUD de beneficiários
      payments/        # Ciclos e reconciliação
      programs/        # Gestão de programas
      audit/           # Consulta de auditoria
```
