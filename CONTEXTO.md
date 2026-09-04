# Contexto do Projeto — Atividade 1

**Disciplina:** Tópicos Especiais em Banco de Dados  
**Instituição:** UNEB  
**Tema:** Integração de Bancos de Dados Operacionais, ETL & Data Warehouse

---

## 1. Objetivo da Atividade

Aplicar os conceitos de **modelagem dimensional** e **ETL** para estruturar um Data Warehouse
(DW) a partir de bancos de dados operacionais relacionais.

Os conceitos centrais trabalhados são:
- Orientação por assunto
- Integração de dados heterogêneos
- Não-volatilidade
- Variação temporal
- Star Schema (Esquema Estrela)

---

## 2. Arquivos Fornecidos pelo Professor

| Arquivo | Descrição |
|---|---|
| `mysql_operational_dbs.sql` | Script DDL+DML dos 3 bancos OLTP de origem |
| `instrucoes.txt` | Enunciado com objetivos, dimensões e métricas esperadas |
| `Estudo de Caso 1_v2.html` | Material de apoio com diagrama, regras ETL e roteiro do aluno |

---

## 3. Bancos de Dados Operacionais (Fontes OLTP)

O script `mysql_operational_dbs.sql` cria e popula **3 bancos isolados**:

### 3.1 `vendas_db` — Sistema Comercial (FONTE PRINCIPAL)

```
produtos
  ├── id_produto (PK)
  ├── nome_produto
  ├── categoria
  └── preco

clientes
  ├── id_cliente (PK)
  ├── nome_cliente
  ├── cidade
  └── estado

vendas
  ├── id_venda (PK)
  ├── id_cliente (FK → clientes)
  ├── id_produto (FK → produtos)
  ├── data_venda
  ├── quantidade
  └── valor_total
```

### 3.2 `logistica_db` — Estoque e Entregas

```
fornecedores
  ├── id_fornecedor (PK)
  ├── nome_fornecedor
  └── contato

estoque
  ├── id_estoque (PK)
  ├── id_produto     (FK EXTERNA → vendas_db.produtos)
  ├── id_fornecedor  (FK → fornecedores)
  ├── quantidade_disponivel
  └── data_ultima_entrada

entregas
  ├── id_entrega (PK)
  ├── id_venda   (FK EXTERNA → vendas_db.vendas)
  ├── data_entrega
  └── status_entrega  ('Entregue' | 'Em Trânsito' | 'Pendente')
```

### 3.3 `financeiro_db` — Pagamentos e Despesas

```
pagamentos
  ├── id_pagamento (PK)
  ├── id_venda     (FK EXTERNA → vendas_db.vendas)
  ├── data_pagamento
  ├── valor_pago
  └── metodo_pagamento  ('Pix' | 'Cartão de Crédito' | 'Cartão de Débito' | 'Boleto')

despesas
  ├── id_despesa (PK)
  ├── descricao
  ├── valor
  ├── data_despesa
  └── tipo_despesa  ('Fixa' | 'Variável')
```

### 3.4 Conectores entre os bancos

| Conector | Chave | Liga |
|---|---|---|
| 1 | `id_venda` | `vendas_db.vendas` ↔ `logistica_db.entregas` ↔ `financeiro_db.pagamentos` |
| 2 | `id_produto` | `vendas_db.produtos` ↔ `logistica_db.estoque` |

---

## 4. Processo de Negócio a Modelar

**Processo central:** Venda de Produtos

**Granularidade:** Cada registro individual de venda (nível de transação por cliente e produto).

---

## 5. Modelo Dimensional Alvo (Star Schema)

O Data Warehouse será criado em um novo banco chamado `dw_vendas`.

### Dimensões

| Tabela | Chave | Atributos | Fonte |
|---|---|---|---|
| `Dim_Tempo` | `sk_tempo` | `data_completa`, `dia`, `mes`, `nome_mes`, `trimestre`, `ano` | Derivada de `vendas.data_venda` |
| `Dim_Cliente` | `sk_cliente` | `id_cliente_origem`, `nome_cliente`, `cidade`, `estado` | `vendas_db.clientes` |
| `Dim_Produto` | `sk_produto` | `id_produto_origem`, `nome_produto`, `categoria`, `preco` | `vendas_db.produtos` |

