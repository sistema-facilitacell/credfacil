-- ============================================================
-- FACILITACRED — Banco de Dados Completo v2
-- Supabase (PostgreSQL)
-- ============================================================
-- Cole no SQL Editor do Supabase e clique em RUN
-- ============================================================

-- EXTENSÕES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── USUÁRIOS DO SISTEMA ────────────────────────────────────
CREATE TABLE IF NOT EXISTS usuarios (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome         TEXT NOT NULL,
  email        TEXT UNIQUE NOT NULL,
  senha_hash   TEXT NOT NULL,
  perfil       TEXT NOT NULL CHECK (perfil IN ('admin','vendedor','suporte','cliente')),
  telefone     TEXT,
  ativo        BOOLEAN DEFAULT true,
  ultimo_login TIMESTAMP,
  criado_em    TIMESTAMP DEFAULT NOW()
);

-- ── CLIENTES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clientes (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome            TEXT NOT NULL,
  cpf             TEXT UNIQUE NOT NULL,
  rg              TEXT,
  cnh             TEXT,
  telefone        TEXT NOT NULL,
  email           TEXT,
  endereco        TEXT,
  numero          TEXT,
  complemento     TEXT,
  bairro          TEXT,
  cidade          TEXT,
  estado          TEXT,
  cep             TEXT,
  renda_mensal    NUMERIC(10,2),
  tipo_renda      TEXT CHECK (tipo_renda IN ('clt','autonomo','empresario','aposentado','outro')),
  data_nascimento DATE,
  nome_mae        TEXT,
  asaas_id        TEXT,
  status          TEXT DEFAULT 'ativo' CHECK (status IN ('ativo','bloqueado','inadimplente','inativo')),
  observacoes     TEXT,
  criado_em       TIMESTAMP DEFAULT NOW(),
  criado_por      UUID REFERENCES usuarios(id)
);

-- ── DOCUMENTOS DOS CLIENTES/CANDIDATOS ────────────────────
CREATE TABLE IF NOT EXISTS documentos (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  candidato_id    UUID,   -- pode ser candidato_id ou cliente_id
  cliente_id      UUID REFERENCES clientes(id),
  tipo            TEXT NOT NULL CHECK (tipo IN ('rg_frente','rg_verso','cnh','selfie','extrato_bancario','carteira_trabalho','comprovante_renda','outro')),
  url             TEXT NOT NULL,  -- Supabase Storage URL
  nome_arquivo    TEXT,
  tamanho_bytes   INT,
  aprovado        BOOLEAN,
  aprovado_por    UUID REFERENCES usuarios(id),
  observacao      TEXT,
  criado_em       TIMESTAMP DEFAULT NOW()
);

-- ── CANDIDATOS (pré-aprovação) ─────────────────────────────
CREATE TABLE IF NOT EXISTS candidatos (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome            TEXT NOT NULL,
  cpf             TEXT NOT NULL,
  rg              TEXT,
  cnh             TEXT,
  telefone        TEXT NOT NULL,
  email           TEXT,
  data_nascimento DATE,
  renda_mensal    NUMERIC(10,2),
  tipo_renda      TEXT CHECK (tipo_renda IN ('clt','autonomo','empresario','aposentado','outro')),
  endereco        TEXT,
  cidade          TEXT,
  estado          TEXT,
  cep             TEXT,
  celular_desejado TEXT,
  valor_celular    NUMERIC(10,2),
  -- Documentos (URLs Supabase Storage)
  doc_rg_frente    TEXT,
  doc_rg_verso     TEXT,
  doc_cnh          TEXT,
  doc_selfie       TEXT,
  doc_extrato      TEXT,
  doc_ctps         TEXT,   -- Carteira de trabalho (CLT)
  doc_outro        TEXT,
  -- Análise
  status           TEXT DEFAULT 'pendente' CHECK (status IN ('pendente','em_analise','aprovado','reprovado','aguardando_docs','cancelado')),
  score_interno    INT DEFAULT 0,
  observacao       TEXT,
  motivo_reprovacao TEXT,
  analisado_por    UUID REFERENCES usuarios(id),
  analisado_em     TIMESTAMP,
  -- Origem
  vendedor_id      UUID REFERENCES usuarios(id),
  origem           TEXT DEFAULT 'qr_code' CHECK (origem IN ('qr_code','balcao','indicacao','online')),
  criado_em        TIMESTAMP DEFAULT NOW()
);

