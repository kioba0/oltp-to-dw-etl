-- =====================================================
-- Atividade 1: Consultas Analíticas (OLAP) sobre o Data Warehouse
-- Destino das queries: dw_vendas (Star Schema)
-- =====================================================

USE dw_vendas;

-- =====================================================
-- Visão 1: Total de Vendas por Estado
-- Objetivo: Identificar a distribuição geográfica do faturamento
--           e volume de itens vendidos.
-- =====================================================
SELECT
  `Dim Cliente - Sk Cliente`.`estado` AS `Dim Cliente - Sk Cliente__estado`,
  SUM(`Fato_Vendas`.`valor_total`) AS `sum`,
  SUM(`Fato_Vendas`.`quantidade`) AS `sum_2`
FROM
  `Fato_Vendas`
  LEFT JOIN (
    SELECT
      `Dim_Cliente`.`sk_cliente` AS `sk_cliente`,
      `Dim_Cliente`.`id_cliente_origem` AS `id_cliente_origem`,
      `Dim_Cliente`.`nome_cliente` AS `nome_cliente`,
      `Dim_Cliente`.`cidade` AS `cidade`,
      `Dim_Cliente`.`estado` AS `estado`
    FROM
      `Dim_Cliente`
  ) AS `Dim Cliente - Sk Cliente` ON `Fato_Vendas`.`sk_cliente` = `Dim Cliente - Sk Cliente`.`sk_cliente`
GROUP BY
  `Dim Cliente - Sk Cliente`.`estado`
ORDER BY
  `Dim Cliente - Sk Cliente`.`estado` ASC;


-- =====================================================
-- Visão 2: Total de Vendas por Categoria de Produto
-- Objetivo: Identificar quais categorias de produtos geram maior receita
--           e volume de vendas para a empresa.
-- =====================================================
SELECT
  `Dim Produto - Sk Produto`.`categoria` AS `Dim Produto - Sk Produto__categoria`,
  SUM(`Fato_Vendas`.`valor_total`) AS `sum`,
  SUM(`Fato_Vendas`.`quantidade`) AS `sum_2`
FROM
  `Fato_Vendas`
  LEFT JOIN (
    SELECT
      `Dim_Produto`.`sk_produto` AS `sk_produto`,
      `Dim_Produto`.`id_produto_origem` AS `id_produto_origem`,
      `Dim_Produto`.`nome_produto` AS `nome_produto`,
      `Dim_Produto`.`categoria` AS `categoria`,
      `Dim_Produto`.`preco` AS `preco`
    FROM
      `Dim_Produto`
  ) AS `Dim Produto - Sk Produto` ON `Fato_Vendas`.`sk_produto` = `Dim Produto - Sk Produto`.`sk_produto`
GROUP BY
  `Dim Produto - Sk Produto`.`categoria`
ORDER BY
  `Dim Produto - Sk Produto`.`categoria` ASC;


-- =====================================================
-- Visão 3: Faturamento por Período (Mês e Ano)
-- Objetivo: Analisar a evolução temporal das vendas e do faturamento,
--           permitindo identificar tendências de crescimento e sazonalidade.
-- =====================================================
SELECT
  STR_TO_DATE(
    CONCAT(
      DATE_FORMAT(`Dim Tempo - Sk Tempo`.`data_completa`, '%Y-%m'),
      '-01'
    ),
    '%Y-%m-%d'
  ) AS `Dim Tempo - Sk Tempo__data_completa`,
  SUM(`Fato_Vendas`.`valor_total`) AS `sum`,
  SUM(`Fato_Vendas`.`quantidade`) AS `sum_2`
FROM
  `Fato_Vendas`
  LEFT JOIN (
    SELECT
      `Dim_Tempo`.`sk_tempo` AS `sk_tempo`,
      `Dim_Tempo`.`data_completa` AS `data_completa`,
      `Dim_Tempo`.`dia` AS `dia`,
      `Dim_Tempo`.`mes` AS `mes`,
      `Dim_Tempo`.`nome_mes` AS `nome_mes`,
      `Dim_Tempo`.`trimestre` AS `trimestre`,
      `Dim_Tempo`.`ano` AS `ano`
    FROM
      `Dim_Tempo`
  ) AS `Dim Tempo - Sk Tempo` ON `Fato_Vendas`.`sk_tempo` = `Dim Tempo - Sk Tempo`.`sk_tempo`
GROUP BY
  STR_TO_DATE(
    CONCAT(
      DATE_FORMAT(`Dim Tempo - Sk Tempo`.`data_completa`, '%Y-%m'),
      '-01'
    ),
    '%Y-%m-%d'
  )
ORDER BY
  STR_TO_DATE(
    CONCAT(
      DATE_FORMAT(`Dim Tempo - Sk Tempo`.`data_completa`, '%Y-%m'),
      '-01'
    ),
    '%Y-%m-%d'
  ) ASC;


-- =====================================================
-- SUGESTÕES ADICIONAIS DE CONSULTAS PARA O METABASE
-- =====================================================

