# SIFAP 2.0 Constitution

## Core Principles

### I. Legacy Traceability (NON-NEGOTIABLE)
Every requirement (REQ-ID) must include a `source_legacy:` line pointing to a `.NSN` program or `.ddm` file in `01-arqueologia/legado-sifap/`, or be explicitly marked `[GREENFIELD]` with a one-line justification. CI rejects PRs that violate this rule.

### II. Modular Monolith
The target architecture is a single deployable unit (Java 21 + Spring Boot 3.3) with clear internal module boundaries: `beneficiary`, `payment`, `audit`, `admin`. No module imports `infrastructure` classes from another module. Communication cross-module via domain interfaces or domain events only.

### III. EARS Requirements Syntax
All functional requirements use one of the 6 EARS patterns: Ubiquitous, Event-Driven, State-Driven, Optional, Unwanted Behavior, Complex. Every requirement must have testable acceptance criteria.

### IV. Test-First
Tests are written alongside implementation, not after. Every REQ-ID maps to at least one test method annotated with the REQ-ID in `@DisplayName`. Coverage target: >= 70% for business logic modules.

### V. Security by Design
OWASP Top 10 compliance. No hardcoded secrets. SQL only via JPA/JPQL. CPF masked in logs (LGPD). OAuth2/JWT for authentication. Managed Identity for Azure service-to-service.

## Technology Stack

- **Backend:** Java 21 + Spring Boot 3.3 + JPA/Hibernate + PostgreSQL 16
- **Frontend:** Next.js 15 (App Router) + TypeScript 5 (strict) + Tailwind CSS + shadcn/ui
- **Containers:** Docker + Docker Compose
- **IaC:** Terraform (Azure provider ~> 3.x)
- **CI/CD:** GitHub Actions
- **Testing:** JUnit 5 + Testcontainers (backend); Vitest + Testing Library (frontend)

## Development Workflow

1. Every feature starts with a spec (`/speckit.specify`) before any code.
2. Ambiguities resolved via `/speckit.clarify` before planning.
3. Plan generated via `/speckit.plan` with modules, contracts, data model.
4. Tasks broken down via `/speckit.tasks` — small, testable, traceable.
5. Consistency validated via `/speckit.analyze` before implementation.
6. Branch strategy: `spec/<NNN>-<feature>` → `develop` → `stage` → `main`.

## Governance

This constitution supersedes ad-hoc decisions. Amendments require ADR documentation. All PRs must verify compliance with traceability rules.

**Version**: 1.0.0 | **Ratified**: 2026-05-20 | **Last Amended**: 2026-05-20
