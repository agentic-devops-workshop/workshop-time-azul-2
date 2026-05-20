# Data Model: Modernização SIFAP

**Feature**: 002-sifap-modernizacao | **Date**: 2026-05-20

## Entity-Relationship Overview

```
┌─────────────────┐       ┌──────────────────┐
│ social_program   │       │  beneficiary      │
│─────────────────│       │──────────────────│
│ PK id            │       │ PK id             │
│ UK code          │◄──┐  │ UK cpf             │
│    name          │   │  │ UK nis             │
│    base_value    │   │  │    full_name       │
│    factor_k      │   │  │    birth_date      │
│    age_min       │   │  │    status (A/S/C/D/I)│
│    age_max       │   │  │ FK program_id      │──┘
│    eligibility   │   │  │    region_code     │
│    start_date    │   │  │    family_income   │
│    end_date      │   │  │    created_at      │
│    created_at    │   │  │    updated_at      │
│    updated_at    │   │  └──────────────────┘
└─────────────────┘   │           │
                       │           │ 1:N (max 5)
                       │           ▼
                       │  ┌──────────────────┐
                       │  │  dependent        │
                       │  │──────────────────│
                       │  │ PK id             │
                       │  │ FK beneficiary_id │
                       │  │    cpf            │
                       │  │    full_name      │
                       │  │    kinship (FI/CO/IR/OU)│
                       │  │    birth_date     │
                       │  │    created_at     │
                       │  └──────────────────┘
                       │
                       │  ┌──────────────────┐
                       ├──│  payment          │
                       │  │──────────────────│
                       │  │ PK id             │
                       │  │ FK beneficiary_id │
                       │  │ FK program_id     │──┘
                       │  │    competence     │ (YYYY-MM)
                       │  │    gross_value    │
                       │  │    discount_total │
                       │  │    net_value      │
                       │  │    status (G/P/C/D/E)│
                       │  │    return_code    │
                       │  │    cancellation_reason│
                       │  │    created_at     │
                       │  │    updated_at     │
                       │  └──────────────────┘
                       │           │
                       │           │ 1:N
                       │           ▼
                       │  ┌──────────────────┐
                       │  │  discount         │
                       │  │──────────────────│
                       │  │ PK id             │
                       │  │ FK payment_id     │
                       │  │    type (J/S/T/A/C)│
                       │  │    percentage     │
                       │  │    value          │
                       │  │    created_at     │
                       │  └──────────────────┘
                       │
                       │  ┌──────────────────┐
                       │  │  audit_trail      │
                       │  │──────────────────│
                       │  │ PK id             │
                       │  │    entity_type    │
                       │  │    entity_id      │
                       │  │    action (INSERT/UPDATE/DELETE)│
                       │  │    user_id        │
                       │  │    before_state   │ (JSONB)
                       │  │    after_state    │ (JSONB)
                       │  │    reason         │
                       │  │    timestamp      │ (UTC)
                       │  └──────────────────┘
```

## Entities

### 1. `beneficiary` (Bounded Context: beneficiary)

**Source**: `CADBENEF.NSN`, `CONSBENF.NSN` | **Adabas FDT**: `BENEFICIARIO.ddm`

| Column | Type | Constraints | Source |
|--------|------|-------------|--------|
| `id` | `BIGSERIAL` | PK | Generated |
| `cpf` | `VARCHAR(14)` | UNIQUE, NOT NULL, immutable | AA (Adabas field) |
| `nis` | `VARCHAR(11)` | UNIQUE | AB |
| `full_name` | `VARCHAR(120)` | NOT NULL | AC |
| `birth_date` | `DATE` | NOT NULL | AD |
| `status` | `VARCHAR(1)` | NOT NULL, CHECK IN ('A','S','C','D','I'), DEFAULT 'A' | AE |
| `program_id` | `BIGINT` | FK → social_program(id), NOT NULL | AF |
| `region_code` | `INTEGER` | NOT NULL, CHECK (1-99) | AG |
| `family_income` | `NUMERIC(15,2)` | NOT NULL, DEFAULT 0 | AH |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Generated |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Generated |

