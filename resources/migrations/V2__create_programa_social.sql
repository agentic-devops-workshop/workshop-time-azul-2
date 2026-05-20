-- ============================================================
-- V2: DDL Programa Social - Migração de PROGRAMA-SOCIAL.ddm (FNR 151)
-- Fonte: 01-arqueologia/legado-sifap/adabas-ddms/PROGRAMA-SOCIAL.ddm
-- PostgreSQL 16
-- ============================================================

-- ============================================================
-- 1. Tabela principal: programa_social
-- ============================================================
create table if not exists programa_social (
   id                  bigserial primary key,
   cod_programa        varchar(4) unique not null,
   nome_programa       varchar(60) not null,
   sigla_programa      varchar(10),
   tipo_programa       char(1) not null,  -- A=ASSISTENC T=TRABALHO P=PREVID
   orgao_responsavel   varchar(10),
   lei_criacao         varchar(20),
   dt_criacao          date,
   dt_encerramento     date,           -- NULL = vigente
   sit_programa        char(1) not null default 'A',

    -- Valores base
   vlr_base_individual numeric(9,2),
   vlr_base_familiar   numeric(9,2),
   vlr_teto_benef      numeric(11,2),
   vlr_piso_benef      numeric(9,2),
   pct_reajuste_anual  numeric(5,2),
   dt_ult_reajuste     date,
   fator_k             numeric(9,4),   -- fator correção especial (não documentado)

    -- Elegibilidade
   renda_max_percap    numeric(9,2),
   idade_min           smallint default 0,
   idade_max           smallint default 0,
   ind_exige_filhos    char(1) not null default 'N',
   qtd_min_filhos      smallint default 0,
   ind_exige_escola    char(1) not null default 'N',
   ind_exige_vacina    char(1) not null default 'N',
   ind_exige_prenatal  char(1) not null default 'N',
   ind_exige_biometria char(1) not null default 'N',

    -- Controle interno
   dt_inclusao         date not null default current_date,
   hr_inclusao         time not null default current_time,
   usr_inclusao        varchar(8) not null,
   dt_ult_alteracao    date,
   hr_ult_alteracao    time,
   usr_ult_alteracao   varchar(8),
   num_versao          integer not null default 1,
   constraint chk_tipo_programa
      check ( tipo_programa in ( 'A',
                                 'T',
                                 'P' ) ),
   constraint chk_sit_programa
      check ( sit_programa in ( 'A',
                                'I',
                                'E' ) ),
   constraint chk_ind_filhos check ( ind_exige_filhos in ( 'S',
                                                           'N' ) ),
   constraint chk_ind_escola check ( ind_exige_escola in ( 'S',
                                                           'N' ) ),
   constraint chk_ind_vacina check ( ind_exige_vacina in ( 'S',
                                                           'N' ) ),
   constraint chk_ind_prenatal check ( ind_exige_prenatal in ( 'S',
                                                               'N' ) ),
   constraint chk_ind_biometria check ( ind_exige_biometria in ( 'S',
                                                                 'N' ) )
);

-- ============================================================
-- 2. Domínio PE: faixas de cálculo (max 5)
-- ============================================================
create table if not exists programa_social_faixa_calculo (
   id                  bigserial primary key,
   programa_social_id  bigint not null,
   renda_inicio        numeric(9,2) not null,
   renda_fim           numeric(9,2) not null,
   fator_multiplicador numeric(7,4) not null,
   vlr_adicional       numeric(9,2) default 0,
   ind_acumulativo     char(1) not null default 'N',  -- S=acumula com faixa ant

    -- Controle interno
   dt_inclusao         date not null default current_date,
   hr_inclusao         time not null default current_time,
   usr_inclusao        varchar(8) not null,
   dt_ult_alteracao    date,
   hr_ult_alteracao    time,
   usr_ult_alteracao   varchar(8),
   num_versao          integer not null default 1,
   constraint chk_faixa_acumulativo check ( ind_acumulativo in ( 'S',
                                                                 'N' ) ),
   constraint fk_faixa_programa foreign key ( programa_social_id )
      references programa_social ( id )
         on delete cascade
);

-- ============================================================
-- 3. Domínio MU: tipos de desconto aplicáveis (max 8)
-- ============================================================
create table if not exists programa_social_tipo_desconto (
   id                 bigserial primary key,
   programa_social_id bigint not null,
   tipo_dsct_aplic    varchar(3) not null,  -- IR/JD/CS/PA/EM/TX/OU/EX

    -- Controle interno
   dt_inclusao        date not null default current_date,
   hr_inclusao        time not null default current_time,
   usr_inclusao       varchar(8) not null,
   dt_ult_alteracao   date,
   hr_ult_alteracao   time,
   usr_ult_alteracao  varchar(8),
   num_versao         integer not null default 1,
   constraint chk_tipo_dsct
      check ( tipo_dsct_aplic in ( 'IR',
                                   'JD',
                                   'CS',
                                   'PA',
                                   'EM',
                                   'TX',
                                   'OU',
                                   'EX' ) ),
   constraint fk_tipo_dsct_programa foreign key ( programa_social_id )
      references programa_social ( id )
         on delete cascade
);

-- ============================================================
-- 4. Domínio PE: parâmetros regionais (max 6)
-- ============================================================
create table if not exists programa_social_param_regional (
   id                  bigserial primary key,
   programa_social_id  bigint not null,
   cod_regiao          varchar(2) not null,  -- 01-05 ou 99
   fator_regional      numeric(7,4) not null,
   vlr_complemento_reg numeric(9,2) default 0,
   ind_ativo_regiao    char(1) not null default 'S',

    -- Controle interno
   dt_inclusao         date not null default current_date,
   hr_inclusao         time not null default current_time,
   usr_inclusao        varchar(8) not null,
   dt_ult_alteracao    date,
   hr_ult_alteracao    time,
   usr_ult_alteracao   varchar(8),
   num_versao          integer not null default 1,
   constraint chk_param_ativo check ( ind_ativo_regiao in ( 'S',
                                                            'N' ) ),
   constraint fk_param_regional_programa foreign key ( programa_social_id )
      references programa_social ( id )
         on delete cascade
);

-- ============================================================
-- Índices (DE) + Superdescriptors
-- ============================================================

-- S1: Código programa (já é UNIQUE na tabela principal)

-- S2: Tipo + Situação
create index idx_programa_tipo_sit on
   programa_social (
      tipo_programa,
      sit_programa
   );

-- FK indexes
create index idx_faixa_programa_id on
   programa_social_faixa_calculo (
      programa_social_id
   );
create index idx_tipo_dsct_programa_id on
   programa_social_tipo_desconto (
      programa_social_id
   );
create index idx_param_regional_programa_id on
   programa_social_param_regional (
      programa_social_id
   );