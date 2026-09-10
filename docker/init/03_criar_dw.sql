-- 1. Cria o banco de dados caso ele ainda não exista
CREATE DATABASE IF NOT EXISTS dw_vendas
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- 2. Define o dw_vendas como banco ativo para os comandos seguintes
USE dw_vendas;

-- -----------------------------------------------------
-- Tabela: Dim_Tempo
-- Dimensão temporal com atributos derivados de data_venda
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Dim_Tempo (
    sk_tempo INT AUTO_INCREMENT PRIMARY KEY,
    data_completa DATE NOT NULL UNIQUE,
    dia INT NOT NULL,
    mes INT NOT NULL,
    nome_mes VARCHAR(20) NOT NULL,
    trimestre INT NOT NULL,
    ano INT NOT NULL
);

-- -----------------------------------------------------
-- Tabela: Dim_Cliente
-- Dimensão com atributos dos clientes (origem: vendas_db.clientes)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Dim_Cliente (
    sk_cliente INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente_origem INT NOT NULL,
    nome_cliente VARCHAR(100) NOT NULL,
    cidade VARCHAR(50),
    estado VARCHAR(50)
);

-- -----------------------------------------------------
-- Tabela: Dim_Produto
-- Dimensão com atributos e categorias dos produtos (origem: vendas_db.produtos)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Dim_Produto (
    sk_produto INT AUTO_INCREMENT PRIMARY KEY,
    id_produto_origem INT NOT NULL,
    nome_produto VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    preco DECIMAL(10, 2) NOT NULL
);

-- -----------------------------------------------------
-- Tabela: Fato_Vendas
-- Tabela fato central do Star Schema (granularidade: 1 linha por item de venda)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Fato_Vendas (
    id_fato INT AUTO_INCREMENT PRIMARY KEY,
    sk_cliente INT NOT NULL,
    sk_produto INT NOT NULL,
    sk_tempo INT NOT NULL,
    quantidade INT NOT NULL,
    valor_total DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_fato_cliente FOREIGN KEY (sk_cliente) REFERENCES Dim_Cliente(sk_cliente),
    CONSTRAINT fk_fato_produto FOREIGN KEY (sk_produto) REFERENCES Dim_Produto(sk_produto),
    CONSTRAINT fk_fato_tempo FOREIGN KEY (sk_tempo) REFERENCES Dim_Tempo(sk_tempo)
);