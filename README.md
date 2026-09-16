# Data Warehouse & ETL: Integração de Silos e Áreas de Convergência

> **Disciplina:** Tópicos Especiais em Banco de Dados  
> **Instituição:** Universidade do Estado da Bahia (UNEB)  
> **Atividade 1:** Modelagem Dimensional, Pipeline de ETL e Análise de Dados (Casos 1 e 1.1)

---

## 📌 Visão Geral do Repositório

Este repositório reúne a implementação prática de **Engenharia de Dados, Modelagem Dimensional (Star Schema / Constelação de Fatos) e Business Intelligence (Metabase)** desenvolvida para a Atividade 1 da disciplina.

O projeto está estruturado em dois estudos de caso complementares:

1. **[Estudo de Caso 1](caso_1/):** Focado na consolidação do processo de **Vendas** a partir de três silos operacionais relacionais (`vendas_db`, `logistica_db`, `financeiro_db`) em um Data Warehouse analítico (`dw_vendas`).
2. **[Estudo de Caso 1.1](caso_1.1/):** Focado no mapeamento e integração de **8 Áreas de Convergência (A.C.)** e suas atividades operacionais em uma **Mega Campanha Promocional Tech (Black Friday / Flash Sale)** no Data Warehouse `dw_tech_campaign`.

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
├── caso_1/                             # Estudo de Caso 1: Vendas e Star Schema [100% CONCLUÍDO]
│   ├── CONTEXTO.md                     # Fundamentação teórica e regras de negócio
│   ├── CHECKLIST.md                    # Checklist com status de todas as fases (100%)
│   ├── solucao/                        # Scripts SQL oficiais e diagrama
│   │   ├── 01_criar_dw.sql             # DDL do banco dw_vendas
│   │   ├── 02_etl_carga.sql            # Pipeline de ETL resolvendo Surrogate Keys
│   │   ├── 03_consultas_analiticas.sql # 6 visões analíticas (3 obrigatórias + 3 executivas)
│   │   ├── diagrama_star_schema.png    # Diagrama em alta resolução (300 DPI)
│   │   └── diagrama_star_schema.puml   # Código-fonte em PlantUML
│
├── caso_1.1/                           # Estudo de Caso 1.1: Áreas de Convergência Tech [100% CONCLUÍDO]
│   ├── CONTEXTO.md                     # 8 A.C.s, Atividades, Métricas/KPIs e Conectores
│   ├── CHECKLIST.md                    # Roteiro de implementação passo a passo
│   ├── solucao/                        # Scripts SQL e pipeline dimensional
│   │   ├── 01_criar_dw_expandido.sql   # DDL do banco analítico dw_tech_campaign
│   │   ├── 02_etl_carga_integrada.sql  # Pipeline ETL unindo os 3 silos OLTP
│   │   └── 03_consultas_metricas_ac.sql# 8 queries analíticas para os KPIs das A.C.s
│   └── diagramas/                      # Artefatos visuais
│       ├── mapa_areas_convergencia.png # Diagrama de fluxo e conectores das 8 A.C.s
│       ├── mapa_areas_convergencia.puml
│       ├── star_schema_integrado.png   # Diagrama da Constelação de Fatos
│       └── star_schema_integrado.puml
│
└── docker/                             # Infraestrutura local compartilhada (Zero-Touch)
    ├── docker-compose.yml              # Orquestração do MySQL 8.0 (3306) + Metabase (3000)
    ├── README.md                       # Guia de inicialização e credenciais
    ├── metabase-data/                  # Base de metadados H2 com dashboards pré-configurados
    └── init/                           # Cargas automáticas executadas no primeiro boot
        ├── 01_oltp.sql                 # Silos operacionais (vendas_db, logistica_db, financeiro_db)
        ├── 02_dados_extras.sql         # 3.000 transações históricas (2024-2026) e 300 clientes
        ├── 03_criar_dw.sql             # Criação do banco analítico dw_vendas (Caso 1)
        ├── 04_etl_carga.sql            # Pipeline de carga inicial (Caso 1)
        ├── 05_criar_dw_expandido.sql   # Criação do DW dw_tech_campaign (Caso 1.1)
        └── 06_etl_carga_integrada.sql  # Pipeline de carga integrado (Caso 1.1)
```

---

## 🚀 Execução do Ambiente e Validação (Docker)

O ambiente foi configurado para inicialização **100% automatizada** via Docker Compose (ambos os DWs já sobem populados no primeiro boot):

```bash
cd docker/
docker compose up -d
```

- **MySQL 8.0:** Disponível na porta `localhost:3306` (usuário `root`, senha `root`).
- **Metabase BI:** Disponível em **[http://localhost:3000](http://localhost:3000)** (`cerveja123@gmail.com` / `cerveja123`).

### Como Executar as Consultas Analíticas:

#### Consultas do Estudo de Caso 1 (dw_vendas):
```bash
docker exec -i oltp_dw_mysql mysql -uroot -proot dw_vendas < caso_1/solucao/03_consultas_analiticas.sql
```

#### Consultas do Estudo de Caso 1.1 (dw_tech_campaign — 8 Áreas de Convergência):
```bash
docker exec -i oltp_dw_mysql mysql -uroot -proot dw_tech_campaign < caso_1.1/solucao/03_consultas_metricas_ac.sql
```

*(Caso queira recriar os DWs manualmente a qualquer momento, os scripts DDL e ETL continuam disponíveis nas respectivas pastas `caso_1/solucao/` e `caso_1.1/solucao/`).*

---

## 📊 Síntese Comparativa dos Casos de Estudo

| Critério | Caso 1 (Concluído) | Caso 1.1 (Concluído) |
|---|---|---|
| **Processo Central** | Venda de Produtos | Campanha Promocional Integrada (Black Friday Tech) |
| **Escopo** | Silos OLTP básicos $\rightarrow$ DW | 8 Áreas de Convergência integradas ponta a ponta |
| **Granularidade** | Transação individual de venda | Transação individual unindo Venda, Entrega, Pagamento e Fornecedor |
| **Tabelas Fato** | `Fato_Vendas` | `Fato_Vendas_Integrada` e `Fato_Despesas_Operacionais` |
| **Dimensões** | Tempo, Cliente, Produto | Tempo, Cliente, Produto, Fornecedor, Entrega, Pagamento |
| **Indicadores** | Faturamento por UF, Categoria, Período, Ticket Médio | OTIF, ROAS, Produtividade RH, Lead Time de Entrega, Ruptura, Margem Líquida |
| **Documentação** | [`caso_1/CONTEXTO.md`](caso_1/CONTEXTO.md) | [`caso_1.1/CONTEXTO.md`](caso_1.1/CONTEXTO.md) |