-- ── CELULARES / ESTOQUE ────────────────────────────────────
CREATE TABLE IF NOT EXISTS celulares (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  modelo        TEXT NOT NULL,
  marca         TEXT NOT NULL,
  imei          TEXT UNIQUE NOT NULL,
  imei2         TEXT,        -- segundo IMEI (dual SIM)
  cor           TEXT,
  armazenamento TEXT,
  ram           TEXT,
  numero_serie  TEXT,
  valor_custo   NUMERIC(10,2),
  valor_venda   NUMERIC(10,2) NOT NULL,
  status        TEXT DEFAULT 'estoque' CHECK (status IN ('estoque','financiado','travado','quitado','perdido','devolvido')),
  lock_provider TEXT,        -- 'paymobi' | 'manual'
  lock_device_id TEXT,       -- ID no provedor de trava
  notas         TEXT,
  criado_em     TIMESTAMP DEFAULT NOW()
);

-- ── CONTRATOS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS contratos (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  numero            TEXT UNIQUE NOT NULL,
  cliente_id        UUID REFERENCES clientes(id) NOT NULL,
  celular_id        UUID REFERENCES celulares(id) NOT NULL,
  valor_aparelho    NUMERIC(10,2) NOT NULL,
  valor_entrada     NUMERIC(10,2) DEFAULT 0,
  valor_financiado  NUMERIC(10,2) NOT NULL,
  num_parcelas      INT NOT NULL,
  valor_parcela     NUMERIC(10,2) NOT NULL,
  valor_total       NUMERIC(10,2) NOT NULL,  -- com juros
  taxa_juros        NUMERIC(5,2) DEFAULT 0,
  data_inicio       DATE NOT NULL,
  data_fim          DATE NOT NULL,
  dia_vencimento    INT DEFAULT 10,  -- dia do mês para vencimento
  status            TEXT DEFAULT 'ativo' CHECK (status IN ('ativo','quitado','inadimplente','cancelado','renegociado')),
  celular_travado   BOOLEAN DEFAULT false,
  dias_atraso       INT DEFAULT 0,
  -- BMP Bank
  bmp_contrato_id   TEXT,
  bmp_status        TEXT,
  -- Assinaturas
  termo_assinado    BOOLEAN DEFAULT false,
  termo_assinado_em TIMESTAMP,
  contrato_url      TEXT,
  -- Vendedor e auditoria
  vendedor_id       UUID REFERENCES usuarios(id),
  criado_em         TIMESTAMP DEFAULT NOW(),
  atualizado_em     TIMESTAMP DEFAULT NOW()
);

-- ── PARCELAS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS parcelas (
  id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  contrato_id         UUID REFERENCES contratos(id) NOT NULL,
  numero              INT NOT NULL,
  valor               NUMERIC(10,2) NOT NULL,
  valor_multa         NUMERIC(10,2) DEFAULT 0,
  valor_juros_mora    NUMERIC(10,2) DEFAULT 0,
  vencimento          DATE NOT NULL,
  pago_em             DATE,
  valor_pago          NUMERIC(10,2),
  status              TEXT DEFAULT 'pendente' CHECK (status IN ('pendente','pago','atrasado','cancelado','renegociado')),
  -- Asaas
  asaas_cobranca_id   TEXT,
  asaas_boleto_url    TEXT,
  asaas_boleto_linha  TEXT,   -- linha digitável do boleto
  asaas_pix_copia_cola TEXT,
  asaas_pix_qrcode    TEXT,
  -- Log
  criado_em           TIMESTAMP DEFAULT NOW(),
  atualizado_em       TIMESTAMP DEFAULT NOW()
);

-- ── TRAVAS IMEI (log) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS travas (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  contrato_id   UUID REFERENCES contratos(id),
  celular_id    UUID REFERENCES celulares(id),
  imei          TEXT NOT NULL,
  tipo          TEXT NOT NULL CHECK (tipo IN ('trava','destrava')),
  motivo        TEXT,
  provider      TEXT,          -- 'paymobi' | 'manual'
  provider_resp TEXT,          -- resposta bruta da API
  sucesso       BOOLEAN DEFAULT true,
  feito_por     UUID REFERENCES usuarios(id),
  criado_em     TIMESTAMP DEFAULT NOW()
);

