-- ============================================================
-- V3: DDL Auditoria - Migração de AUDITORIA.ddm (FNR 153)
-- Fonte: 01-arqueologia/legado-sifap/adabas-ddms/AUDITORIA.ddm
-- PostgreSQL 16
-- Nota: registro imutável (IN-TCU 63/2010), retenção 10 anos
-- ============================================================

-- ============================================================
-- 1. Tabela principal: auditoria
-- ============================================================
create table if not exists auditoria (
   id                 bigserial primary key,
   num_auditoria      numeric(15) unique not null,
   dt_evento          date not null,
   hr_evento          time not null,
   ts_evento          timestamp not null default now(),

    -- Ação
   cod_acao           varchar(2) not null,  -- IN/AL/EX/CO/LG/LO/BT/ER/AU/RE
   cod_modulo         varchar(8) not null,  -- nome programa Natural
   des_acao           varchar(80),

    -- Entidade afetada
   tipo_entidade      varchar(4),     -- BENF/PGTO/PROG/ADMN/SIST
   id_entidade        varchar(15),
   num_cpf_afetado    varchar(11),

    -- Usuário e origem
   usr_evento         varchar(8) not null,
   nome_usuario       varchar(40),
   cod_perfil         varchar(3),     -- ADM/OPR/CON/AUD/SUP
   cod_lotacao        varchar(10),
   ip_origem          varchar(15),
   id_sessao          varchar(20),

    -- Contexto batch
   num_ciclo_batch    numeric(6),
   num_seq_batch      numeric(10),
   nom_job_batch      varchar(16),
   sit_batch          char(1),        -- S=SUCESSO E=ERRO W=WARNING
   des_erro_batch     varchar(120),

    -- Correlação
   id_correlacao      varchar(36),    -- UUID operação composta
   num_seq_correlacao smallint,

    -- Controle interno
   dt_inclusao        date not null default current_date,
   hr_inclusao        time not null default current_time,
   usr_inclusao       varchar(8) not null,
   dt_ult_alteracao   date,
   hr_ult_alteracao   time,
   usr_ult_alteracao  varchar(8),
   num_versao         integer not null default 1,
   constraint chk_aud_acao
      check ( cod_acao in ( 'IN',
                            'AL',
                            'EX',
                            'CO',
                            'LG',
                            'LO',
                            'BT',
                            'ER',
                            'AU',
                            'RE' ) ),
   constraint chk_aud_sit_batch
      check ( sit_batch in ( 'S',
                             'E',
                             'W' ) )
);

-- ============================================================
-- 2. Domínio MU: campos alterados - antes (max 20)
-- ============================================================
create table if not exists auditoria_campo_anterior (
   id                bigserial primary key,
   auditoria_id      bigint not null,
   campo_alterado    varchar(30) not null,
   valor_anterior    varchar(80),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint fk_campo_ant_auditoria foreign key ( auditoria_id )
      references auditoria ( id )
         on delete cascade
);

-- ============================================================
-- 3. Domínio MU: campos alterados - depois (max 20)
-- ============================================================
create table if not exists auditoria_campo_posterior (
   id                bigserial primary key,
   auditoria_id      bigint not null,
   campo_alterado    varchar(30) not null,
   valor_posterior   varchar(80),

    -- Controle interno
   dt_inclusao       date not null default current_date,
   hr_inclusao       time not null default current_time,
   usr_inclusao      varchar(8) not null,
   dt_ult_alteracao  date,
   hr_ult_alteracao  time,
   usr_ult_alteracao varchar(8),
   num_versao        integer not null default 1,
   constraint fk_campo_pos_auditoria foreign key ( auditoria_id )
      references auditoria ( id )
         on delete cascade
);

-- ============================================================
-- Índices (DE) + Superdescriptors
-- ============================================================

-- (DE) AA: Número auditoria (já é UNIQUE)

-- (DE) AB: Data evento
create index idx_auditoria_dt_evento on
   auditoria (
      dt_evento
   );

-- (DE) BA: Código ação
create index idx_auditoria_cod_acao on
   auditoria (
      cod_acao
   );

-- (DE) CB: ID entidade
create index idx_auditoria_id_entidade on
   auditoria (
      id_entidade
   );

-- (DE) CC: CPF afetado
create index idx_auditoria_cpf_afetado on
   auditoria (
      num_cpf_afetado
   );

-- (DE) EA: Usuário evento
create index idx_auditoria_usr_evento on
   auditoria (
      usr_evento
   );

-- S1: Data + Ação
create index idx_auditoria_dt_acao on
   auditoria (
      dt_evento,
      cod_acao
   );

-- S2: Entidade + ID + Data
create index idx_auditoria_entidade_dt on
   auditoria (
      tipo_entidade,
      id_entidade,
      dt_evento
   );

-- S3: Usuário + Data
create index idx_auditoria_usr_dt on
   auditoria (
      usr_evento,
      dt_evento
   );

-- FK indexes
create index idx_campo_ant_auditoria_id on
   auditoria_campo_anterior (
      auditoria_id
   );
create index idx_campo_pos_auditoria_id on
   auditoria_campo_posterior (
      auditoria_id
   );