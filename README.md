# Data Warehouse & ETL: Integração de Silos e Áreas de Convergência

> **Disciplina:** Tópicos Especiais em Banco de Dados  
> **Instituição:** Universidade do Estado da Bahia (UNEB)  
> **Atividade 1:** Modelagem Dimensional, Pipeline de ETL e Análise de Dados (Casos 1 e 1.1)

---

## 📌 Visão Geral do Repositório

Este repositório reúne a implementação prática de **Engenharia de Dados, Modelagem Dimensional (Star Schema) e Business Intelligence (Metabase)** desenvolvida para a Atividade 1 da disciplina.

O projeto está estruturado em dois estudos de caso complementares:

1. **[Estudo de Caso 1](caso_1/):** Focado na consolidação do processo de **Vendas** a partir de três silos operacionais relacionais (`vendas_db`, `logistica_db`, `financeiro_db`) em um Data Warehouse analítico (`dw_vendas`).
2. **[Estudo de Caso 1.1](caso_1.1/):** Focado no mapeamento e integração de **8 Áreas de Convergência (A.C.)** e suas atividades operacionais em uma **Mega Campanha Promocional Tech (Black Friday / Flash Sale)** de alta demanda concorrente.

---

## 📁 Estrutura Modular do Projeto

```
atividade_1/
├── README.md                           # Visão geral e índice mestre (este arquivo)
│
├── materiais/                          # Referências e enunciados do professor
│   ├── caso_1/                         # HTML interativo, instrucoes_caso_1.txt, mysql_operational_dbs.sql
│   └── caso_1.1/                       # Documento docx, estudo_de_caso_1.1.md, anotacoes_quadro.md
│
├── caso_1/                             # Estudo de Caso 1: Vendas e Star Schema [CONCLUÍDO]
│   ├── CONTEXTO.md                     # Fundamentação teórica e regras de negócio
│   ├── CHECKLIST.md                    # Checklist com status de todas as fases (100%)
│   ├── solucao/                        # Scripts SQL oficiais e diagrama
│   │   ├── 01_criar_dw.sql             # DDL do banco dw_vendas
│   │   ├── 02_etl_carga.sql            # Pipeline de ETL resolvendo Surrogate Keys
│   │   ├── 03_consultas_analiticas.sql # 6 visões analíticas (3 obrigatórias + 3 executivas)
│   │   ├── diagrama_star_schema.png    # Diagrama em alta resolução (300 DPI)
│   │   └── diagrama_star_schema.puml   # Código-fonte em PlantUML
│
├── caso_1.1/                           # Estudo de Caso 1.1: Áreas de Convergência Tech [EM ANDAMENTO]
│   ├── CONTEXTO.md                     # 8 A.C.s, Atividades, Métricas/KPIs e Conectores
│   ├── CHECKLIST.md                    # Roteiro de implementação passo a passo
│   ├── solucao/                        # Scripts SQL expandidos e cargas
│   └── diagramas/                      # Mapa das 8 A.C.s e Esquema Estrela Integrado
│
└── docker/                             # Infraestrutura local compartilhada (Zero-Touch)
    ├── docker-compose.yml              # Orquestração do MySQL 8.0 (3306) + Metabase (3000)
    ├── README.md                       # Guia de inicialização e credenciais
    ├── metabase-data/                  # Base de metadados H2 com dashboards pré-configurados
    └── init/                           # Cargas automáticas executadas no primeiro boot
        ├── 01_oltp.sql                 # Silos operacionais (vendas_db, logistica_db, financeiro_db)
        ├── 02_dados_extras.sql         # 3.000 transações históricas (2024-2026) e 300 clientes
        ├── 03_criar_dw.sql             # Criação do banco analítico dw_vendas
        └── 04_etl_carga.sql            # Pipeline de carga inicial
```

---

## 🚀 Execução Rápida do Ambiente (Docker)

O ambiente foi configurado para inicialização **100% automatizada** via Docker Compose:

```bash
cd docker/
docker compose up -d
```

- **MySQL 8.0:** Disponível na porta `localhost:3306` (usuário `root`, senha `root`).
- **Metabase BI:** Disponível em **[http://localhost:3000](http://localhost:3000)**.
  - **Login:** `cerveja123@gmail.com`
  - **Senha:** `cerveja123`

---

## 📊 Síntese dos Casos de Estudo

| Critério | Caso 1 (Concluído) | Caso 1.1 (Em Andamento) |
|---|---|---|
| **Processo Central** | Venda de Produtos | Campanha Promocional Integrada (Black Friday Tech) |
| **Escopo** | Silos OLTP básicos $\rightarrow$ DW | 8 Áreas de Convergência integradas ponta a ponta |
| **Granularidade** | Transação individual de venda | Pedido, expedição e abastecimento com métricas de tempo e custo |
| **Indicadores** | Faturamento por UF, Categoria, Período, Ticket Médio | OTIF, ROAS, Produtividade RH, Lead Time de Entrega, Ruptura, Margem Líquida |
| **Documentação** | [`caso_1/CONTEXTO.md`](caso_1/CONTEXTO.md) | [`caso_1.1/CONTEXTO.md`](caso_1.1/CONTEXTO.md) |
