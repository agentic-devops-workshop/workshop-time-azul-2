# Feature Specification: Modernização SIFAP — EARS + Source Legacy

**Feature Branch**: `spec/002-sifap-modernizacao`

**Created**: 2026-05-20

**Status**: Draft

**Input**: User description: "rascunhar escopo da feature com EARS + source_legacy"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cadastro e Consulta de Beneficiários (Priority: P0)

O operador do SIFAP precisa cadastrar novos beneficiários com validação rigorosa de CPF e consultar beneficiários existentes por CPF ou NIS, incluindo dependentes e programa vinculado.

**Why this priority**: Beneficiários são a entidade central do SIFAP. Sem cadastro funcional, nenhum outro módulo opera. Todas as regras de negócio (29 anos de legado) dependem de dados cadastrais íntegros.

**Independent Test**: Pode ser testado criando um beneficiário com CPF válido, tentando duplicar, consultando por CPF/NIS e verificando que dependentes aparecem na resposta.

**Acceptance Scenarios**:

1. **Given** um CPF válido (ex.: 529.982.247-25) e dados completos, **When** o operador submete o cadastro, **Then** o beneficiário é criado com status 'A' e HTTP 201.
2. **Given** um CPF com dígito verificador inválido, **When** o operador submete o cadastro, **Then** o sistema rejeita com HTTP 422 e mensagem de erro clara.
3. **Given** um CPF já cadastrado, **When** o operador tenta criar novo beneficiário, **Then** o sistema rejeita com HTTP 409 Conflict.
4. **Given** um beneficiário existente, **When** o operador consulta por CPF ou NIS, **Then** o sistema retorna dados completos incluindo dependentes e programa vinculado.
5. **Given** um CPF/NIS inexistente, **When** o operador consulta, **Then** o sistema retorna HTTP 404.
6. **Given** um beneficiário cadastrado, **When** qualquer log é gerado, **Then** o CPF aparece mascarado (XXX.XXX.NNN-NN) conforme LGPD.

`source_legacy: CADBENEF.NSN#L225-L260, CONSBENF.NSN#L65-L79`

---

### User Story 2 - Geração de Ciclo Mensal de Pagamentos (Priority: P0)

O operador precisa iniciar o ciclo mensal de pagamento que cria registros para todos os beneficiários ativos, aplicando os fatores regional, renda, familiar e fator K do programa.

**Why this priority**: O ciclo de pagamento é a razão de existência do SIFAP — processar pagamentos de programas sociais. Sem esta funcionalidade, o sistema não cumpre sua missão primária.

**Independent Test**: Pode ser testado com um conjunto de beneficiários ativos em diferentes programas, verificando que cada pagamento é gerado com valor bruto correto e status 'G'.

**Acceptance Scenarios**:

1. **Given** 100 beneficiários ativos em programas vigentes, **When** o ciclo mensal é iniciado, **Then** 100 registros de pagamento são criados com status 'G'.
2. **Given** beneficiários com status 'S', 'C', 'D' ou 'I', **When** o ciclo é processado, **Then** nenhum pagamento é gerado para eles.
3. **Given** um beneficiário ativo em programa com fator K e região específica, **When** o pagamento é gerado, **Then** valor bruto = VLR-BASE × fator_regional × fator_renda × fator_familiar × fator_K.
4. **Given** CPFs duplicados no lote, **When** o ciclo processa, **Then** apenas a primeira ocorrência gera pagamento.

`source_legacy: BATCHPGT.NSN#L88-L167`

---

### User Story 3 - Cálculo e Aplicação de Descontos (Priority: P0)

O sistema precisa calcular descontos sobre pagamentos respeitando regras de teto (30% para não judiciais, sem teto para judiciais) e contribuição social por faixas.

**Why this priority**: Descontos afetam diretamente o valor líquido recebido por beneficiários. Erros de cálculo geram impacto financeiro, auditoria e risco jurídico. Regras de 29 anos de acumulação.

**Independent Test**: Pode ser testado com pagamentos de diferentes valores, aplicando descontos judiciais e não judiciais e verificando teto e faixas de contribuição social.

**Acceptance Scenarios**:

1. **Given** pagamento bruto de R$ 1.000 e desconto não judicial de R$ 400, **When** o desconto é aplicado, **Then** o valor é truncado em R$ 300 (30% do bruto).
2. **Given** desconto judicial de 80% do bruto, **When** aplicado, **Then** o valor integral é descontado (sem teto).
3. **Given** pagamento bruto de R$ 800, **When** a contribuição social é calculada, **Then** alíquota de 5% é aplicada = R$ 40,00.
4. **Given** pagamento bruto de R$ 3.000, **When** a contribuição social é calculada, **Then** alíquota de 9% é aplicada = R$ 270,00.

`source_legacy: CALCDSCT.NSN#L61-L131`

