-- =====================================================================================
-- Casa de Carnes Rotineira Caroline — Modelagem de Banco de Dados
-- Grupo: Gabriel Diniz Tavares da Costa, Isaac Santos Alves da Costa,
--        Rafael Aceiro Ferreira Gomes, Paulo Henrique Fernandez Prado
-- Script SQL — Entrega 2
-- SGBD: MySQL 8.0+  |  Codificacao: utf8mb4  |  Engine: InnoDB
--
-- Como executar:
--   1) Rode este arquivo inteiro de uma vez (ele recria o banco do zero).
--   2) Testado em MySQL Workbench
-- =====================================================================================


-- =====================================================================================
-- 1) CREATE DATABASE
-- =====================================================================================
DROP DATABASE IF EXISTS acougue_caroline;

CREATE DATABASE acougue_caroline
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE acougue_caroline;


-- =====================================================================================
-- 2) CREATE TABLE 
-- =====================================================================================

-- ---------------------------------------------------------------------------
-- FORNECEDOR
-- ---------------------------------------------------------------------------
CREATE TABLE fornecedor (
  id_fornecedor          INT             NOT NULL AUTO_INCREMENT,
  nome_razao_social      VARCHAR(150)    NOT NULL,
  telefone_whatsapp      VARCHAR(20)     NOT NULL,
  tipo_produto_fornecido VARCHAR(100)    NOT NULL,
  CONSTRAINT pk_fornecedor PRIMARY KEY (id_fornecedor)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------------
-- CATEGORIA_PRODUTO
-- ---------------------------------------------------------------------------
CREATE TABLE categoria_produto (
  id_categoria        INT          NOT NULL AUTO_INCREMENT,
  descricao           VARCHAR(80)  NOT NULL,
  regra_armazenamento VARCHAR(150) NULL,
  CONSTRAINT pk_categoria_produto PRIMARY KEY (id_categoria),
  CONSTRAINT uq_categoria_descricao UNIQUE (descricao)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------------
-- FUNCIONARIO
-- ---------------------------------------------------------------------------
CREATE TABLE funcionario (
  id_funcionario INT          NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(120) NOT NULL,
  funcao         VARCHAR(60)  NOT NULL,
  telefone       VARCHAR(20)  NULL,
  CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------------
-- CLIENTE  (cadastro opcional no negocio real; aqui mantemos o cadastro
-- completo para quem compra fiado/boleto, conforme levantamento)
-- ---------------------------------------------------------------------------
CREATE TABLE cliente (
  id_cliente         INT          NOT NULL AUTO_INCREMENT,
  nome_razao_social  VARCHAR(150) NOT NULL,
  cpf_cnpj           VARCHAR(18)  NULL,
  telefone           VARCHAR(20)  NULL,
  endereco           VARCHAR(200) NULL,
  autorizado_prazo   BOOLEAN      NOT NULL DEFAULT FALSE,
  CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
  CONSTRAINT uq_cliente_cpf_cnpj UNIQUE (cpf_cnpj)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------------
-- PRODUTO
-- Observacao (suposicao assumida pelo grupo): o atributo estoque_atual foi
-- acrescentado no modelo logico (nao existia no DER conceitual) porque e
-- exatamente o que falta hoje no negocio real -- controle de saldo automatizado
-- (problema P1 do levantamento). Sem ele nao ha como responder "o que esta
-- abaixo do minimo" com uma consulta.
-- ---------------------------------------------------------------------------
CREATE TABLE produto (
  id_produto     INT            NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(120)   NOT NULL,
  id_categoria   INT            NOT NULL,
  unidade_venda  ENUM('kg','un','pct','cx') NOT NULL DEFAULT 'kg',
  preco          DECIMAL(10,2)  NOT NULL,
  estoque_minimo DECIMAL(10,2)  NOT NULL DEFAULT 0,
  estoque_atual  DECIMAL(10,2)  NOT NULL DEFAULT 0,
  CONSTRAINT pk_produto PRIMARY KEY (id_produto),
  CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria)
      REFERENCES categoria_produto (id_categoria)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_produto_preco CHECK (preco > 0),
  CONSTRAINT ck_produto_estoque_minimo CHECK (estoque_minimo >= 0),
  CONSTRAINT ck_produto_estoque_atual CHECK (estoque_atual >= 0),
  KEY ix_produto_categoria (id_categoria)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------------
-- PEDIDO_COMPRA
-- ---------------------------------------------------------------------------
CREATE TABLE pedido_compra (
  id_pedido_compra INT  NOT NULL AUTO_INCREMENT,
  id_fornecedor    INT  NOT NULL,
  id_funcionario   INT  NOT NULL,
  data_pedido      DATE NOT NULL,
  prazo_entrega    DATE NULL,
  status           ENUM('aberto','confirmado','recebido','cancelado')
                   NOT NULL DEFAULT 'aberto',
  CONSTRAINT pk_pedido_compra PRIMARY KEY (id_pedido_compra),
  CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (id_fornecedor)
      REFERENCES fornecedor (id_fornecedor)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pedido_funcionario FOREIGN KEY (id_funcionario)
      REFERENCES funcionario (id_funcionario)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_pedido_datas CHECK (prazo_entrega IS NULL OR prazo_entrega >= data_pedido),
  KEY ix_pedido_fornecedor (id_fornecedor)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------------
-- PEDIDO_COMPRA_PRODUTO
-- Tabela associativa que vem do relacionamento N:N "contem" entre Pedido de
-- Compra e Produto no DER conceitual (regra de conversao da apostila: N:N
-- vira tabela com as duas PKs dos lados como FK compondo a PK da nova tabela).
-- O atributo preco_unitario_compra foi acrescentado no logico (suposicao: nao
-- estava no DER conceitual, mas e necessario para calcular o custo do pedido).
-- ---------------------------------------------------------------------------
CREATE TABLE pedido_compra_produto (
  id_pedido_compra      INT           NOT NULL,
  id_produto             INT           NOT NULL,
  quantidade              DECIMAL(10,2) NOT NULL,
  preco_unitario_compra   DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_pedido_compra_produto PRIMARY KEY (id_pedido_compra, id_produto),
  CONSTRAINT fk_pcp_pedido FOREIGN KEY (id_pedido_compra)
      REFERENCES pedido_compra (id_pedido_compra)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pcp_produto FOREIGN KEY (id_produto)
      REFERENCES produto (id_produto)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_pcp_quantidade CHECK (quantidade > 0),
  CONSTRAINT ck_pcp_preco CHECK (preco_unitario_compra > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------------
-- VENDA
-- "Venda a Prazo" foi incorporada aqui (decisao tomada ja na Entrega 1):
-- forma_pagamento = 'fiado' ou 'boleto' + data_vencimento + status_pagamento
-- cobrem o que antes seria uma entidade separada.
-- ---------------------------------------------------------------------------
CREATE TABLE venda (
  id_venda         INT            NOT NULL AUTO_INCREMENT,
  canal            ENUM('balcao','telefone','whatsapp','delivery') NOT NULL,
  data_hora        DATETIME       NOT NULL,
  id_cliente       INT            NULL,
  id_funcionario   INT            NOT NULL,
  forma_pagamento  ENUM('dinheiro','pix','cartao_credito','cartao_debito',
                         'vale_alimentacao','boleto','fiado') NOT NULL,
  valor_total      DECIMAL(10,2)  NOT NULL,
  desconto         DECIMAL(10,2)  NOT NULL DEFAULT 0,
  status           ENUM('concluida','cancelada') NOT NULL DEFAULT 'concluida',
  data_vencimento  DATE           NULL,
  status_pagamento ENUM('pago','em_aberto','atrasado') NULL,
  CONSTRAINT pk_venda PRIMARY KEY (id_venda),
  -- RESTRICT em UPDATE e DELETE (nao CASCADE/SET NULL): o MySQL 8 nao permite
  -- nenhuma acao automatica (CASCADE ou SET NULL, em UPDATE ou DELETE) numa
  -- coluna que tambem apareca num CHECK (erro 3823). id_cliente e PK surrogate
  -- (AUTO_INCREMENT) em cliente, entao nunca e atualizado manualmente -- RESTRICT
  -- no UPDATE nao tem efeito pratico. No DELETE, o unico DELETE de cliente do
  -- script (secao 6.2) so remove quem nunca comprou, entao RESTRICT nao atrapalha
  -- e ainda protege o historico de vendas.
  CONSTRAINT fk_venda_cliente FOREIGN KEY (id_cliente)
      REFERENCES cliente (id_cliente)
      ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_venda_funcionario FOREIGN KEY (id_funcionario)
      REFERENCES funcionario (id_funcionario)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_venda_total CHECK (valor_total >= 0),
  CONSTRAINT ck_venda_desconto CHECK (desconto >= 0),
  CONSTRAINT ck_venda_fiado_boleto_cliente CHECK (
      forma_pagamento NOT IN ('fiado','boleto') OR id_cliente IS NOT NULL
  ),
  CONSTRAINT ck_venda_fiado_boleto_vencimento CHECK (
      forma_pagamento NOT IN ('fiado','boleto') OR data_vencimento IS NOT NULL
  ),
  KEY ix_venda_data_hora (data_hora),
  KEY ix_venda_cliente (id_cliente),
  KEY ix_venda_forma_pag (forma_pagamento)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------------
-- VENDA_PRODUTO
-- Tabela associativa do relacionamento N:N "compoe" entre Venda e Produto.
-- ---------------------------------------------------------------------------
CREATE TABLE venda_produto (
  id_venda        INT            NOT NULL,
  id_produto      INT            NOT NULL,
  peso_quantidade DECIMAL(10,3)  NOT NULL,
  preco_unitario  DECIMAL(10,2)  NOT NULL,
  CONSTRAINT pk_venda_produto PRIMARY KEY (id_venda, id_produto),
  CONSTRAINT fk_vp_venda FOREIGN KEY (id_venda)
      REFERENCES venda (id_venda)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_vp_produto FOREIGN KEY (id_produto)
      REFERENCES produto (id_produto)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_vp_peso CHECK (peso_quantidade > 0),
  CONSTRAINT ck_vp_preco CHECK (preco_unitario > 0)
) ENGINE = InnoDB;

-- Observacao: os indices auxiliares (data_hora, id_cliente, forma_pagamento em
-- venda; id_fornecedor em pedido_compra; id_categoria em produto) foram
-- declarados como KEY dentro de cada CREATE TABLE acima, em vez de com
-- CREATE INDEX separado -- CREATE INDEX exige o privilegio INDEX a parte, que
-- usuarios restritos (ex.: sandbox do myCompiler.io) costumam nao ter. Como
-- KEY faz parte da propria definicao da tabela, basta o privilegio CREATE.


-- =====================================================================================
-- 3) INSERT INTO  (carga da massa de dados)
-- =====================================================================================
-- Fornecedor
INSERT INTO fornecedor (nome_razao_social, telefone_whatsapp, tipo_produto_fornecido) VALUES
  ('Frigorifico Boi Forte Ltda', '11988001122', 'Carnes bovinas em pecas'),
  ('Granja Penas Douradas Ltda', '11988002233', 'Aves e derivados'),
  ('Suinos do Vale Agropecuaria', '11988003344', 'Carnes suinas'),
  ('Distribuidora Sabor e Cia', '11988004455', 'Mercearia, massas e bebidas'),
  ('Congelados Polar Distribuicao', '11988005566', 'Produtos congelados'),
  ('Bebidas Fonte Clara Ltda', '11988006677', 'Bebidas em geral');

-- Categoria de Produto
INSERT INTO categoria_produto (descricao, regra_armazenamento) VALUES
  ('Carne Bovina', 'Camara fria 0 a 4 C, uso em ate 3 dias apos abertura'),
  ('Carne Suina', 'Camara fria 0 a 4 C, uso em ate 3 dias apos abertura'),
  ('Aves', 'Camara fria 0 a 4 C, uso em ate 2 dias apos abertura'),
  ('Congelados', 'Freezer -18 C, nao recongelar apos descongelo'),
  ('Mercearia', 'Ambiente seco e arejado'),
  ('Massas', 'Ambiente seco, ao abrigo de umidade'),
  ('Bebidas', 'Ambiente ou refrigerado conforme o item'),
  ('Rotisseria e Churrasco', 'Refrigerado, consumo em ate 24h apos preparo');

-- Funcionario
INSERT INTO funcionario (nome, funcao, telefone) VALUES
  ('Carolina Mendes Rotineira', 'Proprietaria', '11977001001'),
  ('Jose Carlos Pereira', 'Acougueiro', '11977001002'),
  ('Antonio Ferreira Lima', 'Acougueiro', '11977001003'),
  ('Marcos Vinicius Souza', 'Acougueiro', '11977001004'),
  ('Paulo Roberto Alves', 'Acougueiro', '11977001005'),
  ('Edilson Rodrigues Dias', 'Acougueiro', '11977001006'),
  ('Fernanda Oliveira Santos', 'Balconista', '11977001007'),
  ('Juliana Costa Ramos', 'Balconista', '11977001008'),
  ('Ricardo Nunes Barbosa', 'Operador de Caixa', '11977001009'),
  ('Patricia Gomes Teixeira', 'Operador de Caixa', '11977001010'),
  ('Luiz Henrique Martins', 'Ajudante Geral', '11977001011'),
  ('Diego Almeida Rocha', 'Entregador', '11977001012'),
  ('Sandra Regina Fonseca', 'Responsavel Administrativo-Financeiro', '11977001013');

-- Cliente
INSERT INTO cliente (nome_razao_social, cpf_cnpj, telefone, endereco, autorizado_prazo) VALUES
  ('Mariana Souza Lima', '11122233344', '11966001001', 'Rua das Acacias 120', 1),
  ('Joao Pedro Castro', '22233344455', '11966001002', 'Rua das Palmeiras 45', 0),
  ('Restaurante Sabor Caseiro Ltda', '11222333000155', '11966001003', 'Av. Central 900', 1),
  ('Beatriz Andrade Reis', '33344455566', '11966001004', 'Rua Dois de Maio 88', 0),
  ('Padaria Pao Dourado Ltda', '22333444000166', '11966001005', 'Rua das Flores 230', 1),
  ('Lucas Gabriel Moreira', '44455566677', '11966001006', 'Rua Bela Vista 15', 0),
  ('Camila Fernandes Pires', '55566677788', '11966001007', 'Rua Sao Jose 310', 0),
  ('Hotel Pousada Boa Estadia Ltda', '33444555000177', '11966001008', 'Av. das Nacoes 500', 1),
  ('Rafael Augusto Nogueira', '66677788899', '11966001009', 'Rua Vinte de Abril 77', 0),
  ('Vanessa Cristina Barros', '77788899900', '11966001010', 'Rua das Hortensias 64', 0),
  ('Gustavo Henrique Lacerda', '88899900011', '11966001011', 'Rua do Comercio 12', 0),
  ('Ana Paula Siqueira', '99900011122', '11966001012', 'Rua Jardim Alegre 33', 0),
  ('Felipe Tavares Monteiro', '10011122233', '11966001013', 'Rua Industrial 190', 0),
  ('Larissa Pinheiro Costa', '12121212121', '11966001014', 'Rua das Oliveiras 58', 0),
  ('Eduardo Martins Vieira', '13131313131', '11966001015', 'Rua Santo Antonio 402', 0),
  ('Churrascaria Fogo Brasa Ltda', '44555666000188', '11966001016', 'Av. Brasil 1500', 1),
  ('Isabela Cardoso Farias', '14141414141', '11966001017', 'Rua Nove de Julho 21', 0),
  ('Thiago Ribeiro Correa', '15151515151', '11966001018', 'Rua Marechal Deodoro 155', 0),
  ('Renata Alves Pacheco', '16161616161', '11966001019', 'Rua Ipe Amarelo 40', 0),
  ('Marcelo Souza Prado', '17171717171', '11966001020', 'Rua Cedro Rosa 81', 0);

-- Produto
INSERT INTO produto (nome, id_categoria, unidade_venda, preco, estoque_minimo, estoque_atual) VALUES
  ('Picanha bovina', 1, 'kg', 69.90, 15.00, 8.00),
  ('Alcatra bovina', 1, 'kg', 42.90, 20.00, 35.00),
  ('Costela bovina', 1, 'kg', 32.50, 18.00, 22.00),
  ('Fraldinha bovina', 1, 'kg', 39.90, 12.00, 4.50),
  ('File mignon bovino', 1, 'kg', 79.90, 10.00, 11.00),
  ('Patinho bovino moido', 1, 'kg', 36.90, 25.00, 30.00),
  ('Pernil suino', 2, 'kg', 24.90, 15.00, 17.00),
  ('Lombo suino', 2, 'kg', 28.90, 12.00, 13.50),
  ('Costelinha suina', 2, 'kg', 26.90, 10.00, 6.00),
  ('Linguica toscana', 2, 'kg', 22.90, 20.00, 24.00),
  ('Bacon fatiado', 2, 'kg', 34.90, 8.00, 9.00),
  ('Frango inteiro', 3, 'kg', 13.90, 30.00, 28.00),
  ('Coxa e sobrecoxa de frango', 3, 'kg', 15.90, 25.00, 31.00),
  ('Peito de frango', 3, 'kg', 18.90, 25.00, 20.00),
  ('Asa de frango', 3, 'kg', 14.90, 15.00, 16.00),
  ('Hamburguer congelado 1kg', 4, 'pct', 24.90, 10.00, 12.00),
  ('Nuggets congelados 1kg', 4, 'pct', 22.90, 10.00, 7.00),
  ('Batata congelada 1kg', 4, 'pct', 14.90, 15.00, 18.00),
  ('Arroz tipo 1 5kg', 5, 'un', 28.90, 10.00, 14.00),
  ('Feijao carioca 1kg', 5, 'un', 8.90, 20.00, 25.00),
  ('Sal refinado 1kg', 5, 'un', 3.50, 15.00, 18.00),
  ('Oleo de soja 900ml', 5, 'un', 7.90, 20.00, 19.00),
  ('Macarrao espaguete 500g', 6, 'un', 5.90, 20.00, 22.00),
  ('Molho de tomate 340g', 6, 'un', 4.50, 20.00, 23.00),
  ('Refrigerante cola 2L', 7, 'un', 9.90, 24.00, 30.00),
  ('Agua mineral 500ml', 7, 'un', 2.50, 48.00, 40.00),
  ('Cerveja pilsen lata 350ml', 7, 'un', 4.90, 48.00, 55.00),
  ('Suco de laranja 1L', 7, 'un', 8.90, 15.00, 17.00),
  ('Frango assado rotisseria', 8, 'kg', 24.90, 5.00, 3.00),
  ('Espetinho misto', 8, 'un', 7.90, 20.00, 26.00);

-- Pedido de Compra
INSERT INTO pedido_compra (id_fornecedor, id_funcionario, data_pedido, prazo_entrega, status) VALUES
  (1, 1, '2026-10-01', '2026-10-04', 'recebido'),
  (2, 1, '2026-10-03', '2026-10-04', 'recebido'),
  (3, 1, '2026-10-06', '2026-10-07', 'recebido'),
  (4, 1, '2026-10-08', '2026-10-11', 'recebido'),
  (5, 1, '2026-10-10', '2026-10-12', 'recebido'),
  (6, 1, '2026-10-13', '2026-10-14', 'recebido'),
  (1, 1, '2026-10-15', '2026-10-16', 'recebido'),
  (2, 1, '2026-10-18', '2026-10-19', 'confirmado'),
  (3, 1, '2026-10-20', NULL, 'cancelado'),
  (4, 1, '2026-10-22', '2026-10-25', 'aberto');

-- Item do Pedido de Compra (relacionamento N:N Pedido de Compra x Produto)
INSERT INTO pedido_compra_produto (id_pedido_compra, id_produto, quantidade, preco_unitario_compra) VALUES
  (1, 22, 8.04, 5.54),
  (1, 24, 6.04, 2.8),
  (2, 8, 24.64, 18.85),
  (2, 17, 29.55, 15.38),
  (3, 8, 35.43, 17.26),
  (3, 15, 10.59, 10.12),
  (3, 19, 14.73, 17.97),
  (4, 25, 18.3, 5.62),
  (4, 11, 17.04, 21.32),
  (5, 26, 9.37, 1.57),
  (5, 2, 7.76, 30.32),
  (5, 24, 27.0, 2.7),
  (6, 19, 28.14, 16.24),
  (6, 7, 39.48, 16.97),
  (6, 23, 35.33, 4.1),
  (7, 9, 10.69, 18.61),
  (7, 15, 28.46, 9.09),
  (7, 21, 28.92, 2.34),
  (8, 20, 30.52, 5.15),
  (8, 21, 18.28, 2.02),
  (9, 23, 31.89, 3.57),
  (9, 18, 33.76, 8.34),
  (9, 8, 19.04, 19.85),
  (9, 22, 36.96, 4.43),
  (10, 29, 18.85, 16.47),
  (10, 23, 21.06, 4.16),
  (10, 11, 13.63, 20.77),
  (10, 7, 14.2, 16.07);

-- Venda
INSERT INTO venda (canal, data_hora, id_cliente, id_funcionario, forma_pagamento, valor_total, desconto, status, data_vencimento, status_pagamento) VALUES
  ('whatsapp', '2026-10-01 16:45:00', NULL, 3, 'pix', 9.90, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-02 09:15:00', NULL, 3, 'cartao_debito', 148.69, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-03 19:30:00', 14, 2, 'pix', 222.19, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-04 17:15:00', NULL, 2, 'vale_alimentacao', 26.70, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-05 08:30:00', 3, 10, 'dinheiro', 165.98, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-06 15:45:00', 7, 5, 'boleto', 75.73, 0.00, 'concluida', '2026-10-21', 'em_aberto'),
  ('balcao', '2026-10-07 16:15:00', NULL, 8, 'dinheiro', 25.45, 1.25, 'concluida', NULL, NULL),
  ('balcao', '2026-10-08 17:45:00', 16, 5, 'pix', 90.01, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-09 18:00:00', 11, 8, 'dinheiro', 51.24, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-10 10:00:00', 18, 5, 'dinheiro', 76.02, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-11 07:15:00', NULL, 7, 'cartao_credito', 155.86, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-12 11:15:00', NULL, 6, 'dinheiro', 80.52, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-13 15:15:00', 6, 5, 'dinheiro', 118.52, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-14 07:00:00', NULL, 6, 'cartao_credito', 35.50, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-15 09:30:00', NULL, 2, 'dinheiro', 56.94, 0.00, 'cancelada', NULL, NULL),
  ('balcao', '2026-10-16 09:30:00', NULL, 10, 'pix', 68.00, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-17 11:00:00', 4, 11, 'boleto', 122.73, 0.00, 'concluida', '2026-11-01', 'atrasado'),
  ('balcao', '2026-10-18 11:00:00', NULL, 3, 'dinheiro', 68.90, 0.00, 'cancelada', NULL, NULL),
  ('balcao', '2026-10-19 13:00:00', 5, 8, 'boleto', 178.40, 0.00, 'concluida', '2026-11-03', 'em_aberto'),
  ('delivery', '2026-10-20 12:15:00', NULL, 10, 'cartao_credito', 277.19, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-21 07:15:00', NULL, 2, 'cartao_debito', 87.10, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-22 14:15:00', 8, 4, 'fiado', 145.57, 0.00, 'concluida', '2026-11-21', 'pago'),
  ('balcao', '2026-10-23 07:00:00', NULL, 9, 'cartao_credito', 92.31, 0.00, 'cancelada', NULL, NULL),
  ('delivery', '2026-10-24 11:00:00', 18, 3, 'boleto', 46.35, 0.00, 'concluida', '2026-11-08', 'pago'),
  ('delivery', '2026-10-01 17:00:00', 14, 11, 'boleto', 259.96, 0.00, 'concluida', '2026-10-16', 'em_aberto'),
  ('telefone', '2026-10-02 16:30:00', NULL, 5, 'cartao_credito', 172.70, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-03 15:45:00', NULL, 9, 'cartao_credito', 64.86, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-04 09:00:00', NULL, 10, 'vale_alimentacao', 21.14, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-05 10:45:00', 1, 3, 'dinheiro', 221.43, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-06 15:30:00', NULL, 6, 'vale_alimentacao', 138.69, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-07 19:45:00', 3, 10, 'fiado', 89.94, 0.00, 'concluida', '2026-11-06', 'em_aberto'),
  ('telefone', '2026-10-08 08:45:00', NULL, 2, 'cartao_debito', 219.27, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-09 12:30:00', 18, 3, 'boleto', 111.11, 6.28, 'concluida', '2026-10-24', 'atrasado'),
  ('telefone', '2026-10-10 18:15:00', NULL, 9, 'vale_alimentacao', 284.77, 17.06, 'cancelada', NULL, NULL),
  ('balcao', '2026-10-11 10:45:00', NULL, 2, 'cartao_debito', 123.00, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-12 08:00:00', 1, 10, 'fiado', 57.80, 0.00, 'concluida', '2026-11-11', 'pago'),
  ('balcao', '2026-10-13 19:30:00', 4, 6, 'boleto', 154.68, 0.00, 'concluida', '2026-10-28', 'atrasado'),
  ('balcao', '2026-10-14 13:15:00', 8, 6, 'boleto', 57.30, 0.00, 'concluida', '2026-10-29', 'atrasado'),
  ('balcao', '2026-10-15 17:30:00', NULL, 5, 'dinheiro', 154.04, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-16 17:30:00', NULL, 5, 'cartao_debito', 128.08, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-17 19:45:00', 2, 6, 'fiado', 151.47, 0.00, 'concluida', '2026-11-16', 'pago'),
  ('whatsapp', '2026-10-18 15:00:00', 14, 10, 'cartao_debito', 184.80, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-19 19:00:00', 8, 11, 'cartao_credito', 109.15, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-20 11:15:00', 18, 10, 'boleto', 162.90, 0.00, 'concluida', '2026-11-04', 'pago'),
  ('balcao', '2026-10-21 08:15:00', NULL, 10, 'cartao_credito', 155.81, 0.00, 'cancelada', NULL, NULL),
  ('balcao', '2026-10-22 09:45:00', NULL, 7, 'cartao_debito', 240.83, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-23 08:00:00', NULL, 9, 'cartao_credito', 168.82, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-24 16:15:00', NULL, 3, 'cartao_debito', 349.47, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-01 10:30:00', 6, 8, 'vale_alimentacao', 28.65, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-02 11:00:00', 15, 11, 'boleto', 98.29, 0.00, 'concluida', '2026-10-17', 'em_aberto'),
  ('whatsapp', '2026-10-03 13:00:00', NULL, 10, 'cartao_credito', 32.09, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-04 18:30:00', NULL, 8, 'cartao_credito', 217.08, 13.92, 'concluida', NULL, NULL),
  ('balcao', '2026-10-05 12:30:00', 1, 8, 'boleto', 241.00, 0.00, 'concluida', '2026-10-20', 'em_aberto'),
  ('delivery', '2026-10-06 16:45:00', NULL, 4, 'cartao_debito', 171.30, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-07 17:45:00', NULL, 7, 'cartao_credito', 39.60, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-08 07:45:00', 12, 7, 'vale_alimentacao', 191.44, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-09 07:15:00', 1, 9, 'vale_alimentacao', 42.57, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-10 09:45:00', NULL, 11, 'cartao_credito', 204.47, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-11 09:00:00', 17, 3, 'cartao_credito', 94.63, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-12 09:45:00', 18, 4, 'vale_alimentacao', 75.52, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-13 13:00:00', NULL, 4, 'cartao_debito', 120.84, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-14 08:45:00', NULL, 5, 'dinheiro', 213.62, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-15 12:45:00', NULL, 4, 'dinheiro', 26.30, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-16 13:00:00', 10, 8, 'boleto', 85.51, 0.00, 'concluida', '2026-10-31', 'pago'),
  ('balcao', '2026-10-17 13:15:00', 6, 5, 'boleto', 35.60, 0.00, 'concluida', '2026-11-01', 'em_aberto'),
  ('balcao', '2026-10-18 14:15:00', NULL, 4, 'cartao_debito', 61.58, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-19 17:15:00', NULL, 4, 'vale_alimentacao', 90.36, 5.43, 'concluida', NULL, NULL),
  ('delivery', '2026-10-20 12:30:00', 13, 11, 'cartao_credito', 39.50, 0.00, 'cancelada', NULL, NULL),
  ('whatsapp', '2026-10-21 11:15:00', 7, 2, 'vale_alimentacao', 102.60, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-22 14:00:00', NULL, 2, 'dinheiro', 86.21, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-23 15:30:00', NULL, 11, 'cartao_debito', 141.31, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-24 10:45:00', 13, 2, 'dinheiro', 19.30, 0.00, 'concluida', NULL, NULL),
  ('delivery', '2026-10-01 11:45:00', 8, 2, 'fiado', 114.56, 0.00, 'concluida', '2026-10-31', 'pago'),
  ('balcao', '2026-10-02 17:45:00', 2, 9, 'cartao_credito', 37.27, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-03 13:45:00', 5, 5, 'boleto', 19.60, 0.00, 'concluida', '2026-10-18', 'pago'),
  ('balcao', '2026-10-04 07:30:00', NULL, 4, 'pix', 23.70, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-05 17:30:00', 4, 3, 'cartao_debito', 12.40, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-06 10:15:00', 18, 10, 'pix', 67.21, 6.65, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-07 09:15:00', NULL, 11, 'dinheiro', 27.17, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-08 10:30:00', 5, 9, 'boleto', 99.60, 0.00, 'concluida', '2026-10-23', 'em_aberto'),
  ('whatsapp', '2026-10-09 14:15:00', 17, 7, 'boleto', 128.53, 0.00, 'concluida', '2026-10-24', 'atrasado'),
  ('telefone', '2026-10-10 17:00:00', 3, 4, 'cartao_credito', 152.20, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-11 16:30:00', NULL, 5, 'dinheiro', 53.40, 0.00, 'concluida', NULL, NULL),
  ('telefone', '2026-10-12 19:15:00', NULL, 4, 'cartao_debito', 105.62, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-13 14:00:00', 4, 8, 'boleto', 198.18, 0.00, 'concluida', '2026-10-28', 'em_aberto'),
  ('delivery', '2026-10-14 13:30:00', 2, 3, 'boleto', 167.46, 0.00, 'concluida', '2026-10-29', 'em_aberto'),
  ('balcao', '2026-10-15 12:30:00', NULL, 11, 'cartao_debito', 53.40, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-16 11:00:00', NULL, 11, 'cartao_credito', 133.49, 0.00, 'concluida', NULL, NULL),
  ('balcao', '2026-10-17 17:00:00', 14, 5, 'cartao_debito', 144.05, 0.00, 'concluida', NULL, NULL),
  ('whatsapp', '2026-10-18 09:15:00', NULL, 7, 'cartao_credito', 138.81, 0.00, 'concluida', NULL, NULL);

-- Item de Venda (relacionamento N:N Venda x Produto)
INSERT INTO venda_produto (id_venda, id_produto, peso_quantidade, preco_unitario) VALUES
  (1, 25, 1.0, 9.90),
  (2, 17, 1.0, 22.90),
  (2, 9, 2.137, 26.90),
  (2, 18, 1.0, 14.90),
  (2, 28, 6.0, 8.90),
  (3, 17, 5.0, 22.90),
  (3, 25, 1.0, 9.90),
  (3, 6, 2.65, 36.90),
  (4, 20, 3.0, 8.90),
  (5, 5, 1.583, 79.90),
  (5, 22, 5.0, 7.90),
  (6, 22, 5.0, 7.90),
  (6, 21, 4.0, 3.50),
  (6, 12, 0.627, 13.90),
  (6, 15, 0.907, 14.90),
  (7, 28, 3.0, 8.90),
  (8, 4, 1.464, 39.90),
  (8, 22, 4.0, 7.90),
  (9, 18, 2.0, 14.90),
  (9, 15, 1.439, 14.90),
  (10, 6, 1.611, 36.90),
  (10, 14, 0.877, 18.90),
  (11, 10, 2.988, 22.90),
  (11, 14, 1.801, 18.90),
  (11, 23, 6.0, 5.90),
  (11, 24, 4.0, 4.50),
  (12, 2, 1.877, 42.90),
  (13, 13, 2.842, 15.90),
  (13, 4, 1.838, 39.90),
  (14, 22, 3.0, 7.90),
  (14, 23, 2.0, 5.90),
  (15, 3, 1.752, 32.50),
  (16, 20, 5.0, 8.90),
  (16, 26, 1.0, 2.50),
  (16, 21, 6.0, 3.50),
  (17, 10, 2.238, 22.90),
  (17, 20, 2.0, 8.90),
  (17, 7, 2.156, 24.90),
  (18, 21, 2.0, 3.50),
  (18, 9, 2.301, 26.90),
  (19, 19, 4.0, 28.90),
  (19, 18, 2.0, 14.90),
  (19, 5, 0.413, 79.90),
  (20, 20, 2.0, 8.90),
  (20, 24, 2.0, 4.50),
  (20, 5, 2.936, 79.90),
  (20, 30, 2.0, 7.90),
  (21, 9, 2.426, 26.90),
  (21, 6, 0.592, 36.90),
  (22, 9, 2.911, 26.90),
  (22, 28, 3.0, 8.90),
  (22, 3, 1.248, 32.50),
  (23, 12, 1.478, 13.90),
  (23, 24, 5.0, 4.50),
  (23, 26, 1.0, 2.50),
  (23, 11, 1.34, 34.90),
  (24, 12, 0.489, 13.90),
  (24, 14, 2.093, 18.90),
  (25, 18, 4.0, 14.90),
  (25, 5, 2.095, 79.90),
  (25, 7, 1.324, 24.90),
  (26, 26, 3.0, 2.50),
  (26, 19, 4.0, 28.90),
  (26, 20, 4.0, 8.90),
  (26, 21, 4.0, 3.50),
  (27, 3, 0.934, 32.50),
  (27, 27, 3.0, 4.90),
  (27, 25, 2.0, 9.90),
  (28, 15, 1.419, 14.90),
  (29, 2, 2.591, 42.90),
  (29, 18, 4.0, 14.90),
  (29, 8, 0.66, 28.90),
  (29, 30, 4.0, 7.90),
  (30, 29, 1.582, 24.90),
  (30, 6, 1.0, 36.90),
  (30, 24, 2.0, 4.50),
  (30, 28, 6.0, 8.90),
  (31, 29, 0.674, 24.90),
  (31, 18, 2.0, 14.90),
  (31, 3, 1.334, 32.50),
  (32, 13, 2.854, 15.90),
  (32, 29, 0.353, 24.90),
  (32, 25, 5.0, 9.90),
  (32, 19, 4.0, 28.90),
  (33, 16, 3.0, 24.90),
  (33, 8, 1.477, 28.90),
  (34, 19, 6.0, 28.90),
  (34, 22, 4.0, 7.90),
  (34, 1, 0.666, 69.90),
  (34, 3, 1.547, 32.50),
  (35, 9, 0.352, 26.90),
  (35, 27, 5.0, 4.90),
  (35, 3, 0.441, 32.50),
  (35, 16, 3.0, 24.90),
  (36, 19, 2.0, 28.90),
  (37, 10, 1.862, 22.90),
  (37, 4, 2.808, 39.90),
  (38, 28, 1.0, 8.90),
  (38, 22, 5.0, 7.90),
  (38, 20, 1.0, 8.90),
  (39, 4, 2.707, 39.90),
  (39, 14, 1.541, 18.90),
  (39, 12, 0.713, 13.90),
  (39, 21, 2.0, 3.50),
  (40, 11, 2.543, 34.90),
  (40, 28, 1.0, 8.90),
  (40, 8, 1.053, 28.90),
  (41, 6, 1.258, 36.90),
  (41, 16, 3.0, 24.90),
  (41, 7, 1.219, 24.90),
  (42, 23, 6.0, 5.90),
  (42, 16, 6.0, 24.90),
  (43, 14, 1.193, 18.90),
  (43, 24, 6.0, 4.50),
  (43, 18, 4.0, 14.90),
  (44, 24, 3.0, 4.50),
  (44, 16, 6.0, 24.90),
  (45, 9, 2.931, 26.90),
  (45, 2, 1.794, 42.90),
  (46, 6, 2.841, 36.90),
  (46, 2, 1.59, 42.90),
  (46, 9, 2.52, 26.90),
  (47, 4, 2.364, 39.90),
  (47, 18, 5.0, 14.90),
  (48, 10, 1.946, 22.90),
  (48, 19, 6.0, 28.90),
  (48, 20, 1.0, 8.90),
  (48, 2, 2.858, 42.90),
  (49, 14, 1.516, 18.90),
  (50, 30, 6.0, 7.90),
  (50, 9, 1.892, 26.90),
  (51, 2, 0.748, 42.90),
  (52, 17, 4.0, 22.90),
  (52, 18, 1.0, 14.90),
  (52, 16, 5.0, 24.90),
  (53, 16, 6.0, 24.90),
  (53, 17, 4.0, 22.90),
  (54, 11, 2.616, 34.90),
  (54, 22, 3.0, 7.90),
  (54, 4, 1.411, 39.90),
  (55, 25, 4.0, 9.90),
  (56, 25, 5.0, 9.90),
  (56, 2, 0.654, 42.90),
  (56, 7, 1.078, 24.90),
  (56, 9, 2.678, 26.90),
  (57, 15, 2.857, 14.90),
  (58, 16, 2.0, 24.90),
  (58, 8, 1.336, 28.90),
  (58, 15, 2.789, 14.90),
  (58, 18, 5.0, 14.90),
  (59, 24, 5.0, 4.50),
  (59, 10, 1.866, 22.90),
  (59, 27, 6.0, 4.90),
  (60, 28, 2.0, 8.90),
  (60, 7, 1.844, 24.90),
  (60, 23, 2.0, 5.90),
  (61, 16, 2.0, 24.90),
  (61, 2, 1.656, 42.90),
  (62, 28, 4.0, 8.90),
  (62, 21, 3.0, 3.50),
  (62, 5, 1.214, 79.90),
  (62, 3, 2.17, 32.50),
  (63, 21, 3.0, 3.50),
  (63, 22, 2.0, 7.90),
  (64, 11, 2.45, 34.90),
  (65, 20, 4.0, 8.90),
  (66, 29, 2.473, 24.90),
  (67, 23, 3.0, 5.90),
  (67, 9, 0.838, 26.90),
  (67, 15, 1.339, 14.90),
  (67, 28, 4.0, 8.90),
  (68, 30, 5.0, 7.90),
  (69, 21, 6.0, 3.50),
  (69, 4, 2.045, 39.90),
  (70, 24, 2.0, 4.50),
  (70, 14, 0.657, 18.90),
  (70, 6, 1.756, 36.90),
  (71, 24, 1.0, 4.50),
  (71, 28, 4.0, 8.90),
  (71, 11, 2.9, 34.90),
  (72, 15, 1.295, 14.90),
  (73, 30, 6.0, 7.90),
  (73, 20, 1.0, 8.90),
  (73, 8, 2.016, 28.90),
  (74, 4, 0.934, 39.90),
  (75, 27, 4.0, 4.90),
  (76, 22, 3.0, 7.90),
  (77, 21, 1.0, 3.50),
  (77, 20, 1.0, 8.90),
  (78, 11, 0.698, 34.90),
  (78, 25, 5.0, 9.90),
  (79, 5, 0.34, 79.90),
  (80, 16, 4.0, 24.90),
  (81, 2, 2.996, 42.90),
  (82, 20, 5.0, 8.90),
  (82, 21, 6.0, 3.50),
  (82, 19, 3.0, 28.90),
  (83, 28, 6.0, 8.90),
  (84, 13, 1.144, 15.90),
  (84, 14, 1.144, 18.90),
  (84, 24, 3.0, 4.50),
  (84, 4, 1.311, 39.90),
  (85, 18, 5.0, 14.90),
  (85, 2, 2.883, 42.90),
  (86, 12, 1.67, 13.90),
  (86, 4, 0.718, 39.90),
  (86, 19, 4.0, 28.90),
  (87, 20, 6.0, 8.90),
  (88, 1, 0.687, 69.90),
  (88, 6, 2.075, 36.90),
  (88, 28, 1.0, 8.90),
  (89, 10, 2.397, 22.90),
  (89, 24, 5.0, 4.50),
  (89, 11, 1.91, 34.90),
  (90, 16, 3.0, 24.90),
  (90, 20, 2.0, 8.90),
  (90, 15, 2.338, 14.90),
  (90, 14, 0.607, 18.90);

-- =====================================================================================
-- 4) SELECT com JOIN  (consultas que cruzam multiplas tabelas)
-- =====================================================================================

-- 4.1 Vendas com nome do cliente (quando houver) e nome do funcionario que atendeu
SELECT
    v.id_venda,
    v.data_hora,
    v.canal,
    COALESCE(c.nome_razao_social, '(cliente nao identificado)') AS cliente,
    f.nome                                                        AS atendido_por,
    v.forma_pagamento,
    v.valor_total,
    v.status
FROM venda v
JOIN funcionario f  ON f.id_funcionario = v.id_funcionario
LEFT JOIN cliente c ON c.id_cliente = v.id_cliente
ORDER BY v.data_hora DESC
LIMIT 20;

-- 4.2 Itens vendidos com nome do produto e categoria (3 tabelas)
SELECT
    v.id_venda,
    v.data_hora,
    p.nome            AS produto,
    cat.descricao      AS categoria,
    vp.peso_quantidade,
    vp.preco_unitario,
    ROUND(vp.peso_quantidade * vp.preco_unitario, 2) AS subtotal_item
FROM venda_produto vp
JOIN venda v             ON v.id_venda = vp.id_venda
JOIN produto p            ON p.id_produto = vp.id_produto
JOIN categoria_produto cat ON cat.id_categoria = p.id_categoria
ORDER BY v.data_hora DESC
LIMIT 20;

-- 4.3 Pedidos de compra com fornecedor, funcionario responsavel e custo total do pedido
SELECT
    pc.id_pedido_compra,
    f.nome_razao_social AS fornecedor,
    fu.nome              AS comprado_por,
    pc.data_pedido,
    pc.prazo_entrega,
    pc.status,
    ROUND(SUM(pcp.quantidade * pcp.preco_unitario_compra), 2) AS custo_total_pedido
FROM pedido_compra pc
JOIN fornecedor f        ON f.id_fornecedor = pc.id_fornecedor
JOIN funcionario fu       ON fu.id_funcionario = pc.id_funcionario
JOIN pedido_compra_produto pcp ON pcp.id_pedido_compra = pc.id_pedido_compra
GROUP BY pc.id_pedido_compra, f.nome_razao_social, fu.nome, pc.data_pedido,
         pc.prazo_entrega, pc.status
ORDER BY pc.data_pedido;

-- 4.4 Clientes autorizados a fiado e o total que ja compraram fiado (mesmo pago)
SELECT
    c.id_cliente,
    c.nome_razao_social,
    c.autorizado_prazo,
    COUNT(v.id_venda)         AS qtd_vendas_fiado,
    COALESCE(SUM(v.valor_total), 0) AS total_fiado
FROM cliente c
LEFT JOIN venda v
       ON v.id_cliente = c.id_cliente
      AND v.forma_pagamento = 'fiado'
WHERE c.autorizado_prazo = TRUE
GROUP BY c.id_cliente, c.nome_razao_social, c.autorizado_prazo
ORDER BY total_fiado DESC;


-- =====================================================================================
-- 5) UPDATE
-- =====================================================================================

-- 5.1 Reajuste de 5% no preco de venda de toda a categoria "Carne Bovina"
UPDATE produto p
JOIN categoria_produto cat ON cat.id_categoria = p.id_categoria
SET p.preco = ROUND(p.preco * 1.05, 2)
WHERE cat.descricao = 'Carne Bovina';

-- 5.2 Baixa manual de pagamento: marca como "pago" os fiados vencidos ha mais de 30 dias
-- que o cliente foi ate a loja e quitou (simulando a rotina da responsavel financeira)
UPDATE venda
SET status_pagamento = 'pago'
WHERE forma_pagamento = 'fiado'
  AND status_pagamento = 'em_aberto'
  AND data_vencimento < '2026-10-20';

-- 5.3 Correcao cadastral: atualiza o telefone de um fornecedor
UPDATE fornecedor
SET telefone_whatsapp = '11999887766'
WHERE nome_razao_social = 'Frigorifico Boi Forte Ltda';

-- 5.4 Recebimento de pedido de compra: muda status para "recebido" e da entrada no
-- estoque dos produtos daquele pedido (resolve, na pratica, o problema P1 -- hoje as
-- entradas nao geram nenhuma movimentacao de estoque)
UPDATE produto p
JOIN pedido_compra_produto pcp ON pcp.id_produto = p.id_produto
SET p.estoque_atual = p.estoque_atual + pcp.quantidade
WHERE pcp.id_pedido_compra = 10;

UPDATE pedido_compra
SET status = 'recebido'
WHERE id_pedido_compra = 10;


-- =====================================================================================
-- 6) DELETE
-- =====================================================================================

-- 6.1 Remove um pedido de compra cancelado (e, em cascata, seus itens na tabela
-- associativa pedido_compra_produto)
DELETE FROM pedido_compra
WHERE status = 'cancelado';

-- 6.2 Remove um cliente cadastrado por engano, que nunca teve nenhuma venda
-- (nao tem FK pendente, entao o DELETE e seguro)
DELETE FROM cliente
WHERE nome_razao_social = 'Marcelo Souza Prado'
  AND NOT EXISTS (
        SELECT 1 FROM venda v WHERE v.id_cliente = cliente.id_cliente
  );

-- 6.3 Remove vendas canceladas com mais de 60 dias (politica de limpeza de dados
-- operacionais que nao tem mais valor de auditoria); os itens em venda_produto saem
-- junto por causa do ON DELETE CASCADE
DELETE FROM venda
WHERE status = 'cancelada'
  AND data_hora < '2026-09-01 00:00:00';


-- =====================================================================================
-- 7) CONSULTAS GERENCIAIS
-- Numeracao de problemas (levantamento de campo, secao "Problemas de gestao
-- identificados"):
--   P1 - Estoque sem saldo automatico e sem estoque minimo parametrizado
--   P2 - Fornecedores e cotacoes fora do sistema (cadastro so na agenda do celular)
--   P3 - Controle de fiado/boleto em planilha manual, com baixa manual
--   P4 - Ausencia de cadastro geral de clientes e de historico de compras
-- =====================================================================================

-- G01 — Quais produtos estao hoje abaixo do estoque minimo?
-- Atende: P1 (ruptura de estoque sem controle automatizado)
SELECT
    p.id_produto,
    p.nome,
    cat.descricao     AS categoria,
    p.estoque_atual,
    p.estoque_minimo,
    (p.estoque_minimo - p.estoque_atual) AS falta_para_o_minimo
FROM produto p
JOIN categoria_produto cat ON cat.id_categoria = p.id_categoria
WHERE p.estoque_atual < p.estoque_minimo
ORDER BY falta_para_o_minimo DESC;

-- G02 — Qual o faturamento (vendas concluidas) por forma de pagamento no periodo?
-- Atende: P3 (visibilidade sobre dinheiro/pix/cartao/fiado/boleto, hoje so em planilha)
SELECT
    forma_pagamento,
    COUNT(*)                   AS qtd_vendas,
    ROUND(SUM(valor_total), 2) AS faturamento
FROM venda
WHERE status = 'concluida'
  AND data_hora BETWEEN '2026-10-01 00:00:00' AND '2026-10-24 23:59:59'
GROUP BY forma_pagamento
ORDER BY faturamento DESC;

-- G03 — Qual o faturamento diario no periodo (para acompanhar os 300-400
-- atendimentos/dia que o dono relatou)?
-- Atende: visao gerencial geral de volume e faturamento por dia
SELECT
    DATE(data_hora)              AS dia,
    COUNT(*)                     AS qtd_vendas,
    ROUND(SUM(valor_total), 2)   AS faturamento_dia
FROM venda
WHERE status = 'concluida'
GROUP BY DATE(data_hora)
ORDER BY dia;

-- G04 — Quanto cada cliente autorizado a fiado deve atualmente (em aberto ou atrasado)?
-- Atende: P3 (controle de valores devidos, hoje em planilha com baixa manual)
SELECT
    c.id_cliente,
    c.nome_razao_social,
    c.telefone,
    COUNT(v.id_venda)              AS vendas_em_aberto,
    ROUND(SUM(v.valor_total), 2)   AS valor_devido
FROM cliente c
JOIN venda v ON v.id_cliente = c.id_cliente
WHERE v.forma_pagamento = 'fiado'
  AND v.status_pagamento IN ('em_aberto', 'atrasado')
GROUP BY c.id_cliente, c.nome_razao_social, c.telefone
ORDER BY valor_devido DESC;

-- G05 — Quais clientes cadastrados nunca fizeram nenhuma compra?
-- Atende: P4 (ausencia de historico de compras / cadastro sem acompanhamento)
SELECT
    c.id_cliente,
    c.nome_razao_social,
    c.telefone,
    c.autorizado_prazo
FROM cliente c
LEFT JOIN venda v ON v.id_cliente = c.id_cliente
WHERE v.id_venda IS NULL;

-- G06 — Quais os 5 produtos mais vendidos (em valor) no periodo?
-- Atende: visao gerencial de mix de produtos / giro
SELECT
    p.id_produto,
    p.nome,
    cat.descricao                                   AS categoria,
    ROUND(SUM(vp.peso_quantidade), 3)                AS qtd_total_vendida,
    ROUND(SUM(vp.peso_quantidade * vp.preco_unitario), 2) AS valor_total_vendido
FROM venda_produto vp
JOIN venda v               ON v.id_venda = vp.id_venda
JOIN produto p              ON p.id_produto = vp.id_produto
JOIN categoria_produto cat  ON cat.id_categoria = p.id_categoria
WHERE v.status = 'concluida'
GROUP BY p.id_produto, p.nome, cat.descricao
ORDER BY valor_total_vendido DESC
LIMIT 5;

-- G07 — Qual o custo total de compras por fornecedor no periodo?
-- Atende: P2 (hoje nao ha visao nenhuma de gasto por fornecedor, so agenda de celular)
SELECT
    f.id_fornecedor,
    f.nome_razao_social,
    COUNT(DISTINCT pc.id_pedido_compra)                      AS qtd_pedidos,
    ROUND(SUM(pcp.quantidade * pcp.preco_unitario_compra), 2) AS custo_total
FROM fornecedor f
JOIN pedido_compra pc          ON pc.id_fornecedor = f.id_fornecedor
JOIN pedido_compra_produto pcp ON pcp.id_pedido_compra = pc.id_pedido_compra
WHERE pc.status <> 'cancelado'
GROUP BY f.id_fornecedor, f.nome_razao_social
ORDER BY custo_total DESC;

-- G08 — Qual o percentual de vendas canceladas por canal?
-- Atende: visao gerencial de qualidade de atendimento por canal (balcao/telefone/
-- whatsapp/delivery)
SELECT
    canal,
    COUNT(*)                                                       AS total_vendas,
    SUM(CASE WHEN status = 'cancelada' THEN 1 ELSE 0 END)          AS canceladas,
    ROUND(100 * SUM(CASE WHEN status = 'cancelada' THEN 1 ELSE 0 END)
              / COUNT(*), 1)                                        AS pct_cancelamento
FROM venda
GROUP BY canal
ORDER BY pct_cancelamento DESC;


-- =====================================================================================
-- 8) CONSULTAS DE AUDITORIA
-- Verificam consistencia e integridade dos dados (coisas que uma FK/CHECK simples
-- nao cobre, por envolverem regra de negocio entre tabelas diferentes).
-- =====================================================================================

-- A01 — Existe alguma venda fiado para cliente que nao esta autorizado a prazo?
-- Atende: P3 (falha de controle que hoje passa batido na planilha manual)
SELECT
    v.id_venda,
    v.data_hora,
    c.id_cliente,
    c.nome_razao_social,
    c.autorizado_prazo,
    v.forma_pagamento,
    v.valor_total
FROM venda v
JOIN cliente c ON c.id_cliente = v.id_cliente
WHERE v.forma_pagamento = 'fiado'
  AND c.autorizado_prazo = FALSE;

-- A02 — Existe alguma venda cujo valor_total nao bate com a soma dos itens
-- (peso_quantidade * preco_unitario) menos o desconto?
-- Atende: consistencia financeira do caixa (conferencia de digitacao)
SELECT
    v.id_venda,
    v.data_hora,
    v.valor_total                                   AS valor_total_registrado,
    v.desconto,
    ROUND(SUM(vp.peso_quantidade * vp.preco_unitario) - v.desconto, 2) AS valor_total_calculado,
    ROUND(v.valor_total -
          (SUM(vp.peso_quantidade * vp.preco_unitario) - v.desconto), 2) AS diferenca
FROM venda v
JOIN venda_produto vp ON vp.id_venda = v.id_venda
GROUP BY v.id_venda, v.data_hora, v.valor_total, v.desconto
HAVING ABS(diferenca) > 0.01;

-- A03 — Existe venda fiado/boleto sem data de vencimento ou sem status de pagamento
-- preenchidos? (checagem de completude, alem do que o CHECK ja garante)
-- Atende: P3 (consistencia do controle de prazo)
SELECT id_venda, forma_pagamento, data_vencimento, status_pagamento
FROM venda
WHERE forma_pagamento IN ('fiado', 'boleto')
  AND (data_vencimento IS NULL OR status_pagamento IS NULL);

-- A04 — Existe algum produto sem nenhum movimento de venda nos ultimos 30 dias
-- com estoque atual maior que zero (indicio de encalhe/perda potencial)?
-- Atende: P1 (giro de estoque, complementa o controle de minimo)
SELECT
    p.id_produto,
    p.nome,
    p.estoque_atual,
    MAX(v.data_hora) AS ultima_venda
FROM produto p
LEFT JOIN venda_produto vp ON vp.id_produto = p.id_produto
LEFT JOIN venda v          ON v.id_venda = vp.id_venda AND v.status = 'concluida'
GROUP BY p.id_produto, p.nome, p.estoque_atual
HAVING ultima_venda IS NULL OR ultima_venda < '2026-09-24 00:00:00'
ORDER BY ultima_venda;

-- A05 — Existe pedido de compra sem nenhum item lancado em pedido_compra_produto?
-- Atende: integridade referencial de negocio (pedido "vazio" nao deveria existir)
SELECT pc.id_pedido_compra, pc.data_pedido, pc.status
FROM pedido_compra pc
LEFT JOIN pedido_compra_produto pcp ON pcp.id_pedido_compra = pc.id_pedido_compra
WHERE pcp.id_produto IS NULL;

-- A06 — Existe cliente com CPF/CNPJ duplicado ou vazio apesar de ja ter comprado fiado?
-- Atende: P3/P4 (qualidade do cadastro usado para cobranca)
SELECT c.id_cliente, c.nome_razao_social, c.cpf_cnpj
FROM cliente c
JOIN venda v ON v.id_cliente = c.id_cliente
WHERE v.forma_pagamento = 'fiado'
  AND (c.cpf_cnpj IS NULL OR c.cpf_cnpj = '')
GROUP BY c.id_cliente, c.nome_razao_social, c.cpf_cnpj;
