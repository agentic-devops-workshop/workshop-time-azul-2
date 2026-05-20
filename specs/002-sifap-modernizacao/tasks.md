# Tasks: Modernização SIFAP — EARS + Source Legacy

**Input**: Design documents from `/specs/002-sifap-modernizacao/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included for business logic services per constitution principle IV (Test-First) and `copilot-instructions.md` mandate.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Web app**: `backend/src/` (Java 21 + Spring Boot 3.3), `frontend/` (Next.js 15 + TypeScript 5)
- **Migrations**: `backend/src/main/resources/db/migration/`
- **Tests**: `backend/src/test/java/gov/sifap/`, `frontend/__tests__/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization — Maven backend + Next.js frontend + Docker

- [ ] T001 Create backend Maven project with Spring Boot 3.3, JPA, Security, Flyway, PostgreSQL, Testcontainers dependencies in backend/pom.xml
- [ ] T002 [P] Create frontend Next.js 15 project with TypeScript 5 strict, Tailwind CSS, shadcn/ui, Zustand, TanStack Query in frontend/package.json and frontend/tsconfig.json
- [ ] T003 [P] Update Docker Compose for local dev with PostgreSQL 16 persistent volume in docker-compose.yml
- [ ] T004 [P] Configure application.yml (datasource, flyway, security, logging) and application-test.yml (Testcontainers) in backend/src/main/resources/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Create Flyway migrations V1__create_beneficiary.sql, V2__create_social_program.sql, V3__create_payment.sql, V4__create_discount.sql, V5__create_audit_trail.sql in backend/src/main/resources/db/migration/
- [ ] T006 Create BaseEntity (id, createdAt, updatedAt) with JPA @MappedSuperclass in backend/src/main/java/gov/sifap/shared/domain/BaseEntity.java
- [ ] T007 Create SocialProgram JPA entity (shared across US2, US7, US10) in backend/src/main/java/gov/sifap/admin/domain/SocialProgram.java
- [ ] T008 [P] Implement SecurityConfig with OAuth2 Resource Server and role-based access (OPERADOR, AUDITOR, ADMINISTRADOR) in backend/src/main/java/gov/sifap/shared/security/SecurityConfig.java
- [ ] T009 [P] Implement CpfMasker Logback PatternLayoutEncoder (FR-015 LGPD masking XXX.XXX.NNN-NN) in backend/src/main/java/gov/sifap/shared/security/CpfMasker.java
- [ ] T010 [P] Implement GlobalExceptionHandler with RFC 7807 ProblemDetail responses in backend/src/main/java/gov/sifap/shared/exception/GlobalExceptionHandler.java
- [ ] T011 Create SifapApplication main class with @SpringBootApplication in backend/src/main/java/gov/sifap/SifapApplication.java
- [ ] T012 [P] Create shared TypeScript types (from contracts/) and typed API client in frontend/lib/types.ts and frontend/lib/api-client.ts
- [ ] T013 Create frontend root layout (with Tailwind + providers) and dashboard page in frontend/app/layout.tsx and frontend/app/page.tsx

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 — Cadastro e Consulta de Beneficiários (Priority: P0) 🎯 MVP

**Goal**: Operators register beneficiaries with CPF Módulo 11 validation and query by CPF/NIS, including dependents and linked program.

**Independent Test**: Create beneficiary with valid CPF → attempt duplicate → query by CPF/NIS → verify dependents appear. All acceptance scenarios pass.

**Source Legacy**: `CADBENEF.NSN#L225-L260`, `CONSBENF.NSN#L65-L79`

### Implementation for User Story 1

