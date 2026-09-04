CREATE DATABASE IF NOT EXISTS vendas_db;
USE vendas_db;

CREATE TABLE IF NOT EXISTS produtos (
    id_produto INT PRIMARY KEY AUTO_INCREMENT,
    nome_produto VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    preco DECIMAL(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nome_cliente VARCHAR(100) NOT NULL,
    cidade VARCHAR(50),
    estado VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS vendas (
    id_venda INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT,
    id_produto INT,
    data_venda DATE NOT NULL,
    quantidade INT NOT NULL,
    valor_total DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

INSERT INTO produtos (nome_produto, categoria, preco) VALUES
('Notebook Dell XPS', 'Eletrônicos', 7500.00),
('Smartphone Samsung', 'Eletrônicos', 3200.00),
('Teclado Mecânico', 'Acessórios', 450.00),
('Mouse Gamer', 'Acessórios', 180.00),
('Monitor Ultrawide', 'Eletrônicos', 1800.00),
('Cadeira Gamer', 'Móveis', 1200.00),
('Webcam Full HD', 'Acessórios', 250.00),
('Fone de Ouvido Bluetooth', 'Acessórios', 300.00),
('SSD 1TB', 'Componentes', 600.00),
('Placa de Vídeo RTX', 'Componentes', 4000.00);

INSERT INTO clientes (nome_cliente, cidade, estado) VALUES
('Ana Silva', 'São Paulo', 'SP'),
('Bruno Costa', 'Rio de Janeiro', 'RJ'),
('Carla Santos', 'Belo Horizonte', 'MG'),
('Daniel Oliveira', 'Porto Alegre', 'RS'),
('Eduarda Pereira', 'Curitiba', 'PR'),
('Fernando Lima', 'Salvador', 'BA'),
('Gabriela Rocha', 'Fortaleza', 'CE'),
('Henrique Souza', 'Recife', 'PE'),
('Isabela Almeida', 'Brasília', 'DF'),
('João Carlos', 'Campinas', 'SP');

INSERT INTO vendas (id_cliente, id_produto, data_venda, quantidade, valor_total) VALUES
(1, 1, '2024-01-10', 1, 7500.00),
(2, 2, '2024-01-11', 1, 3200.00),
(3, 3, '2024-01-12', 2, 900.00),
(4, 4, '2024-01-13', 1, 180.00),
(5, 5, '2024-01-14', 1, 1800.00),
(6, 6, '2024-01-15', 1, 1200.00),
(7, 7, '2024-01-16', 3, 750.00),
(8, 8, '2024-01-17', 1, 300.00),
(9, 9, '2024-01-18', 1, 600.00),
(10, 10, '2024-01-19', 1, 4000.00);

-- Logística DB
CREATE DATABASE IF NOT EXISTS logistica_db;
USE logistica_db;

CREATE TABLE IF NOT EXISTS fornecedores (
    id_fornecedor INT PRIMARY KEY AUTO_INCREMENT,
    nome_fornecedor VARCHAR(100) NOT NULL,
    contato VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS estoque (
    id_estoque INT PRIMARY KEY AUTO_INCREMENT,
    id_produto INT,
    id_fornecedor INT,
    quantidade_disponivel INT NOT NULL,
    data_ultima_entrada DATE,
    FOREIGN KEY (id_produto) REFERENCES vendas_db.produtos(id_produto),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedores(id_fornecedor)
);

CREATE TABLE IF NOT EXISTS entregas (
    id_entrega INT PRIMARY KEY AUTO_INCREMENT,
    id_venda INT,
    data_entrega DATE,
    status_entrega VARCHAR(50),
    FOREIGN KEY (id_venda) REFERENCES vendas_db.vendas(id_venda)
);

INSERT INTO fornecedores (nome_fornecedor, contato) VALUES
('Tech Supplies Ltda', 'contato@tech.com'),
('Eletro Mais S.A.', 'vendas@eletromais.com'),
('Móveis Conforto', 'sac@moveisconforto.com'),
('Componentes Top', 'comercial@componentestop.com'),
('Acessórios Express', 'atendimento@acessorios.com'),
('Global Tech', 'info@globaltech.com'),
('Inova Soluções', 'suporte@inovasolucoes.com'),
('Mega Distribuidora', 'vendas@megadistribuidora.com'),
('Parceiros TI', 'contato@parceirosti.com'),
('Soluções Digitais', 'comercial@solucoesdigitais.com');

INSERT INTO estoque (id_produto, id_fornecedor, quantidade_disponivel, data_ultima_entrada) VALUES
(1, 1, 50, '2024-01-01'),
(2, 2, 100, '2024-01-02'),
(3, 5, 200, '2024-01-03'),
(4, 5, 150, '2024-01-04'),
(5, 1, 30, '2024-01-05'),
(6, 3, 40, '2024-01-06'),
(7, 5, 120, '2024-01-07'),
(8, 5, 180, '2024-01-08'),
(9, 4, 70, '2024-01-09'),
(10, 4, 25, '2024-01-10');

INSERT INTO entregas (id_venda, data_entrega, status_entrega) VALUES
(1, '2024-01-15', 'Entregue'),
(2, '2024-01-16', 'Entregue'),
(3, '2024-01-17', 'Em Trânsito'),
(4, '2024-01-18', 'Entregue'),
(5, '2024-01-19', 'Entregue'),
(6, '2024-01-20', 'Pendente'),
(7, '2024-01-21', 'Entregue'),
(8, '2024-01-22', 'Em Trânsito'),
(9, '2024-01-23', 'Entregue'),
(10, '2024-01-24', 'Pendente');

-- Financeiro DB
CREATE DATABASE IF NOT EXISTS financeiro_db;
USE financeiro_db;

CREATE TABLE IF NOT EXISTS pagamentos (
    id_pagamento INT PRIMARY KEY AUTO_INCREMENT,
    id_venda INT,
    data_pagamento DATE NOT NULL,
    valor_pago DECIMAL(10, 2) NOT NULL,
    metodo_pagamento VARCHAR(50),
    FOREIGN KEY (id_venda) REFERENCES vendas_db.vendas(id_venda)
);

CREATE TABLE IF NOT EXISTS despesas (
    id_despesa INT PRIMARY KEY AUTO_INCREMENT,
    descricao VARCHAR(255) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL,
    data_despesa DATE NOT NULL,
    tipo_despesa VARCHAR(50)
);

INSERT INTO pagamentos (id_venda, data_pagamento, valor_pago, metodo_pagamento) VALUES
(1, '2024-01-10', 7500.00, 'Cartão de Crédito'),
(2, '2024-01-11', 3200.00, 'Pix'),
(3, '2024-01-12', 900.00, 'Cartão de Débito'),
(4, '2024-01-13', 180.00, 'Cartão de Crédito'),
(5, '2024-01-14', 1800.00, 'Pix'),
(6, '2024-01-15', 1200.00, 'Boleto'),
(7, '2024-01-16', 750.00, 'Cartão de Crédito'),
(8, '2024-01-17', 300.00, 'Pix'),
(9, '2024-01-18', 600.00, 'Cartão de Débito'),
(10, '2024-01-19', 4000.00, 'Cartão de Crédito');

INSERT INTO despesas (descricao, valor, data_despesa, tipo_despesa) VALUES
('Aluguel Escritório', 5000.00, '2024-01-01', 'Fixa'),
('Salários Equipe', 25000.00, '2024-01-05', 'Fixa'),
('Conta de Luz', 800.00, '2024-01-10', 'Variável'),
('Material de Escritório', 300.00, '2024-01-15', 'Variável'),
('Manutenção Servidores', 1500.00, '2024-01-20', 'Fixa'),
('Marketing Digital', 2000.00, '2024-01-25', 'Variável'),
('Serviço de Limpeza', 400.00, '2024-01-30', 'Fixa'),
('Viagem a Negócios', 1200.00, '2024-02-01', 'Variável'),
('Software Licenças', 700.00, '2024-02-05', 'Fixa'),
('Treinamento Equipe', 900.00, '2024-02-10', 'Variável');
