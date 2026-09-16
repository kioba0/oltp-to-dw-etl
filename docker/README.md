# Ambiente Docker — MySQL + Metabase

Sobe o banco de dados MySQL e o Metabase integrados via Docker Compose, com inicialização e carga analítica **100% automatizadas**.

## Pré-requisitos

- Docker instalado e rodando
- Docker Compose v2+

## Como usar

### 1. Subir o ambiente

```bash
# A partir da pasta docker/
docker compose up -d
```

Na **primeira execução**, o container MySQL executa automaticamente em ordem todos os scripts da pasta `init/`:
1. `init/01_oltp.sql`: Cria e popula os 3 bancos operacionais transacionais (`vendas_db`, `logistica_db`, `financeiro_db`).
2. `init/02_dados_extras.sql`: Carrega volume histórico complementar (3.000 vendas adicionais de 2024 a 2026 e 300 clientes).
3. `init/03_criar_dw.sql`: Cria o Data Warehouse `dw_vendas` (Caso 1) e a estrutura do Star Schema (dimensões e fato).
4. `init/04_etl_carga.sql`: Executa o pipeline ETL do Caso 1, carregando o `dw_vendas`.
5. `init/05_criar_dw_expandido.sql`: Cria o DW `dw_tech_campaign` (Caso 1.1) e o modelo em Constelação de Fatos.
6. `init/06_etl_carga_integrada.sql`: Executa o pipeline ETL integrado do Caso 1.1, resolvendo todas as SKs sem nulos.

> [!NOTE]
> Nenhum script DDL ou de carga precisa ser executado manualmente para subir a aplicação: tudo sobe pronto, consistente e integrado ao Metabase.

### 2. Acompanhar os logs

```bash
docker compose logs -f
```

Aguarde o Metabase aparecer como `Started` antes de abrir o navegador.

### 3. Acessar o Metabase

Abrir no navegador: **http://localhost:3000**

O ambiente já vem **pré-configurado com a conexão ao Data Warehouse e os gráficos do dashboard prontos**!

**Credenciais de Acesso:**
- **E-mail:** `cerveja123@gmail.com`
- **Senha:** `cerveja123`

---

### 4. Conectar o Metabase ao MySQL (Já configurado para dw_vendas)

A conexão com o `dw_vendas` já está salva na base versionada do Metabase (`metabase-data/`). Caso precise criar a conexão com o `dw_tech_campaign` (Caso 1.1):

| Campo | Valor (Caso 1) | Valor (Caso 1.1) |
|---|---|---|
| Tipo de banco | MySQL | MySQL |
| Host | `mysql` | `mysql` |
| Porta | `3306` | `3306` |
| Banco | `dw_vendas` | `dw_tech_campaign` |
| Usuário | `root` | `root` |
| Senha | `root` | `root` |

### 5. Consultas Analíticas (OLAP via Terminal)

Para inspecionar os Data Warehouses e testar as visões analíticas implementadas nas entregas acadêmicas:

**Conexão interativa aos DWs:**
```bash
# Conectar ao DW do Caso 1:
docker exec -it oltp_dw_mysql mysql -uroot -proot dw_vendas

# Conectar ao DW do Caso 1.1:
docker exec -it oltp_dw_mysql mysql -uroot -proot dw_tech_campaign
```

**Executar os scripts de visões analíticas de uma vez:**
```bash
# Executar as 6 visões analíticas do Caso 1:
docker exec -i oltp_dw_mysql mysql -uroot -proot dw_vendas < ../caso_1/solucao/03_consultas_analiticas.sql

# Executar as 8 consultas das Áreas de Convergência do Caso 1.1:
docker exec -i oltp_dw_mysql mysql -uroot -proot dw_tech_campaign < ../caso_1.1/solucao/03_consultas_metricas_ac.sql
```

### 6. Parar o ambiente

```bash
docker compose down
```

Para parar **e apagar os volumes de dados** (reset total para recomeçar do zero):

```bash
docker compose down -v
```

---

## Estrutura de Arquivos

```
docker/
├── docker-compose.yml       # Orquestração dos serviços (MySQL 8.0 + Metabase)
├── .env                     # Variáveis de ambiente locais (opcional)
├── init/                    # Scripts SQL executados automaticamente no primeiro boot
│   ├── 01_oltp.sql          # Dados operacionais base (vendas_db, logistica_db, financeiro_db)
│   ├── 02_dados_extras.sql  # Volume histórico complementar (3000 vendas, 300 clientes)
│   ├── 03_criar_dw.sql      # DDL do DW dw_vendas (Caso 1 - Star Schema)
│   ├── 04_etl_carga.sql     # Pipeline ETL do DW dw_vendas (Caso 1)
│   ├── 05_criar_dw_expandido.sql # DDL do DW dw_tech_campaign (Caso 1.1 - Constelação)
│   └── 06_etl_carga_integrada.sql# Pipeline ETL integrado do DW dw_tech_campaign (Caso 1.1)
├── metabase-data/           # Base H2 persistida com dashboards e gráficos prontos
│   └── metabase.db/
└── README.md                # Este documento de instruções
```

## Relação com os Scripts de Entrega Modular

Os artefatos oficiais de entrega estão organizados por módulo:

* **Caso 1 (`caso_1/solucao/`):** Modelagem dimensional básica para Vendas (`dw_vendas`).
* **Caso 1.1 (`caso_1.1/solucao/`):** Modelagem integrada em Constelação de Fatos para a Campanha Promocional (`dw_tech_campaign`), com 8 Áreas de Convergência, KPIs operacionais e enriquecimento de dados.
