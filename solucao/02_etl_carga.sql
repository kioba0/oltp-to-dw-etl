-- =====================================================
-- Atividade 1: Pipeline de ETL (Extract, Transform, Load)
-- Destino: dw_vendas (Star Schema)
-- Fontes: vendas_db
-- =====================================================

USE dw_vendas;

-- -----------------------------------------------------
-- 1. Carga da Dim_Tempo
-- Extração: datas únicas de transações de vendas_db.vendas
-- Transformação: decomposição em dia, mês, nome do mês (PT-BR), trimestre e ano
-- Carga: dw_vendas.Dim_Tempo
-- -----------------------------------------------------
INSERT INTO dw_vendas.Dim_Tempo (data_completa, dia, mes, nome_mes, trimestre, ano)
SELECT DISTINCT
    data_venda AS data_completa,
    DAY(data_venda) AS dia,
    MONTH(data_venda) AS mes,
    ELT(MONTH(data_venda), 
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 
        'Maio', 'Junho', 'Julho', 'Agosto', 
        'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ) AS nome_mes,
    QUARTER(data_venda) AS trimestre,
    YEAR(data_venda) AS ano
FROM vendas_db.vendas
ORDER BY data_venda;

-- -----------------------------------------------------
-- 2. Carga da Dim_Cliente
-- Extração: todos os clientes de vendas_db.clientes
-- Transformação: mapeamento com preservação de id_cliente como id_cliente_origem
-- Carga: dw_vendas.Dim_Cliente
-- -----------------------------------------------------
INSERT INTO dw_vendas.Dim_Cliente (id_cliente_origem, nome_cliente, cidade, estado)
SELECT 
    id_cliente AS id_cliente_origem,
    nome_cliente,
    cidade,
    estado
FROM vendas_db.clientes
ORDER BY id_cliente;

-- -----------------------------------------------------
-- 3. Carga da Dim_Produto
-- Extração: todos os produtos de vendas_db.produtos
-- Transformação: mapeamento com preservação de id_produto como id_produto_origem
-- Carga: dw_vendas.Dim_Produto
-- -----------------------------------------------------
INSERT INTO dw_vendas.Dim_Produto (id_produto_origem, nome_produto, categoria, preco)
SELECT 
    id_produto AS id_produto_origem,
    nome_produto,
    categoria,
    preco
FROM vendas_db.produtos
ORDER BY id_produto;

-- -----------------------------------------------------
-- 4. Carga da Fato_Vendas (Passo Crítico do ETL)
-- Extração: transações individuais de vendas_db.vendas
-- Transformação: resolução das chaves naturais para Surrogate Keys (SKs)
--                via INNER JOIN com as três tabelas de dimensão já populadas
-- Carga: dw_vendas.Fato_Vendas
-- -----------------------------------------------------
INSERT INTO dw_vendas.Fato_Vendas (sk_cliente, sk_produto, sk_tempo, quantidade, valor_total)
SELECT 
    dc.sk_cliente,
    dp.sk_produto,
    dt.sk_tempo,
    v.quantidade,
    v.valor_total
FROM vendas_db.vendas v
INNER JOIN dw_vendas.Dim_Cliente dc 
    ON v.id_cliente = dc.id_cliente_origem
INNER JOIN dw_vendas.Dim_Produto dp 
    ON v.id_produto = dp.id_produto_origem
INNER JOIN dw_vendas.Dim_Tempo dt 
    ON v.data_venda = dt.data_completa
ORDER BY v.id_venda;

-- -----------------------------------------------------
-- 5. Validação da Carga
-- -----------------------------------------------------
SELECT 'Dim_Tempo' AS tabela, COUNT(*) AS total_registros FROM dw_vendas.Dim_Tempo
UNION ALL
SELECT 'Dim_Cliente', COUNT(*) FROM dw_vendas.Dim_Cliente
UNION ALL
SELECT 'Dim_Produto', COUNT(*) FROM dw_vendas.Dim_Produto
UNION ALL
SELECT 'Fato_Vendas', COUNT(*) FROM dw_vendas.Fato_Vendas;

-- Checagem de integridade: nenhuma chave substituta deve ser nula
SELECT * 
FROM dw_vendas.Fato_Vendas 
WHERE sk_cliente IS NULL 
   OR sk_produto IS NULL 
   OR sk_tempo IS NULL;
