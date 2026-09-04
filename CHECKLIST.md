# Checklist — Atividade 1: ETL & Data Warehouse

> Marque cada tarefa com `[x]` conforme for concluindo.  
> Consulte `CONTEXTO.md` para entender cada etapa em detalhe.

---

## Fase 0 — Preparação do Ambiente

- [ ] **0.1 — Abrir o material de apoio no browser**
  - Abrir `Estudo de Caso 1_v2.html` no navegador para ter o guia visual do professor.
  - Navegar pelas abas: Silos OLTP → Áreas de Convergência → Modelo Dimensional → Pipeline ETL → Roteiro do Aluno.

- [ ] **0.2 — Garantir acesso ao MySQL**
  - Ter MySQL rodando localmente (ou MySQL Workbench / DBeaver conectado).
  - Confirmar que o usuário tem permissão para `CREATE DATABASE`.

- [ ] **0.3 — Criar a pasta `solucao/`**
  - Criar a subpasta `atividade_1/solucao/` onde ficarão os scripts da entrega.

---

## Fase 1 — Carregar os Bancos Operacionais (OLTP)

- [ ] **1.1 — Executar o script OLTP fornecido**
  - Arquivo: `mysql_operational_dbs.sql`
  - Esse script cria e popula os 3 bancos de origem:
    - `vendas_db` → tabelas: `produtos`, `clientes`, `vendas`
    - `logistica_db` → tabelas: `fornecedores`, `estoque`, `entregas`
    - `financeiro_db` → tabelas: `pagamentos`, `despesas`
  - **Atenção:** não modificar esse arquivo, ele é fornecido pelo professor.
  - Como executar: `SOURCE mysql_operational_dbs.sql;` no MySQL CLI, ou importar pelo Workbench.

- [ ] **1.2 — Validar os dados carregados**
  - Confirmar que cada tabela tem 10 registros (conforme os INSERTs do script).
  - Consultas de validação:
    ```sql
    SELECT COUNT(*) FROM vendas_db.vendas;      -- esperado: 10
    SELECT COUNT(*) FROM vendas_db.clientes;    -- esperado: 10
    SELECT COUNT(*) FROM vendas_db.produtos;    -- esperado: 10
    ```

---

## Fase 2 — Criar o Data Warehouse (DDL)

> Arquivo a criar: `solucao/01_criar_dw.sql`

- [ ] **2.1 — Criar o banco `dw_vendas`**
  - Criar um banco de dados separado chamado `dw_vendas`.
  - Esse banco representará o Data Warehouse, isolado dos bancos operacionais.

- [ ] **2.2 — Criar a tabela `Dim_Tempo`**
  - Derivada das datas de venda do OLTP.
  - Campos: `sk_tempo` (PK auto_increment), `data_completa`, `dia`, `mes`, `nome_mes`, `trimestre`, `ano`.
  - A `sk_tempo` é uma **surrogate key** — não usa o ID do banco de origem, é gerada pelo DW.

- [ ] **2.3 — Criar a tabela `Dim_Cliente`**
  - Derivada de `vendas_db.clientes`.
  - Campos: `sk_cliente` (PK), `id_cliente_origem`, `nome_cliente`, `cidade`, `estado`.
  - O campo `id_cliente_origem` mantém o ID original para rastreabilidade.

- [ ] **2.4 — Criar a tabela `Dim_Produto`**
  - Derivada de `vendas_db.produtos`.
  - Campos: `sk_produto` (PK), `id_produto_origem`, `nome_produto`, `categoria`, `preco`.

- [ ] **2.5 — Criar a tabela `Fato_Vendas`**
  - Tabela central do Star Schema.
  - Campos: `id_fato` (PK), `sk_cliente` (FK), `sk_produto` (FK), `sk_tempo` (FK), `quantidade`, `valor_total`.
  - As FKs referenciam as surrogate keys das dimensões, não os IDs do OLTP.

---

## Fase 3 — ETL: Extração, Transformação e Carga

> Arquivo a criar: `solucao/02_etl_carga.sql`

- [ ] **3.1 — Carregar `Dim_Tempo`**
  - **Extração:** selecionar datas únicas de `vendas_db.vendas.data_venda`.
  - **Transformação:** decompor a data em `dia`, `mes`, `nome_mes` (MONTHNAME), `trimestre` (QUARTER), `ano` (YEAR).
  - **Carga:** inserir no `dw_vendas.Dim_Tempo` com `INSERT INTO ... SELECT DISTINCT`.

- [ ] **3.2 — Carregar `Dim_Cliente`**
  - **Extração:** selecionar todos os clientes de `vendas_db.clientes`.
  - **Transformação:** copiar os campos diretamente (nenhuma transformação complexa necessária).
  - **Carga:** inserir no `dw_vendas.Dim_Cliente`, preservando o `id_cliente` como `id_cliente_origem`.

- [ ] **3.3 — Carregar `Dim_Produto`**
  - **Extração:** selecionar todos os produtos de `vendas_db.produtos`.
  - **Transformação:** copiar os campos diretamente.
  - **Carga:** inserir no `dw_vendas.Dim_Produto`, preservando o `id_produto` como `id_produto_origem`.

