# API Contract: Payment Module

**Base Path**: `/api/v1/payments`

## Endpoints

### POST /api/v1/payments/cycles
**Generate monthly payment cycle (FR-008)**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Request Body**: `CreateCycleRequest`
- **Response**: `201 Created` → `CycleResponse`
- **Errors**: `409` (cycle already exists for competence + program)
- **Audit**: INSERT on payment (bulk)
- **Notes**: Generates one payment per active beneficiary in the program. Calculates gross value, applies discounts, computes net value.

```json
// Request
{
  "competence": "2026-01",
  "programId": 1
}

// Response 201
{
  "competence": "2026-01",
  "programId": 1,
  "totalPayments": 8500,
  "totalGrossValue": 12750000.00,
  "totalDiscounts": 382500.00,
  "totalNetValue": 12367500.00,
  "status": "GENERATED"
}
```

### GET /api/v1/payments
**List payments with filters**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Query Params**: `competence`, `programId`, `beneficiaryId`, `status`, `page`, `size`, `sort`
- **Response**: `200 OK` → `Page<PaymentResponse>`

### GET /api/v1/payments/{id}
**Get payment details**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Response**: `200 OK` → `PaymentDetailResponse` (includes discounts list)
- **Errors**: `404`

### PATCH /api/v1/payments/{id}/cancel
**Cancel a generated payment (FR-017)**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Request Body**: `{ "reason": "Beneficiary deceased" }`
- **Response**: `200 OK` → `PaymentResponse`
- **Errors**: `422` (only status 'G' can be cancelled)
- **Audit**: UPDATE on payment

### POST /api/v1/payments/reconciliation
**Import CNAB 240 return file (FR-010)**

- **Auth**: OPERADOR, ADMINISTRADOR
- **Content-Type**: `multipart/form-data` (file upload)
- **Response**: `200 OK` → `ReconciliationResponse`
- **Errors**: `400` (invalid file format)
- **Audit**: UPDATE on payment (bulk)

```json
// Response 200
{
  "fileName": "RET20260115.TXT",
  "totalRecords": 8500,
  "paid": 8200,
  "returned": 250,
  "reversed": 50,
  "unmatched": 0
}
```

### GET /api/v1/payments/export
**Export payments to CSV (FR-018)**

- **Auth**: OPERADOR, AUDITOR, ADMINISTRADOR
- **Query Params**: `competence`, `programId`, `status`
- **Response**: `200 OK`, `Content-Type: text/csv`
- **Headers**: `Content-Disposition: attachment; filename="payments-2026-01.csv"`

## DTOs (Java Records)

```java
public record CreateCycleRequest(
    @NotBlank @Pattern(regexp = "\\d{4}-\\d{2}") String competence,
    @NotNull Long programId
) {}

public record PaymentResponse(
    Long id, Long beneficiaryId, String beneficiaryName,
    String competence, BigDecimal grossValue,
    BigDecimal discountTotal, BigDecimal netValue,
    String status, String returnCode, Instant createdAt
) {}

public record PaymentDetailResponse(
    Long id, Long beneficiaryId, String beneficiaryName, String beneficiaryCpf,
    String competence, BigDecimal grossValue, BigDecimal discountTotal,
    BigDecimal netValue, String status, String returnCode,
    String cancellationReason, List<DiscountResponse> discounts,
    Instant createdAt, Instant updatedAt
) {}

public record DiscountResponse(
    Long id, String type, BigDecimal percentage, BigDecimal value
) {}
```