-- ── RECEBIMENTOS / CAIXA ──────────────────────────────────
CREATE TABLE IF NOT EXISTS recebimentos (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  contrato_id   UUID REFERENCES contratos(id),
  parcela_id    UUID REFERENCES parcelas(id),
  cliente_id    UUID REFERENCES clientes(id),
  tipo          TEXT NOT NULL CHECK (tipo IN ('parcela','entrada','taxa','multa','outros')),
  canal         TEXT DEFAULT 'pix' CHECK (canal IN ('pix','boleto','dinheiro','transferencia','cartao')),
  valor         NUMERIC(10,2) NOT NULL,
  data_recebimento DATE NOT NULL DEFAULT CURRENT_DATE,
  asaas_payment_id TEXT,
  observacao    TEXT,
  registrado_por UUID REFERENCES usuarios(id),
  criado_em     TIMESTAMP DEFAULT NOW()
);

-- ── NOTIFICAÇÕES ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notificacoes (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id    UUID REFERENCES clientes(id),
  contrato_id   UUID REFERENCES contratos(id),
  tipo          TEXT NOT NULL,
  canal         TEXT NOT NULL CHECK (canal IN ('sms','whatsapp','email','sistema','ligacao')),
  mensagem      TEXT,
  enviado       BOOLEAN DEFAULT false,
  enviado_em    TIMESTAMP,
  criado_em     TIMESTAMP DEFAULT NOW()
);

-- ── TERMOS ASSINADOS ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS termos (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  contrato_id     UUID REFERENCES contratos(id) NOT NULL,
  cliente_id      UUID REFERENCES clientes(id) NOT NULL,
  versao          TEXT DEFAULT 'v1',
  conteudo_html   TEXT,
  assinatura_cliente TEXT,  -- base64 da assinatura digital ou confirmação
  ip_assinatura   TEXT,
  assinado_em     TIMESTAMP,
  enviado_whatsapp BOOLEAN DEFAULT false,
  vendedor_id     UUID REFERENCES usuarios(id),
  criado_em       TIMESTAMP DEFAULT NOW()
);

-- ── USUÁRIO ADMIN PADRÃO ──────────────────────────────────
INSERT INTO usuarios (nome, email, senha_hash, perfil, telefone) VALUES
('Administrador', 'admin@facilitacred.com', 'Admin@2026!', 'admin', '45999999999')
ON CONFLICT (email) DO NOTHING;

-- ── ROW LEVEL SECURITY ────────────────────────────────────
ALTER TABLE usuarios      ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidatos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE celulares     ENABLE ROW LEVEL SECURITY;
ALTER TABLE contratos     ENABLE ROW LEVEL SECURITY;
ALTER TABLE parcelas      ENABLE ROW LEVEL SECURITY;
ALTER TABLE travas        ENABLE ROW LEVEL SECURITY;
ALTER TABLE recebimentos  ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificacoes  ENABLE ROW LEVEL SECURITY;
ALTER TABLE termos        ENABLE ROW LEVEL SECURITY;

-- Políticas (simplifado — restrinja por perfil em produção)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='usuarios' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON usuarios      FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='clientes' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON clientes      FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='documentos' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON documentos    FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='candidatos' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON candidatos    FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='celulares' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON celulares     FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='contratos' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON contratos     FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='parcelas' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON parcelas      FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='travas' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON travas        FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='recebimentos' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON recebimentos  FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='notificacoes' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON notificacoes  FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='termos' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON termos        FOR ALL USING (true);
  END IF;
END $$;

-- ── STORAGE BUCKET ────────────────────────────────────────
-- Rode separadamente no painel Supabase → Storage → New Bucket
-- Nome: documentos | Public: ON
-- INSERT INTO storage.buckets (id, name, public) VALUES ('documentos','documentos',true)
-- ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════════════════════
-- TABELA DE VENDEDORES (portal próprio, aprovação pelo admin)
-- Execute no SQL Editor do Supabase
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS vendedores (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome          TEXT NOT NULL,
  cpf           TEXT UNIQUE NOT NULL,
  telefone      TEXT NOT NULL,
  email         TEXT,
  cidade        TEXT,
  senha_hash    TEXT NOT NULL,
  status        TEXT DEFAULT 'pendente' CHECK (status IN ('pendente','ativo','inativo','reprovado')),
  origem        TEXT DEFAULT 'outro' CHECK (origem IN ('indicacao','instagram','google','outro')),
  aprovado_por  UUID REFERENCES usuarios(id),
  aprovado_em   TIMESTAMP,
  criado_em     TIMESTAMP DEFAULT NOW()
);

