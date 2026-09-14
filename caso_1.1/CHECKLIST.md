# Checklist — Estudo de Caso 1.1: Áreas de Convergência & DW Integrado

> **Disciplina:** Tópicos Especiais em Banco de Dados (UNEB)  
> **Tema:** E-commerce Tech — Áreas de Convergência (A.C.), Atividades Operacionais, Métricas e DW  
> Marque cada tarefa com `[x]` conforme for concluindo. Consulte `CONTEXTO.md` para o detalhamento teórico.

---

## Fase 0 — Organização e Estruturação do Projeto

- [x] **0.1 — Reestruturação Modular do Repositório**
  - Criação da separação simétrica entre `caso_1/` e `caso_1.1/`.
  - Reorganização de materiais de apoio em `materiais/caso_1/` e `materiais/caso_1.1/`.
  - Preservação do histórico de commits via `git mv`.

- [x] **0.2 — Definição do Escopo do Caso 1.1**
  - Adaptação do exemplo didático da lousa para o banco real de Tecnologia/Hardware.
  - Definição do tema: *"Mega Campanha Promocional Tech (Black Friday / Flash Sale)"*.
  - Criação do documento estruturante [`caso_1.1/CONTEXTO.md`](CONTEXTO.md).

---

## Fase 1 — Formalização das Áreas, Atividades e Métricas (Tarefa 1)

- [x] **1.1 — Mapeamento das 8 Áreas de Convergência (A.C.)**
  - 1. Gerência Geral $\rightarrow$ Atividade: Monitoramento de Eficiência Geral e Torre de Controle.
  - 2. RH $\rightarrow$ Atividade: Dimensionamento da Equipe de Expedição e Suporte.
  - 3. Marketing $\rightarrow$ Atividade: Gestão de Campanhas de Tráfego e Conversão Tech.
  - 4. Logística Externa $\rightarrow$ Atividade: Expedição e Gestão de Despacho de Entregas.
  - 5. Logística Interna $\rightarrow$ Atividade: Abastecimento e Entrada de Fornecedores de Hardware.
  - 6. Produção / Operações $\rightarrow$ Atividade: Gestão de Estoque e Prevenção de Ruptura.
  - 7. Finanças $\rightarrow$ Atividade: Conciliação Financeira e Margem Líquida.
  - 8. Comercial $\rightarrow$ Atividade: Homologação e Negociação com Fornecedores Parceiros.

- [x] **1.2 — Definição das Características de Desempenho (Métricas/KPIs)**
  - Métrica da Gerência Geral: Taxa OTIF (% On-Time In-Full).
  - Métrica do RH: Produtividade Operacional por Colaborador de Expedição.
  - Métrica do Marketing: ROAS (Return on Ad Spend) da Campanha Tech.
  - Métrica da Logística Externa: Lead Time Médio de Entrega em dias e Pontualidade por UF.
  - Métrica da Logística Interna: Tempo Médio de Reposição de Fornecedores (Lead Time de Entrada).
  - Métrica da Produção/Operações: Taxa de Ruptura de Estoque (% Stockout).
  - Métrica de Finanças: Margem de Contribuição Líquida (R$ e %).
  - Métrica do Comercial: Índice de Concentração de Fornecimento (Volume por Fornecedor).

---

## Fase 2 — Mapeamento de Integrações entre Áreas (Tarefa 2)

- [x] **2.1 — Matriz de Conectores e Fluxos de Dados**
  - Mapear conectores entre os silos: `id_venda`, `id_produto`, `id_fornecedor`, `id_cliente`.
  - Definir eventos disparadores (fechamento comercial, recebimento em doca, aprovação de pagamento, despacho e entrega).
  - Tabela de conectores e gatilhos documentada em [`CONTEXTO.md`](CONTEXTO.md).

- [ ] **2.2 — Geração do Diagrama Visual de Áreas de Convergência**
  - Desenhar o mapa conceitual de fluxo e interações em PlantUML (`diagramas/mapa_areas_convergencia.puml`).
  - Exportar imagem em alta resolução (`diagramas/mapa_areas_convergencia.png`).

---

## Fase 3 — Modelagem do Data Warehouse Integrado (Tarefa 3)