**Validation Rules**:
- CPF validated via Módulo 11 (FR-001)
- Status auto-transitions to 'S' when age > 75 (FR-002)
- Valid state transitions per R-007: A→S, A→C, A→I, S→C, S→I, I→A

**Indexes**:
- `idx_beneficiary_cpf` on `cpf` (unique, primary lookup)
- `idx_beneficiary_nis` on `nis` (unique, alternative lookup)
- `idx_beneficiary_status` on `status` (filter active beneficiaries for payment cycle)
- `idx_beneficiary_program` on `program_id` (FK join optimization)

### 2. `dependent` (Bounded Context: beneficiary)

**Source**: `CADDEPEND.NSN` | **Adabas FDT**: `DEPENDENTE.ddm`

| Column | Type | Constraints | Source |
|--------|------|-------------|--------|
| `id` | `BIGSERIAL` | PK | Generated |
| `beneficiary_id` | `BIGINT` | FK → beneficiary(id), NOT NULL | Parent ref |
| `cpf` | `VARCHAR(14)` | NOT NULL | BA |
| `full_name` | `VARCHAR(120)` | NOT NULL | BB |
| `kinship` | `VARCHAR(2)` | NOT NULL, CHECK IN ('FI','CO','IR','OU') | BC |
| `birth_date` | `DATE` | NOT NULL | BD |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Generated |

**Validation Rules**:
- Max 5 dependents per beneficiary (FR-003) — enforced at application level
- CPF unique within same beneficiary: `UNIQUE(beneficiary_id, cpf)`
- Kinship must be FI (Filho), CO (Cônjuge), IR (Irmão), OU (Outro)

**Indexes**:
- `idx_dependent_beneficiary` on `beneficiary_id`
- `uq_dependent_cpf_beneficiary` UNIQUE on `(beneficiary_id, cpf)`

### 3. `social_program` (Bounded Context: admin)

**Source**: `CADPROG.NSN` | **Adabas FDT**: `PROGRAMA-SOCIAL.ddm`

| Column | Type | Constraints | Source |
|--------|------|-------------|--------|
| `id` | `BIGSERIAL` | PK | Generated |
| `code` | `VARCHAR(10)` | UNIQUE, NOT NULL, immutable | CA |
| `name` | `VARCHAR(100)` | NOT NULL | CB |
| `base_value` | `NUMERIC(15,2)` | NOT NULL | CC |
| `factor_k` | `NUMERIC(10,6)` | NOT NULL, DEFAULT 1.0 | CD |
| `age_min` | `INTEGER` | NOT NULL, DEFAULT 0 | CE |
| `age_max` | `INTEGER` | NOT NULL, DEFAULT 0 (0 = no limit) | CF |
| `eligibility_code` | `VARCHAR(5)` | NOT NULL | CG |
| `start_date` | `DATE` | NOT NULL | CH |
| `end_date` | `DATE` | NULL (null = indefinite) | CI |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Generated |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Generated |

**Validation Rules**:
- Code is immutable after creation (FR-014)
- `age_max = 0` means no upper age limit (FR-005)
- Adjustment formula: `VLR-CALC = base_value × (1.00 + factor_k × 0.347215)` (BR-028)

**Indexes**:
- `idx_program_code` UNIQUE on `code` (primary lookup)

### 4. `payment` (Bounded Context: payment)

**Source**: `BATCHPGT.NSN`, `BATCHCON.NSN` | **Adabas FDT**: `PAGAMENTO.ddm`

| Column | Type | Constraints | Source |
|--------|------|-------------|--------|
| `id` | `BIGSERIAL` | PK | Generated |
| `beneficiary_id` | `BIGINT` | FK → beneficiary(id), NOT NULL | DA |
| `program_id` | `BIGINT` | FK → social_program(id), NOT NULL | DB |
| `competence` | `VARCHAR(7)` | NOT NULL (YYYY-MM format) | DC |
| `gross_value` | `NUMERIC(15,2)` | NOT NULL | DD |
| `discount_total` | `NUMERIC(15,2)` | NOT NULL, DEFAULT 0 | DE |
| `net_value` | `NUMERIC(15,2)` | NOT NULL | DF |
| `status` | `VARCHAR(1)` | NOT NULL, CHECK IN ('G','P','C','D','E'), DEFAULT 'G' | DG |
| `return_code` | `VARCHAR(4)` | NULL | DH |
| `cancellation_reason` | `VARCHAR(500)` | NULL | DI |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Generated |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Generated |

