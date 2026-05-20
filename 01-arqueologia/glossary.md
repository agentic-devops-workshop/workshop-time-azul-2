<!-- markdownlint-disable MD013 MD025 MD026 MD028 MD029 MD034 MD040 MD051 MD060 -->

# Glossário do SIFAP Legado

![ESTÁGIO 01 Arqueologia](https://img.shields.io/badge/ESTÁGIO-01%20Arqueologia-F25022?style=for-the-badge) ![TIPO Worksheet](https://img.shields.io/badge/TIPO-Worksheet-1A1A1A?style=for-the-badge) ![PREENCHA Durante S1](https://img.shields.io/badge/PREENCHA-Durante%20S1-737373?style=for-the-badge)

> 🗺 **Você está aqui:** [Kit PT-BR](../README.md) → [Estágio 1](README.md) → **glossary**

> **Para quem é isto?** Este é um **artefato preenchido pelo time** durante o Estágio 1 (Arqueologia).
>
> **O que você terá ao final do estágio:**
>
> 1. Este documento totalmente preenchido com os dados reais do legado SIFAP
> 2. Rastreabilidade para `01-arqueologia/legado-sifap/` (programas `.NSN` e DDMs)
> 3. Base de evidência usada nas EARS do Estágio 2 (`source_legacy:`)
>
> 📘 **Guia passo a passo:** [`GUIDE.md`](GUIDE.md).


> Preencha esta tabela com todos os termos, abreviações e siglas encontrados no código Natural/Adabas.
> **Meta: no mínimo 30 termos.**

## Por que isso importa

Sistemas legados têm vocabulário próprio que ninguém documenta em lugar nenhum — só está no nome das variáveis. Se o time do Estágio 2 não souber o que `DSCT`, `BENF`, `PE` ou `CTC` significam, vai escrever uma spec sobre o que ele _acha_ que isso significa. Glossário é o que evita esse desencontro.

## Como preencher

- **Termo**: a abreviação ou sigla exatamente como aparece no código
- **Expansão**: o significado completo do termo
- **Programa**: em qual arquivo `.NSN` ou `.ddm` o termo foi encontrado
- **Contexto**: breve explicação de como/onde o termo é usado

## Dica de extração

Prompt útil no Copilot Chat (cole o conteúdo de 2–3 arquivos `.NSN` no chat antes):

> _"Liste todas as abreviações e siglas usadas neste código Natural. Para cada uma, sugira a expansão e marque com 'CONFIRMADO' ou 'HIPÓTESE'."_

## Termos encontrados

| #   | Termo | Expansão | Programa | Contexto |
| --- | ----- | -------- | -------- | -------- |
| 1   | BENF | Beneficiário | VALELEG, VALBENEF, CALCBENF, CONSBENF | Pessoa física cadastrada no programa social |
| 2   | CPF | Cadastro de Pessoa Física | Todos | Identificador único do beneficiário (11 dígitos) |
| 3   | DSCT | Desconto | CALCDSCT, BATCHPGT, BATCHCON | Deduções compulsórias do benefício (INSS, pensão, etc) |
| 4   | NIS | Número de Identificação Social | VALELEG, VALBENEF, CONSBENF, CALCBENF, BATCHPGT | Identificador do programa social (11 dígitos) |
| 5   | PAGTO | Pagamento | RELPGT, BATCHPGT, BATCHCON, CALCDSCT | Registro de transferência de valores ao beneficiário |
| 6   | ARQ | Arquivo | Todos | Referência a arquivos de dados (ARQ 150=BENEF, ARQ 155=PROG, ARQ 160=PAGTO, ARQ 170=AUDIT) |
| 7   | PROGRAMA | Programa Social | Todos | Tipo de benefício assistencial/previdenciário/trabalho |
| 8   | ELEG | Elegibilidade | VALELEG, CADPROG | Verificação de requisitos para participação no programa |
| 9   | COMPETENCIA | Competência | RELPGT, CALCDSCT, CALCCORR, BATCHPGT, BATCHCON | Período de referência (AAAAMM) do pagamento |
| 10  | VLR | Valor | Todos | Quantia monetária em reais (formato N9.2) |
| 11  | UF | Unidade Federativa | Todos | Estado brasileiro (2 letras: SP, RJ, MG, etc) |
| 12  | CEP | Código de Endereçamento Postal | VALBENEF, CONSBENF, CADBENEF | Código postal (8 dígitos) |
| 13  | RG | Registro Geral | VALDOCS, VALBENEF, CONSBENF, CADBENEF | Documento de identidade estadual |
| 14  | DT | Data | Todos | Formato AAAAMMDD (8 dígitos) |
| 15  | STATUS | Status/Situação | Todos | Estados: A=Ativo, C=Cancelado, D=Desligado, I=Inativo |
| 16  | DESCONTO | Desconto | CALCDSCT | Redução compulsória do benefício (abreviação: DSCT) |
| 17  | BRUTO | Valor Bruto | RELPGT, CALCBENF, BATCHPGT, BATCHREL, BATCHCON | Benefício antes de descontos |
| 18  | LIQUIDO | Valor Líquido | RELPGT, CALCBENF, BATCHPGT, BATCHREL, BATCHCON | Benefício após descontos |
| 19  | ABONO | Abono Especial | CALCBENF, BATCHPGT, RELPGT | Complementação ou 13º salário |
| 20  | REAJUSTE | Reajuste | CADPROG, CALCBENF, BATCHPGT | Fator de multiplicação de valores |
| 21  | CONTRIB | Contribuição | CALCDSCT | Alíquota de contribuição social (3% a 9%) |
| 22  | ALIQUOTA | Alíquota | CALCDSCT | Percentual de desconto aplicado |
| 23  | FATOR | Fator | CALCBENF, CADPROG, BATCHPGT | Multiplicador de cálculo (região, família, renda) |
| 24  | REGIAO | Região | CALCBENF, BATCHREL, BATCHPGT | Código de região geográfica (5 regiões do Brasil) |
| 25  | DEPENDENTES | Dependentes | CADDEPEND, CALCBENF | Pessoas vinculadas ao beneficiário titular |
| 26  | RENDA | Renda Familiar | VALELEG, VALBENEF, CALCBENF, BATCHPGT | Renda total do grupo familiar |
| 27  | AUDIT | Auditoria | RELAUDIT, BATCHCON | Trilha de eventos do sistema (quem, quando, o quê) |
| 28  | TELA | Tela | CONSBENF, VALDOCS | Interface online 3270 (terminal mainframe) |
| 29  | MAINFRAME | Mainframe | RELPGT, BATCHPGT, BATCHREL | Computador central que processa os lotes |
| 30  | CNAB | Câmara de Compensação Automática Bancária | BATCHCON | Padrão de retorno bancário (240 ou 400 caracteres) |
| 31  | IPCA | Índice de Preços ao Consumidor Amplo | CALCCORR | Índice de inflação para correção retroativa |
| 32  | PE | Periodic Element (Ocorrência Múltipla) | CADDEPEND, CALCDSCT | Array em Natural (DESCONTOS(PE), DEPENDENTES(PE)) |
| 33  | MAP | Map (Tela Formatada) | CONSBENF | Mapa de tela COBOL/Natural para entrada de dados |
| 34  | CTPS | Carteira de Trabalho | VALDOCS | Documento de trabalho (série/número/UF) |
| 35  | TITULO | Título de Eleitor | VALDOCS | Documento eleitoral (estado/número) |
| 36  | FLAT FILE | Arquivo Sequencial | BATCHREL | Arquivo texto para impressão em mainframe (66 lin/pag) |
| 37  | LOTE | Lote | BATCHPGT, BATCHCON | Processamento em batch (1º dia útil do mês) |
| 38  | CONCILIACAO | Conciliação | BATCHCON | Validação de pagamentos vs retorno bancário |
| 39  | LOG | Log de Erros | BATCHPGT | Registro de divergências e falhas de processamento |
| 40  | PENSAO | Pensão | CALCDSCT | Tipo de desconto: pensão alimentícia/judicial |
| 41  | JUDICIAL | Desconto Judicial | CALCDSCT | Tipo de desconto: ordem judicial ou de contribuição |
| 42  | SINDICAL | Sindical | CALCDSCT | Tipo de desconto: contribuição sindical |
| 43  | ADMIN | Administrativo | CALCDSCT | Tipo de desconto: taxa administrativa |
| 44  | NATALINO | Abono Natalino | CALCBENF | 13º mês de benefício (dezembro) |
| 45  | IMPOSTO | Imposto | CALCDSCT | Tipo de desconto: imposto (IRPF, etc) |
| 8   |       |          |          |          |
| 9   |       |          |          |          |
| 10  |       |          |          |          |
| 11  |       |          |          |          |
| 12  |       |          |          |          |
| 13  |       |          |          |          |
| 14  |       |          |          |          |
| 15  |       |          |          |          |
| 16  |       |          |          |          |
| 17  |       |          |          |          |
| 18  |       |          |          |          |
| 19  |       |          |          |          |
| 20  |       |          |          |          |
| 21  |       |          |          |          |
| 22  |       |          |          |          |
| 23  |       |          |          |          |
| 24  |       |          |          |          |
| 25  |       |          |          |          |
| 26  |       |          |          |          |
| 27  |       |          |          |          |
| 28  |       |          |          |          |
| 29  |       |          |          |          |
| 30  |       |          |          |          |

> Adicione mais linhas conforme necessário. Não se limite a 30!

## Exemplo de linha bem preenchida

| #   | Termo  | Expansão | Programa                        | Contexto                                                                                                         |
| --- | ------ | -------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| 1   | `DSCT` | Desconto | `CALCDSCT.NSN`, `PAGAMENTO.ddm` | Tipo de dedução aplicada sobre valor bruto do pagamento. Tipos: 'J' (judicial), 'I' (imposto), 'T' (trabalhista) |

## Observações

- Anote aqui qualquer padrão de nomenclatura que o time identificou:
- Convenções de prefixo/sufixo encontradas:
- Termos ambíguos que precisam de validação com especialista:

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
<a href="business-rules-catalog.md"><strong>business-rules-catalog.md</strong></a><br/>
<sub>Catálogo de regras.</sub>
</td>
</tr>
</table>

<sub>↑ <a href="README.md">Voltar ao Kit PT-BR</a></sub>

