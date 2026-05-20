-- ============================================================
-- V0: DDL Beneficiário - Migração de BENEFICIARIO.ddm (FNR 150)
-- Fonte: 01-arqueologia/legado-sifap/adabas-ddms/BENEFICIARIO.ddm
-- PostgreSQL 16
-- ============================================================

-- ============================================================
-- 1. Tabela principal: beneficiario (identificação + controle)
-- ============================================================
create table if not exists beneficiario (
   id                bigserial primary key,
   num_inscricao     numeric(11) unique not null,
   num_cpf           varchar(11) not null,
   nome_completo     varchar(60) not null,
   nome_mae          varchar(60) not null,
   nome_pai          varchar(60),
   dt_nascimento     date not null,
   sexo              char(1) not null,
   est_civil         char(1),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint chk_benef_sexo
      check ( sexo in ( 'M',
                        'F',
                        'I' ) ),
   constraint chk_benef_est_civil
      check ( est_civil in ( 'S',
                             'C',
                             'D',
                             'V',
                             'U' ) )
);

-- ============================================================
-- 2. Domínio: documento_rg
-- ============================================================
create table if not exists beneficiario_documento_rg (
   id                bigserial primary key,
   beneficiario_id   bigint not null,
   rg_numero         varchar(15) not null,
   rg_orgao          varchar(10),
   rg_uf             char(2),
   rg_dt_expedicao   date,

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint fk_documento_rg_beneficiario foreign key ( beneficiario_id )
      references beneficiario ( id )
         on delete cascade
);

-- ============================================================
-- 3. Domínio: endereco
-- ============================================================
create table if not exists beneficiario_endereco (
   id                bigserial primary key,
   beneficiario_id   bigint not null,
   logradouro        varchar(60),
   numero            varchar(10),
   complemento       varchar(30),
   bairro            varchar(40),
   municipio         varchar(40),
   uf                char(2),
   cep               numeric(8),
   cod_ibge          numeric(7),
   cod_regiao        varchar(2),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint fk_endereco_beneficiario foreign key ( beneficiario_id )
      references beneficiario ( id )
         on delete cascade
);

-- ============================================================
-- 4. Domínio: beneficio (dados do programa social vinculado)
-- ============================================================
create table if not exists beneficiario_beneficio (
   id                  bigserial primary key,
   beneficiario_id     bigint not null,
   cod_programa        varchar(4) not null,
   dt_cadastro         date not null,
   dt_inicio_benef     date,
   dt_fim_benef        date,           -- NULL = sem prazo
   sit_beneficiario    char(1) not null default 'A',
   mot_situacao        varchar(3),
   dt_ult_situacao     date,
   vlr_renda_familiar  numeric(11,2),
   qtd_membros_familia smallint,
   ind_renda_percap    numeric(9,2),

    -- Controle interno
   dt_inclusao         date not null default current_date,
   hr_inclusao         time not null default current_time,
   usr_inclusao        varchar(8) not null,
   dt_ult_alteracao    date,
   hr_ult_alteracao    time,
   usr_ult_alteracao   varchar(8),
   num_versao          integer not null default 1,
   constraint chk_beneficio_situacao
      check ( sit_beneficiario in ( 'A',
                                    'S',
                                    'C',
                                    'I',
                                    'D' ) ),
   constraint fk_beneficio_beneficiario foreign key ( beneficiario_id )
      references beneficiario ( id )
         on delete cascade
);

-- ============================================================
-- 5. Domínio: contato
-- ============================================================
create table if not exists beneficiario_contato (
   id                bigserial primary key,
   beneficiario_id   bigint not null,
   tel_fixo          varchar(14),
   tel_celular       varchar(15),
   email             varchar(80),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint fk_contato_beneficiario foreign key ( beneficiario_id )
      references beneficiario ( id )
         on delete cascade
);

-- ============================================================
-- 6. Domínio: biometria
-- ============================================================
create table if not exists beneficiario_biometria (
   id                bigserial primary key,
   beneficiario_id   bigint not null,
   ind_biometria     char(1) not null default 'N',
   dt_coleta_bio     date,
   cod_posto_bio     varchar(6),
   hash_digital      varchar(64),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint chk_biometria_ind
      check ( ind_biometria in ( 'S',
                                 'N',
                                 'P' ) ),
   constraint fk_biometria_beneficiario foreign key ( beneficiario_id )
      references beneficiario ( id )
         on delete cascade
);

-- ============================================================
-- 7. Domínio: dependente (origem PE - grupo periódico, max 10)
-- ============================================================
create table if not exists dependente (
   id                 bigserial primary key,
   beneficiario_id    bigint not null,
   cpf_dependente     varchar(11) not null default '00000000000',
   nome_dependente    varchar(60) not null,
   dt_nasc_dependente date,
   parentesco         varchar(2) not null,
   sit_dependente     char(1) not null default 'A',
   ind_deficiencia    char(1) not null default 'N',

    -- Controle interno
   dt_inclusao        date not null default current_date,
   hr_inclusao        time not null default current_time,
   usr_inclusao       varchar(8) not null,
   dt_ult_alteracao   date,
   hr_ult_alteracao   time,
   usr_ult_alteracao  varchar(8),
   num_versao         integer not null default 1,
   constraint chk_dependente_parentesco
      check ( parentesco in ( 'FI',
                              'CJ',
                              'NT',
                              'TU' ) ),
   constraint chk_dependente_situacao
      check ( sit_dependente in ( 'A',
                                  'I',
                                  'D' ) ),
   constraint chk_dependente_deficiencia check ( ind_deficiencia in ( 'S',
                                                                      'N' ) ),
   constraint fk_dependente_beneficiario foreign key ( beneficiario_id )
      references beneficiario ( id )
         on delete cascade
);

-- ============================================================
-- Índices (DE) - campos indexados no Adabas original
-- ============================================================

-- S1: CPF completo (superdescriptor)
create unique index idx_beneficiario_cpf on
   beneficiario (
      num_cpf
   );

-- (DE) BG: UF no endereço
create index idx_endereco_uf on
   beneficiario_endereco (
      uf
   );

-- (DE) CB: Data cadastro no benefício
create index idx_beneficio_dt_cadastro on
   beneficiario_beneficio (
      dt_cadastro
   );

-- (DE) GA: Data inclusão
create index idx_beneficiario_dt_inclusao on
   beneficiario (
      dt_inclusao
   );

-- S2: UF + Situação (superdescriptor composto)
-- NOTA: No modelo normalizado, UF está em beneficiario_endereco e situação em
-- beneficiario_beneficio. Esse superdescriptor requer JOIN entre tabelas.
-- Índice funcional criado na tabela de benefício por situação para consultas frequentes.
create index idx_beneficio_situacao on
   beneficiario_beneficio (
      sit_beneficiario
   );

-- S3: Programa + Situação (superdescriptor composto)
create index idx_beneficio_programa_situacao on
   beneficiario_beneficio (
      cod_programa,
      sit_beneficiario
   );

-- FK indexes
create index idx_documento_rg_beneficiario_id on
   beneficiario_documento_rg (
      beneficiario_id
   );
create index idx_endereco_beneficiario_id on
   beneficiario_endereco (
      beneficiario_id
   );
create index idx_beneficio_beneficiario_id on
   beneficiario_beneficio (
      beneficiario_id
   );
create index idx_contato_beneficiario_id on
   beneficiario_contato (
      beneficiario_id
   );
create index idx_biometria_beneficiario_id on
   beneficiario_biometria (
      beneficiario_id
   );
create index idx_dependente_beneficiario_id on
   dependente (
      beneficiario_id
   );