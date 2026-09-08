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
  `Dim Cliente - Sk Cliente`.`estado` ASC


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
  `Dim Produto - Sk Produto`.`categoria` ASC


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
  ) ASC