- [ ] T014 [P] [US1] Create BeneficiaryStatus enum (A/S/C/D/I) and Kinship enum (FI/CO/IR/OU) in backend/src/main/java/gov/sifap/beneficiary/domain/BeneficiaryStatus.java and backend/src/main/java/gov/sifap/beneficiary/domain/Kinship.java
- [ ] T015 [US1] Create Beneficiary JPA entity (CPF unique, NIS, status state machine, region_code, family_income) in backend/src/main/java/gov/sifap/beneficiary/domain/Beneficiary.java
- [ ] T016 [US1] Create Dependent JPA entity (CPF unique per beneficiary, kinship, @ManyToOne to Beneficiary) in backend/src/main/java/gov/sifap/beneficiary/domain/Dependent.java
- [ ] T017 [US1] Create BeneficiaryRepository (findByCpf, findByNis) in backend/src/main/java/gov/sifap/beneficiary/infrastructure/BeneficiaryRepository.java
- [ ] T018 [P] [US1] Create BeneficiaryDto and DependentDto Java records in backend/src/main/java/gov/sifap/beneficiary/api/BeneficiaryDto.java and backend/src/main/java/gov/sifap/beneficiary/api/DependentDto.java
- [ ] T019 [US1] Implement BeneficiaryService (CPF Módulo 11 validation, CRUD, status state machine A↔S/C/D/I) in backend/src/main/java/gov/sifap/beneficiary/application/BeneficiaryService.java
- [ ] T020 [US1] Write unit tests for BeneficiaryService (CPF valid/invalid, duplicate, status transitions, query) in backend/src/test/java/gov/sifap/beneficiary/BeneficiaryServiceTest.java
- [ ] T021 [US1] Implement BeneficiaryController (POST /api/v1/beneficiaries, GET by id/cpf/nis, PUT, PATCH status) with @Valid + OpenAPI in backend/src/main/java/gov/sifap/beneficiary/api/BeneficiaryController.java
- [ ] T022 [P] [US1] Create CPF client-side validator and beneficiary-form component in frontend/lib/cpf-validator.ts and frontend/components/domain/beneficiary-form.tsx
- [ ] T023 [US1] Create beneficiary pages (list+search, detail with dependents, create form) in frontend/app/(dashboard)/beneficiaries/page.tsx, frontend/app/(dashboard)/beneficiaries/[id]/page.tsx, and frontend/app/(dashboard)/beneficiaries/new/page.tsx

**Checkpoint**: Beneficiary registration and lookup fully functional. US1 independently testable.

---

## Phase 4: User Story 2 — Geração de Ciclo Mensal de Pagamentos (Priority: P0)

**Goal**: Operators initiate monthly payment cycle generating one Payment per active beneficiary with factor calculations (regional × income × family × K).

**Independent Test**: Seed beneficiaries + programs → initiate cycle → verify payment count and gross values match factor formula. Inactive beneficiaries excluded.

**Source Legacy**: `BATCHPGT.NSN#L88-L167`

### Implementation for User Story 2

- [ ] T024 [P] [US2] Create PaymentStatus enum (G/P/C/D/E) and PaymentCycle value object (competence YYYY-MM + status) in backend/src/main/java/gov/sifap/payment/domain/PaymentStatus.java and backend/src/main/java/gov/sifap/payment/domain/PaymentCycle.java
- [ ] T025 [US2] Create Payment JPA entity (competence, gross/discount/net BigDecimal, status, return_code, FK to Beneficiary+SocialProgram) in backend/src/main/java/gov/sifap/payment/domain/Payment.java
- [ ] T026 [US2] Create PaymentRepository (findByCompetence, findByBeneficiaryId) in backend/src/main/java/gov/sifap/payment/infrastructure/PaymentRepository.java
- [ ] T027 [P] [US2] Create PaymentDto and CycleRequestDto Java records in backend/src/main/java/gov/sifap/payment/api/PaymentDto.java and backend/src/main/java/gov/sifap/payment/api/CycleRequestDto.java
- [ ] T028 [US2] Implement PaymentCycleService (batch generation with virtual threads R-001, factor calculation FR-008, initial status 'G' FR-016, duplicate CPF guard) in backend/src/main/java/gov/sifap/payment/application/PaymentCycleService.java
- [ ] T029 [US2] Write unit tests for PaymentCycleService (factor formula, inactive exclusion, duplicate cycle 409, BigDecimal precision R-004) in backend/src/test/java/gov/sifap/payment/PaymentCycleServiceTest.java
- [ ] T030 [US2] Implement PaymentController (POST /api/v1/payments/cycles, GET /api/v1/payments with filters) with OpenAPI in backend/src/main/java/gov/sifap/payment/api/PaymentController.java
- [ ] T031 [US2] Create payment pages (cycle list + initiation) and payment-table component in frontend/app/(dashboard)/payments/page.tsx and frontend/components/domain/payment-table.tsx