- [ ] **3.1 — Especificação do Modelo Dimensional Alvo**
  - Avaliar tabelas de dimensão necessárias:
    - `Dim_Tempo` (data, dia, mês, trimestre, ano, sazonalidade).
    - `Dim_Cliente` (estado, cidade, nome).
    - `Dim_Produto` (categoria, nome, faixa de preço).
    - `Dim_Fornecedor` (nome, contato, linha de suprimento).
    - `Dim_Entrega` (status, prazo limite).
    - `Dim_Pagamento` (método de pagamento).
  - Especificação das Tabelas Fato:
    - **`Fato_Vendas_Integrada` (Central):**
      - Surrogate Keys (FKs): `sk_cliente`, `sk_produto`, `sk_fornecedor`, `sk_tempo_venda`, `sk_tempo_entrega`, `sk_tempo_pagamento`, `sk_entrega`, `sk_pagamento`.
      - Métricas e Fatos: `quantidade`, `valor_total_venda`, `valor_pago`, `dias_para_entrega`, `flag_entregue_no_prazo`.
    - **`Fato_Despesas_Operacionais` (Apoio Financeiro):**
      - Campos: `id_despesa_fato`, `sk_tempo`, `tipo_despesa`, `descricao`, `valor_despesa`.

- [ ] **3.2 — Criação do Script DDL (`solucao/01_criar_dw_expandido.sql`)**
  - Criar o banco `dw_tech_campaign` (ou extensão de `dw_vendas`).
  - DDL com todas as tabelas de dimensões, chaves primárias (`AUTO_INCREMENT`), índices e constraints.

- [ ] **3.3 — Diagrama do Esquema Estrela Integrado**
  - Código em PlantUML (`diagramas/star_schema_integrado.puml`).
  - Exportação em PNG de alta resolução (`diagramas/star_schema_integrado.png`).

---

## Fase 4 — Pipeline ETL: Extração, Transformação e Carga (Tarefa 3)

- [ ] **4.1 — Extração e Carga das Dimensões**
  - Carga da `Dim_Tempo` a partir de `vendas_db.vendas` e `logistica_db.entregas`.
  - Carga da `Dim_Cliente` a partir de `vendas_db.clientes`.
  - Carga da `Dim_Produto` a partir de `vendas_db.produtos`.
  - Carga da `Dim_Fornecedor` a partir de `logistica_db.fornecedores`.
  - Carga da `Dim_Entrega` a partir de `logistica_db.entregas`.
  - Carga da `Dim_Pagamento` a partir de `financeiro_db.pagamentos`.

- [ ] **4.2 — Carga da Tabela Fato com Resolução de Surrogate Keys**
  - Script com múltiplos `INNER JOIN` / `LEFT JOIN` unindo os 3 bancos operacionais (`vendas_db`, `logistica_db`, `financeiro_db`).
  - Resolução de todas as SKs sem deixar campos nulos.
  - Cálculo de métricas pré-agregadas (dias de entrega, flag de pontualidade).

- [ ] **4.3 — Validação de Integridade do ETL (`solucao/02_etl_carga_integrada.sql`)**
  - Queries de conferência de contagem de linhas e verificação de integridade referencial.

---

## Fase 5 — Consultas Analíticas das 8 Áreas de Convergência (Tarefa 3)

> Arquivo: `solucao/03_consultas_metricas_ac.sql`

- [ ] **5.1 — Query KPI 1 (Gerência Geral):** Taxa OTIF (% On-Time In-Full global).
- [ ] **5.2 — Query KPI 2 (RH):** Produtividade da Equipe de Expedição.
- [ ] **5.3 — Query KPI 3 (Marketing):** ROAS da Campanha Tech (Faturamento vs. Despesas de Mkt).
- [ ] **5.4 — Query KPI 4 (Logística Externa):** Lead Time Médio de Entrega e Pontualidade por UF.
- [ ] **5.5 — Query KPI 5 (Logística Interna):** Tempo Médio de Reposição por Fornecedor (Lead Time de Entrada).
- [ ] **5.6 — Query KPI 6 (Produção/Operações):** Taxa de Ruptura de Estoque por Categoria de Produto.
- [ ] **5.7 — Query KPI 7 (Finanças):** Margem de Contribuição Líquida por Linha de Produto.
- [ ] **5.8 — Query KPI 8 (Comercial):** Grau de Concentração de Fornecimento por Fornecedor Parceiro.

---

## Fase 6 — Revisão Final, Documentação e Commit

- [ ] **6.1 — Validação Ponta a Ponta**
  - Execução dos scripts SQL em ordem e conferência dos resultados.
- [ ] **6.2 — Atualização do `README.md` Principal**
  - Documentação da entrega do Caso 1 e Caso 1.1 na raiz do repositório.
- [ ] **6.3 — Commit e Sincronização no GitHub**
  - Commit estruturado no git seguindo convenção SemVer / Conventional Commits.