**Validation Rules**:
- Created with status 'G' always (FR-016)
- Cancellation only from 'G' with mandatory reason (FR-017)
- Status transitions via CNAB: G→P ('00'), G→D ('01'), G→E ('02') (FR-010)
- One payment per (beneficiary_id, program_id, competence): `UNIQUE(beneficiary_id, program_id, competence)`

**Status State Machine**:
```
    G (Generated)
    ├── → P (Paid)       via CNAB return '00'
    ├── → D (Devolvido)  via CNAB return '01'
    ├── → E (Estornado)  via CNAB return '02'
    └── → C (Cancelled)  via manual cancellation
```
No transitions out of P, D, E, or C (all terminal).

**Indexes**:
- `idx_payment_beneficiary` on `beneficiary_id`
- `idx_payment_competence` on `competence`
- `idx_payment_status` on `status` (filter 'G' for CNAB reconciliation)
- `uq_payment_cycle` UNIQUE on `(beneficiary_id, program_id, competence)`

### 5. `discount` (Bounded Context: payment)

**Source**: `CALCDSCT.NSN` | **Adabas FDT**: `DESCONTO.ddm`

| Column | Type | Constraints | Source |
|--------|------|-------------|--------|
| `id` | `BIGSERIAL` | PK | Generated |
| `payment_id` | `BIGINT` | FK → payment(id), NOT NULL | EA |
| `type` | `VARCHAR(1)` | NOT NULL, CHECK IN ('J','S','T','A','C') | EB |
| `percentage` | `NUMERIC(5,2)` | NOT NULL | EC |
| `value` | `NUMERIC(15,2)` | NOT NULL | ED |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | Generated |

**Validation Rules**:
- Non-judicial (S/T/A/C) total capped at 30% of payment gross_value (FR-006)
- Judicial (J) applied at full value, no cap (FR-007)
- Social contribution brackets (FR-009): ≤500→3%, ≤1000→5%, ≤2000→7%, >2000→9%

**Indexes**:
- `idx_discount_payment` on `payment_id`

### 6. `audit_trail` (Bounded Context: audit)

**Source**: `RELAUDIT.NSN`

| Column | Type | Constraints | Source |
|--------|------|-------------|--------|
| `id` | `BIGSERIAL` | PK | Generated |
| `entity_type` | `VARCHAR(50)` | NOT NULL | FA |
| `entity_id` | `BIGINT` | NOT NULL | FB |
| `action` | `VARCHAR(10)` | NOT NULL, CHECK IN ('INSERT','UPDATE','DELETE') | FC |
| `user_id` | `VARCHAR(100)` | NOT NULL | FD |
| `before_state` | `JSONB` | NULL (null on INSERT) | FE |
| `after_state` | `JSONB` | NULL (null on DELETE) | FF |
| `reason` | `VARCHAR(500)` | NULL | FG |
| `timestamp` | `TIMESTAMPTZ` | NOT NULL, DEFAULT NOW() | FH |

**Immutability Rules**:
- Table has NO UPDATE or DELETE grants — only INSERT + SELECT (FR-011)
- Application rejects DELETE/UPDATE via HTTP 405 (FR-011, Story 5)

**Indexes**:
- `idx_audit_timestamp` on `timestamp` (date range queries, FR-012)
- `idx_audit_entity` on `(entity_type, entity_id)` (entity-specific queries)
- `idx_audit_action` on `action` (action filter)

## Cross-Module References

| From Module | To Module | Mechanism | Why |
|------------|-----------|-----------|-----|
| `payment` | `beneficiary` | FK `beneficiary_id` | Payment belongs to a beneficiary |
| `payment` | `admin` | FK `program_id` | Payment belongs to a program |
| `beneficiary` | `admin` | FK `program_id` | Beneficiary enrolled in a program |
| `audit` | all | Polymorphic `entity_type` + `entity_id` | Audit tracks all entities |

**Note**: Cross-module FK references are acceptable in a Modular Monolith within a single database. The bounded context boundary is enforced at the **Java package level** (no direct class imports), not at the database level.