**Checkpoint**: Payment cycle generation fully functional. US2 independently testable.

---

## Phase 5: User Story 3 — Cálculo e Aplicação de Descontos (Priority: P0)

**Goal**: System calculates discounts with 30% ceiling for non-judicial, no ceiling for judicial, and social contribution by brackets (≤500=3%, ≤1000=5%, ≤2000=7%, >2000=9%).

**Independent Test**: Apply discounts of varying types/amounts to payments → verify ceiling enforcement and bracket calculation match legacy output for reference dataset.

**Source Legacy**: `CALCDSCT.NSN#L61-L131`

### Implementation for User Story 3

- [ ] T032 [P] [US3] Create DiscountType enum (J/S/T/A/C — judicial, syndicate, tax, alimony, contribution) in backend/src/main/java/gov/sifap/payment/domain/DiscountType.java
- [ ] T033 [US3] Create Discount JPA entity (type, percentage, value BigDecimal, FK to Payment) and DiscountRepository in backend/src/main/java/gov/sifap/payment/domain/Discount.java and backend/src/main/java/gov/sifap/payment/infrastructure/DiscountRepository.java
- [ ] T034 [US3] Implement DiscountService (FR-006 non-judicial 30% ceiling, FR-007 judicial full bypass, FR-009 social contribution brackets, BigDecimal R-004) in backend/src/main/java/gov/sifap/payment/application/DiscountService.java
- [ ] T035 [US3] Write unit tests for DiscountService (all 4 brackets, ceiling truncation, judicial bypass, multiple discounts, net=0 edge case) in backend/src/test/java/gov/sifap/payment/DiscountServiceTest.java

**Checkpoint**: Discount calculation matches legacy behavior (SC-007). US3 independently testable.

---

## Phase 6: User Story 4 — Conciliação Bancária CNAB 240 (Priority: P0)

**Goal**: Operator imports CNAB 240 bank return file; system updates payment statuses ('00'→P, '01'→D, '02'→E) and detects value divergences.

**Independent Test**: Import sample CNAB file with mixed return codes → verify status transitions and divergence alerts.

**Source Legacy**: `BATCHCON.NSN#L76-L141`

### Implementation for User Story 4

- [ ] T036 [US4] Implement CnabFileParser (CNAB 240 Banco do Brasil fixed-width format, record type detection, field extraction, R-002) in backend/src/main/java/gov/sifap/payment/infrastructure/CnabFileParser.java
- [ ] T037 [US4] Write unit tests for CnabFileParser (valid file, corrupt file, unknown return codes) in backend/src/test/java/gov/sifap/payment/CnabFileParserTest.java
- [ ] T038 [US4] Implement ReconciliationService (FR-010 status updates, divergence > R$0.01 detection, unknown code handling) in backend/src/main/java/gov/sifap/payment/application/ReconciliationService.java
- [ ] T039 [US4] Implement ReconciliationController (POST /api/v1/payments/reconciliation multipart file upload) with OpenAPI in backend/src/main/java/gov/sifap/payment/api/ReconciliationController.java
- [ ] T040 [US4] Create reconciliation page and cnab-upload component (drag-drop, progress, result summary) in frontend/app/(dashboard)/payments/reconciliation/page.tsx and frontend/components/domain/cnab-upload.tsx

**Checkpoint**: CNAB reconciliation processes 10K records in <2min (SC-003). US4 independently testable.

---

## Phase 7: User Story 5 — Trilha de Auditoria Imutável (Priority: P0)

**Goal**: All domain operations (INSERT/UPDATE/DELETE) produce immutable audit records with before/after state. Auditors query by date range with pagination. DELETE/PUT/POST on audit records return 405.

