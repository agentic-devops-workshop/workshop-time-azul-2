<!-- markdownlint-disable MD013 MD025 MD026 MD028 MD029 MD034 MD040 MD051 MD060 -->

# Mistérios Encontrados — SIFAP Legado

![ESTÁGIO 01 Arqueologia](https://img.shields.io/badge/ESTÁGIO-01%20Arqueologia-F25022?style=for-the-badge) ![TIPO Worksheet](https://img.shields.io/badge/TIPO-Worksheet-1A1A1A?style=for-the-badge) ![PREENCHA Durante S1](https://img.shields.io/badge/PREENCHA-Durante%20S1-737373?style=for-the-badge)

> 🗺 **Você está aqui:** [Kit PT-BR](../README.md) → [Estágio 1](README.md) → **mysteries-found**

> **Para quem é isto?** Este é um **artefato preenchido pelo time** durante o Estágio 1 (Arqueologia).
>
> **O que você terá ao final do estágio:**
>
> 1. Este documento totalmente preenchido com os dados reais do legado SIFAP
> 2. Rastreabilidade para `01-arqueologia/legado-sifap/` (programas `.NSN` e DDMs)
> 3. Base de evidência usada nas EARS do Estágio 2 (`source_legacy:`)
>
> 📘 **Guia passo a passo:** [`GUIDE.md`](GUIDE.md).


> Registre aqui toda lógica, comportamento ou código que o time não conseguiu explicar.
> "Mistérios" são trechos de código sem documentação, com lógica não-óbvia ou que parecem workarounds.
>
> **Cota mínima para passar pelo portão do Estágio 2:** 5 mistérios documentados.

## O que conta como "mistério"?

- Código que faz algo inesperado sem comentário explicando por quê
- Valores hardcoded sem explicação (números mágicos)
- Lógica condicional que parece um workaround ou gambiarra
- Campos no DDM que não são usados por nenhum programa
- Programas que existem mas não são chamados por ninguém
- Comportamento diferente entre o que a documentação diz e o que o código faz
- Easter eggs deixados pelos desenvolvedores originais

## Níveis de Confiança

| Nível     | Significado                                         |
| --------- | --------------------------------------------------- |
| **ALTA**  | Temos certeza de que há algo estranho aqui          |
| **MÉDIA** | Parece suspeito, mas pode ter explicação            |
| **BAIXA** | Pode ser intencional, mas não conseguimos confirmar |

## Mistérios Catalogados

| ID      | Descrição | Onde Encontrado | Impacto Potencial | Confiança |
| ------- | --------- | --------------- | ----------------- | --------- |
| MYS-004 | Em dezembro o cálculo muda completamente: inclui 13º salário + abono natalino 15% exclusivo para programas tipo 'A' | `CALCBENF.NSN#L242-L260` | Pagamento errado em dezembro se não reproduzir toda a lógica do mês | ALTA |
| MYS-005 | O sistema trunca valores (divide por 100 após multiplicar) em vez de arredondar, causando perda sistemática de centavos | `CALCBENF.NSN#L231-L237`, `CALCDSCT.NSN#L91-L95` | Drift financeiro acumulado em grandes bases de beneficiários | ALTA |
| MYS-006 | Pensão alimentícia ('P') é cortada pelo teto de 30%, mas judicial ('J') não é — ambas são obrigações legais | `CALCDSCT.NSN#L133-L170` | Beneficiário com pensão pode ter o valor cortado ilegalmente | ALTA |
| MYS-007 | CPFs iniciados com `000` são aceitos como válidos sem passar pelo cálculo de dígito verificador | `VALBENEF.NSN#L194-L201` | Registros de teste do governo podem estar em produção sem controle | ALTA |
| MYS-008 | Beneficiários com `COD-REGIAO = 99` pulam TODAS as validações de elegibilidade e são aprovados automaticamente | `VALELEG.NSN#L105-L112` | Qualquer beneficiário com região 99 recebe benefício sem nenhuma verificação | ALTA |
| MYS-009 | O batch BATCHPGT processa beneficiários ordenados por CPF devido a uma otimização de 1999 que virou dependência de sistemas downstream | `BATCHPGT.NSN#L177-L181` | Mudar a ordem de processamento quebra sistemas que consomem o arquivo de saída | MÉDIA |
| MYS-010 | Eventos de exclusão (ACAO='EX') são sistematicamente filtrados e nunca aparecem no relatório de auditoria | `RELAUDIT.NSN#L104-L108` | Exclusões de beneficiários são invisíveis na trilha de auditoria do TCU | ALTA |

## Detalhamento dos Mistérios

### MYS-004: Cálculo completamente diferente em dezembro

- **Arquivo**: `01-arqueologia/legado-sifap/natural-programs/CALCBENF.NSN#L242-L260`
- **Trecho de código**:

```natural
IF #MES = 12
  MOVE 'D' TO #TIPO-PGTO
  COMPUTE #VLR-13 = #VLR-BASE * #FATOR-REG * #FATOR-IDADE
  COMPUTE #VLR-TEMP = #VLR-13 * 100
  COMPUTE #VLR-13 = #VLR-TEMP / 100
  COMPUTE #VLR-BRUTO = #VLR-BENF + #VLR-13
* ABONO NATALINO - 15% ADICIONAL PARA PROGRAMAS TIPO 'A'
  IF #TIPO-PROG = 'A'
    COMPUTE #VLR-ABONO = #VLR-BENF * 0.15
    COMPUTE #VLR-BRUTO = #VLR-BRUTO + #VLR-ABONO
  ELSE
    MOVE 0 TO #VLR-ABONO
  END-IF
END-IF
```

- **O que esperávamos**: Cálculo uniforme em todos os meses.
- **O que o código faz**: Em dezembro (`#MES = 12`), o tipo de pagamento muda para 'D' (décimo), inclui o 13º salário calculado com fórmula diferente (`BASE × FATOR_REG × FATOR_IDADE`, sem `FATOR_FAM` e `FATOR_RND`) e adiciona 15% de abono natalino — mas só para programas do tipo 'A' (Assistencial).
- **Hipótese do time**: A fórmula do 13º foi definida separadamente por resolução interna e nunca documentada junto com o cálculo mensal.
- **Risco se ignorarmos**: O pagamento de dezembro será calculado errado para todos os beneficiários. O abono de 15% não aparece em nenhum documento do `legacy-docs/`.

---

### MYS-005: Truncamento sistemático em vez de arredondamento

- **Arquivo**: `01-arqueologia/legado-sifap/natural-programs/CALCBENF.NSN#L231-L237` e `CALCDSCT.NSN#L91-L95`
- **Trecho de código**:

```natural
* TRUNCAR P/ 2 CASAS DECIMAIS - PADRAO MAINFRAME
COMPUTE #VLR-TEMP = #VLR-BENF * 100
COMPUTE #VLR-BENF = #VLR-TEMP / 100
```

- **O que esperávamos**: Arredondamento para 2 casas decimais (R$ 123,456 → R$ 123,46).
- **O que o código faz**: Trunca (R$ 123,456 → R$ 123,45). O padrão é aplicado em pelo menos 6 pontos distintos: benefício bruto, 13º, abono, desconto, teto de desconto e valor líquido.
- **Hipótese do time**: Era o comportamento padrão do mainframe ADABAS em 1997. Nunca foi revisado.
- **Risco se ignorarmos**: Java usa arredondamento padrão `HALF_UP`. Uma implementação ingênua resultará em centavos a mais para todos os beneficiários, criando divergência com o histórico de pagamentos e potencialmente falhas de conciliação financeira.

---

### MYS-006: Pensão alimentícia ('P') sujeita ao teto de 30%, mas judicial ('J') não

- **Arquivo**: `01-arqueologia/legado-sifap/natural-programs/CALCDSCT.NSN#L133-L170`
- **Trecho de código**:

```natural
VALUE 'J'
* JUDICIAL NAO TEM TETO
    ADD #VLR-DSCT-ITEM TO #VLR-TOTAL-DSCT
  VALUE 'P'
* PENSAO ALIMENTICIA
    ADD #VLR-DSCT-ITEM TO #VLR-TOTAL-DSCT
...
* APLICAR TETO 30% - EXCETO JUDICIAL
  IF #TIPO-DSCT NE 'J'
    IF #VLR-TOTAL-DSCT > #VLR-MAX-DSCT
      MOVE #VLR-MAX-DSCT TO #VLR-TOTAL-DSCT
    END-IF
  END-IF
```

- **O que esperávamos**: Pensão alimentícia ('P'), sendo obrigação judicial, também deveria ser isenta do teto.
- **O que o código faz**: Apenas `'J'` (desconto judicial genérico) escapa do teto. `'P'` (pensão) é tratado como desconto comum e tem o valor cortado em 30% do bruto se ultrapassar.
- **Hipótese do time**: Provavelmente um bug introduzido em 2007 quando a alteração de Marcia Helena incluiu o desconto judicial ('J') mas não ajustou 'P', que já existia.
- **Risco se ignorarmos**: Beneficiários com ordem judicial de pensão alimentícia podem ter o desconto cortado ilegalmente, expondo o órgão a ações judiciais.

---

### MYS-007: CPFs iniciados com 000 são aceitos sem validação

- **Arquivo**: `01-arqueologia/legado-sifap/natural-programs/VALBENEF.NSN#L194-L201`
- **Trecho de código**:

```natural
* CPF COM TODOS DIGITOS IGUAIS
  IF #TODOS-IGUAIS
* EXCECAO: CPFs INICIADOS COM 000 SAO VALIDOS (TESTE GOVERNO)
    IF #DIG(1) = 0 AND #DIG(2) = 0 AND #DIG(3) = 0
      MOVE TRUE TO #CPF-VALIDO
      ESCAPE ROUTINE
    END-IF
  END-IF
```

- **O que esperávamos**: Todo CPF com todos os dígitos iguais deveria ser rejeitado (regra padrão da Receita Federal).
- **O que o código faz**: CPFs no formato `000.000.000-00` (todos zeros) são marcados como válidos e saltam todo o resto da rotina de validação.
- **Hipótese do time**: Backdoor de testes do governo que nunca foi removido do código de produção.
- **Risco se ignorarmos**: Se a nova aplicação implementar a validação correta de CPF sem essa exceção, todos os registros cadastrados com CPF `000.xxx.xxx-xx` tornarão inválidos. Pode haver beneficiários reais cadastrados com esse CPF especial.

---

### MYS-008: Região 99 ignora toda a lógica de elegibilidade

- **Arquivo**: `01-arqueologia/legado-sifap/natural-programs/VALELEG.NSN#L105-L112`
- **Trecho de código**:

```natural
* REGIAO 99 - INTERNACIONAL/DIPLOMATICO
IF #COD-REG = 99
  MOVE TRUE TO #ELEGIVEL
  WRITE 'BENEFICIARIO ELEGIVEL - REGIAO ESPECIAL'
  ESCAPE ROUTINE
END-IF
```

- **O que esperávamos**: Todos os beneficiários passam pelas mesmas verificações de status, faixa etária, renda e documentação.
- **O que o código faz**: Se `COD-REGIAO = 99`, o programa retorna `ELEGIVEL = TRUE` imediatamente, sem verificar status, renda, idade, documentos ou tipo de programa.
- **Hipótese do time**: Criado em 2013 para atender beneficiários em situação diplomática ou no exterior. Mas não há documentação do critério de elegibilidade aplicável nem audit trail específico.
- **Risco se ignorarmos**: Se a nova aplicação implementar elegibilidade corretamente sem esse bypass, beneficiários da região 99 serão bloqueados. Se o bypass for replicado sem auditoria, é uma superfície de fraude: qualquer beneficiário com `COD-REGIAO = 99` recebe benefício sem qualquer verificação.

---

### MYS-009: Ordem de processamento do batch virou dependência não documentada

- **Arquivo**: `01-arqueologia/legado-sifap/natural-programs/BATCHPGT.NSN#L177-L181`
- **Trecho de código**:

```natural
* LEITURA EM ORDEM ALFABETICA POR CPF (OTIMIZACAO 1999)
* NOTA: SISTEMAS DOWNSTREAM DEPENDEM DESTA ORDENACAO
READ BENEFICIARIO-V BY CPF
```

- **O que esperávamos**: A ordem de processamento de um batch de geração de pagamentos não deveria importar para os resultados.
- **O que o código faz**: Processa beneficiários em ordem crescente de CPF. O comentário avisa explicitamente que sistemas downstream dependem dessa ordenação, mas não documenta quais sistemas são esses.
- **Hipótese do time**: Algum sistema de conciliação bancária ou relatório externo (possivelmente o do TCU) foi configurado para receber o arquivo de pagamentos nessa ordem e passou a depender dela.
- **Risco se ignorarmos**: Mudar para qualquer outra estratégia de ordenação (ex.: por nome, por programa, paralela) pode quebrar silenciosamente a conciliação downstream sem gerar erro imediato.

---

### MYS-010: Eventos de exclusão são ocultos da trilha de auditoria

- **Arquivo**: `01-arqueologia/legado-sifap/natural-programs/RELAUDIT.NSN#L104-L108`
- **Trecho de código**:

```natural
* FILTRO ACAO - EXCLUSOES NAO SAO EXIBIDAS
  IF AUDITORIA-V.ACAO = 'EX'
    ADD 1 TO #QTD-FILTRADOS
    ESCAPE TOP
  END-IF
```

- **O que esperávamos**: Um relatório de auditoria completo deveria mostrar todas as ações, incluindo exclusões.
- **O que o código faz**: Eventos com `ACAO = 'EX'` (exclusão) são silenciosamente contabilizados em `#QTD-FILTRADOS` e nunca exibidos — nem em tela, nem em impressora. O registro existe no banco mas nunca aparece no relatório.
- **Hipótese do time**: Pode ter sido intencional (excluir "ruído" operacional do TCU) ou um bug de 2014 introduzido durante a "limpeza de relatório" mencionada no cabeçalho. Nenhum documento explica a decisão.
- **Risco se ignorarmos**: O sistema moderno precisa expor exclusões ou há risco de compliance com a LGPD e com auditorias do TCU. Se replicarmos o filtro sem questionar, perpetuamos potencial ocultação de dados.

---

## Easter Eggs

> Dica: existem **3 easter eggs** escondidos no código legado. Registre aqui os que encontrar:

1. [ ] Easter Egg 1: \_\_\_
2. [ ] Easter Egg 2: \_\_\_
3. [ ] Easter Egg 3: \_\_\_

## Resumo

- Total de mistérios encontrados: **7**
- Confiança alta: **6** (MYS-004, MYS-005, MYS-006, MYS-007, MYS-008, MYS-010)
- Confiança média: **1** (MYS-009)
- Confiança baixa: **0**
- Easter eggs encontrados: **0** / 3

### Cobertura por programa

| Programa | Mistérios encontrados |
| -------- | --------------------- |
| `CALCBENF.NSN` | MYS-004, MYS-005 |
| `CALCDSCT.NSN` | MYS-005, MYS-006 |
| `VALBENEF.NSN` | MYS-007 |
| `VALELEG.NSN` | MYS-008 |
| `BATCHPGT.NSN` | MYS-009 |
| `RELAUDIT.NSN` | MYS-010 |

---

### Continuar a leitura

<table width="100%">
<tr>
<td width="50%" valign="top" align="left">
<sub><strong>← ANTERIOR</strong></sub><br/>
<a href="mysteries-checklist.md"><strong>mysteries-checklist.md</strong></a><br/>
<sub>Lista do que procurar.</sub>
</td>
<td width="50%" valign="top" align="right">
<sub><strong>PRÓXIMO →</strong></sub><br/>
<a href="discovery-report.md"><strong>discovery-report.md</strong></a><br/>
<sub>Síntese final.</sub>
</td>
</tr>
</table>

<sub>↑ <a href="README.md">Voltar ao Kit PT-BR</a></sub>