- [ ] **3.4 — Carregar `Fato_Vendas`**
  - **Extração:** selecionar de `vendas_db.vendas`.
  - **Transformação (passo crítico):** fazer JOIN com as três dimensões para **resolver as surrogate keys**:
    - `id_cliente` → buscar o `sk_cliente` correspondente em `Dim_Cliente`
    - `id_produto` → buscar o `sk_produto` correspondente em `Dim_Produto`
    - `data_venda` → buscar o `sk_tempo` correspondente em `Dim_Tempo`
  - **Carga:** inserir no `dw_vendas.Fato_Vendas` com os SKs resolvidos.
  - Isso representa o **coração do ETL**: substituir as chaves naturais do OLTP pelas surrogate keys do DW.

- [ ] **3.5 — Validar a carga**
  - Confirmar que `Fato_Vendas` tem 10 registros (1 por venda do OLTP).
  - Verificar que nenhuma FK ficou nula.
    ```sql
    SELECT COUNT(*) FROM dw_vendas.Fato_Vendas;           -- esperado: 10
    SELECT * FROM dw_vendas.Fato_Vendas WHERE sk_cliente IS NULL; -- esperado: vazio
    ```

---

## Fase 4 — Consultas Analíticas (as 3 visões exigidas)

> Arquivo a criar: `solucao/03_consultas_analiticas.sql`
>
> Todas as queries devem rodar contra `dw_vendas`, não contra os bancos OLTP.

- [ ] **4.1 — Visão 1: Total de Vendas por Estado**
  - Fazer JOIN de `Fato_Vendas` com `Dim_Cliente`.
  - Agrupar por `estado`.
  - Retornar: `estado`, `total_itens` (SUM de quantidade), `faturamento_total` (SUM de valor_total).
  - Ordenar por `faturamento_total` decrescente.

- [ ] **4.2 — Visão 2: Total de Vendas por Categoria de Produto**
  - Fazer JOIN de `Fato_Vendas` com `Dim_Produto`.
  - Agrupar por `categoria`.
  - Retornar: `categoria`, `total_itens`, `faturamento_total`.
  - Ordenar por `faturamento_total` decrescente.

- [ ] **4.3 — Visão 3: Faturamento por Período (Mês/Ano)**
  - Fazer JOIN de `Fato_Vendas` com `Dim_Tempo`.
  - Agrupar por `ano` e `mes`.
  - Retornar: `ano`, `mes`, `nome_mes`, `total_itens`, `faturamento_total`.
  - Ordenar cronologicamente.

---

## Fase 5 — Diagrama Star Schema (entrega visual)

- [ ] **5.1 — Escolher a ferramenta de diagramação**
  - Opções recomendadas:
    - **dbdiagram.io** → online, gratuito, exporta PNG/PDF, específico para diagramas de BD
    - **draw.io (diagrams.net)** → online e desktop, mais flexível
    - **MySQL Workbench** → EER Diagram a partir do banco criado

- [ ] **5.2 — Representar as 4 tabelas no diagrama**
  - `Dim_Tempo`, `Dim_Cliente`, `Dim_Produto` e `Fato_Vendas`.
  - Mostrar todos os campos de cada tabela.
  - Indicar PK e FKs.

- [ ] **5.3 — Representar os relacionamentos**
  - Linhas de relacionamento de `Fato_Vendas` para cada dimensão (cardinalidade N:1).

- [ ] **5.4 — Exportar o diagrama**
  - Salvar como imagem (PNG ou PDF) em `solucao/diagrama_star_schema.png`.

---

## Fase 6 — Revisão Final

- [ ] **6.1 — Executar tudo do zero em sequência**
  - Rodar `mysql_operational_dbs.sql` → `01_criar_dw.sql` → `02_etl_carga.sql` → `03_consultas_analiticas.sql`
  - Confirmar que nenhuma etapa gera erro.

- [ ] **6.2 — Verificar os resultados das 3 visões analíticas**
  - Visão 1 deve retornar 10 linhas (1 por estado/cliente, sem agrupamentos duplicados)
  - Visão 2 deve retornar 4 categorias: Eletrônicos, Acessórios, Componentes, Móveis
  - Visão 3 deve retornar 1 linha (todos os dados são de janeiro/2024)

- [ ] **6.3 — Revisar os arquivos da entrega**
  - `solucao/01_criar_dw.sql` ✓
  - `solucao/02_etl_carga.sql` ✓
  - `solucao/03_consultas_analiticas.sql` ✓
  - `solucao/diagrama_star_schema.png` ✓

---

## Resumo do que será entregue

| Arquivo | Conteúdo |
|---|---|
| `solucao/01_criar_dw.sql` | DDL completo do banco `dw_vendas` (4 tabelas) |
| `solucao/02_etl_carga.sql` | Script ETL de carga das dimensões e da fato |
| `solucao/03_consultas_analiticas.sql` | 3 queries analíticas sobre o DW |
| `solucao/diagrama_star_schema.png` | Diagrama visual do Star Schema |