**Independent Test**: Perform CRUD on beneficiaries/payments → verify audit records created with correct before/after JSON. Attempt DELETE on audit → get 405.

**Source Legacy**: `RELAUDIT.NSN#L45-L82`

### Implementation for User Story 5

- [ ] T041 [P] [US5] Create AuditAction enum (INSERT/UPDATE/DELETE) in backend/src/main/java/gov/sifap/audit/domain/AuditAction.java
- [ ] T042 [US5] Create AuditTrail JPA entity (entity_type, entity_id, action, user_id, before/after JSON, reason, timestamp UTC) in backend/src/main/java/gov/sifap/audit/domain/AuditTrail.java
- [ ] T043 [US5] Create AuditRepository (findByTimestampBetween with Pageable) in backend/src/main/java/gov/sifap/audit/infrastructure/AuditRepository.java
- [ ] T044 [US5] Implement AuditListener (JPA EntityListener, captures before/after state as JSON, R-003) in backend/src/main/java/gov/sifap/audit/infrastructure/AuditListener.java
- [ ] T045 [US5] Implement AuditService (FR-011 immutable recording, FR-012 paginated query default 20/page, FR-013 payment status change tracking) in backend/src/main/java/gov/sifap/audit/application/AuditService.java
- [ ] T046 [US5] Implement AuditController (GET /api/v1/audit with date/entity/action filters + pagination, 405 for POST/PUT/DELETE) with AuditQueryDto record in backend/src/main/java/gov/sifap/audit/api/AuditController.java and backend/src/main/java/gov/sifap/audit/api/AuditQueryDto.java
- [ ] T047 [US5] Create audit page and audit-log-viewer component (date range picker, entity/action filters, paginated table) in frontend/app/(dashboard)/audit/page.tsx and frontend/components/domain/audit-log-viewer.tsx

**Checkpoint**: 100% domain operations produce audit records (SC-004). Audit query <2s (SC-005). US5 independently testable.

---

## Phase 8: User Story 6 — Gestão de Dependentes (Priority: P1)

**Goal**: Operators manage dependents per beneficiary: max 5, validated kinship (FI/CO/IR/OU), unique CPF per beneficiary.

**Independent Test**: Add 5 dependents → try 6th (422) → duplicate CPF (409) → invalid kinship (422).

**Source Legacy**: `CADDEPEND.NSN#L58-L60`

### Implementation for User Story 6

- [ ] T048 [US6] Enhance BeneficiaryService with dependent CRUD (FR-003 max 5 limit, kinship enum validation, CPF uniqueness per beneficiary) in backend/src/main/java/gov/sifap/beneficiary/application/BeneficiaryService.java
- [ ] T049 [US6] Add dependent endpoints (POST/PUT/DELETE /api/v1/beneficiaries/{id}/dependents) to BeneficiaryController in backend/src/main/java/gov/sifap/beneficiary/api/BeneficiaryController.java

**Checkpoint**: Dependent CRUD with all constraints enforced. US6 independently testable.

---

## Phase 9: User Story 7 — Validação de Elegibilidade por Programa (Priority: P1)

**Goal**: Operators query whether a beneficiary is eligible for a social program based on age range, status, region, and program parameters. Region 99 (diplomatic) always eligible.

**Independent Test**: Check eligibility for beneficiaries with varying ages/regions/statuses against program with defined age range.

**Source Legacy**: `VALELEG.NSN#L71-L108`

### Implementation for User Story 7

- [ ] T050 [US7] Implement EligibilityService (FR-005 age range check, status filter, region validation, region 99 bypass, IDADE-MAX=0 no upper limit) in backend/src/main/java/gov/sifap/beneficiary/application/EligibilityService.java
- [ ] T051 [US7] Write unit tests for EligibilityService (all scenarios: in-range, out-of-range, region 99, inactive status, no age limit) in backend/src/test/java/gov/sifap/beneficiary/EligibilityServiceTest.java
- [ ] T052 [US7] Add eligibility check endpoint (GET /api/v1/programs/{code}/eligibility?beneficiaryId=) to ProgramController in backend/src/main/java/gov/sifap/admin/api/ProgramController.java

