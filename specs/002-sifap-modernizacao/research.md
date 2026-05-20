# Research: Modernização SIFAP

**Feature**: 002-sifap-modernizacao | **Date**: 2026-05-20

## R-001: Batch Processing Strategy for Payment Cycle (FR-008)

**Context**: The monthly payment cycle generates one Payment record per active beneficiary (up to 10K). Legacy `BATCHPGT.NSN` processes sequentially via FIND/READ loops on Adabas.

**Decision**: Use Spring `@Async` with virtual threads (Java 21 `--enable-preview` not needed — GA in 21) for parallel payment generation within a single `@Transactional` boundary using `saveAll()` batch inserts.

**Rationale**: Virtual threads handle 10K lightweight tasks efficiently without thread pool exhaustion. Spring Boot 3.3 supports `spring.threads.virtual.enabled=true`. Batch inserts via `spring.jpa.properties.hibernate.jdbc.batch_size=50` reduce round-trips.

**Alternatives Considered**:
- Spring Batch: Too heavyweight for a single-step ETL. Payment cycle is not a multi-step pipeline.
- `@Scheduled` + JDBC Template: Loses JPA benefits (audit listener, entity lifecycle). Rejected.
- Reactive (WebFlux): Constitution mandates Spring MVC (Servlet stack). Rejected.

## R-002: CNAB 240 File Parsing (FR-010)

**Context**: Banco do Brasil CNAB 240 return files use fixed-position records (240 chars/line). Legacy `BATCHCON.NSN` parses positionally.

**Decision**: Implement a custom `CnabFileParser` using positional substring extraction. No external library needed — the format is well-documented and fixed.

**Rationale**: CNAB 240 BB layout has 5 record types: Header (0), Header Lote (1), Detail (3), Trailer Lote (5), Trailer (9). Only Detail records (type 3, segment T+U) carry return codes. Custom parser keeps the dependency footprint minimal and matches the legacy positional parsing approach.

**Alternatives Considered**:
- `jrimum-texgit`: Unmaintained since 2018. Rejected.
- `cnab240-java`: Low adoption, no Spring Boot integration. Rejected.
- Apache Camel + FlatPack: Overkill for single-format parsing. Rejected.

## R-003: Audit Trail Implementation (FR-011, FR-013)

**Context**: Every domain operation must produce an immutable audit record with before/after state, user, timestamp. Legacy `RELAUDIT.NSN` writes audit records to an Adabas file.

**Decision**: Use JPA `@EntityListener` on domain entities. The listener captures `@PrePersist`, `@PreUpdate`, `@PreRemove` events, serializes before/after state to JSON using Jackson, and inserts into `audit_trail` table. The `audit_trail` table has no UPDATE/DELETE grants at the database level.

**Rationale**: JPA EntityListeners are transparent to business code — no service-layer coupling. JSON snapshots preserve full state history. Database-level immutability (revoke UPDATE/DELETE on audit table) provides defense-in-depth beyond application logic.

**Alternatives Considered**:
- Hibernate Envers: Auto-generates revision tables but harder to query via custom filters (date range, entity, action). Rejected for query flexibility.
- Spring AOP: Cross-cutting but less precise entity state capture. Rejected.
- Event Sourcing: Paradigm shift too large for workshop scope. Rejected.

## R-004: Financial Calculation Precision (FR-006, FR-007, FR-009)

**Context**: Discount calculations, social contribution brackets, and payment values require exact decimal arithmetic. Legacy Natural uses packed decimal (P format).

**Decision**: Use `BigDecimal` throughout for all monetary values. `RoundingMode.HALF_EVEN` (banker's rounding) for intermediate calculations. Store as `NUMERIC(15,2)` in PostgreSQL. Never use `double` or `float` for money.

**Rationale**: `BigDecimal` with explicit scale matches packed decimal precision from Adabas. Banker's rounding minimizes cumulative bias. The 30% discount cap (FR-006) requires precise comparison: `discountTotal.compareTo(grossValue.multiply(new BigDecimal("0.30"))) > 0`.

**Alternatives Considered**:
- `long` (cents): Loses sub-cent precision during percentage calculations. Rejected.
- JSR 354 (JavaMoney): Additional dependency with no clear benefit over `BigDecimal` for this use case. Rejected.

## R-005: CPF Masking Strategy (FR-015, LGPD)

**Context**: CPF must never appear unmasked in any log output. Legacy system had no masking requirement.

**Decision**: Implement a `CpfMasker` utility in `shared/security/` that replaces CPF patterns with `XXX.XXX.NNN-NN` format (showing only last 5 digits). Register a custom Logback `PatternLayout` converter that applies masking to all log output automatically.

**Rationale**: Logback converter intercepts all log messages at the framework level — no risk of developer forgetting to mask. The `CpfMasker` is also available as a utility for explicit use in DTOs and exports.

**Alternatives Considered**:
- Manual masking per log statement: Error-prone, developers will forget. Rejected.
- Log sanitization post-processing: Data already in log files before masking. Rejected.

## R-006: Authentication & Authorization (Constitution V)

**Context**: Gov.br OAuth2/OIDC provides authentication. SIFAP needs role-based authorization for 3 roles: OPERADOR, AUDITOR, ADMINISTRADOR.

**Decision**: Spring Security OAuth2 Resource Server validates JWT tokens from Gov.br. Roles are extracted from JWT claims and mapped to Spring authorities. Method-level `@PreAuthorize` annotations enforce access control per endpoint.

**Rationale**: OAuth2 Resource Server is the standard Spring Security approach for API-only backends. JWT claim extraction avoids a separate user database for roles. Method-level security is auditable and testable.

**Authorization Matrix**:

| Endpoint Group | OPERADOR | AUDITOR | ADMINISTRADOR |
|---------------|----------|---------|---------------|
| Beneficiary CRUD | ✅ Read/Write | ✅ Read | ✅ Read/Write |
| Payment Cycles | ✅ Initiate/Cancel | ✅ Read | ✅ Full |
| Reconciliation | ✅ Import | ✅ Read | ✅ Full |
| Audit Trail | ❌ | ✅ Read | ✅ Read |
| Programs CRUD | ❌ | ❌ | ✅ Full |
| CSV Export | ✅ Export | ✅ Export | ✅ Export |

## R-007: Beneficiary Status State Machine

**Context**: Beneficiary has 5 statuses (A/S/C/D/I) but valid transitions aren't documented in spec.

**Decision**: Directed acyclic transitions with one reactivation path:
- `A → S` (auto-senior at 75 years, FR-002)
- `A → C` (manual cancellation)
- `A → I` (temporary inactivation)
- `S → C` (cancel a senior)
- `S → I` (inactivate a senior)
- `I → A` (reactivation — only valid reverse transition)

**Rationale**: Government systems need error correction capability (wrongful cancellation → inactivation → reactivation). `D` (Desligado) is a terminal legacy status preserved for data migration but not reachable via the new system. Cancelled (`C`) and Desligado (`D`) are terminal — no transitions out.

## R-008: Database Migration Strategy

**Context**: PostgreSQL 16 target. Need schema versioning for CI/CD.

**Decision**: Flyway for migration management. One migration per entity/table. Naming: `V{N}__{description}.sql`. Migrations are idempotent and forward-only. No rollback migrations in v1 — fixes go forward as new migrations.

**Rationale**: Flyway is the Spring Boot standard, integrates via `spring-boot-starter-flyway`. Sequential versioning matches the bounded context creation order. Testcontainers applies migrations automatically in tests.
