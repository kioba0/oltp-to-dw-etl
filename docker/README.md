# Ambiente Docker — MySQL + Metabase

Sobe o banco de dados MySQL e o Metabase juntos via Docker Compose.

## Pré-requisitos

- Docker instalado e rodando
- Docker Compose v2+

## Como usar

### 1. Subir o ambiente

```bash
# A partir da pasta docker/
docker compose up -d
```

Na **primeira execução**, o MySQL inicializa automaticamente com o script `init/01_oltp.sql`,
que cria e popula os 3 bancos operacionais (`vendas_db`, `logistica_db`, `financeiro_db`).

### 2. Acompanhar os logs

```bash
docker compose logs -f
```

Aguarde o Metabase aparecer como `Started` antes de abrir o browser.

### 3. Acessar o Metabase

Abrir no browser: **http://localhost:3000**

O ambiente já vem **pré-configurado com a conexão ao Data Warehouse e os gráficos do dashboard prontos**!

**Credenciais de Acesso:**
- **E-mail:** `cerveja123@gmail.com`
- **Senha:** `cerveja123`

---

### 4. Conectar o Metabase ao MySQL (Já configurado automaticamente)

A conexão com o `dw_vendas` já está salva na base do Metabase. Caso precise recriá-la manualmente:

| Campo | Valor |
|---|---|
| Tipo de banco | MySQL |
| Host | `mysql` (nome do serviço no compose) |
| Porta | `3306` |
| Banco | `dw_vendas` |
| Usuário | `root` |
| Senha | `root` |

### 5. Parar o ambiente

```bash
docker compose down
```

Para parar **e apagar os dados** (volumes):

```bash
docker compose down -v
```

## Estrutura

```
docker/
├── docker-compose.yml   # Orquestração dos serviços
├── .env                 # Variáveis de ambiente (não versionar!)
├── init/
│   ├── 01_oltp.sql      # Script OLTP base executado na 1ª inicialização
│   └── 02_dados_extras.sql # Volume histórico (3000 vendas 2024-2026, 300 clientes)
└── README.md            # Este arquivo
```

## Ordem de execução dos scripts SQL

Após o ambiente subir, executar na seguinte ordem dentro do MySQL:

```
1. init/01_oltp.sql          → criado automaticamente pelo container (dados base)
2. init/02_dados_extras.sql  → criado automaticamente pelo container (volume histórico)
3. solucao/01_criar_dw.sql   → cria o banco dw_vendas e as tabelas dimensionais
4. solucao/02_etl_carga.sql  → carrega as dimensões e a tabela fato
5. solucao/03_consultas_analiticas.sql → as 3 visões analíticas
```

Para conectar ao MySQL pelo terminal:

```bash
docker exec -it oltp_dw_mysql mysql -uroot -proot
```