-- =====================================================
-- Visão 4: Indicadores Executivos Globais (KPI Cards / Smart Numbers)
-- Objetivo: Alimentar cartões de destaque no topo do dashboard
-- Gráfico Metabase: Number (Cartão)
-- =====================================================
SELECT 
    COUNT(fv.id_fato) AS total_transacoes,
    SUM(fv.quantidade) AS total_itens_vendidos,
    SUM(fv.valor_total) AS faturamento_global,
    ROUND(SUM(fv.valor_total) / COUNT(fv.id_fato), 2) AS ticket_medio_transacao,
    ROUND(SUM(fv.valor_total) / SUM(fv.quantidade), 2) AS preco_medio_por_item,
    COUNT(DISTINCT fv.sk_cliente) AS total_clientes_unicos
FROM dw_vendas.Fato_Vendas fv;


-- =====================================================
-- Visão 5: Top 10 Produtos Mais Rentáveis
-- Objetivo: Identificar os produtos de maior impacto no faturamento
-- Gráfico Metabase: Bar (Horizontal) ou Table
-- =====================================================
SELECT 
    dp.nome_produto,
    dp.categoria,
    SUM(fv.quantidade) AS total_unidades_vendidas,
    SUM(fv.valor_total) AS faturamento_total
FROM dw_vendas.Fato_Vendas fv
JOIN dw_vendas.Dim_Produto dp ON fv.sk_produto = dp.sk_produto
GROUP BY dp.sk_produto, dp.nome_produto, dp.categoria
ORDER BY faturamento_total DESC
LIMIT 10;


-- =====================================================
-- Visão 6: Top 10 Clientes com Maior Volume de Compra (Clientes VIP)
-- Objetivo: Reconhecer os clientes mais valiosos para ações comerciais
-- Gráfico Metabase: Bar (Horizontal) ou Table
-- =====================================================
SELECT 
    dc.nome_cliente,
    CONCAT(dc.cidade, ' - ', dc.estado) AS localizacao,
    COUNT(fv.id_fato) AS total_pedidos,
    SUM(fv.quantidade) AS total_itens,
    SUM(fv.valor_total) AS faturamento_total
FROM dw_vendas.Fato_Vendas fv
JOIN dw_vendas.Dim_Cliente dc ON fv.sk_cliente = dc.sk_cliente
GROUP BY dc.sk_cliente, dc.nome_cliente, dc.cidade, dc.estado
ORDER BY faturamento_total DESC
LIMIT 10;


-- =====================================================
-- Visão 7: Top 10 Cidades em Faturamento
-- Objetivo: Analisar as cidades mais representativas dentro dos estados
-- Gráfico Metabase: Bar (Horizontal)
-- =====================================================
SELECT 
    dc.cidade,
    dc.estado,
    CONCAT(dc.cidade, ' (', dc.estado, ')') AS cidade_uf,
    COUNT(fv.id_fato) AS total_compras,
    SUM(fv.valor_total) AS faturamento_total
FROM dw_vendas.Fato_Vendas fv
JOIN dw_vendas.Dim_Cliente dc ON fv.sk_cliente = dc.sk_cliente
GROUP BY dc.cidade, dc.estado
ORDER BY faturamento_total DESC
LIMIT 10;


-- =====================================================
-- Visão 8: Evolução Temporal de Faturamento por Categoria (Multi-série)
-- Objetivo: Observar crescimento, sazonalidade e perda de mercado por categoria
-- Gráfico Metabase: Area (Stacked) ou Line
-- =====================================================
SELECT 
    STR_TO_DATE(CONCAT(DATE_FORMAT(dt.data_completa, '%Y-%m'), '-01'), '%Y-%m-%d') AS mes_ano,
    dp.categoria,
    SUM(fv.valor_total) AS faturamento_total,
    SUM(fv.quantidade) AS total_itens
FROM dw_vendas.Fato_Vendas fv
JOIN dw_vendas.Dim_Tempo dt ON fv.sk_tempo = dt.sk_tempo
JOIN dw_vendas.Dim_Produto dp ON fv.sk_produto = dp.sk_produto
GROUP BY mes_ano, dp.categoria
ORDER BY mes_ano ASC, faturamento_total DESC;


-- =====================================================
-- Visão 9: Comparativo Trimestral de Faturamento (Sazonalidade Q1 a Q4)
-- Objetivo: Identificar tendências sazonais e crescimento ano a ano
-- Gráfico Metabase: Bar (Barras agrupadas por ano)
-- =====================================================
SELECT 
    dt.ano,
    dt.trimestre,
    CONCAT('T', dt.trimestre, '/', dt.ano) AS trimestre_ano,
    SUM(fv.valor_total) AS faturamento_total,
    SUM(fv.quantidade) AS total_itens
FROM dw_vendas.Fato_Vendas fv
JOIN dw_vendas.Dim_Tempo dt ON fv.sk_tempo = dt.sk_tempo
GROUP BY dt.ano, dt.trimestre, trimestre_ano
ORDER BY dt.ano ASC, dt.trimestre ASC;


-- =====================================================
-- Visão 10: Distribuição de Faturamento por Dia do Mês
-- Objetivo: Identificar dias de pico de compra ao longo do mês (efeito salário/quinto dia útil)
-- Gráfico Metabase: Line ou Bar
-- =====================================================
SELECT 
    dt.dia,
    COUNT(fv.id_fato) AS total_vendas,
    SUM(fv.valor_total) AS faturamento_total,
    ROUND(AVG(fv.valor_total), 2) AS ticket_medio
FROM dw_vendas.Fato_Vendas fv
JOIN dw_vendas.Dim_Tempo dt ON fv.sk_tempo = dt.sk_tempo
GROUP BY dt.dia
ORDER BY dt.dia ASC;
