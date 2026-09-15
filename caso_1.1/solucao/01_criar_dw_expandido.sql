-- ====================================================================
-- Atividade 1.1 — Data Warehouse Integrado (Constelação de Fatos)
-- Banco de Destino: dw_tech_campaign
-- Fontes Operacionais (OLTP): vendas_db, logistica_db, financeiro_db
-- ====================================================================

-- 1. Criação do Banco de Dados Analítico
CREATE DATABASE IF NOT EXISTS dw_tech_campaign
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE dw_tech_campaign;

-- --------------------------------------------------------------------
-- 2. TABELAS DIMENSÃO (Dimensões Conformadas com Surrogate Keys)
-- --------------------------------------------------------------------

-- 2.1 Dim_Tempo: Decomposição temporal para análise de vendas, entregas e custos
CREATE TABLE IF NOT EXISTS Dim_Tempo (
    sk_tempo INT AUTO_INCREMENT PRIMARY KEY,
    data_completa DATE NOT NULL UNIQUE,
    dia INT NOT NULL,
    mes INT NOT NULL,
    nome_mes VARCHAR(20) NOT NULL,
    trimestre INT NOT NULL,
    ano INT NOT NULL,
    dia_semana VARCHAR(20) NOT NULL,
    eh_fim_de_semana BOOLEAN NOT NULL DEFAULT FALSE
);

-- 2.2 Dim_Cliente: Perfil geográfico e cadastral dos consumidores
CREATE TABLE IF NOT EXISTS Dim_Cliente (
    sk_cliente INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente_origem INT NOT NULL,
    nome_cliente VARCHAR(100) NOT NULL,
    cidade VARCHAR(50),
    estado VARCHAR(50)
);

-- 2.3 Dim_Produto: Catálogo de hardware, periféricos e móveis
CREATE TABLE IF NOT EXISTS Dim_Produto (
    sk_produto INT AUTO_INCREMENT PRIMARY KEY,
    id_produto_origem INT NOT NULL,
    nome_produto VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    preco DECIMAL(10, 2) NOT NULL
);

-- 2.4 Dim_Fornecedor: Parceiros de suprimentos comerciais
CREATE TABLE IF NOT EXISTS Dim_Fornecedor (
    sk_fornecedor INT AUTO_INCREMENT PRIMARY KEY,
    id_fornecedor_origem INT NOT NULL,
    nome_fornecedor VARCHAR(100) NOT NULL,
    contato VARCHAR(100)
);

-- 2.5 Dim_Entrega: Status operacional e canal de fulfillment
CREATE TABLE IF NOT EXISTS Dim_Entrega (
    sk_entrega INT AUTO_INCREMENT PRIMARY KEY,
    id_entrega_origem INT NOT NULL,
    status_entrega VARCHAR(50) NOT NULL
);

-- 2.6 Dim_Pagamento: Método financeiro de liquidação
CREATE TABLE IF NOT EXISTS Dim_Pagamento (
    sk_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    id_pagamento_origem INT NOT NULL,
    metodo_pagamento VARCHAR(50) NOT NULL
);

-- --------------------------------------------------------------------
-- 3. TABELAS FATO
-- --------------------------------------------------------------------

-- 3.1 Fato_Vendas_Integrada (Tabela Fato Central)
-- Granularidade: 1 linha por transação individual de venda
-- Integração: Venda + Entrega (Logística) + Pagamento (Financeiro) + Fornecedor
CREATE TABLE IF NOT EXISTS Fato_Vendas_Integrada (
    id_fato_venda INT AUTO_INCREMENT PRIMARY KEY,
    sk_cliente INT NOT NULL,
    sk_produto INT NOT NULL,
    sk_fornecedor INT NOT NULL,
    sk_tempo_venda INT NOT NULL,
    sk_tempo_entrega INT NULL,
    sk_tempo_pagamento INT NULL,
    sk_entrega INT NOT NULL,
    sk_pagamento INT NOT NULL,
    quantidade INT NOT NULL,
    valor_total_venda DECIMAL(10, 2) NOT NULL,
    valor_pago DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    dias_para_entrega INT NULL,
    flag_entregue_no_prazo BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_fato_vendas_cliente FOREIGN KEY (sk_cliente) REFERENCES Dim_Cliente(sk_cliente),
    CONSTRAINT fk_fato_vendas_produto FOREIGN KEY (sk_produto) REFERENCES Dim_Produto(sk_produto),
    CONSTRAINT fk_fato_vendas_fornecedor FOREIGN KEY (sk_fornecedor) REFERENCES Dim_Fornecedor(sk_fornecedor),
    CONSTRAINT fk_fato_vendas_tempo_venda FOREIGN KEY (sk_tempo_venda) REFERENCES Dim_Tempo(sk_tempo),
    CONSTRAINT fk_fato_vendas_tempo_entrega FOREIGN KEY (sk_tempo_entrega) REFERENCES Dim_Tempo(sk_tempo),
    CONSTRAINT fk_fato_vendas_tempo_pagamento FOREIGN KEY (sk_tempo_pagamento) REFERENCES Dim_Tempo(sk_tempo),
    CONSTRAINT fk_fato_vendas_entrega FOREIGN KEY (sk_entrega) REFERENCES Dim_Entrega(sk_entrega),
    CONSTRAINT fk_fato_vendas_pagamento FOREIGN KEY (sk_pagamento) REFERENCES Dim_Pagamento(sk_pagamento)
);

-- 3.2 Fato_Despesas_Operacionais (Tabela Fato de Apoio Financeiro e RH)
-- Granularidade: 1 linha por despesa operacional registrada
-- Finalidade: Apuração do ROAS (Marketing), DRE e Margem Líquida Real
CREATE TABLE IF NOT EXISTS Fato_Despesas_Operacionais (
    id_fato_despesa INT AUTO_INCREMENT PRIMARY KEY,
    sk_tempo INT NOT NULL,
    id_despesa_origem INT NOT NULL,
    tipo_despesa VARCHAR(50) NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    valor_despesa DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_fato_despesas_tempo FOREIGN KEY (sk_tempo) REFERENCES Dim_Tempo(sk_tempo)
);
