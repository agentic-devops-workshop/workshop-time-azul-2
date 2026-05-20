-- ============================================================
-- V1: DDL Pagamento - Migração de PAGAMENTO.ddm (FNR 152)
-- Fonte: 01-arqueologia/legado-sifap/adabas-ddms/PAGAMENTO.ddm
-- PostgreSQL 16
-- ============================================================

-- ============================================================
-- 1. Tabela principal: pagamento
-- ============================================================
create table if not exists pagamento (
   id                 bigserial primary key,
   num_pagamento      numeric(15) unique not null,
   num_cpf            varchar(11) not null,
   num_inscricao      numeric(11),
   cod_programa       varchar(4) not null,
   ano_mes_ref        numeric(6) not null,  -- AAAAMM competência
   num_ciclo          numeric(6),

    -- Valores
   vlr_bruto          numeric(11,2) not null,
   vlr_liquido        numeric(11,2) not null,
   vlr_desconto_total numeric(9,2) not null default 0,

    -- Status e processamento
   sit_pagamento      char(1) not null default 'P',
   dt_geracao         date,
   hr_geracao         time,
   dt_emissao         date,
   dt_confirmacao     date,
   dt_cancelamento    date,
   mot_cancelamento   varchar(3),

    -- Controle interno
   dt_inclusao        date not null default current_date,
   hr_inclusao        time not null default current_time,
   usr_inclusao       varchar(8) not null,
   dt_ult_alteracao   date,
   hr_ult_alteracao   time,
   usr_ult_alteracao  varchar(8),
   num_versao         integer not null default 1,
   constraint chk_pagamento_situacao
      check ( sit_pagamento in ( 'P',
                                 'G',
                                 'E',
                                 'C',
                                 'D',
                                 'X',
                                 'R' ) )
);

-- ============================================================
-- 2. Domínio PE: desconto (grupo periódico, max 8)
-- ============================================================
create table if not exists pagamento_desconto (
   id                bigserial primary key,
   pagamento_id      bigint not null,
   tipo_desconto     varchar(3) not null,  -- IR/JD/CS/PA/EM/TX/OU/EX
   vlr_desconto      numeric(9,2) not null,
   pct_desconto      numeric(5,2),
   num_processo      varchar(20),    -- processo judicial (se JD)
   dt_inicio_dsct    date,
   dt_fim_dsct       date,           -- NULL = indefinido

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint chk_tipo_desconto
      check ( tipo_desconto in ( 'IR',
                                 'JD',
                                 'CS',
                                 'PA',
                                 'EM',
                                 'TX',
                                 'OU',
                                 'EX' ) ),
   constraint fk_desconto_pagamento foreign key ( pagamento_id )
      references pagamento ( id )
         on delete cascade
);

-- ============================================================
-- 3. Domínio: dados bancários
-- ============================================================
create table if not exists pagamento_dados_bancarios (
   id                bigserial primary key,
   pagamento_id      bigint not null,
   cod_banco         varchar(3) not null,
   cod_agencia       varchar(6) not null,
   num_conta         varchar(13) not null,
   tipo_conta        char(1) not null,  -- C=CORRENTE P=POUPANCA
   cod_operacao      varchar(3),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint chk_tipo_conta check ( tipo_conta in ( 'C',
                                                     'P' ) ),
   constraint fk_dados_bancarios_pagamento foreign key ( pagamento_id )
      references pagamento ( id )
         on delete cascade
);

-- ============================================================
-- 4. Domínio: integração SIAFI
-- ============================================================
create table if not exists pagamento_integracao_siafi (
   id                bigserial primary key,
   pagamento_id      bigint not null,
   num_ob_siafi      varchar(12),
   num_ne_siafi      varchar(12),
   cod_ug_emitente   varchar(6),
   cod_gestao        varchar(5),
   sit_integ_siafi   char(1) not null default 'P',

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint chk_sit_integ
      check ( sit_integ_siafi in ( 'I',
                                   'P',
                                   'E' ) ),
   constraint fk_integ_siafi_pagamento foreign key ( pagamento_id )
      references pagamento ( id )
         on delete cascade
);

-- ============================================================
-- 5. Domínio: conciliação bancária
-- ============================================================
create table if not exists pagamento_conciliacao (
   id                bigserial primary key,
   pagamento_id      bigint not null,
   dt_conciliacao    date,
   sit_conciliacao   char(1) not null default 'P',
   vlr_conciliado    numeric(11,2),
   cod_retorno_banco varchar(2),
   des_retorno_banco varchar(40),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint chk_sit_conciliacao
      check ( sit_conciliacao in ( 'C',
                                   'D',
                                   'P',
                                   'N' ) ),
   constraint fk_conciliacao_pagamento foreign key ( pagamento_id )
      references pagamento ( id )
         on delete cascade
);

-- ============================================================
-- 6. Domínio: hash de arquivos
-- ============================================================
create table if not exists pagamento_hash_arquivo (
   id                bigserial primary key,
   pagamento_id      bigint not null,
   hash_arq_remessa  varchar(64),
   hash_arq_retorno  varchar(64),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint fk_hash_pagamento foreign key ( pagamento_id )
      references pagamento ( id )
         on delete cascade
);

-- ============================================================
-- Índices (DE) + Superdescriptors
-- ============================================================

create index idx_pagamento_cpf on
   pagamento (
      num_cpf
   );
create index idx_pagamento_programa on
   pagamento (
      cod_programa
   );
create index idx_pagamento_competencia on
   pagamento (
      ano_mes_ref
   );
create index idx_pagamento_dt_geracao on
   pagamento (
      dt_geracao
   );

-- S1: CPF + Competência
create index idx_pagamento_cpf_competencia on
   pagamento (
      num_cpf,
      ano_mes_ref
   );

-- S2: Programa + Competência + Situação
create index idx_pagamento_prog_comp_sit on
   pagamento (
      cod_programa,
      ano_mes_ref,
      sit_pagamento
   );

-- S3: Ciclo + Situação
create index idx_pagamento_ciclo_sit on
   pagamento (
      num_ciclo,
      sit_pagamento
   );

-- FK indexes
create index idx_desconto_pagamento_id on
   pagamento_desconto (
      pagamento_id
   );
create index idx_dados_bancarios_pagamento_id on
   pagamento_dados_bancarios (
      pagamento_id
   );
create index idx_integ_siafi_pagamento_id on
   pagamento_integracao_siafi (
      pagamento_id
   );
create index idx_conciliacao_pagamento_id on
   pagamento_conciliacao (
      pagamento_id
   );
create index idx_hash_pagamento_id on
   pagamento_hash_arquivo (
      pagamento_id
   );