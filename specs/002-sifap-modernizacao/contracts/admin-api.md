# API Contract: Admin Module

**Base Path**: `/api/v1/programs`

## Endpoints

### POST /api/v1/programs
**Create a social program (FR-014)**

- **Auth**: ADMINISTRADOR
- **Request Body**: `CreateProgramRequest`
- **Response**: `201 Created` → `ProgramResponse`
- **Errors**: `400` (validation), `409` (code already exists)
- **Audit**: INSERT on social_program

```json
// Request
{
  "code": "BF001",
  "name": "Bolsa Família",
  "baseValue": 1500.00,
  "factorK": 1.0,
  "ageMin": 0,
  "ageMax": 0,
  "eligibilityCode": "RF3SM",
  "startDate": "2026-01-01",
  "endDate": null
}

// Response 201
{
  "id": 1,
  "code": "BF001",
  "name": "Bolsa Família",
  "baseValue": 1500.00,
  "factorK": 1.0,
  "ageMin": 0,
  "ageMax": 0,
  "eligibilityCode": "RF3SM",
  "startDate": "2026-01-01",
  "endDate": null,
  "createdAt": "2026-01-01T00:00:00Z"
}
```

### GET /api/v1/programs
**List all programs**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Query Params**: `active` (boolean filter — endDate null or > today), `page`, `size`
- **Response**: `200 OK` → `Page<ProgramResponse>`

### GET /api/v1/programs/{id}
**Get program by ID**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Response**: `200 OK` → `ProgramResponse`
- **Errors**: `404`

### PUT /api/v1/programs/{id}
**Update program (code is immutable)**

- **Auth**: ADMINISTRADOR
- **Request Body**: `UpdateProgramRequest` (code field rejected)
- **Response**: `200 OK` → `ProgramResponse`
- **Errors**: `400` (validation), `404`, `422` (attempted code change)
- **Audit**: UPDATE on social_program

### GET /api/v1/programs/{id}/eligibility
**Check eligibility rules for a program (FR-005)**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Query Params**: `age`, `income`, `regionCode`
- **Response**: `200 OK` → `EligibilityCheckResponse`

```json
// Response 200
{
  "programId": 1,
  "programName": "Bolsa Família",
  "eligible": true,
  "reasons": []
}

// Response 200 (not eligible)
{
  "programId": 2,
  "programName": "BPC Idoso",
  "eligible": false,
  "reasons": ["Age 60 below minimum 65", "Income 2500.00 exceeds limit 1412.00"]
}
```

## DTOs (Java Records)

```java
public record CreateProgramRequest(
    @NotBlank @Size(max = 10) String code,
    @NotBlank @Size(max = 100) String name,
    @NotNull @DecimalMin("0.01") BigDecimal baseValue,
    @NotNull BigDecimal factorK,
    @Min(0) int ageMin,
    @Min(0) int ageMax,
    @NotBlank @Size(max = 5) String eligibilityCode,
    @NotNull LocalDate startDate,
    LocalDate endDate
) {}

public record ProgramResponse(
    Long id, String code, String name,
    BigDecimal baseValue, BigDecimal factorK,
    int ageMin, int ageMax, String eligibilityCode,
    LocalDate startDate, LocalDate endDate,
    Instant createdAt
) {}
```