---

### User Story 4 - Conciliação Bancária CNAB 240 (Priority: P0)

Após o banco processar os pagamentos, o operador importa o arquivo de retorno CNAB 240 e o sistema atualiza o status de cada pagamento.

**Why this priority**: A conciliação é o fechamento do ciclo financeiro. Sem ela, não há confirmação de quais pagamentos foram efetivados, gerando inconsistência de dados e risco contábil.

**Independent Test**: Pode ser testado importando um arquivo CNAB 240 com códigos de retorno '00', '01', '02' e verificando que os status dos pagamentos são atualizados corretamente.

**Acceptance Scenarios**:

1. **Given** pagamento com status 'G' e código retorno '00', **When** o arquivo CNAB é importado, **Then** status muda para 'P' (pago).
2. **Given** código retorno '01', **When** importado, **Then** status muda para 'D' (devolvido).
3. **Given** divergência de valor > R$ 0,01 entre pagamento e retorno, **When** processado, **Then** registro de auditoria de divergência é gerado.
4. **Given** código de retorno desconhecido, **When** processado, **Then** status permanece 'G' e alerta é gerado.

`source_legacy: BATCHCON.NSN#L76-L141`

---

### User Story 5 - Trilha de Auditoria Imutável (Priority: P0)

O auditor (TCU/CGU) precisa consultar uma trilha de auditoria imutável de todas as operações no sistema, com filtros por período, entidade e ação.

**Why this priority**: Obrigação legal de rastreabilidade. Sem auditoria, o sistema não atende requisitos de compliance governamental, impedindo operação em produção.

**Independent Test**: Pode ser testado executando operações de INSERT/UPDATE/DELETE em beneficiários e pagamentos e verificando que registros de auditoria completos são gerados e não podem ser removidos.

**Acceptance Scenarios**:

1. **Given** uma operação de INSERT em beneficiário, **When** a operação é concluída, **Then** um registro de auditoria é gravado com before_state=null e after_state preenchido.
2. **Given** uma alteração de status de pagamento G→P, **When** a operação é concluída, **Then** registro de auditoria contém: entidade, ID, ação, usuário, before, after, timestamp UTC.
3. **Given** uma tentativa de DELETE em registro de auditoria, **When** o operador tenta, **Then** o sistema retorna HTTP 405 (Method Not Allowed).
4. **Given** um auditor informando período de datas, **When** consulta é feita, **Then** registros do intervalo são retornados com paginação (20 por página).

`source_legacy: RELAUDIT.NSN#L45-L82`

---

### User Story 6 - Gestão de Dependentes (Priority: P1)

O operador precisa cadastrar dependentes vinculados a beneficiários, com limite de 5 por beneficiário e validação de parentesco.

**Why this priority**: Dependentes influenciam o fator familiar no cálculo de pagamentos (BR-027). Sem eles o cálculo fica incompleto, mas o fluxo principal de pagamento ainda funciona.

**Independent Test**: Pode ser testado adicionando dependentes a um beneficiário, testando limite de 5 e validação de parentesco e CPF.

**Acceptance Scenarios**:

1. **Given** beneficiário com 4 dependentes, **When** operador adiciona o 5º, **Then** adição é aceita.
2. **Given** beneficiário com 5 dependentes, **When** operador tenta adicionar 6º, **Then** HTTP 422.
3. **Given** parentesco inválido (não FI/CO/IR/OU), **When** operador submete, **Then** HTTP 422.
4. **Given** CPF duplicado entre dependentes do mesmo beneficiário, **When** submetido, **Then** HTTP 409.

`source_legacy: CADDEPEND.NSN#L58-L60`

---

### User Story 7 - Validação de Elegibilidade por Programa (Priority: P1)

O operador precisa consultar se um beneficiário é elegível para um programa social, considerando idade, status, região e parâmetros do programa.

**Why this priority**: Elegibilidade é pré-requisito para incluir beneficiários em ciclos de pagamento, mas a geração do ciclo já faz validação implícita.

**Independent Test**: Pode ser testado consultando elegibilidade de beneficiários com diferentes idades, regiões e status.

**Acceptance Scenarios**:

1. **Given** beneficiário ativo com idade dentro da faixa do programa, **When** elegibilidade consultada, **Then** retorna elegível.
2. **Given** beneficiário ativo com idade fora da faixa, **When** consultada, **Then** retorna não elegível.
3. **Given** beneficiário com região 99 (diplomático), **When** consultada, **Then** sempre elegível (bypass).
4. **Given** beneficiário com status 'C' ou 'D', **When** consultada, **Then** não elegível.
5. **Given** programa com IDADE-MAX=0, **When** consultada, **Then** sem limite superior de idade.

`source_legacy: VALELEG.NSN#L71-L108`

---

### User Story 8 - Promoção Automática a Status Sênior (Priority: P1)

