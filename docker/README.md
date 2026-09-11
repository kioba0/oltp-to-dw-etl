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
3. `init/03_criar_dw.sql`: Cria o Data Warehouse `dw_vendas` e a estrutura do Star Schema (dimensões e fato).
4. `init/04_etl_carga.sql`: Executa o pipeline ETL, mapeando e resolvendo Surrogate Keys e carregando o DW.

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

### 4. Conectar o Metabase ao MySQL (Já configurado automaticamente)

A conexão com o `dw_vendas` já está salva na base versionada do Metabase (`metabase-data/`). Caso precise recriá-la manualmente:

| Campo | Valor |
|---|---|
| Tipo de banco | MySQL |
| Host | `mysql` (nome do serviço no compose) |
| Porta | `3306` |
| Banco | `dw_vendas` |
| Usuário | `root` |
| Senha | `root` |

### 5. Consultas Analíticas (OLAP via Terminal)

Para inspecionar o Data Warehouse e testar as visões analíticas implementadas na entrega acadêmica:

**Conexão interativa ao DW:**
```bash
docker exec -it oltp_dw_mysql mysql -uroot -proot dw_vendas
```

**Executar o script com as 6 visões analíticas de uma vez:**
```bash
docker exec -i oltp_dw_mysql mysql -uroot -proot dw_vendas < ../solucao/03_consultas_analiticas.sql
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
│   ├── 03_criar_dw.sql      # DDL do Data Warehouse dw_vendas (Star Schema)
│   └── 04_etl_carga.sql     # Pipeline ETL (transformação e carga em dw_vendas)
├── metabase-data/           # Base H2 persistida com dashboards e gráficos prontos
│   └── metabase.db/
└── README.md                # Este documento de instruções
```

## Relação com os Scripts de Entrega (`../solucao/`)

Os arquivos dentro da pasta `../solucao/` são os artefatos oficiais da entrega da atividade:

| Arquivo | Descrição |
|---|---|
| `solucao/01_criar_dw.sql` | Script DDL original de criação do DW `dw_vendas` e modelo Star Schema |
| `solucao/02_etl_carga.sql` | Script original do pipeline de Extração, Transformação e Carga (ETL) |
| `solucao/03_consultas_analiticas.sql` | 6 visões analíticas (3 obrigatórias da atividade + 3 bônus executivas) |
| `solucao/diagrama_star_schema.png` | Diagrama em alta resolução do modelo Star Schema |
| `solucao/diagrama_star_schema.puml` | Código-fonte do diagrama em PlantUML |
