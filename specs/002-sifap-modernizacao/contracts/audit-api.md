# API Contract: Audit Module

**Base Path**: `/api/v1/audit`

## Endpoints

### GET /api/v1/audit
**Query audit trail with filters (FR-012)**

- **Auth**: AUDITOR, ADMINISTRADOR
- **Query Params**: `entityType`, `entityId`, `action`, `userId`, `startDate`, `endDate`, `page`, `size`, `sort`
- **Response**: `200 OK` → `Page<AuditTrailResponse>`
- **Notes**: Default sort by `timestamp DESC`

```json
// Response 200
{
  "content": [
    {
      "id": 42,
      "entityType": "beneficiary",
      "entityId": 1,
      "action": "UPDATE",
      "userId": "gov.br:12345678900",
      "beforeState": { "status": "A", "fullName": "Maria Silva" },
      "afterState": { "status": "C", "fullName": "Maria Silva" },
      "reason": "Beneficiary requested cancellation",
      "timestamp": "2026-01-15T14:30:00Z"
    }
  ],
  "totalElements": 150,
  "totalPages": 15,
  "number": 0,
  "size": 10
}
```

### GET /api/v1/audit/{id}
**Get single audit record**

- **Auth**: AUDITOR, ADMINISTRADOR
- **Response**: `200 OK` → `AuditTrailResponse`
- **Errors**: `404`

### GET /api/v1/audit/export
**Export audit trail to CSV (FR-013)**

- **Auth**: AUDITOR, ADMINISTRADOR
- **Query Params**: `entityType`, `startDate`, `endDate`
- **Response**: `200 OK`, `Content-Type: text/csv`
- **Headers**: `Content-Disposition: attachment; filename="audit-2026-01.csv"`

### Immutability Enforcement

- **POST /api/v1/audit** → `405 Method Not Allowed` (audit records are created internally via JPA EntityListener, never via API)
- **PUT /api/v1/audit/{id}** → `405 Method Not Allowed`
- **PATCH /api/v1/audit/{id}** → `405 Method Not Allowed`
- **DELETE /api/v1/audit/{id}** → `405 Method Not Allowed`

## DTOs (Java Records)

```java
public record AuditTrailResponse(
    Long id, String entityType, Long entityId,
    String action, String userId,
    Map<String, Object> beforeState,
    Map<String, Object> afterState,
    String reason, Instant timestamp
) {}
```
