-- ====================================================================
-- Atividade 1.1: Consultas Analíticas das 8 Áreas de Convergência (OLAP)
-- Banco Analítico: dw_tech_campaign (Data Warehouse Integrado)
-- Padrão de Excelência: Fórmulas de Negócio, CTEs e Métricas Reais de Operação
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
-- KPI: Lead Time Médio de Entrega, Modalidade e Pontualidade por UF
-- Objetivo: Monitorar tempo de trânsito por modalidade (Expressa vs Padrão) e por estado.
-- ====================================================================
SELECT 
    dc.estado AS uf,
    de.modalidade_frete,
    COUNT(fv.id_fato_venda) AS total_pedidos,
    ROUND(AVG(fv.dias_para_entrega), 1) AS lead_time_medio_dias,
    MIN(fv.dias_para_entrega) AS lead_time_minimo_dias,
    MAX(fv.dias_para_entrega) AS lead_time_maximo_dias,
    SUM(CASE WHEN fv.flag_entregue_no_prazo = TRUE THEN 1 ELSE 0 END) AS entregas_no_prazo,
    ROUND(SUM(CASE WHEN fv.flag_entregue_no_prazo = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(fv.id_fato_venda), 2) AS taxa_pontualidade_pct
FROM dw_tech_campaign.Fato_Vendas_Integrada fv
JOIN dw_tech_campaign.Dim_Cliente dc ON fv.sk_cliente = dc.sk_cliente
JOIN dw_tech_campaign.Dim_Entrega de ON fv.sk_entrega = de.sk_entrega
GROUP BY dc.estado, de.modalidade_frete
ORDER BY uf ASC, taxa_pontualidade_pct DESC;


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
-- 6. PRODUÇÃO / OPERAÇÕES (Atividade 6.1 — Gestão de Estoque e Ruptura Real)
-- KPI: Taxa Real de Ruptura de Estoque (% Stockout) e Cobertura por Categoria
-- Objetivo: Confrontar o saldo físico remanescente no armazém contra o limiar de
--           segurança (50 un) e apurar o índice de produtos em ruptura/risco crítico.
-- ====================================================================
WITH produtos_status AS (
    SELECT 
        dp.sk_produto,
        dp.nome_produto,
        dp.categoria,
        dp.quantidade_estoque_disponivel AS saldo_estoque_atual,
        dp.estoque_minimo_seguranca,
        SUM(fv.quantidade) AS total_unidades_demandadas,
        CASE 
            WHEN dp.quantidade_estoque_disponivel = 0 THEN 'Ruptura Total (Esgotado)'
            WHEN dp.quantidade_estoque_disponivel <= dp.estoque_minimo_seguranca THEN 'Estoque Crítico (Risco Alto)'
            ELSE 'Estoque Regular'
        END AS situacao_estoque,
        CASE 
            WHEN dp.quantidade_estoque_disponivel <= dp.estoque_minimo_seguranca THEN 1 
            ELSE 0 
        END AS flag_em_risco_ruptura
    FROM dw_tech_campaign.Dim_Produto dp
    LEFT JOIN dw_tech_campaign.Fato_Vendas_Integrada fv ON dp.sk_produto = fv.sk_produto
    GROUP BY dp.sk_produto, dp.nome_produto, dp.categoria, dp.quantidade_estoque_disponivel, dp.estoque_minimo_seguranca
)
SELECT 
    categoria,
    COUNT(sk_produto) AS total_modelos_ativos,
    SUM(total_unidades_demandadas) AS demanda_total_vendida,
    SUM(saldo_estoque_atual) AS saldo_total_em_armazem,
    SUM(flag_em_risco_ruptura) AS modelos_em_risco_ou_ruptura,
    ROUND(SUM(flag_em_risco_ruptura) * 100.0 / COUNT(sk_produto), 2) AS taxa_ruptura_percentual,
    ROUND(SUM(saldo_estoque_atual) * 1.0 / NULLIF(SUM(total_unidades_demandadas), 0), 2) AS razao_cobertura_estoque_demanda
FROM produtos_status
GROUP BY categoria
ORDER BY taxa_ruptura_percentual DESC, demanda_total_vendida DESC;


-- ====================================================================
-- 7. FINANÇAS (Atividade 7.1 — Conciliação Financeira e Margem de Contribuição)
-- KPI: Volume Liquidado por Método, Tipo de Liquidação e Parcelamento
-- Objetivo: Avaliar liquidez imediata (D+0) vs capital a receber a prazo (D+30).
-- ====================================================================
SELECT 
    dpg.metodo_pagamento,
    dpg.tipo_liquidacao,
    dpg.permite_parcelamento,
    COUNT(fv.id_fato_venda) AS total_transacoes,
    SUM(fv.valor_total_venda) AS faturamento_bruto,
    SUM(fv.valor_pago) AS total_liquidado_em_caixa,
    ROUND(SUM(fv.valor_pago) * 100.0 / (SELECT SUM(valor_pago) FROM dw_tech_campaign.Fato_Vendas_Integrada), 2) AS participacao_no_caixa_pct,
    ROUND(AVG(fv.valor_total_venda), 2) AS ticket_medio_transacao
FROM dw_tech_campaign.Fato_Vendas_Integrada fv
JOIN dw_tech_campaign.Dim_Pagamento dpg ON fv.sk_pagamento = dpg.sk_pagamento
GROUP BY dpg.metodo_pagamento, dpg.tipo_liquidacao, dpg.permite_parcelamento
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