O sistema deve alterar automaticamente o status de beneficiários para 'S' (Sênior) quando ultrapassam 75 anos de idade.

**Why this priority**: Regra de negócio consolidada com 29 anos de uso, mas executa apenas durante processamentos periódicos.

**Independent Test**: Pode ser testado com beneficiários em idades limítrofes (74 anos e 364 dias vs 75 anos) e verificando a transição de status.

**Acceptance Scenarios**:

1. **Given** beneficiário com 74 anos e 364 dias, **When** processamento diário executa, **Then** status permanece 'A'.
2. **Given** beneficiário completando 75 anos hoje, **When** processamento executa, **Then** status muda para 'S'.
3. **Given** transição A→S, **When** ocorre, **Then** evento de auditoria gerado com motivo 'AUTO_SENIOR'.

`source_legacy: CADBENEF.NSN#L135-L137`

---

### User Story 9 - Cancelamento Manual e Exportação de Relatórios (Priority: P1)

O operador precisa cancelar pagamentos ainda em status 'G' e exportar relatórios de pagamento em CSV.

**Why this priority**: Cancelamento evita pagamentos indevidos; exportação CSV suporta prestação de contas. Ambos são operacionais mas não bloqueiam o fluxo principal.

**Independent Test**: Pode ser testado cancelando pagamentos em status 'G' e tentando cancelar em outros status; exportando CSV e validando formato.

**Acceptance Scenarios**:

1. **Given** pagamento com status 'G', **When** operador cancela informando motivo, **Then** status muda para 'C' e auditoria registrada.
2. **Given** pagamento com status 'P', **When** operador tenta cancelar, **Then** HTTP 422.
3. **Given** cancelamento sem motivo, **When** submetido, **Then** HTTP 422.
4. **Given** operador solicita exportação, **When** relatório gerado, **Then** CSV UTF-8 com BOM, colunas da tela, quebra por programa e subtotais.

`source_legacy: BATCHPGT.NSN#L160-L167, RELPGT.NSN#L71-L85`

---

### User Story 10 - Cadastro de Programas Sociais (Priority: P1)

O administrador precisa cadastrar e manter programas sociais com parâmetros de valor, faixas etárias, fator de reajuste e vigência.

**Why this priority**: Programas são pré-requisito para pagamentos, mas uma vez cadastrados, são relativamente estáticos.

**Independent Test**: Pode ser testado criando programas com diferentes parâmetros e verificando fórmula de reajuste.

**Acceptance Scenarios**:

1. **Given** dados válidos de programa, **When** administrador submete cadastro, **Then** programa criado com HTTP 201.
2. **Given** programa com DT-FIM=null, **When** criado, **Then** vigência indefinida.
3. **Given** fator de reajuste 1.5, **When** cálculo aplicado, **Then** VLR-CALC = VLR-BASE × (1.00 + 1.5 × 0.347215).
4. **Given** programa já cadastrado, **When** operador tenta alterar código, **Then** HTTP 422 (código imutável).

`source_legacy: CADPROG.NSN#L60-L82`

---

### Edge Cases

