-- ====================================================================
-- Atividade 1.1: Pipeline de ETL Integrado (Extract, Transform, Load)
-- Destino: dw_tech_campaign (Constelação de Fatos)
-- Fontes Operacionais (OLTP): vendas_db, logistica_db, financeiro_db
-- ====================================================================

USE dw_tech_campaign;

-- --------------------------------------------------------------------
-- 1. CARGA DAS TABELAS DIMENSÃO
-- --------------------------------------------------------------------

-- 1.1 Carga da Dim_Tempo
-- Extração: União de todas as datas de vendas, entregas, pagamentos, despesas e estoque
-- Transformação: Decomposição em dia, mês, nome_mes (PT-BR), trimestre, ano, dia_semana e flag de fim de semana
-- Carga: dw_tech_campaign.Dim_Tempo
INSERT INTO dw_tech_campaign.Dim_Tempo (
    data_completa, 
    dia, 
    mes, 
    nome_mes, 
    trimestre, 
    ano, 
    dia_semana, 
    eh_fim_de_semana
)
SELECT 
    dt AS data_completa,
    DAY(dt) AS dia,
    MONTH(dt) AS mes,
    ELT(MONTH(dt), 
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 
        'Maio', 'Junho', 'Julho', 'Agosto', 
        'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ) AS nome_mes,
    QUARTER(dt) AS trimestre,
    YEAR(dt) AS ano,
    ELT(DAYOFWEEK(dt),
        'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
        'Quinta-feira', 'Sexta-feira', 'Sábado'
    ) AS dia_semana,
    IF(DAYOFWEEK(dt) IN (1, 7), TRUE, FALSE) AS eh_fim_de_semana
FROM (
    SELECT data_venda AS dt FROM vendas_db.vendas WHERE data_venda IS NOT NULL
    UNION
    SELECT data_entrega AS dt FROM logistica_db.entregas WHERE data_entrega IS NOT NULL
    UNION
    SELECT data_pagamento AS dt FROM financeiro_db.pagamentos WHERE data_pagamento IS NOT NULL
    UNION
    SELECT data_despesa AS dt FROM financeiro_db.despesas WHERE data_despesa IS NOT NULL
    UNION
    SELECT data_ultima_entrada AS dt FROM logistica_db.estoque WHERE data_ultima_entrada IS NOT NULL
) todas_datas
ORDER BY dt;

-- 1.2 Carga da Dim_Cliente
-- Extração: clientes de vendas_db.clientes
-- Transformação: preservação de id_cliente como id_cliente_origem
-- Carga: dw_tech_campaign.Dim_Cliente
INSERT INTO dw_tech_campaign.Dim_Cliente (
    id_cliente_origem, 
    nome_cliente, 
    cidade, 
    estado
)
SELECT 
    id_cliente AS id_cliente_origem,
    nome_cliente,
    cidade,
    estado
FROM vendas_db.clientes
ORDER BY id_cliente;

-- 1.3 Carga da Dim_Produto (Enriquecida com Saldo Físico e Limite de Segurança)
-- Extração: produtos de vendas_db.produtos + estoque físico de logistica_db.estoque
-- Transformação: mapeamento de quantidade em armazém e threshold de segurança (50 un)
-- Carga: dw_tech_campaign.Dim_Produto
INSERT INTO dw_tech_campaign.Dim_Produto (
    id_produto_origem, 
    nome_produto, 
    categoria, 
    preco,
    quantidade_estoque_disponivel,
    estoque_minimo_seguranca
)
SELECT 
    p.id_produto AS id_produto_origem,
    p.nome_produto,
    p.categoria,
    p.preco,
    COALESCE(est.quantidade_disponivel, 0) AS quantidade_estoque_disponivel,
    50 AS estoque_minimo_seguranca
FROM vendas_db.produtos p
LEFT JOIN (
    SELECT id_produto, SUM(quantidade_disponivel) AS quantidade_disponivel
    FROM logistica_db.estoque
    GROUP BY id_produto
) est ON p.id_produto = est.id_produto
ORDER BY p.id_produto;

-- 1.4 Carga da Dim_Fornecedor
-- Extração: fornecedores de logistica_db.fornecedores
-- Transformação: preservação de id_fornecedor como id_fornecedor_origem
-- Carga: dw_tech_campaign.Dim_Fornecedor
INSERT INTO dw_tech_campaign.Dim_Fornecedor (
    id_fornecedor_origem, 
    nome_fornecedor, 
    contato
)
SELECT 
    id_fornecedor AS id_fornecedor_origem,
    nome_fornecedor,
    contato
FROM logistica_db.fornecedores
ORDER BY id_fornecedor;

-- 1.5 Carga da Dim_Entrega (Enriquecida com Modalidade e Canal de Fulfillment)
-- Extração: registros operacionais de logistica_db.entregas cruzados com vendas e clientes
-- Transformação: classificação de modalidade (Expressa vs Padrão) e malha de fulfillment
-- Carga: dw_tech_campaign.Dim_Entrega
INSERT INTO dw_tech_campaign.Dim_Entrega (
    id_entrega_origem, 
    status_entrega,
    modalidade_frete,
    canal_fulfillment
)
SELECT 
    e.id_entrega AS id_entrega_origem,
    e.status_entrega,
    CASE 
        WHEN DATEDIFF(e.data_entrega, v.data_venda) <= 4 THEN 'Entrega Expressa (Same/Next-Day)'
        ELSE 'Logística Padrão Rodoviária'
    END AS modalidade_frete,
    CASE 
        WHEN c.estado IN ('SP', 'RJ', 'MG', 'BA') THEN 'Hub Regional / Frota Urbana'
        ELSE 'Malha Interestadual'
    END AS canal_fulfillment
FROM logistica_db.entregas e
INNER JOIN vendas_db.vendas v ON e.id_venda = v.id_venda
INNER JOIN vendas_db.clientes c ON v.id_cliente = c.id_cliente
ORDER BY e.id_entrega;

-- 1.6 Carga da Dim_Pagamento (Enriquecida com Tipo de Liquidação e Parcelamento)
-- Extração: registros de transações de financeiro_db.pagamentos
-- Transformação: classificação financeira (Instantânea D+0, Compensação D+1, Crédito D+30)
-- Carga: dw_tech_campaign.Dim_Pagamento
INSERT INTO dw_tech_campaign.Dim_Pagamento (
    id_pagamento_origem, 
    metodo_pagamento,
    tipo_liquidacao,
    permite_parcelamento
)
SELECT 
    id_pagamento AS id_pagamento_origem,
    metodo_pagamento,
    CASE 
        WHEN metodo_pagamento IN ('Pix', 'Cartão de Débito') THEN 'Instantânea (D+0)'
        WHEN metodo_pagamento = 'Boleto' THEN 'Compensação Bancária (D+1)'
        WHEN metodo_pagamento = 'Cartão de Crédito' THEN 'Crédito Rotativo (D+30)'
        ELSE 'Outro'
    END AS tipo_liquidacao,
    CASE 
        WHEN metodo_pagamento = 'Cartão de Crédito' THEN TRUE 
        ELSE FALSE 
    END AS permite_parcelamento
FROM financeiro_db.pagamentos
ORDER BY id_pagamento;

-- --------------------------------------------------------------------
-- 2. CARGA DA TABELA FATO CENTRAL (Fato_Vendas_Integrada)
-- --------------------------------------------------------------------
-- Extração: transações de vendas_db.vendas
-- Transformação: resolução das chaves naturais para Surrogate Keys (SKs)
--                via múltiplos JOINs com as dimensões já carregadas;
--                cálculo derivado de dias_para_entrega e flag_entregue_no_prazo.
-- Carga: dw_tech_campaign.Fato_Vendas_Integrada
INSERT INTO dw_tech_campaign.Fato_Vendas_Integrada (
    sk_cliente,
    sk_produto,
    sk_fornecedor,
    sk_tempo_venda,
    sk_tempo_entrega,
    sk_tempo_pagamento,
    sk_entrega,
    sk_pagamento,
    quantidade,
    valor_total_venda,
    valor_pago,
    dias_para_entrega,
    flag_entregue_no_prazo
)
SELECT 
    dc.sk_cliente,
    dp.sk_produto,
    df.sk_fornecedor,
    dt_venda.sk_tempo AS sk_tempo_venda,
    dt_entrega.sk_tempo AS sk_tempo_entrega,
    dt_pagamento.sk_tempo AS sk_tempo_pagamento,
    de.sk_entrega,
    dpg.sk_pagamento,
    v.quantidade,
    v.valor_total AS valor_total_venda,
    COALESCE(p.valor_pago, 0.00) AS valor_pago,
    CASE 
        WHEN e.data_entrega IS NOT NULL AND v.data_venda IS NOT NULL 
        THEN DATEDIFF(e.data_entrega, v.data_venda)
        ELSE NULL 
    END AS dias_para_entrega,
    CASE 
        WHEN e.status_entrega = 'Entregue' 
             AND e.data_entrega IS NOT NULL 
             AND DATEDIFF(e.data_entrega, v.data_venda) <= 7 
        THEN TRUE 
        ELSE FALSE 
    END AS flag_entregue_no_prazo
FROM vendas_db.vendas v
INNER JOIN dw_tech_campaign.Dim_Cliente dc 
    ON v.id_cliente = dc.id_cliente_origem
INNER JOIN dw_tech_campaign.Dim_Produto dp 
    ON v.id_produto = dp.id_produto_origem
LEFT JOIN (
    SELECT id_produto, MIN(id_fornecedor) AS id_fornecedor 
    FROM logistica_db.estoque 
    GROUP BY id_produto
) est ON v.id_produto = est.id_produto
INNER JOIN dw_tech_campaign.Dim_Fornecedor df 
    ON est.id_fornecedor = df.id_fornecedor_origem
INNER JOIN dw_tech_campaign.Dim_Tempo dt_venda 
    ON v.data_venda = dt_venda.data_completa
LEFT JOIN logistica_db.entregas e 
    ON v.id_venda = e.id_venda
LEFT JOIN dw_tech_campaign.Dim_Tempo dt_entrega 
    ON e.data_entrega = dt_entrega.data_completa
INNER JOIN dw_tech_campaign.Dim_Entrega de 
    ON e.id_entrega = de.id_entrega_origem
LEFT JOIN financeiro_db.pagamentos p 
    ON v.id_venda = p.id_venda
LEFT JOIN dw_tech_campaign.Dim_Tempo dt_pagamento 
    ON p.data_pagamento = dt_pagamento.data_completa
INNER JOIN dw_tech_campaign.Dim_Pagamento dpg 
    ON p.id_pagamento = dpg.id_pagamento_origem
ORDER BY v.id_venda;

-- --------------------------------------------------------------------
-- 3. CARGA DA TABELA FATO DE APOIO (Fato_Despesas_Operacionais)
-- --------------------------------------------------------------------
-- Extração: registros contábeis de financeiro_db.despesas
-- Transformação: resolução da Surrogate Key temporal (sk_tempo)
-- Carga: dw_tech_campaign.Fato_Despesas_Operacionais
INSERT INTO dw_tech_campaign.Fato_Despesas_Operacionais (
    sk_tempo,
    id_despesa_origem,
    tipo_despesa,
    descricao,
    valor_despesa
)
SELECT 
    dt.sk_tempo,
    d.id_despesa AS id_despesa_origem,
    d.tipo_despesa,
    d.descricao,
    d.valor AS valor_despesa
FROM financeiro_db.despesas d
INNER JOIN dw_tech_campaign.Dim_Tempo dt 
    ON d.data_despesa = dt.data_completa
ORDER BY d.id_despesa;

-- --------------------------------------------------------------------
-- 4. VALIDAÇÃO DE INTEGRIDADE E CONFERÊNCIA DE CARGA
-- --------------------------------------------------------------------

SELECT 'Dim_Tempo' AS tabela, COUNT(*) AS total_registros FROM dw_tech_campaign.Dim_Tempo
UNION ALL
SELECT 'Dim_Cliente', COUNT(*) FROM dw_tech_campaign.Dim_Cliente
UNION ALL
SELECT 'Dim_Produto', COUNT(*) FROM dw_tech_campaign.Dim_Produto
UNION ALL
SELECT 'Dim_Fornecedor', COUNT(*) FROM dw_tech_campaign.Dim_Fornecedor
UNION ALL
SELECT 'Dim_Entrega', COUNT(*) FROM dw_tech_campaign.Dim_Entrega
UNION ALL
SELECT 'Dim_Pagamento', COUNT(*) FROM dw_tech_campaign.Dim_Pagamento
UNION ALL
SELECT 'Fato_Vendas_Integrada', COUNT(*) FROM dw_tech_campaign.Fato_Vendas_Integrada
UNION ALL
SELECT 'Fato_Despesas_Operacionais', COUNT(*) FROM dw_tech_campaign.Fato_Despesas_Operacionais;

-- Checagem de integridade referencial: nenhuma chave substituta essencial deve ser nula
SELECT * 
FROM dw_tech_campaign.Fato_Vendas_Integrada 
WHERE sk_cliente IS NULL 
   OR sk_produto IS NULL 
   OR sk_fornecedor IS NULL 
   OR sk_tempo_venda IS NULL 
   OR sk_entrega IS NULL 
   OR sk_pagamento IS NULL;