### Fato

| Tabela | FKs | Métricas | Fonte |
|---|---|---|---|
| `Fato_Vendas` | `sk_cliente`, `sk_produto`, `sk_tempo` | `quantidade`, `valor_total` | `vendas_db.vendas` |

### Diagrama (ASCII)

```
       ┌───────────────────┐
       │    Dim_Tempo      │
       │───────────────────│
       │ sk_tempo (PK)     │
       │ data_completa     │
       │ dia               │
       │ mes               │
       │ nome_mes          │
       │ trimestre         │
       │ ano               │
       └────────┬──────────┘
                │ FK
┌───────────────┼───────────────────────────────────┐
│               ▼                                   │
│  ┌────────────────────────┐                       │
│  │     Fato_Vendas        │                       │
│  │────────────────────────│    ┌────────────────┐ │
│  │ id_fato (PK)           │    │  Dim_Produto   │ │
│  │ sk_cliente (FK) ───────┼──┐ │────────────────│ │
│  │ sk_produto (FK) ───────┼──┼►│ sk_produto(PK) │ │
│  │ sk_tempo   (FK)        │  │ │ id_prod_origem │ │
│  │────────────────────────│  │ │ nome_produto   │ │
│  │ quantidade   [MÉTRICA] │  │ │ categoria      │ │
│  │ valor_total  [MÉTRICA] │  │ │ preco          │ │
│  └────────────────────────┘  │ └────────────────┘ │
│                              │                    │
│  ┌───────────────────────┐   │                    │
│  │    Dim_Cliente        │◄──┘                    │
│  │───────────────────────│                        │
│  │ sk_cliente (PK)       │                        │
│  │ id_cli_origem         │                        │
│  │ nome_cliente          │                        │
│  │ cidade                │                        │
│  │ estado                │                        │
│  └───────────────────────┘                        │
└───────────────────────────────────────────────────┘
```

---

## 6. Visões Analíticas Exigidas

As consultas devem ser executadas **contra o DW** (dw_vendas), não contra o banco operacional.

| # | Visão | Agrupamento | Métricas |
|---|---|---|---|
| 1 | Vendas por Estado | `Dim_Cliente.estado` | `SUM(quantidade)`, `SUM(valor_total)` |
| 2 | Vendas por Categoria | `Dim_Produto.categoria` | `SUM(quantidade)`, `SUM(valor_total)` |
| 3 | Faturamento por Período | `Dim_Tempo.ano`, `Dim_Tempo.mes` | `SUM(quantidade)`, `SUM(valor_total)` |

---

## 7. Conceitos-Chave

| Conceito | Significado no projeto |
|---|---|
| **OLTP** | Bancos operacionais de origem (`vendas_db`, `logistica_db`, `financeiro_db`) |
| **OLAP / DW** | Banco analítico de destino (`dw_vendas`) |
| **ETL** | Extração dos dados OLTP → Transformação → Carga no DW |
| **Star Schema** | Modelo com 1 tabela fato central ligada a tabelas dimensão |
| **Surrogate Key (SK)** | Chave substituta gerada no DW (desacoplada do ID de origem) |
| **Granularidade** | Nível de detalhe do fato — aqui é 1 linha por transação de venda |
| **Dimensão** | Tabela de contexto (quem, o quê, quando) |
| **Fato** | Tabela de métricas numéricas (quanto, quantos) |

---

## 8. Estrutura de Arquivos do Projeto

```
atividade_1/
├── Estudo de Caso 1_v2.html         # Material de apoio do professor (visualizar no browser)
├── instrucoes.txt                   # Enunciado oficial da atividade
├── mysql_operational_dbs.sql        # Script dos bancos OLTP (NÃO MODIFICAR)
│
├── CONTEXTO.md                      # Este arquivo — contexto e referência do projeto
├── CHECKLIST.md                     # Tarefas passo a passo com status
│
└── solucao/                         # (a criar) Scripts da solução
    ├── 01_criar_dw.sql              # DDL do banco dw_vendas
    ├── 02_etl_carga.sql             # ETL: carga das dimensões e da fato
    └── 03_consultas_analiticas.sql  # 3 visões analíticas exigidas
```
