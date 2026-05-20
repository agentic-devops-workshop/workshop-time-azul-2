# API Contract: Beneficiary Module

**Base Path**: `/api/v1/beneficiaries`

## Endpoints

### POST /api/v1/beneficiaries
**Create a new beneficiary**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Request Body**: `CreateBeneficiaryRequest`
- **Response**: `201 Created` → `BeneficiaryResponse`
- **Errors**: `400` (invalid CPF, missing fields), `409` (CPF already exists)
- **Audit**: INSERT on beneficiary

```json
// Request
{
  "cpf": "123.456.789-09",
  "nis": "12345678901",
  "fullName": "Maria da Silva",
  "birthDate": "1980-05-15",
  "programId": 1,
  "regionCode": 53,
  "familyIncome": 1200.00
}

// Response 201
{
  "id": 1,
  "cpf": "123.456.789-09",
  "nis": "12345678901",
  "fullName": "Maria da Silva",
  "birthDate": "1980-05-15",
  "status": "A",
  "programName": "Bolsa Família",
  "regionCode": 53,
  "familyIncome": 1200.00,
  "createdAt": "2026-01-15T10:30:00Z"
}
```

### GET /api/v1/beneficiaries
**List beneficiaries with filters**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Query Params**: `status`, `programId`, `regionCode`, `page`, `size`, `sort`
- **Response**: `200 OK` → `Page<BeneficiaryResponse>`

### GET /api/v1/beneficiaries/{id}
**Get beneficiary by ID**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Response**: `200 OK` → `BeneficiaryResponse`
- **Errors**: `404` (not found)

### GET /api/v1/beneficiaries/cpf/{cpf}
**Find beneficiary by CPF**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Response**: `200 OK` → `BeneficiaryResponse`
- **Errors**: `404` (not found)

### PUT /api/v1/beneficiaries/{id}
**Update beneficiary**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Request Body**: `UpdateBeneficiaryRequest` (CPF is immutable — not accepted)
- **Response**: `200 OK` → `BeneficiaryResponse`
- **Errors**: `400` (validation), `404` (not found), `422` (invalid status transition)
- **Audit**: UPDATE on beneficiary

### PATCH /api/v1/beneficiaries/{id}/status
**Change beneficiary status**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Request Body**: `{ "status": "C", "reason": "..." }`
- **Response**: `200 OK` → `BeneficiaryResponse`
- **Errors**: `422` (invalid transition per R-007)
- **Audit**: UPDATE on beneficiary

### GET /api/v1/beneficiaries/{id}/eligibility
**Check program eligibility for a beneficiary (FR-005)**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Response**: `200 OK` → `EligibilityResponse`
- **Logic**: Validates age range, income, region against program rules

---

### POST /api/v1/beneficiaries/{beneficiaryId}/dependents
**Add a dependent to a beneficiary**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Request Body**: `CreateDependentRequest`
- **Response**: `201 Created` → `DependentResponse`
- **Errors**: `400` (validation), `409` (CPF duplicate within beneficiary), `422` (max 5 exceeded, FR-003)
- **Audit**: INSERT on dependent

```json
// Request
{
  "cpf": "987.654.321-00",
  "fullName": "João da Silva",
  "kinship": "FI",
  "birthDate": "2010-03-20"
}
```

### GET /api/v1/beneficiaries/{beneficiaryId}/dependents
**List dependents of a beneficiary**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Response**: `200 OK` → `List<DependentResponse>`

### DELETE /api/v1/beneficiaries/{beneficiaryId}/dependents/{id}
**Remove a dependent**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Response**: `204 No Content`
- **Errors**: `404` (not found)
- **Audit**: DELETE on dependent

## DTOs (Java Records)

```java
public record CreateBeneficiaryRequest(
    @NotBlank @CPF String cpf,
    @Size(max = 11) String nis,
    @NotBlank @Size(max = 120) String fullName,
    @NotNull @Past LocalDate birthDate,
    @NotNull Long programId,
    @NotNull @Min(1) @Max(99) Integer regionCode,
    @NotNull @DecimalMin("0.00") BigDecimal familyIncome
) {}

public record BeneficiaryResponse(
    Long id, String cpf, String nis, String fullName,
    LocalDate birthDate, String status, String programName,
    Integer regionCode, BigDecimal familyIncome,
    Instant createdAt
) {}
```