**Checkpoint**: Eligibility validation covers all legacy rules. US7 independently testable.

---

## Phase 10: User Story 8 — Promoção Automática a Status Sênior (Priority: P1)

**Goal**: System automatically promotes beneficiary status to 'S' (Sênior) when age exceeds 75 years. Audit event generated with reason 'AUTO_SENIOR'.

**Independent Test**: Create beneficiaries at boundary ages (74y364d, 75y) → run promotion job → verify only ≥75 transitions with audit trail.

**Source Legacy**: `CADBENEF.NSN#L135-L137`

### Implementation for User Story 8

- [ ] T053 [US8] Implement senior auto-promotion @Scheduled daily job (FR-002, query beneficiaries with status 'A' and age ≥ 75, transition to 'S', emit audit event AUTO_SENIOR) in backend/src/main/java/gov/sifap/beneficiary/application/BeneficiaryService.java
- [ ] T054 [US8] Write unit tests for senior promotion (boundary 74y364d vs 75y0d, already 'S' skip, audit event generation) in backend/src/test/java/gov/sifap/beneficiary/SeniorPromotionTest.java

**Checkpoint**: Auto-promotion executes daily with correct age boundary. US8 independently testable.

---

## Phase 11: User Story 9 — Cancelamento Manual e Exportação de Relatórios (Priority: P1)

**Goal**: Operators cancel payments in status 'G' with mandatory reason. Export payment reports as CSV (UTF-8 BOM) with subtotals by social program.

**Independent Test**: Cancel 'G' payment (success) → cancel 'P' payment (422) → cancel without reason (422) → export CSV and validate format/subtotals.

**Source Legacy**: `BATCHPGT.NSN#L160-L167`, `RELPGT.NSN#L71-L85`

### Implementation for User Story 9

- [ ] T055 [US9] Implement payment cancellation logic (FR-017, only status 'G', mandatory reason, transition G→C, audit trail) in backend/src/main/java/gov/sifap/payment/application/PaymentCycleService.java
- [ ] T056 [US9] Implement PaymentExportService (FR-018, CSV UTF-8 with BOM, columns per contract, group by program with subtotals) in backend/src/main/java/gov/sifap/payment/application/PaymentExportService.java
- [ ] T057 [US9] Add cancellation endpoint (PATCH /api/v1/payments/{id}/cancel) and export endpoint (GET /api/v1/payments/export?format=csv) to PaymentController in backend/src/main/java/gov/sifap/payment/api/PaymentController.java

**Checkpoint**: Cancellation + CSV export match legacy behavior. US9 independently testable.

---

## Phase 12: User Story 10 — Cadastro de Programas Sociais (Priority: P1)

**Goal**: Administrators register and maintain social programs with code (immutable), base value, K adjustment factor, age range, eligibility code, and validity period.

**Independent Test**: Create program → verify adjustment formula VLR-CALC = VLR-BASE × (1.00 + K × 0.347215) → attempt code change (422) → set open-ended validity (DT-FIM=null).

**Source Legacy**: `CADPROG.NSN#L60-L82`

### Implementation for User Story 10

- [ ] T058 [US10] Create ProgramRepository (findByCode) and ProgramDto Java record in backend/src/main/java/gov/sifap/admin/infrastructure/ProgramRepository.java and backend/src/main/java/gov/sifap/admin/api/ProgramDto.java
- [ ] T059 [US10] Implement ProgramService (CRUD, immutable code validation, adjustment formula, validity period handling) in backend/src/main/java/gov/sifap/admin/application/ProgramService.java
- [ ] T060 [US10] Implement ProgramController (POST /api/v1/programs, GET list+detail, PUT update) with OpenAPI in backend/src/main/java/gov/sifap/admin/api/ProgramController.java
- [ ] T061 [US10] Create program pages (list, create form with factor preview) in frontend/app/(dashboard)/programs/page.tsx and frontend/app/(dashboard)/programs/new/page.tsx

