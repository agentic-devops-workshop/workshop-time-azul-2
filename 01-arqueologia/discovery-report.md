<!-- markdownlint-disable MD013 MD025 MD026 MD028 MD029 MD034 MD040 MD051 MD060 -->

# Relatório de Descoberta — Estágio 1: Arqueologia Digital

![ESTÁGIO 01 Arqueologia](https://img.shields.io/badge/ESTÁGIO-01%20Arqueologia-F25022?style=for-the-badge) ![TIPO Worksheet](https://img.shields.io/badge/TIPO-Worksheet-1A1A1A?style=for-the-badge) ![PREENCHA Durante S1](https://img.shields.io/badge/PREENCHA-Durante%20S1-737373?style=for-the-badge)

> 🗺 **Você está aqui:** [Kit PT-BR](../README.md) → [Estágio 1](README.md) → **discovery-report**

> **Para quem é isto?** Este é um **artefato preenchido pelo time** durante o Estágio 1 (Arqueologia).
>
> **O que você terá ao final do estágio:**
>
> 1. Este documento totalmente preenchido com os dados reais do legado SIFAP
> 2. Rastreabilidade para `01-arqueologia/legado-sifap/` (programas `.NSN` e DDMs)
> 3. Base de evidência usada nas EARS do Estágio 2 (`source_legacy:`)
>
> 📘 **Guia passo a passo:** [`GUIDE.md`](GUIDE.md).


> Este documento consolida todas as descobertas do Estágio 1.
> Preencha cada seção com as conclusões do time. **Este é o input principal do Estágio 2** — sem ele, a especificação vira chute.

**Time**: Time Azul 2
**Data**: 19/05/2026
**Edição**: 1.0 (fechamento do Estágio 1)
**Participantes**: Product Owner, Requirements Engineer, Enterprise Architect, Software Architect, Technical Lead, Developer, DBA, QA Engineer, DevOps Engineer, Tech Writer

---

## 1. Sumário Executivo

> Em 3 a 5 frases, resuma o que o time descobriu sobre o SIFAP legado.
> O que é este sistema? Qual sua criticidade? Qual o estado do código?

O SIFAP legado e um sistema Natural/Adabas de alta criticidade para cadastro, elegibilidade, calculo e processamento de pagamentos de programas sociais. A analise encontrou regras de negocio centrais embutidas no codigo, com forte dependencia de constantes hardcoded e duplicacao de logica entre programas. Foram mapeadas 45 regras de negocio com rastreabilidade para os programas .NSN, incluindo regras criticas financeiras, de identidade e de status. O estado do codigo e funcional, porem com alta divida tecnica e risco de regressao em mudancas sem especificacao moderna e testes de regressao orientados por regra.

---

## 2. Visão Geral do Sistema

### 2.1 Propósito do SIFAP

O SIFAP gerencia o ciclo completo de beneficios sociais: cadastro de beneficiarios e dependentes, validacao documental, verificacao de elegibilidade, calculo de valores brutos/liquidos, aplicacao de descontos, processamento batch mensal e conciliacao com retorno bancario CNAB. O sistema tambem gera relatorios operacionais e trilha de auditoria para conformidade.

### 2.2 Arquitetura Legada

A arquitetura legada possui 15 programas Natural e 4 DDMs principais (BENEFICIARIO, PROGRAMA-SOCIAL, PAGAMENTO e AUDITORIA). Nao foram encontradas chamadas CALLNAT entre os 15 programas; todos operam como pontos de entrada independentes, com sub-rotinas internas via PERFORM. Os fluxos principais sao: (1) fluxo online de cadastro/validacao, (2) fluxo de calculo de beneficio e descontos, (3) fluxo batch mensal de geracao e conciliacao de pagamentos, (4) fluxo de relatorios e auditoria.

### 2.3 Usuários e Perfis

Os usuarios principais sao operadores de cadastro, analistas de beneficio, equipe financeira e equipe de auditoria/compliance. Ha perfil operacional online (inclusao, alteracao e consulta), perfil batch (execucao de processamento e conciliacao), perfil de controle (emissao de relatorios) e perfil de auditoria (consulta de trilhas e divergencias).

---

## 3. Principais Descobertas

### 3.1 Regras de Negócio Críticas

> Liste as 5 regras de negócio mais importantes encontradas.

1. CPF do beneficiário é imutável durante alteração cadastral (BR-001).
2. Cálculo do benefício aplica Fator K como ajuste multiplicativo obrigatório (BR-012).
3. Desconto compulsório é limitado a 30% do valor bruto do benefício (BR-030).
4. Desconto judicial é exceção e pode ultrapassar o teto de 30% (BR-031).
5. Validação de CPF com algoritmo Módulo 11 antes de efetivar cadastro/atualização (BR-034).
6. Processamento mensal em BATCHPGT é obrigatório para geração de pagamentos (BR-016).
7. Elegibilidade de pagamento depende do status do beneficiário (status bloqueantes impedem pagamento) (BR-040).
8. Fatores regionais hardcoded alteram diretamente o valor final do benefício (BR-017).

### 3.2 Dependências Complexas

> Quais programas estão mais acoplados? Onde há risco de efeito cascata?

Os maiores pontos de acoplamento estao em BATCHPGT, CALCBENF e CALCDSCT, que concentram regras financeiras e impactam diretamente PAGAMENTO. VALELEG e VALBENEF tambem possuem alto acoplamento funcional por influenciarem elegibilidade e consistencia cadastral antes do calculo. O principal risco de efeito cascata esta na duplicacao de regras entre programas (ex.: validacao CPF e fatores regionais), onde uma mudanca parcial gera comportamento inconsistente entre cadastro, calculo e processamento batch.

### 3.3 Dívida Técnica Identificada

> Que problemas no código legado vão complicar a migração?

- [x] Constantes hardcoded sem origem funcional documentada (ex.: 0.347215 no fator K; fatores regionais; teto de 30%).
- [x] Duplicacao de logica critica em multiplos programas (validacao CPF, fatores regionais, faixas de renda).
- [x] Divergencias de arredondamento/truncamento e regras de excecao sem parametrizacao externa.

### 3.4 Gaps de Documentação

> O que a documentação existente NÃO cobre?

A documentacao existente nao cobre a motivacao de regras historicas, a origem legal de constantes e a justificativa de excecoes operacionais (ex.: regiao 99 e descontos judiciais sem teto). Tambem nao existe dicionario canonico de status e codigos de retorno bancario versionado com impacto de negocio. A governanca de mudancas (quando e por que regras foram alteradas) depende de comentarios locais em codigo, sem trilha funcional consolidada.

---

## 4. Mistérios e Riscos

### 4.1 Mistérios Não Resolvidos

> Resuma os mistérios do arquivo `mysteries-found.md` que permanecem sem explicação.

| ID  | Descrição | Risco para Migração |
| --- | --------- | ------------------- |
| MYS-001 | Constante 0.347215 do Fator K sem referencia normativa/funcional | Alto risco de recalculo incorreto em migracao |
| MYS-002 | Regiao 99 com bypass de elegibilidade sem regra formal publicada | Risco de concessoes indevidas ou bloqueios indevidos |
| MYS-003 | Tabela IPCA congelada (2010-2012) sem estrategia de atualizacao | Risco de correcao monetaria incorreta |
| MYS-004 | Parsing CNAB por posicoes fixas sem validacao robusta de layout | Risco critico de conciliacao falha |
| MYS-005 | Divergencia de arredondamento entre programas (round vs truncate) | Risco de divergencia financeira e auditoria |

### 4.2 Riscos para o Estágio 2

> O que o time de especificação precisa saber antes de começar?

1. Risco de regressao funcional por duplicacao de regras em diferentes programas sem ponto unico de verdade.
2. Risco financeiro por mudanca de calculo/desconto sem preservar excecoes legais e regras de teto.
3. Risco de inconsistencias de dados por ausencia de contrato canonico para status, codigos de retorno e arredondamento.

---

## 5. Recomendações

### 5.1 O que migrar primeiro

> Com base na priorização do Par 1 (Product Owner), quais funcionalidades devem ser migradas primeiro?

| Prioridade | Funcionalidade | Justificativa |
| ---------- | -------------- | ------------- |
| 1          | Nucleo de pagamento mensal (elegibilidade + calculo + processamento batch) | Preserva fluxo fim a fim critico com BR-016, BR-017, BR-012 e BR-040 |
| 2          | Nucleo financeiro de descontos | Mitiga risco legal/financeiro com BR-030 e BR-031 |
| 3          | Nucleo de identidade e validacao cadastral | Garante integridade de entrada com BR-001 e BR-034 |

### 5.2 O que descartar

> Funcionalidades que provavelmente não precisam ser migradas:

- Relatorios com layout legado de impressao (66 linhas/pagina): substituir por camada moderna de reporting sem reproduzir formato historico.
- Heuristicas cosmeticas de apresentacao em terminal 3270: nao agregam regra de negocio e podem ser simplificadas.
- Duplicacoes tecnicas da mesma validacao em programas distintos: descartar reimplementacao repetida e centralizar em servico unico.

### 5.3 O que evoluir

> Funcionalidades que devem ser migradas E melhoradas:

- Validacao de CPF e identidade: migrar e centralizar em componente unico reutilizavel, com testes de regressao por casos limite.
- Calculo de beneficio (Fator K, fatores regionais, faixas de renda): externalizar parametros e versionar politicas por vigencia.
- Descontos e excecoes legais: implementar motor de regras com trilha de decisao auditavel para teto e excecoes judiciais.
- Processamento batch mensal: manter processamento deterministico e idempotente, com checkpoints e reprocessamento seguro.
- Elegibilidade por status: publicar matriz oficial de status e motivos bloqueantes, com mensagens explicitas de rejeicao.
- Conciliacao CNAB: encapsular parser por versao de layout com validacao estrutural e alarmes de incompatibilidade.

---

## 6. Métricas do Estágio

| Métrica                       | Valor        |
| ----------------------------- | ------------ |
| Programas analisados          | 15 / 15      |
| DDMs mapeados                 | 4 / 4        |
| Regras de negócio encontradas | 45           |
| Regras escondidas encontradas | 10 / 10      |
| Easter eggs encontrados       | 0 / 3        |
| Termos no glossário           | 45           |
| Mistérios catalogados         | 10           |
| Tempo total gasto             | 24 horas     |

---

## 7. Notas para o Próximo Estágio

> Deixe aqui mensagens para o time no Estágio 2 (Especificação Moderna):

Para o Estagio 2, usar as 8 regras priorizadas como baseline obrigatoria de preservacao comportamental: BR-001, BR-012, BR-016, BR-017, BR-030, BR-031, BR-034 e BR-040. Cada EARS deve conter `source_legacy` explicito com rastreabilidade para o programa/linha de origem. Definir testes de aceitacao orientados por regra (happy path, excecoes e limites), principalmente para calculo financeiro, elegibilidade e descontos. Tratar constantes hardcoded como decisoes explicitas (ADR) e nao como detalhe tecnico de implementacao.

---

## Definição de Pronto deste relatório

- [x] Todas as seções acima preenchidas (sem placeholders).
- [x] Pelo menos 5 regras críticas listadas em §3.1, cada uma referenciando uma `BR-XXX` do catálogo.
- [x] Decisões de migrar/descartar/evoluir em §5 cobrem as 8+ funcionalidades principais.
- [x] Métricas de §6 conferem com os outros artefatos (glossary.md, business-rules-catalog.md, mysteries-found.md).

— Paula


---

### Continuar a leitura

<table width="100%">
<tr>
<td width="50%" valign="top" align="left">
<sub><strong>← ANTERIOR</strong></sub><br/>
<a href="mysteries-found.md"><strong>mysteries-found.md</strong></a><br/>
<sub>Lista de mistérios.</sub>
</td>
<td width="50%" valign="top" align="right">
<sub><strong>PRÓXIMO →</strong></sub><br/>
<a href="../02-spec-moderna/GUIDE.md"><strong>Estágio 2 — Spec</strong></a><br/>
<sub>Próximo estágio: spec moderna.</sub>
</td>
</tr>
</table>

<sub>↑ <a href="../README.md">Voltar ao Kit PT-BR</a></sub>