ALTER TABLE vendedores ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='vendedores' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON vendedores FOR ALL USING (true);
  END IF;
END $$;

-- Adicionar FK de vendedores na tabela de candidatos e contratos
-- (se ainda não existir):
ALTER TABLE candidatos ADD COLUMN IF NOT EXISTS vendedor_ext_id UUID REFERENCES vendedores(id);
ALTER TABLE contratos  ADD COLUMN IF NOT EXISTS vendedor_ext_id UUID REFERENCES vendedores(id);


-- ── CONFIGURAÇÕES DO SISTEMA ─────────────────────────────────
CREATE TABLE IF NOT EXISTS configuracoes (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  chave        TEXT UNIQUE NOT NULL,
  valor        TEXT,
  atualizado_em TIMESTAMP DEFAULT NOW()
);

ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='configuracoes' AND policyname='acesso_total') THEN
    CREATE POLICY "acesso_total" ON configuracoes FOR ALL USING (true);
  END IF;
END $$;

-- Inserir configuração padrão
INSERT INTO configuracoes (chave, valor) 
VALUES ('configuracoes', '{}')
ON CONFLICT (chave) DO NOTHING;

-- ══════════════════════════════════════════════════════════
-- CORREÇÃO DE RLS — Execute se ainda houver erro 400
-- ══════════════════════════════════════════════════════════

-- Garante acesso total via anon key para todas as tabelas
ALTER TABLE usuarios       FORCE ROW LEVEL SECURITY;
ALTER TABLE clientes       FORCE ROW LEVEL SECURITY;
ALTER TABLE candidatos     FORCE ROW LEVEL SECURITY;
ALTER TABLE celulares      FORCE ROW LEVEL SECURITY;
ALTER TABLE contratos      FORCE ROW LEVEL SECURITY;
ALTER TABLE parcelas       FORCE ROW LEVEL SECURITY;
ALTER TABLE travas         FORCE ROW LEVEL SECURITY;
ALTER TABLE recebimentos   FORCE ROW LEVEL SECURITY;
ALTER TABLE configuracoes  FORCE ROW LEVEL SECURITY;
ALTER TABLE vendedores     FORCE ROW LEVEL SECURITY;

-- Drop e recria políticas garantindo acesso pelo anon key
DROP POLICY IF EXISTS "acesso_total" ON usuarios;
DROP POLICY IF EXISTS "acesso_total" ON clientes;
DROP POLICY IF EXISTS "acesso_total" ON candidatos;
DROP POLICY IF EXISTS "acesso_total" ON celulares;
DROP POLICY IF EXISTS "acesso_total" ON contratos;
DROP POLICY IF EXISTS "acesso_total" ON parcelas;
DROP POLICY IF EXISTS "acesso_total" ON travas;
DROP POLICY IF EXISTS "acesso_total" ON recebimentos;
DROP POLICY IF EXISTS "acesso_total" ON configuracoes;
DROP POLICY IF EXISTS "acesso_total" ON vendedores;

CREATE POLICY "acesso_total" ON usuarios      FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON clientes      FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON candidatos    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON celulares     FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON contratos     FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON parcelas      FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON travas        FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON recebimentos  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON configuracoes FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acesso_total" ON vendedores    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- ── COLUNAS ADICIONAIS CONTRATOS (execute se necessário) ──
ALTER TABLE contratos ADD COLUMN IF NOT EXISTS primeiro_vencimento DATE;
ALTER TABLE contratos ADD COLUMN IF NOT EXISTS criado_por UUID REFERENCES usuarios(id);

-- ── CORRIGIR COLUNAS NOT NULL NA TABELA TRAVAS ──────────
ALTER TABLE travas ALTER COLUMN contrato_id DROP NOT NULL;
ALTER TABLE travas ALTER COLUMN celular_id DROP NOT NULL;

-- ── ADICIONAR COLUNA lida EM NOTIFICACOES SE NECESSÁRIO ──
ALTER TABLE notificacoes ADD COLUMN IF NOT EXISTS lida BOOLEAN DEFAULT false;

-- ── ADICIONAR COLUNAS IMEI E MODELO DIRETO NO CONTRATO ──
ALTER TABLE contratos ADD COLUMN IF NOT EXISTS celular_imei TEXT;
ALTER TABLE contratos ADD COLUMN IF NOT EXISTS celular_modelo TEXT;