**Checkpoint**: Program CRUD with immutable code and adjustment formula. US10 independently testable.

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T062 [P] Add OpenAPI/Swagger annotations across all remaining controllers and generate API documentation
- [ ] T063 [P] Configure Vitest + Testing Library and write frontend component tests in frontend/vitest.config.ts
- [ ] T064 [P] Create Dockerfiles for backend (multi-stage Java 21) and frontend (Node 20 Alpine) in backend/Dockerfile and frontend/Dockerfile
- [ ] T065 Security hardening: review CORS configuration, validate all @Valid annotations, verify CPF masking in all log paths
- [ ] T066 Run quickstart.md validation end-to-end (Docker Compose up, migrations, create beneficiary, run cycle, reconcile, query audit)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3–12)**: All depend on Foundational phase completion
  - P0 stories (US1–US5) should be prioritized
  - P1 stories (US6–US10) can proceed after P0 or in parallel if staffed
- **Polish (Phase 13)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (P0)**: Can start after Phase 2 — No dependencies on other stories ← **MVP**
- **US2 (P0)**: Can start after Phase 2 — Uses SocialProgram entity (created in Phase 2)
- **US3 (P0)**: Depends on US2 (needs Payment entity) — but can start models in parallel
- **US4 (P0)**: Depends on US2 (needs Payment entity for status updates)
- **US5 (P0)**: Can start after Phase 2 — Cross-cutting; AuditListener intercepts all entities
- **US6 (P1)**: Depends on US1 (extends Beneficiary with dependent CRUD)
- **US7 (P1)**: Can start after Phase 2 — Uses SocialProgram + Beneficiary
- **US8 (P1)**: Depends on US1 (modifies BeneficiaryService with scheduled job)
- **US9 (P1)**: Depends on US2 (modifies PaymentCycleService + adds export)
- **US10 (P1)**: Can start after Phase 2 — SocialProgram entity already in Phase 2

### Within Each User Story

- Models before services
- Services before controllers
- Tests alongside service implementation (write test → implement → pass)
- Backend before frontend pages (API must exist)
- Core implementation before integration

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Phase 2 completes: US1, US2, US5, US7, US10 can all start in parallel
- US3 and US4 can start in parallel once US2 Payment entity is created (T025)
- US6 and US8 can start once US1 BeneficiaryService exists (T019)
- Within each story: enums [P], DTOs [P], and frontend components [P] can parallelize

---

## Parallel Example: Phase 3 (User Story 1)

```bash
# Launch all parallelizable tasks for US1:
Task T014: "Create BeneficiaryStatus and Kinship enums" [P]
Task T018: "Create BeneficiaryDto and DependentDto records" [P]
Task T022: "Create CPF validator and beneficiary-form component" [P]

# Then sequential chain:
Task T015: "Create Beneficiary JPA entity"
Task T016: "Create Dependent JPA entity"
Task T017: "Create BeneficiaryRepository"
Task T019: "Implement BeneficiaryService"
Task T020: "Write unit tests for BeneficiaryService"
Task T021: "Implement BeneficiaryController"
Task T023: "Create beneficiary pages"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (Beneficiary CRUD)
4. **STOP and VALIDATE**: Test beneficiary registration + lookup independently
5. Deploy/demo if ready — the core entity is operational

### Incremental Delivery (P0 Stories)

1. Complete Setup + Foundational → Foundation ready
2. Add US1 (Beneficiary) → Test independently → **MVP!**
3. Add US2 (Payment Cycle) → Test independently → Core payment flow
4. Add US3 (Discounts) → Test independently → Financial calculations
5. Add US4 (CNAB Reconciliation) → Test independently → Bank integration
6. Add US5 (Audit Trail) → Test independently → Compliance complete
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers after Phase 2:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (Beneficiary) → then US6 (Dependents) → US8 (Senior)
   - Developer B: US2 (Payments) → then US3 (Discounts) → US9 (Cancel/Export)
   - Developer C: US5 (Audit) → then US4 (CNAB) → US7 (Eligibility)
   - Developer D: US10 (Programs) → then frontend polish → Phase 13
3. Stories complete and integrate independently
