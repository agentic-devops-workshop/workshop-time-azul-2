<!-- markdownlint-disable MD013 MD025 MD026 MD028 MD029 MD034 MD040 MD051 MD060 -->

# Decisões de Escopo — SIFAP 2.0

![ESTÁGIO 02 Spec](https://img.shields.io/badge/ESTÁGIO-02%20Spec-00A4EF?style=for-the-badge) ![TIPO Worksheet](https://img.shields.io/badge/TIPO-Worksheet-1A1A1A?style=for-the-badge) ![PREENCHA Durante S2](https://img.shields.io/badge/PREENCHA-Durante%20S2-737373?style=for-the-badge)

> 🗺 **Você está aqui:** [Kit PT-BR](../README.md) → [Estágio 2](README.md) → **Scope Decisions**

> **Para quem é isto?** Este é um **artefato preenchido pelo time** durante o Estágio 2 (Spec Moderna).
>
> **O que você terá ao final do estágio:**
>
> 1. Este documento preenchido para sua feature
> 2. Rastreabilidade `source_legacy:` para cada REQ-ID
> 3. Sign-off do Product Owner antes da passagem H2
>
> 📘 **Guia passo a passo:** [`GUIDE.md`](GUIDE.md).


> Para cada funcionalidade encontrada no Estágio 1, decida: **Migrar**, **Descartar** ou **Evoluir**.
>
> - **Migrar**: trazer para o SIFAP 2.0 como está (mesma lógica, nova tecnologia)
> - **Descartar**: não trazer — funcionalidade obsoleta ou desnecessária
> - **Evoluir**: trazer E melhorar (nova UX, novo fluxo, nova capacidade)

**Time**: Time Azul 2
**Data**: 19/05/2026
**Edição**:
**Par 1 (Product Owner) responsável**: [Nome]

## Por que isso importa

O escopo é o que protege o time de chegar às 17h00 com 12 features pela metade. Se o Par 1 não cortar, o Estágio 3 não fecha. **Decisão difícil é tomada aqui, não no Estágio 3.**

## Como decidir

Pergunte de cada funcionalidade:

1. **Afeta o ciclo mensal de pagamento?** Sim → Migrar. Não → considere descartar.
2. **Tem uso documentado nos últimos 12 meses?** Não → descartar.
3. **Faz parte de um relatório regulatório obrigatório (TCU, CGU, BB)?** Sim → Migrar como está.
4. **Tem uma versão moderna mais barata de implementar?** Sim → Evoluir.

---

## Decisões por Funcionalidade

| #   | Funcionalidade            | Decisão    | Justificativa | Regra de Negócio (BR-XXX) | Prioridade |
| --- | ------------------------- | ---------- | ------------- | ------------------------- | ---------- |
| 1   | Cadastro de Beneficiários | Migrar     | Core do sistema — cadastro é pré-requisito de pagamento. Lógica de validação CPF Módulo 11 é crítica e bem documentada no legado. | BR-001, BR-034 | Alta |
| 2   | Consulta de Beneficiários | Evoluir    | Legado usa tela Natural caracter. Evoluir para busca por CPF/NIS com UX moderna (Next.js) e mascaramento LGPD. | BR-042 | Alta |
| 3   | Registro de Pagamentos    | Migrar     | Ciclo mensal de pagamentos é a razão de existir do SIFAP. Manter lógica exata de cálculo (fator K, regional, renda, familiar). | BR-016, BR-021 | Alta |
| 4   | Processamento Batch       | Evoluir    | Legado é batch noturno sequencial. Evoluir para processamento com virtual threads (Java 21) e progresso observável em tempo real. | BR-016, BR-017, BR-018 | Alta |
| 5   | Cálculo de Benefícios     | Migrar     | Fórmula de cálculo com fator K e reajuste é regra regulatória. Migrar exatamente: VLR-CALC = VLR-BASE × (1.00 + FATOR × 0.347215). | BR-012, BR-027 | Alta |
| 6   | Validação de CPF          | Migrar     | Algoritmo Módulo 11 é padrão nacional. Migrar sem alteração. | BR-034 | Média |
| 7   | Relatórios                | Evoluir    | Legado gera relatórios em texto fixo (132 colunas). Evoluir para CSV/PDF exportável com filtros por programa social. | BR-043 | Média |
| 8   | Auditoria                 | Evoluir    | Legado tem trilha básica append-only. Evoluir para auditoria completa com before/after state (JSONB), filtros por período e export. | BR-044 | Alta |
| 9   | Gestão de Usuários        | Evoluir    | Legado não tem autenticação real. Evoluir para OAuth2/OIDC com 3 roles (OPERATOR, ADMIN, AUDITOR) e integração Gov.br. | — | Alta |
| 10  | Conciliação Bancária      | Migrar     | Processamento de retorno CNAB 240 do BB é obrigatório. Manter mapeamento de códigos de retorno e detecção de divergências. | BR-024, BR-025 | Alta |
| 11  | Descontos                 | Migrar     | Regras de desconto (teto 30% não-judicial, judicial sem teto, contribuição social por faixa) são regulatórias. Migrar exatamente. | BR-030, BR-031 | Alta |
| 12  | Correção Monetária        | Descartar  | Índice de correção monetária (IGPM/IPCA) não é mais usado desde 2018. O sistema legado ainda calcula mas o resultado é ignorado. | BR-028, BR-029 | Baixa |

> Adicione linhas para cada funcionalidade identificada no `discovery-report.md` do Estágio 1.

---

## Funcionalidades Novas (não existem no legado)

> Liste funcionalidades que o SIFAP 2.0 deveria ter e que não existem no sistema legado. Cada uma vira REQ-ID com `source_legacy: [GREENFIELD] <justificativa>`.

| #   | Funcionalidade Nova | Justificativa | Prioridade | Complexidade |
| --- | ------------------- | ------------- | ---------- | ------------ |
| N1  | Mascaramento CPF/LGPD | Lei 13.709/2018 (LGPD) Art. 6º — dados pessoais não podem ser expostos em logs, relatórios ou telas sem necessidade. Não existe no legado. | Alta | Média |
| N2  | Dashboard analítico | Visão consolidada de pagamentos por programa, região e período. Legado não tem visualização — só relatórios textuais. | Média | Alta |
| N3  | API de integração REST | Exposição de endpoints REST/JSON para integração com outros sistemas do governo. Legado opera isolado via arquivos batch. | Alta | Média |

---

## Resumo de Escopo

| Decisão   | Quantidade | Percentual |
| --------- | ---------- | ---------- |
| Migrar    | 5          | 42%        |
| Descartar | 1          | 8%         |
| Evoluir   | 6          | 50%        |
| **Total** | **12**     | 100%       |

## Riscos de Escopo

> Liste os riscos das decisões tomadas:

| Risco | Probabilidade | Impacto | Mitigação |
| ----- | ------------- | ------- | --------- |
| Fórmula de cálculo de benefício tem caso de borda não documentado (fator K × 0.347215 — constante mágica sem explicação no legado) | Média | Alto | Testes de equivalência com dados reais do BATCHPGT.NSN; validar 100 casos antes do deploy |
| Conciliação CNAB 240 pode ter códigos de retorno novos não mapeados no legado | Baixa | Médio | Tratar código desconhecido como "pendente" + alerta; mapear novos códigos sob demanda |
| Mascaramento LGPD pode impactar debugging em produção (CPF mascarado dificulta investigação) | Alta | Médio | Permitir acesso a CPF completo apenas via role ADMIN + log de auditoria do próprio acesso |

## Aprovação

- [ ] Par 1 (Product Owner) aprovou as decisões de escopo
- [ ] Par 2 (Enterprise Architect) validou a viabilidade técnica
- [ ] Par 3 (Technical Lead) confirmou que cabe nas 3 horas do Estágio 3
- [ ] Time concordou com as prioridades

> **Aprovação obrigatória na Passagem #2** (~16:00). Sem ela, o Estágio 3 não começa.

— Paula


---

### Continuar a leitura

<table width="100%">
<tr>
<td width="50%" valign="top" align="left">
<sub><strong>← ANTERIOR</strong></sub><br/>
<a href="GUIDE.md"><strong>GUIDE do Estágio 2</strong></a><br/>
<sub>Passo a passo do estágio.</sub>
</td>
<td width="50%" valign="top" align="right">
<sub><strong>PRÓXIMO →</strong></sub><br/>
<a href="ADR-TEMPLATE.md"><strong>ADR-TEMPLATE</strong></a><br/>
<sub>Template de ADR.</sub>
</td>
</tr>
</table>

<sub>↑ <a href="../README.md">Voltar ao Kit PT-BR</a></sub>