- What happens when a beneficiary reaches exactly 75 years on a non-business day? The next processing run handles the transition.
- How does the system handle CNAB 240 file corruption? File parsing fails gracefully; no status updates are applied and error is logged.
- What happens when payment cycle is initiated twice for the same competence month? HTTP 409 — cycle already exists for that competence.
- How does the system handle a beneficiary with region_code 99 AND age outside program range? Region 99 overrides age validation (always eligible).
- What if all 5 discounts on a payment are judicial? All are applied without ceiling; net value can reach zero or negative (held for manual review).
- What happens when a beneficiary with status 'S' (Sênior) has a payment in status 'G'? Sênior does not generate new payments, but existing 'G' payments can still be cancelled or processed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST validate beneficiary CPF using Módulo 11 algorithm before allowing registration. `source_legacy: CADBENEF.NSN#L225-L260`
- **FR-002**: System MUST automatically change beneficiary status to 'S' (Sênior) when age exceeds 75 years. `source_legacy: CADBENEF.NSN#L135-L137`
- **FR-003**: System MUST NOT allow more than 5 dependents per beneficiary. `source_legacy: CADDEPEND.NSN#L58-L60`
- **FR-004**: System MUST return beneficiary data (including dependents and linked program) when queried by CPF or NIS. `source_legacy: CONSBENF.NSN#L65-L79`
- **FR-005**: System MUST validate beneficiary eligibility based on age range, status, and region against program parameters. `source_legacy: VALELEG.NSN#L71-L108`
- **FR-006**: System MUST NOT allow non-judicial discount totals to exceed 30% of gross payment value. `source_legacy: CALCDSCT.NSN#L101-L103`
- **FR-007**: System MUST apply judicial discounts ('J') at full value without the 30% ceiling. `source_legacy: CALCDSCT.NSN#L125-L131`
- **FR-008**: System MUST generate one Payment record per active beneficiary when monthly cycle is initiated, applying regional, income, family, and program K factors. `source_legacy: BATCHPGT.NSN#L88-L167`
- **FR-009**: System MUST calculate social contribution using brackets: ≤R$500=3%, ≤R$1000=5%, ≤R$2000=7%, >R$2000=9%. `source_legacy: CALCDSCT.NSN#L61-L68`
- **FR-010**: System MUST update payment status based on CNAB 240 return codes: '00'→P, '01'→D, '02'→E. `source_legacy: BATCHCON.NSN#L76-L141`
- **FR-011**: System MUST record an immutable audit trail for every INSERT, UPDATE, or DELETE on any domain entity. `source_legacy: RELAUDIT.NSN#L45-L65`
- **FR-012**: System MUST allow audit query by date range with pagination (default 20 records/page). `source_legacy: RELAUDIT.NSN#L77-L82`
- **FR-013**: System MUST record audit entry with before/after state whenever a Payment status changes. `source_legacy: RELAUDIT.NSN#L45-L72`
- **FR-014**: System MUST allow registration of social programs with code, name, base value, adjustment factor, age range, eligibility code, and validity period. `source_legacy: CADPROG.NSN#L60-L82`
- **FR-015**: System MUST mask CPF in all logs using format XXX.XXX.NNN-NN (LGPD). `source_legacy: [GREENFIELD] LGPD Art. 6º`
- **FR-016**: System MUST create every new Payment with status 'G' (generated). `source_legacy: BATCHPGT.NSN#L156`
- **FR-017**: System MUST allow manual cancellation of Payment in status 'G' with mandatory reason. `source_legacy: BATCHPGT.NSN#L160-L167`
- **FR-018**: System MUST export payment reports as CSV (UTF-8 with BOM) with subtotals by social program. `source_legacy: RELPGT.NSN#L71-L85`

### Key Entities

- **Beneficiary**: A person receiving social program benefits. Key attributes: CPF (unique, immutable), NIS (alternative lookup), status (A/S/C/D/I), region_code, family_income, num_dependents (max 5).
- **Dependent**: A family member linked to a beneficiary. Key attributes: CPF (unique per beneficiary), kinship (FI/CO/IR/OU). Max 5 per beneficiary.
- **Social Program**: A government social aid program. Key attributes: code (unique, immutable), base value, adjustment factor (K), age range (min/max), eligibility code, validity period.
- **Payment**: A monthly payment record for a beneficiary under a program. Key attributes: competence (YYYY-MM), gross/discount/net values, status (G/P/C/D/E), return_code.
- **Discount**: A deduction applied to a payment. Key attributes: type (J/S/T/A/C), percentage, value. Non-judicial types capped at 30% of gross.
- **Audit Trail**: An immutable record of every domain operation. Key attributes: entity_type, entity_id, action, user_id, before/after state (JSON), reason, timestamp (UTC).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operators can register a new beneficiary (with CPF validation) in under 30 seconds.
- **SC-002**: Monthly payment cycle for 10,000 active beneficiaries completes in under 5 minutes.
- **SC-003**: CNAB 240 reconciliation file with 10,000 records is processed in under 2 minutes with zero data loss.
- **SC-004**: 100% of domain operations (INSERT/UPDATE/DELETE) produce a corresponding immutable audit record.
- **SC-005**: Auditors can query audit trail by date range and receive paginated results in under 2 seconds.
- **SC-006**: Zero CPF values appear unmasked in any system log (LGPD compliance).
- **SC-007**: Discount calculations match legacy SIFAP output for 100% of a reference dataset of 500 payment scenarios.
- **SC-008**: 95% of operators complete the beneficiary lookup flow (CPF/NIS → full profile) in under 10 seconds.
- **SC-009**: All 18 EARS requirements trace back to legacy source code (.NSN programs) or have documented GREENFIELD justification.
- **SC-010**: System supports 200 concurrent operators without response degradation beyond 500ms for read operations.

## Assumptions

- Operators have stable intranet connectivity within government network (GovNet).
- Authentication will be handled by Gov.br OAuth2/OIDC — the SIFAP system does not manage user credentials directly.
- Mobile support is out of scope for v1 — operators use desktop browsers.
- CNAB 240 files follow Banco do Brasil standard format — no multi-bank support in v1.
- Legacy SIFAP data will be migrated via a separate ETL process not covered by this spec.
- The existing business rules catalog (BR-001 to BR-045) is the authoritative source of legacy behavior, validated by the archaeology stage.
- Monetary correction rules (BR-028, BR-029) and advanced syndicate discount (BR-032) are deferred to v2.
- Social program parameters (base value, K factor, age ranges) are relatively static — bulk import is not required in v1.
