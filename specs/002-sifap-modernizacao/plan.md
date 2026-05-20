# Implementation Plan: Modernização SIFAP — EARS + Source Legacy

**Branch**: `spec/002-sifap-modernizacao` | **Date**: 2026-05-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-sifap-modernizacao/spec.md`

## Summary

Modernize the SIFAP (Sistema de Fiscalização e Administração de Pagamentos) legacy system from Natural/Adabas to a Modular Monolith using Java 21 + Spring Boot 3.3 + PostgreSQL 16 (backend) and Next.js 15 + TypeScript 5 (frontend). The system manages social program beneficiaries, monthly payment cycles, discount calculations, CNAB 240 bank reconciliation, and an immutable audit trail for TCU/CGU compliance. 18 functional requirements (all with `source_legacy:` traceability) organized across 4 bounded contexts: `beneficiary`, `payment`, `audit`, `admin`.

## Technical Context

**Language/Version**: Java 21 (backend) / TypeScript 5 strict (frontend)

**Primary Dependencies**: Spring Boot 3.3, Spring Data JPA/Hibernate, Spring Security (OAuth2 Resource Server), Flyway, Next.js 15 (App Router), Tailwind CSS 3.4+, shadcn/ui, Zustand 4+, TanStack Query 5+

**Storage**: PostgreSQL 16 (Docker, persistent volume `pgdata`)

**Testing**: JUnit 5 + Testcontainers (backend); Vitest + Testing Library (frontend)

**Target Platform**: Linux containers (Docker Compose local, Azure target)

**Project Type**: Web application — REST API backend + SPA frontend

**Performance Goals**: 200 concurrent operators, <500ms p95 reads, <5min batch cycle for 10K beneficiaries, <2min CNAB reconciliation for 10K records, <30s beneficiary registration

**Constraints**: Government intranet (GovNet), LGPD compliance (CPF masking), TCU/CGU audit immutability, Gov.br OAuth2/OIDC authentication, single-bank CNAB 240 (Banco do Brasil) in v1

**Scale/Scope**: ~10,000 beneficiaries, 200 concurrent operators, 45 legacy business rules (BR-001 to BR-045), 18 functional requirements, 10 user stories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|-----------|------|--------|
| I. Legacy Traceability | All 18 FRs carry `source_legacy:` → .NSN programs or `[GREENFIELD]` with justification | ✅ PASS |
| II. Modular Monolith | Architecture uses 4 bounded contexts (`beneficiary`, `payment`, `audit`, `admin`) in single Spring Boot deployable. No cross-module infrastructure imports. | ✅ PASS |
| III. EARS Requirements Syntax | All FRs use EARS patterns (Ubiquitous, Event-Driven, State-Driven, Optional, Unwanted, Complex). All have testable acceptance criteria. | ✅ PASS |
| IV. Test-First | Plan mandates test-alongside-implementation. Every REQ-ID maps to `@DisplayName` test method. Coverage target ≥70% for business logic. | ✅ PASS |
| V. Security by Design | OWASP Top 10 compliance. No hardcoded secrets. SQL via JPA/JPQL only. CPF masked in logs (LGPD). OAuth2/JWT auth. Managed Identity for Azure. | ✅ PASS |

**Gate Result**: ALL PASS — proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/002-sifap-modernizacao/
├── spec.md              # Feature specification (created)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output — REST API contracts
│   ├── beneficiary-api.md
│   ├── payment-api.md
│   ├── audit-api.md
│   └── admin-api.md
├── checklists/          # Quality checklists
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
backend/
├── src/main/java/gov/sifap/
│   ├── beneficiary/                # Bounded Context: Beneficiary
│   │   ├── domain/
│   │   │   ├── Beneficiary.java    # JPA entity (FR-001, FR-002, FR-004)
│   │   │   ├── Dependent.java      # JPA entity (FR-003)
│   │   │   ├── BeneficiaryStatus.java  # Enum: A/S/C/D/I
│   │   │   └── Kinship.java        # Enum: FI/CO/IR/OU
│   │   ├── application/
│   │   │   ├── BeneficiaryService.java
│   │   │   └── EligibilityService.java  # FR-005
│   │   ├── infrastructure/
│   │   │   └── BeneficiaryRepository.java
│   │   └── api/
│   │       ├── BeneficiaryController.java
│   │       ├── BeneficiaryDto.java  # Java record
│   │       └── DependentDto.java    # Java record
│   ├── payment/                    # Bounded Context: Payment
│   │   ├── domain/
│   │   │   ├── Payment.java        # JPA entity (FR-008, FR-016, FR-017)
│   │   │   ├── Discount.java       # JPA entity (FR-006, FR-007, FR-009)
│   │   │   ├── PaymentStatus.java  # Enum: G/P/C/D/E
│   │   │   ├── DiscountType.java   # Enum: J/S/T/A/C
│   │   │   └── PaymentCycle.java   # Value object (competence + status)
│   │   ├── application/
│   │   │   ├── PaymentCycleService.java   # FR-008, batch generation
│   │   │   ├── DiscountService.java       # FR-006, FR-007, FR-009
│   │   │   ├── ReconciliationService.java # FR-010, CNAB 240
│   │   │   └── PaymentExportService.java  # FR-018, CSV export
│   │   ├── infrastructure/
│   │   │   ├── PaymentRepository.java
│   │   │   ├── DiscountRepository.java
│   │   │   └── CnabFileParser.java  # CNAB 240 parser
│   │   └── api/
│   │       ├── PaymentController.java
│   │       ├── ReconciliationController.java
│   │       ├── PaymentDto.java
│   │       └── CycleRequestDto.java
│   ├── audit/                      # Bounded Context: Audit
│   │   ├── domain/
│   │   │   ├── AuditTrail.java     # JPA entity (FR-011, FR-013)
│   │   │   └── AuditAction.java    # Enum: INSERT/UPDATE/DELETE
│   │   ├── application/
│   │   │   └── AuditService.java    # FR-011, FR-012
│   │   ├── infrastructure/
│   │   │   ├── AuditRepository.java
│   │   │   └── AuditListener.java   # JPA EntityListener
│   │   └── api/
│   │       ├── AuditController.java  # FR-012
│   │       └── AuditQueryDto.java
│   ├── admin/                      # Bounded Context: Admin
│   │   ├── domain/
│   │   │   └── SocialProgram.java   # JPA entity (FR-014)
│   │   ├── application/
│   │   │   └── ProgramService.java
│   │   ├── infrastructure/
│   │   │   └── ProgramRepository.java
│   │   └── api/
│   │       ├── ProgramController.java
│   │       └── ProgramDto.java
│   ├── shared/                     # Shared Kernel
│   │   ├── domain/
│   │   │   └── BaseEntity.java      # id, createdAt, updatedAt
│   │   ├── security/
│   │   │   ├── CpfMasker.java       # FR-015, LGPD log masking
│   │   │   └── SecurityConfig.java  # OAuth2 resource server
│   │   └── exception/
│   │       └── GlobalExceptionHandler.java  # RFC 7807 ProblemDetail
│   └── SifapApplication.java
├── src/main/resources/
│   ├── application.yml
│   ├── application-test.yml
│   └── db/migration/
│       ├── V1__create_beneficiary.sql
│       ├── V2__create_social_program.sql
│       ├── V3__create_payment.sql
│       ├── V4__create_discount.sql
│       └── V5__create_audit_trail.sql
├── src/test/java/gov/sifap/
│   ├── beneficiary/
│   ├── payment/
│   ├── audit/
│   └── admin/
├── pom.xml
└── Dockerfile

frontend/
├── app/
│   ├── layout.tsx
│   ├── page.tsx                    # Dashboard
│   ├── (dashboard)/
│   │   ├── beneficiaries/
│   │   │   ├── page.tsx            # List + search
│   │   │   ├── [id]/page.tsx       # Detail view
│   │   │   └── new/page.tsx        # Create form
│   │   ├── payments/
│   │   │   ├── page.tsx            # Payment cycles
│   │   │   └── reconciliation/page.tsx  # CNAB import
│   │   ├── programs/
│   │   │   ├── page.tsx            # List programs
│   │   │   └── new/page.tsx        # Create program
│   │   └── audit/
│   │       └── page.tsx            # Audit trail query
│   └── api/                        # API route handlers (if needed)
├── components/
│   ├── ui/                         # shadcn/ui components
│   └── domain/
│       ├── beneficiary-form.tsx
│       ├── payment-table.tsx
│       ├── cnab-upload.tsx
│       └── audit-log-viewer.tsx
├── lib/
│   ├── api-client.ts               # Typed fetch wrapper
│   ├── types.ts                    # Shared types from API contracts
│   └── cpf-validator.ts            # Client-side CPF validation
├── package.json
├── tsconfig.json                   # strict: true
├── tailwind.config.ts
├── vitest.config.ts
└── Dockerfile
```

**Structure Decision**: Web application (Option 2) — separate `backend/` and `frontend/` directories matching the existing `docker-compose.yml` service definitions. Modular Monolith for backend with package-by-feature (4 bounded contexts). Next.js 15 App Router for frontend with route groups per domain.

## Complexity Tracking

No constitution violations to justify. Architecture uses 4 bounded contexts within a single deployable — consistent with Principle II (Modular Monolith).
