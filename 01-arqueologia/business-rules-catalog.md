<!-- markdownlint-disable MD013 MD025 MD026 MD028 MD029 MD034 MD040 MD051 MD060 -->

# Catálogo de Regras de Negócio — SIFAP Legado

![ESTÁGIO 01 Arqueologia](https://img.shields.io/badge/ESTÁGIO-01%20Arqueologia-F25022?style=for-the-badge) ![TIPO Worksheet](https://img.shields.io/badge/TIPO-Worksheet-1A1A1A?style=for-the-badge) ![PREENCHA Durante S1](https://img.shields.io/badge/PREENCHA-Durante%20S1-737373?style=for-the-badge)

> 🗺 **Você está aqui:** [Kit PT-BR](../README.md) → [Estágio 1](README.md) → **business-rules-catalog**

> **Para quem é isto?** Este é um **artefato preenchido pelo time** durante o Estágio 1 (Arqueologia).
>
> **O que você terá ao final do estágio:**
>
> 1. Este documento totalmente preenchido com os dados reais do legado SIFAP
> 2. Rastreabilidade para `01-arqueologia/legado-sifap/` (programas `.NSN` e DDMs)
> 3. Base de evidência usada nas EARS do Estágio 2 (`source_legacy:`)
>
> 📘 **Guia passo a passo:** [`GUIDE.md`](GUIDE.md).


> Registre aqui todas as regras de negócio extraídas do código Natural/Adabas.
> Cada regra precisa ter rastreabilidade até o código-fonte.
>
> **REGRA DURA:** linhas com `Programa Fonte` vazio são **inválidas** e não contam para o gate do Estágio 2. Use o formato `01-arqueologia/legado-sifap/natural-programs/ARQUIVO.NSN#L<inicio>-L<fim>` sempre que possível. Mínimo aceito: nome do arquivo .NSN.

## Como pensar em "regra de negócio"

O que conta:

- Um `IF` que decide algo no domínio (ex.: _"se a UF é do Nordeste e o programa é Seca, valor base × 1.2"_)
- Uma constante numérica sem explicação (ex.: `0.075` num cálculo de imposto)
- Uma transição de status com regra (ex.: _"só de A para S, nunca de I para A"_)
- Um tratamento especial para um caso (ex.: _"se o CPF começa com 999, é teste"_)

O que NÃO conta: paginação de relatório, formatação de saída, manipulação de cursor Adabas, abertura de arquivo. Ignore esses detalhes de implementação.

## Níveis de Risco

| Nível       | Descrição                                                     |
| ----------- | ------------------------------------------------------------- |
| **CRÍTICO** | Regra financeira ou de segurança — erro causa prejuízo direto |
| **ALTO**    | Regra de negócio central — afeta fluxo principal              |
| **MÉDIO**   | Regra de validação ou formatação — afeta qualidade dos dados  |
| **BAIXO**   | Regra de apresentação ou conveniência — impacto limitado      |

## Regras Encontradas

| ID     | Regra de Negócio | Programa Fonte | Campos DDM | Nível de Risco | Notas |
| ------ | ---------------- | -------------- | ---------- | -------------- | ----- |
### Cálculos Financeiros

| ID | Regra de Negócio | Programa Fonte | Campos DDM | Nível de Risco | Notas |
|----|------------------|---------------|------------|---------------|-------|
| BR-012 | Fator K aplica ajuste multiplicativo: VLR-CALC = VLR-BASE × (1.00 + FATOR-REAJ × 0.347215) | `01-arqueologia/legado-sifap/natural-programs/CADPROG.NSN#L76-L78` | PROGRAMA-SOCIAL.VLR-BASE, PROGRAMA-SOCIAL.FATOR-REAJUSTE | CRÍTICO | CONSTANTE MISTÉRIO: 0.347215 sem origem documentada. Reutilizada em CALCBENF e BATCHPGT. |
| BR-017 | Fatores regionais hardcoded: 27 regiões com multiplicadores de 1.0 a 1.4 | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L95-L124,CALCBENF.NSN#L170-L199` | BENEFICIARIO.COD-REGIAO | ALTO | Tabelas idênticas em BATCHPGT e CALCBENF. |
| BR-018 | Faixas de renda com fatores multiplicadores: 5 faixas (até 300=1.0x, até 600=0.85x, até 1000=0.7x, até 1500=0.55x, >1500=0.4x) | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L126-L135,CALCBENF.NSN#L201-L210` | BENEFICIARIO.RENDA-FAMILIAR | ALTO | Fator cai com renda crescente. |
| BR-027 | Fator Familiar adicional por dependente: sem dep=1.0x, 1-2 dep=(1.0 + dep*0.05), 3-4 dep=(1.1 + (dep-2)*0.03), >4 dep=(1.16 + (dep-4)*0.02) | `01-arqueologia/legado-sifap/natural-programs/CALCBENF.NSN#L183-L199` | BENEFICIARIO.NUM-DEPENDENTES | ALTO | Fórmula progressiva de bônus familiar. |
| BR-028 | Tabela IPCA congelada em 2014: 3 anos (2010-2012) com índices mensais para correção retroativa de pagamentos | `01-arqueologia/legado-sifap/natural-programs/CALCCORR.NSN#L51-L85` | PAGAMENTO.VLR-CORRECAO, PAGAMENTO.DT-CORRECAO | MÉDIO | Bloco comentado (PLANO VERÃO 1989-1991) nunca removido. |
| BR-029 | Índice acumulado truncado: VLR-CORR * 100, trunca, / 100 (não arredonda) | `01-arqueologia/legado-sifap/natural-programs/CALCCORR.NSN#L110-L116` | PAGAMENTO.VLR-CORRECAO | MÉDIO | Pode deixar centavos para trás. |
| BR-030 | Desconto compulsório tem teto de 30% do bruto: totaliza todos os descontos até limite 30% | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L101-L103` | PAGAMENTO.VLR-DESCONTO | ALTO | Proteção legal de renda mínima. Judicial não tem teto. |
| BR-031 | Desconto judicial sem teto: pode exceder 30% do bruto se ordem judicial | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L125-L131` | PAGAMENTO.VLR-DESCONTO | CRÍTICO | Tipo 'J' (judicial) é exceção. |
| BR-032 | Desconto sindical fixo 1%: tipo 'S' sempre calcula como BRUTO * 0.01 | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L144-L146` | BENEFICIARIO.DESCONTOS.PCT-DSCT | MÉDIO | Hardcoded 1%. |
| BR-033 | Contribuição social com faixas: 500=3%, 1000=5%, 2000=7%, >2000=9% | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L61-L68` | PAGAMENTO.VLR-BRUTO | MÉDIO | Tabela alíquotas em 4 faixas. |

### Validações de Status

| ID | Regra de Negócio | Programa Fonte | Campos DDM | Nível de Risco | Notas |
|----|------------------|---------------|------------|---------------|-------|
| BR-002 | Status automático SÊNIOR: beneficiário com idade > 75 anos recebe STATUS='S' automaticamente | `01-arqueologia/legado-sifap/natural-programs/CADBENEF.NSN#L135-L137` | BENEFICIARIO.STATUS, BENEFICIARIO.DT-NASCIMENTO | ALTO | Alterado em 2011. |
| BR-007 | Bloqueio de Cancelados: STATUS='C' ou 'D' não pode adicionar dependentes | `01-arqueologia/legado-sifap/natural-programs/CADDEPEND.NSN#L57-L59` | BENEFICIARIO.STATUS | ALTO | Evita operações em beneficiários inativos. |
| BR-020 | Status ATIVO apenas processado: IF STATUS NE 'A', ignora beneficiário | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L163-L167` | BENEFICIARIO.STATUS, PAGAMENTO.STATUS-PGTO | MÉDIO | Consistente com CALCBENF, VALELEG. |
| BR-040 | Status beneficiário bloqueia elegibilidade: 'A'=ativo/elegível, 'S'=suspenso, 'C'/'D'=cancelado/desligado, 'I'=inativo | `01-arqueologia/legado-sifap/natural-programs/VALELEG.NSN#L77-L95` | BENEFICIARIO.STATUS | ALTO | Múltiplos valores de status. |

### Regras de Identidade e Cadastro

| ID | Regra de Negócio | Programa Fonte | Campos DDM | Nível de Risco | Notas |
|----|------------------|---------------|------------|---------------|-------|
| BR-001 | CPF é imutável na alteração | `01-arqueologia/legado-sifap/natural-programs/CADBENEF.NSN#L142-L181` | BENEFICIARIO.CPF | CRÍTICO | Evita fraude de troca de identidade. |
| BR-004 | COD-PROGRAMA é imutável na alteração | `01-arqueologia/legado-sifap/natural-programs/CADBENEF.NSN#L167,L142-L181` | BENEFICIARIO.COD-PROGRAMA | ALTO | Trocar de programa requer exclusão + recadastro. |
| BR-005 | Dependentes iniciam em zero | `01-arqueologia/legado-sifap/natural-programs/CADBENEF.NSN#L167` | BENEFICIARIO.NUM-DEPENDENTES | MÉDIO | Só aumenta via CADDEPEND. |
| BR-006 | Limite de 5 dependentes por beneficiário | `01-arqueologia/legado-sifap/natural-programs/CADDEPEND.NSN#L58-L60` | BENEFICIARIO.NUM-DEPENDENTES | MÉDIO | Limite arbitrário. |
| BR-008 | Parentesco restrito a 4 códigos | `01-arqueologia/legado-sifap/natural-programs/CADDEPEND.NSN#L75-L77` | BENEFICIARIO.DEPENDENTES.PARENTESCO | MÉDIO | FI, CO, IR, OU. |
| BR-009 | CPF duplicado em dependentes é rejeitado | `01-arqueologia/legado-sifap/natural-programs/CADDEPEND.NSN#L87-L90` | BENEFICIARIO.DEPENDENTES.CPF-DEP | MÉDIO | Permite CPF=0. |
| BR-034 | Validação CPF com Módulo 11: 3 cópias da mesma lógica | `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L85-L120,VALDOCS.NSN#L68-L105,CADBENEF.NSN#L225-L260` | BENEFICIARIO.CPF | ALTO | Duplicação crítica. |
| BR-035 | Validação data de nascimento | `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L89-L115` | BENEFICIARIO.DT-NASCIMENTO | MÉDIO | Verifica dias por mês (bissexto=29). |
| BR-036 | Validação nome: exige espaço e comprimento > 1 | `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L116-L125` | BENEFICIARIO.NOME | BAIXO | Nome único rejeita. |
| BR-037 | Validação UF: 27 UFs hardcoded | `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L121-L150` | BENEFICIARIO.UF | BAIXO | Se nova UF criada, código quebra. |
| BR-038 | Documentos especiais com prefixos | `01-arqueologia/legado-sifap/natural-programs/VALDOCS.NSN#L50-L58` | BENEFICIARIO.CPF | MÉDIO | 8 prefixos de CPF indicam doc especial. |

### Regras de Processamento em Lote e Relatórios

| ID | Regra de Negócio | Programa Fonte | Campos DDM | Nível de Risco | Notas |
|----|------------------|---------------|------------|---------------|-------|
| BR-016 | Processamento BATCHPGT é CRÍTICO: execução 1º dia útil do mês | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L10-L12,L150-L160` | BENEFICIARIO.STATUS, PAGAMENTO.* | CRÍTICO | Se falhar parcialmente, deixa pagamentos incompletos. |
| BR-019 | Deduplicação de CPF em BATCHPGT | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L155-L160` | BENEFICIARIO.CPF | MÉDIO | Só primeira cópia é processada. |
| BR-021 | Acumuladores por status de pagamento: G, P, C, D, E | `01-arqueologia/legado-sifap/natural-programs/BATCHREL.NSN#L73-L85` | PAGAMENTO.STATUS-PGTO | MÉDIO | Mapeamento de status em relatório. |
| BR-022 | Mapeamento de região para índice | `01-arqueologia/legado-sifap/natural-programs/BATCHREL.NSN#L64-L82` | BENEFICIARIO.COD-REGIAO | MÉDIO | 5 regiões macro. |
| BR-023 | Arredondamento divergente entre programas | `01-arqueologia/legado-sifap/natural-programs/BATCHREL.NSN#L85-L91` | PAGAMENTO.VLR-BRUTO | MÉDIO | Pode causar divergência de centavos. |
| BR-024 | Conciliação bancária com CNAB 240: parsing de posições fixas | `01-arqueologia/legado-sifap/natural-programs/BATCHCON.NSN#L76-L91` | PAGAMENTO.CPF-BENEF, PAGAMENTO.VLR-LIQUIDO, PAGAMENTO.DT-PAGAMENTO | CRÍTICO | Se layout Banco do Brasil muda, quebra. |
| BR-025 | Status atualizado por código de retorno CNAB | `01-arqueologia/legado-sifap/natural-programs/BATCHCON.NSN#L115-L141` | PAGAMENTO.STATUS-PGTO, PAGAMENTO.COD-RETORNO | ALTO | Mapeamento de retorno bancário. |
| BR-026 | Divergência de centavos aceita até 0.01 | `01-arqueologia/legado-sifap/natural-programs/BATCHCON.NSN#L106-L112` | PAGAMENTO.VLR-LIQUIDO | MÉDIO | Tolerância hardcoded. |
| BR-043 | Relatório de pagamentos com quebra de programa | `01-arqueologia/legado-sifap/natural-programs/RELPGT.NSN#L71-L85` | PAGAMENTO.COD-PROGRAMA | MÉDIO | Subtotal ao programa mudar. |
| BR-044 | Auditoria trilha: todas as ações registradas em ARQ 170 | `01-arqueologia/legado-sifap/natural-programs/RELAUDIT.NSN#L45-L65` | AUDITORIA.ACAO, AUDITORIA.DT-EVENTO, AUDITORIA.HR-EVENTO | MÉDIO | Trilha para compliance. |
| BR-045 | Data padrão para auditoria se vazia | `01-arqueologia/legado-sifap/natural-programs/RELAUDIT.NSN#L77-L82` | AUDITORIA.DT-EVENTO | BAIXO | 19970101 é data "fundação" do SIFAP. |

### Regras de Elegibilidade e Autorização

| ID | Regra de Negócio | Programa Fonte | Campos DDM | Nível de Risco | Notas |
|----|------------------|---------------|------------|---------------|-------|
| BR-014 | Elegibilidade é atributo do programa | `01-arqueologia/legado-sifap/natural-programs/CADPROG.NSN#L60,L82` | PROGRAMA-SOCIAL.COD-ELEGIBILIDADE | ALTO | Usado em VALELEG. |
| BR-039 | Região 99 é exceção (INTERNACIONAL/DIPLOMÁTICO): sempre elegível | `01-arqueologia/legado-sifap/natural-programs/VALELEG.NSN#L71-L76` | BENEFICIARIO.COD-REGIAO, BENEFICIARIO.STATUS | MÉDIO | Região 99 bypass todas as regras. |
| BR-041 | Faixa etária como elegibilidade | `01-arqueologia/legado-sifap/natural-programs/VALELEG.NSN#L96-L108` | PROGRAMA-SOCIAL.IDADE-MIN, PROGRAMA-SOCIAL.IDADE-MAX | MÉDIO | Se IDADE-MAX=0, não valida máximo. |
| BR-042 | Busca alternativa por NIS | `01-arqueologia/legado-sifap/natural-programs/CONSBENF.NSN#L65-L79` | BENEFICIARIO.CPF, BENEFICIARIO.NIS | MÉDIO | 2 índices de busca. |

### Regras de Negócio Temporais

| ID | Regra de Negócio | Programa Fonte | Campos DDM | Nível de Risco | Notas |
|----|------------------|---------------|------------|---------------|-------|
| BR-003 | Auditoria de Timestamps: DT-CADASTRO e DT-ATUALIZACAO sempre preenchidas | `01-arqueologia/legado-sifap/natural-programs/CADBENEF.NSN#L172-L173,L178` | BENEFICIARIO.DT-CADASTRO, BENEFICIARIO.DT-ATUALIZACAO | MÉDIO | Permite auditoria temporal. |
| BR-015 | Data Fim pode ser zero (indefinida) | `01-arqueologia/legado-sifap/natural-programs/CADPROG.NSN#L62` | PROGRAMA-SOCIAL.DT-FIM | MÉDIO | Vigência indefinida. |

| BR-016 | Processamento BATCHPGT é CRÍTICO: execução 1º dia útil do mês, processa TODOS beneficiários ativos em ordem alfabética por CPF | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L10-L12,L150-L160` | BENEFICIARIO.STATUS, PAGAMENTO.* | **CRÍTICO** | Sistemas downstream dependem desta ordenação (CPF). Se falhar parcialmente, deixa pagamentos incompletos/inconsistentes. Alterado em 2015 com "INC AUDITORIA" mas sem detalhes. |
| BR-017 | Fatores regionais hardcoded: 27 regiões com multiplicadores de 1.0 a 1.4 (ex: AC=1.35, SP=1.10) | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L95-L124,CALCBENF.NSN#L170-L199` | BENEFICIARIO.COD-REGIAO | ALTO | Tabelas idênticas em BATCHPGT e CALCBENF. Se regional fator muda (ex: novo critério de pobreza), requer UPDATE em 2+ programas. Sem versionamento. |
| BR-018 | Faixas de renda com fatores multiplicadores: 5 faixas (até 300=1.0x, até 600=0.85x, até 1000=0.7x, até 1500=0.55x, >1500=0.4x) | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L126-L135,CALCBENF.NSN#L201-L210` | BENEFICIARIO.RENDA-FAMILIAR | ALTO | Fator cai com renda crescente (progressivo inverso). Implementado em BATCHPGT e CALCBENF. Se faixa muda (legislação), requer alterar 2 programas. |
| BR-019 | Deduplicação de CPF em BATCHPGT: se mesmo CPF aparece 2x, processa 1ª vez, ignora 2ª | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L155-L160` | BENEFICIARIO.CPF | MÉDIO | Otimização de 1999 (CARLOS SILVA). Se beneficiário se registra 2x (erro operacional), só primeira cópia é processada. Deixa 2ª órfã. |
| BR-020 | Status ATIVO apenas processado: IF STATUS NE 'A', ignora beneficiário (em BATCHPGT) | `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L163-L167` | BENEFICIARIO.STATUS, PAGAMENTO.STATUS-PGTO | MÉDIO | Beneficiário 'C'/'D'/'I'/'S' não gera pagamento. Consistente com CALCBENF, VALELEG. Se alguém muda status para 'S', pagamento fica suspenso silenciosamente. |
| BR-021 | Acumuladores por status de pagamento 5 status: G (gerado), P (pago), C (cancelado), D (devolvido), E (estornado) | `01-arqueologia/legado-sifap/natural-programs/BATCHREL.NSN#L73-L85` | PAGAMENTO.STATUS-PGTO | MÉDIO | Mapeamento de status em relatório: G=gerado, P=pago, C=cancelado, D=devolvido, E=estornado. Se novo status adicionado, BATCHREL quebra (NONE case). |
| BR-022 | Mapeamento de região para índice: COD-REGIAO 1-5=NORTE, 6-10=NORDESTE, 11-15=SUDESTE, 16-20=SUL, 21-25=CENTRO-OESTE | `01-arqueologia/legado-sifap/natural-programs/BATCHREL.NSN#L64-L82` | BENEFICIARIO.COD-REGIAO | MÉDIO | Código define 5 regiões macro. Mapeamento está hardcoded em BATCHREL. Se nova região adicionada (ex: região 99), precisa alterar lógica de mapeamento. |
| BR-023 | Arredondamento divergente entre programas: BATCHREL arredonda (+0.005, trunca) vs CALCBENF pode truncar diferente | `01-arqueologia/legado-sifap/natural-programs/BATCHREL.NSN#L85-L91` | PAGAMENTO.VLR-BRUTO | MÉDIO | Comentário no código: "NOTA: ARREDONDAMENTO DIFERE DO CALCBENF (ROUND VS TRUNCATE)". Pode causar divergência de centavos em reconciliação. |
| BR-024 | Conciliação bancária com CNAB 240: CPF, valor e data extraídos de posições fixas no arquivo de retorno | `01-arqueologia/legado-sifap/natural-programs/BATCHCON.NSN#L76-L91` | PAGAMENTO.CPF-BENEF, PAGAMENTO.VLR-LIQUIDO, PAGAMENTO.DT-PAGAMENTO | CRÍTICO | Parsing de posições hardcoded (CPF em 44-11, VLR em 120-15, DT em 140-8, RET em 231-2). Se layout Banco do Brasil muda, quebra. Sem validação de estrutura. |
| BR-025 | Status atualizado por código de retorno CNAB: '00'=P (pago), '01'=D (devolvido), '02'=E (estornado) | `01-arqueologia/legado-sifap/natural-programs/BATCHCON.NSN#L115-L141` | PAGAMENTO.STATUS-PGTO, PAGAMENTO.COD-RETORNO | ALTO | Mapeamento de retorno bancário -> status. Se novo código introduzido, NONE case ignora (padrão STATUS=G permanece). |
| BR-026 | Divergência de centavos aceita até 0.01: se diferença > 0.01, gera auditoria de divergência | `01-arqueologia/legado-sifap/natural-programs/BATCHCON.NSN#L106-L112` | PAGAMENTO.VLR-LIQUIDO | MÉDIO | Tolerância de arredondamento fixada em 1 centavo. Hardcoded, não configurável. Se inflação muda, critério pode ficar obsoleto. |
| BR-027 | Fator Familiar adicional por dependente: sem dep=1.0x, 1-2 dep=(1.0 + dep*0.05), 3-4 dep=(1.1 + (dep-2)*0.03), >4 dep=(1.16 + (dep-4)*0.02) | `01-arqueologia/legado-sifap/natural-programs/CALCBENF.NSN#L183-L199` | BENEFICIARIO.NUM-DEPENDENTES | ALTO | Fórmula progressiva de bônus familiar. Hardcoded em CALCBENF. Se política muda (ex: reduzir incentivo para > 4 filhos), requer code change. |
| BR-028 | Tabela IPCA congelada em 2014: 3 anos (2010-2012) com índices mensais para correção retroativa de pagamentos | `01-arqueologia/legado-sifap/natural-programs/CALCCORR.NSN#L51-L85` | PAGAMENTO.VLR-CORRECAO, PAGAMENTO.DT-CORRECAO | MÉDIO | Bloco comentado (PLANO VERÃO 1989-1991) nunca removido. Se período após 2012 precisa correção, não há dados. Tabela exigir UPDATE manual anual. |
| BR-029 | Índice acumulado truncado: VLR-CORR * 100, trunca, / 100 (não arredonda) — pode deixar centavos para trás | `01-arqueologia/legado-sifap/natural-programs/CALCCORR.NSN#L110-L116` | PAGAMENTO.VLR-CORRECAO | MÉDIO | Truncamento sistemático de centavos em correção retroativa. Pode acumular diferença financeira em grandes volumes. |
| BR-030 | Desconto compulsório tem teto de 30% do bruto: totaliza todos os descontos (judicial, pensão, imposto, sindical, admin) até limite 30% | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L101-L103` | PAGAMENTO.VLR-DESCONTO | ALTO | Proteção legal de renda mínima (70% líquido). Hardcoded em 0.30. Se legislação muda, requer UPDATE. Judicial não tem teto (sai da regra). |
| BR-031 | Desconto judicial sem teto: diferente dos demais descontos, pode exceder 30% do bruto se ordem judicial | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L125-L131` | PAGAMENTO.VLR-DESCONTO | CRÍTICO | Tipo 'J' (judicial) tem tratamento especial: (a) pode ser valor fixo OU percentual; (b) SEM teto de 30%. Asymmetry com outras deduções pode gerar litígio. |
| BR-032 | Desconto sindical fixo 1%: tipo 'S' sempre calcula como BRUTO * 0.01 (ignora percentual cadastrado) | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L144-L146` | BENEFICIARIO.DESCONTOS.PCT-DSCT | MÉDIO | Hardcoded 1%, PCT-DSCT é ignorado para 'S'. Se sindicato negocia 2%, código não respeita. Impacta acordo sindical. |
| BR-033 | Contribuição social com faixas: 500=3%, 1000=5%, 2000=7%, >2000=9% | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L61-L68` | PAGAMENTO.VLR-BRUTO | MÉDIO | Tabela alíquotas em 4 faixas. Alterado em 2015 ("NOVAS ALIQUOTAS") mas sem documentação de legislação. Se INSS muda, requer code update. |
| BR-034 | Validação CPF com Módulo 11: 3 cópias da mesma lógica em CADBENEF, VALDOCS, VALBENEF | `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L85-L120,VALDOCS.NSN#L68-L105,CADBENEF.NSN#L225-L260` | BENEFICIARIO.CPF | ALTO | Duplicação crítica de validação. Se algoritmo tem bug, 3 correções necessárias. Sem centralização. |
| BR-035 | Validação data de nascimento: verifica dias por mês (considerando bissexto com 29 dias) | `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L89-L115` | BENEFICIARIO.DT-NASCIMENTO | MÉDIO | Tabela DIASí-MES hardcoded. Validação inclui fevereiro=29 (bissexto). Sem cálculo dinâmico de ano bissexto (sempre permite 29/02). |
| BR-036 | Validação nome: exige espaço (separador nome e sobrenome) e comprimento > 1 caractere | `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L116-L125` | BENEFICIARIO.NOME | BAIXO | Simples validação: IF TEM ESPACO E NAO VAZIO. Permite "A B" (1+1 caracteres). Nome único (sem sobrenome) rejeita. |
| BR-037 | Validação UF: 27 UFs hardcoded em tabela (AC, AL, AM, ... TO, DF) | `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L121-L150` | BENEFICIARIO.UF | BAIXO | Se nova UF criada (improvável), código quebra. Tabela nunca foi alterada desde 1998. |
| BR-038 | Documentos especiais com prefixos: 8 prefixos de CPF indicam documento especial (000, 001, 002, 010, 011, 099, 100, 999) | `01-arqueologia/legado-sifap/natural-programs/VALDOCS.NSN#L50-L58` | BENEFICIARIO.CPF | MÉDIO | Interpretação: CPF começando em 999, 000, etc. é "documento especial" (teste?). Sem explicação. Se regra muda, hardcoded requer UPDATE. |
| BR-039 | Região 99 é exceção (INTERNACIONAL/DIPLOMÁTICO): beneficiário com COD-REGIAO=99 é SEMPRE elegível, sem validações | `01-arqueologia/legado-sifap/natural-programs/VALELEG.NSN#L71-L76` | BENEFICIARIO.COD-REGIAO, BENEFICIARIO.STATUS | MÉDIO | Workaround: região 99 bypass todas as regras de elegibilidade (status, renda, idade). Sem documentação de quem merece 99. Alterado em 2013 ("INC REGIAO 99") sem contexto. |
| BR-040 | Status beneficiário bloqueia elegibilidade: 'A'=ativo/elegível, 'S'=suspenso (motivo: "BENEFICIARIO SUSPENSO"), 'C'/'D'=cancelado/desligado, 'I'=inativo | `01-arqueologia/legado-sifap/natural-programs/VALELEG.NSN#L77-L95` | BENEFICIARIO.STATUS | ALTO | Múltiplos valores de status com diferentes significados. Não mapeado em data dict. 'S' é novo (2011: "AJUSTE STATUS IDOSO"?). |
| BR-041 | Faixa etária como elegibilidade: programa define IDADE-MIN e IDADE-MAX; se > MAX ou < MIN, rejeita | `01-arqueologia/legado-sifap/natural-programs/VALELEG.NSN#L96-L108` | PROGRAMA-SOCIAL.IDADE-MIN, PROGRAMA-SOCIAL.IDADE-MAX | MÉDIO | Validação de faixa etária por programa. Se IDADE-MAX=0, não valida máximo (sem limite superior). Lógica assimétrica. |
| BR-042 | Busca alternativa por NIS: CONSBENF permite buscar beneficiário por CPF OU por NIS (Número de Identificação Social) | `01-arqueologia/legado-sifap/natural-programs/CONSBENF.NSN#L65-L79` | BENEFICIARIO.CPF, BENEFICIARIO.NIS | MÉDIO | 2 índices de busca. NIS é campo alternativo que pode não estar sempre preenchido (legacy data issue). |
| BR-043 | Relatório de pagamentos com quebra de programa: lê pagamentos de competência, acumula por programa, imprime subtotal ao programa muda | `01-arqueologia/legado-sifap/natural-programs/RELPGT.NSN#L71-L85` | PAGAMENTO.COD-PROGRAMA | MÉDIO | Relatório usa control-break (quebra) por COD-PROGRAMA. Se programas não estão em ordem, subtotais erram. |
| BR-044 | Auditoria trilha: todas as ações (INSERT, UPDATE, DELETE, CONSULTA, CONCILIACAO, DIVERGENCIA) são registradas em ARQ 170 com usuário, data, hora, antes/depois | `01-arqueologia/legado-sifap/natural-programs/RELAUDIT.NSN#L45-L65` | AUDITORIA.ACAO, AUDITORIA.DT-EVENTO, AUDITORIA.HR-EVENTO | MÉDIO | Trilha implementada para conformidade/compliance. Ações mapeadas: IN (inclusão), AL (alteração), CO (consulta), CC (conciliação), DV (divergência), OU (outros). Sem descrição de cada. |
| BR-045 | Data padrão para auditoria se vazia: se DT-INI=0, padrão=19970101; se DT-FIM=0, padrão=hoje | `01-arqueologia/legado-sifap/natural-programs/RELAUDIT.NSN#L77-L82` | AUDITORIA.DT-EVENTO | BAIXO | Heurística de data padrão. 19970101 é data "fundação" do SIFAP (primeira alteração em 1997). Sem erro se usuário não informa. |

> Adicione mais linhas conforme necessário. Lembre-se: existem **10 regras escondidas** no código!

## Exemplo de linha bem preenchida

| ID     | Regra de Negócio                                                                        | Programa Fonte                                   | Campos DDM                                                               | Nível de Risco | Notas                                      |
| ------ | --------------------------------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------ | -------------- | ------------------------------------------ |
| BR-013 | Desconto total não pode exceder 30% do valor bruto, exceto descontos judiciais (tipo J) | `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L142-L148` | `PAGAMENTO.VLR-BRUTO`, `PAGAMENTO.VLR-TOTAL-DSCT`, `PAGAMENTO.TIPO-DSCT` | CRÍTICO        | Regra financeira. Tipo 'J' = exceção legal |

## Regras por Categoria

### Cálculos Financeiros

<!-- Liste aqui as regras relacionadas a cálculos de valores, benefícios, etc. -->

### Validações de Status

<!-- Liste aqui as regras de transição de status (A, S, C, I, D) -->

### Regras de Autorização

<!-- Liste aqui as regras de quem pode fazer o quê -->

### Regras de Negócio Temporais

<!-- Liste aqui regras com prazos, datas-limite, períodos -->

## Resumo Estatístico

- Total de regras encontradas: \_\_\_
- Regras críticas: \_\_\_
- Regras com duplicação: \_\_\_
- Regras sem documentação (escondidas): \_\_\_

---

### Continuar a leitura

<table width="100%">
<tr>
<td width="50%" valign="top" align="left">
<sub><strong>← ANTERIOR</strong></sub><br/>
<a href="GUIDE.md"><strong>GUIDE do Estágio 1</strong></a><br/>
<sub>Passo a passo do estágio.</sub>
</td>
<td width="50%" valign="top" align="right">
<sub><strong>PRÓXIMO →</strong></sub><br/>
<a href="dependency-map.md"><strong>dependency-map.md</strong></a><br/>
<sub>Mapa de quem chama quem.</sub>
</td>
</tr>
</table>

<sub>↑ <a href="README.md">Voltar ao Kit PT-BR</a></sub>

