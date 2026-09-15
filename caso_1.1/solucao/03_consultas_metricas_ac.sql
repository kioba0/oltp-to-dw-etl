-- ====================================================================
-- Atividade 1.1: Consultas Analíticas das 8 Áreas de Convergência (OLAP)
-- Banco Analítico: dw_tech_campaign (Data Warehouse Integrado)
-- ====================================================================

USE dw_tech_campaign;

-- ====================================================================
-- 1. GERÊNCIA GERAL (Atividade 1.1 — Torre de Controle e Eficiência Global)
-- KPI: Taxa OTIF (% On-Time In-Full)
-- Objetivo: Medir a taxa global de cumprimento integral e pontual dos pedidos.
-- ====================================================================
SELECT 
    COUNT(*) AS total_pedidos_campanha,
    SUM(CASE WHEN de.status_entrega = 'Entregue' THEN 1 ELSE 0 END) AS total_pedidos_entregues,
    SUM(CASE WHEN fv.flag_entregue_no_prazo = TRUE THEN 1 ELSE 0 END) AS total_pedidos_no_prazo,
    ROUND(SUM(CASE WHEN fv.flag_entregue_no_prazo = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS taxa_otif_percentual,
    ROUND(SUM(CASE WHEN de.status_entrega = 'Pendente' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS taxa_pedidos_pendentes_pct
FROM dw_tech_campaign.Fato_Vendas_Integrada fv
JOIN dw_tech_campaign.Dim_Entrega de ON fv.sk_entrega = de.sk_entrega;


-- ====================================================================
-- 2. RECURSOS HUMANOS (Atividade 2.1 — Dimensionamento da Equipe de Expedição)
-- KPI: Produtividade Operacional e Custo de Pessoal por Pedido
-- Objetivo: Relacionar despesas com salários ao volume de expedição por período.
-- ====================================================================
WITH despesas_rh AS (
    SELECT 
        dt.ano,
        dt.mes,
        dt.nome_mes,
        SUM(fd.valor_despesa) AS total_salarios_equipe
    FROM dw_tech_campaign.Fato_Despesas_Operacionais fd
    JOIN dw_tech_campaign.Dim_Tempo dt ON fd.sk_tempo = dt.sk_tempo
    WHERE fd.descricao LIKE '%Salários%'
    GROUP BY dt.ano, dt.mes, dt.nome_mes
),
pedidos_mes AS (
    SELECT 
        dt.ano,
        dt.mes,
        COUNT(fv.id_fato_venda) AS total_pedidos_expedidos
    FROM dw_tech_campaign.Fato_Vendas_Integrada fv
    JOIN dw_tech_campaign.Dim_Tempo dt ON fv.sk_tempo_venda = dt.sk_tempo
    GROUP BY dt.ano, dt.mes
)
SELECT 
    dr.ano,
    dr.nome_mes,
    pm.total_pedidos_expedidos,
    dr.total_salarios_equipe,
    ROUND(dr.total_salarios_equipe / pm.total_pedidos_expedidos, 2) AS custo_pessoal_por_pedido,
    ROUND(pm.total_pedidos_expedidos / (dr.total_salarios_equipe / 2500.00), 2) AS pedidos_por_operador_equivalente
FROM despesas_rh dr
JOIN pedidos_mes pm ON dr.ano = pm.ano AND dr.mes = pm.mes
ORDER BY dr.ano, dr.mes;


-- ====================================================================
-- 3. MARKETING (Atividade 3.1 — Gestão de Campanhas de Tráfego Tech)
-- KPI: ROAS (Return on Ad Spend) e CAC Médio por Pedido
-- Objetivo: Medir a alavancagem de receita gerada para cada R$ investido em anúncios.
-- ====================================================================
WITH faturamento_anual AS (
    SELECT 
        dt.ano,
        SUM(fv.valor_total_venda) AS receita_bruta_vendas,
        COUNT(fv.id_fato_venda) AS total_pedidos
    FROM dw_tech_campaign.Fato_Vendas_Integrada fv
    JOIN dw_tech_campaign.Dim_Tempo dt ON fv.sk_tempo_venda = dt.sk_tempo
    GROUP BY dt.ano
),
despesas_mkt AS (
    SELECT 
        dt.ano,
        SUM(fd.valor_despesa) AS total_investimento_marketing
    FROM dw_tech_campaign.Fato_Despesas_Operacionais fd
    JOIN dw_tech_campaign.Dim_Tempo dt ON fd.sk_tempo = dt.sk_tempo
    WHERE fd.descricao LIKE '%Marketing%'
    GROUP BY dt.ano
)
SELECT 
    fa.ano,
    fa.total_pedidos,
    fa.receita_bruta_vendas,
    dm.total_investimento_marketing,
    ROUND(fa.receita_bruta_vendas / dm.total_investimento_marketing, 2) AS roas,
    ROUND(dm.total_investimento_marketing / fa.total_pedidos, 2) AS custo_aquisicao_por_pedido
FROM faturamento_anual fa
JOIN despesas_mkt dm ON fa.ano = dm.ano
ORDER BY fa.ano;


-- ====================================================================
-- 4. LOGÍSTICA EXTERNA (Atividade 4.1 — Expedição e Gestão de Despacho de Entregas)
-- KPI: Lead Time Médio de Entrega (dias) e Índice de Pontualidade por UF
-- Objetivo: Identificar gargalos regionais de transporte e tempo de trânsito.
-- ====================================================================
SELECT 
    dc.estado AS uf,
    COUNT(fv.id_fato_venda) AS total_pedidos,
    ROUND(AVG(fv.dias_para_entrega), 1) AS lead_time_medio_dias,
    MIN(fv.dias_para_entrega) AS lead_time_minimo_dias,
    MAX(fv.dias_para_entrega) AS lead_time_maximo_dias,
    SUM(CASE WHEN fv.flag_entregue_no_prazo = TRUE THEN 1 ELSE 0 END) AS entregas_no_prazo,
    ROUND(SUM(CASE WHEN fv.flag_entregue_no_prazo = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(fv.id_fato_venda), 2) AS taxa_pontualidade_pct
FROM dw_tech_campaign.Fato_Vendas_Integrada fv
JOIN dw_tech_campaign.Dim_Cliente dc ON fv.sk_cliente = dc.sk_cliente
GROUP BY dc.estado
ORDER BY taxa_pontualidade_pct DESC, lead_time_medio_dias ASC;


-- ====================================================================
-- 5. LOGÍSTICA INTERNA (Atividade 5.1 — Abastecimento e Entrada de Fornecedores)
-- KPI: Volume de Reposição e Giro de Abastecimento por Parceiro
-- Objetivo: Avaliar a eficiência e fluxo de abastecimento vindo de cada distribuidor.
-- ====================================================================
SELECT 
    df.nome_fornecedor,
    df.contato,
    COUNT(DISTINCT fv.sk_produto) AS total_skus_distribuidos,
    SUM(fv.quantidade) AS total_unidades_repostas_e_vendidas,
    ROUND(AVG(fv.dias_para_entrega), 1) AS tempo_medio_ciclo_dias,
    SUM(fv.valor_total_venda) AS volume_financeiro_movimentado
FROM dw_tech_campaign.Fato_Vendas_Integrada fv
JOIN dw_tech_campaign.Dim_Fornecedor df ON fv.sk_fornecedor = df.sk_fornecedor
GROUP BY df.sk_fornecedor, df.nome_fornecedor, df.contato
ORDER BY volume_financeiro_movimentado DESC;


-- ====================================================================
-- 6. PRODUÇÃO / OPERAÇÕES (Atividade 6.1 — Gestão de Estoque e Prevenção de Ruptura)
-- KPI: Taxa de Giro e Demanda por Categoria de Produto
-- Objetivo: Monitorar quais linhas exigem maior estoque de segurança para evitar stockout.
-- ====================================================================
SELECT 
    dp.categoria,
    COUNT(DISTINCT dp.sk_produto) AS total_modelos_ativos,
    SUM(fv.quantidade) AS total_itens_vendidos,
    SUM(fv.valor_total_venda) AS receita_total_categoria,
    ROUND(AVG(dp.preco), 2) AS preco_medio_produto,
    ROUND(SUM(fv.quantidade) / COUNT(DISTINCT dp.sk_produto), 1) AS taxa_giro_por_modelo
FROM dw_tech_campaign.Fato_Vendas_Integrada fv
JOIN dw_tech_campaign.Dim_Produto dp ON fv.sk_produto = dp.sk_produto
GROUP BY dp.categoria
ORDER BY total_itens_vendidos DESC;


-- ====================================================================
-- 7. FINANÇAS (Atividade 7.1 — Conciliação Financeira e Margem de Contribuição)
-- KPI: Volume Liquidado por Método de Pagamento e Adimplência
-- Objetivo: Avaliar o fluxo de caixa efetivo e a distribuição dos meios de pagamento.
-- ====================================================================
SELECT 
    dpg.metodo_pagamento,
    COUNT(fv.id_fato_venda) AS total_transacoes,
    SUM(fv.valor_total_venda) AS faturamento_bruto,
    SUM(fv.valor_pago) AS total_liquidado_em_caixa,
    ROUND(SUM(fv.valor_pago) * 100.0 / (SELECT SUM(valor_pago) FROM dw_tech_campaign.Fato_Vendas_Integrada), 2) AS participacao_no_caixa_pct,
    ROUND(AVG(fv.valor_total_venda), 2) AS ticket_medio_transacao
FROM dw_tech_campaign.Fato_Vendas_Integrada fv
JOIN dw_tech_campaign.Dim_Pagamento dpg ON fv.sk_pagamento = dpg.sk_pagamento
GROUP BY dpg.metodo_pagamento
ORDER BY total_liquidado_em_caixa DESC;


-- ====================================================================
-- 8. COMERCIAL (Atividade 8.1 — Homologação e Negociação com Fornecedores)
-- KPI: Grau de Concentração de Fornecimento (% de Dependência por Fornecedor)
-- Objetivo: Identificar dependência comercial de fornecedores parceiros.
-- ====================================================================
WITH fornecedores_consolidado AS (
    SELECT 
        df.nome_fornecedor,
        df.contato,
        SUM(fv.quantidade) AS total_itens_negociados,
        SUM(fv.valor_total_venda) AS receita_fornecedor
    FROM dw_tech_campaign.Fato_Vendas_Integrada fv
    JOIN dw_tech_campaign.Dim_Fornecedor df ON fv.sk_fornecedor = df.sk_fornecedor
    GROUP BY df.sk_fornecedor, df.nome_fornecedor, df.contato
)
SELECT 
    nome_fornecedor,
    contato,
    total_itens_negociados,
    receita_fornecedor,
    ROUND(receita_fornecedor * 100.0 / (SELECT SUM(valor_total_venda) FROM dw_tech_campaign.Fato_Vendas_Integrada), 2) AS percentual_concentracao_receita
FROM fornecedores_consolidado
ORDER BY receita_fornecedor DESC;
