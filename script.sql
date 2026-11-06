-- =====================================================================================
-- Casa de Carnes Rotineira Caroline — Modelagem de Banco de Dados
-- Grupo: Gabriel Diniz Tavares da Costa, Isaac Santos Alves da Costa,
--        Rafael Aceiro Ferreira Gomes, Paulo Henrique Fernandez Prado
-- Script SQL — Entrega 2
-- SGBD: MySQL 8.0.16+ (CHECK exige 8.0.16+)  |  Codificacao: utf8mb4  |  Engine: InnoDB
--
-- Como executar:
--   1) Rode este arquivo inteiro de uma vez (ele recria o banco do zero).
--   2) Ordem: CREATE DATABASE -> CREATE TABLE -> INSERT -> SELECT com JOIN -> UPDATE
--      -> DELETE -> consultas gerenciais (G) -> consultas de auditoria (A).
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
-- 2) CREATE TABLE + CONSTRAINTS (alinhado ao DER conceitual v2.1 e ao modelo logico)
-- =====================================================================================

-- FUNCIONARIO: Pessoa física que presta serviço ao estabelecimento em uma função definida (proprietário, açougueiro, balconista, caixa, ajudante geral, entregador ou administrativo/financeiro) e que executa e responde pelas operações registradas no sistema. Difere de CLIENTE e FORNECEDOR, que são partes externas ao estabelecimento.
CREATE TABLE FUNCIONARIO (
  ID_FUNCIONARIO INT NOT NULL AUTO_INCREMENT,
  NM_FUNCIONARIO VARCHAR(100) NOT NULL,
  TP_FUNCAO VARCHAR(20) NOT NULL,
  NR_TELEFONE VARCHAR(11) NULL,
  IN_ATIVO TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT PK_FUNCIONARIO PRIMARY KEY (ID_FUNCIONARIO),
  CONSTRAINT CK_FUNCIONARIO_TP_FUNCAO CHECK (TP_FUNCAO IN ('PROPRIETARIO','ACOUGUEIRO','BALCONISTA','CAIXA','AJUDANTE_GERAL','ENTREGADOR','ADMIN_FINANCEIRO')),
  CONSTRAINT CK_FUNCIONARIO_NR_TELEFONE CHECK (NR_TELEFONE REGEXP '^[0-9]{10,11}$'),
  CONSTRAINT CK_FUNCIONARIO_IN_ATIVO CHECK (IN_ATIVO IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FORNECEDOR: Pessoa jurídica (ou produtor) que vende mercadorias ao estabelecimento mediante pedido de compra. Difere de CLIENTE porque é origem — e não destino — da mercadoria. Hoje é conhecido apenas pela agenda do celular do proprietário (problema P1).
CREATE TABLE FORNECEDOR (
  ID_FORNECEDOR INT NOT NULL AUTO_INCREMENT,
  NM_FORNECEDOR VARCHAR(100) NOT NULL,
  NR_CNPJ CHAR(14) NULL,
  NR_TELEFONE VARCHAR(11) NOT NULL,
  IN_HABITUAL TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT PK_FORNECEDOR PRIMARY KEY (ID_FORNECEDOR),
  CONSTRAINT UQ_FORNECEDOR_NR_CNPJ UNIQUE (NR_CNPJ),
  CONSTRAINT CK_FORNECEDOR_NR_CNPJ CHECK (NR_CNPJ REGEXP '^[0-9]{14}$'),
  CONSTRAINT CK_FORNECEDOR_NR_TELEFONE CHECK (NR_TELEFONE REGEXP '^[0-9]{10,11}$'),
  CONSTRAINT CK_FORNECEDOR_IN_HABITUAL CHECK (IN_HABITUAL IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CATEGORIA: Agrupamento de produtos que compartilham a mesma regra de armazenamento e conservação (carne bovina, suína, aves, congelados, mercearia, massas, bebidas, rotisseria, churrasco). Difere de PRODUTO por descrever o grupo, não o item vendável.
CREATE TABLE CATEGORIA (
  ID_CATEGORIA INT NOT NULL AUTO_INCREMENT,
  NM_CATEGORIA VARCHAR(50) NOT NULL,
  DS_REGRA_ARMAZENAMENTO VARCHAR(255) NOT NULL,
  IN_PERECIVEL TINYINT(1) NOT NULL,
  IN_EXIGE_INSPECAO TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT PK_CATEGORIA PRIMARY KEY (ID_CATEGORIA),
  CONSTRAINT UQ_CATEGORIA_NM_CATEGORIA UNIQUE (NM_CATEGORIA),
  CONSTRAINT CK_CATEGORIA_IN_PERECIVEL CHECK (IN_PERECIVEL IN (0,1)),
  CONSTRAINT CK_CATEGORIA_IN_EXIGE_INSPECAO CHECK (IN_EXIGE_INSPECAO IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CLIENTE: Pessoa física ou jurídica que compra do estabelecimento e foi cadastrada porque a operação exigiu identificação (nota com CPF, boleto, faturamento ou venda a prazo). Difere do comprador anônimo de balcão, que não é cliente cadastrado (RN09).
CREATE TABLE CLIENTE (
  ID_CLIENTE INT NOT NULL AUTO_INCREMENT,
  NM_CLIENTE VARCHAR(100) NOT NULL,
  TP_PESSOA CHAR(1) NOT NULL,
  NR_DOCUMENTO VARCHAR(14) NOT NULL,
  NR_TELEFONE VARCHAR(11) NOT NULL,
  DS_LOGRADOURO VARCHAR(100) NOT NULL,
  NR_ENDERECO VARCHAR(10) NOT NULL,
  NM_BAIRRO VARCHAR(60) NOT NULL,
  NR_CEP CHAR(8) NOT NULL,
  IN_AUTORIZADO_PRAZO TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT PK_CLIENTE PRIMARY KEY (ID_CLIENTE),
  CONSTRAINT UQ_CLIENTE_NR_DOCUMENTO UNIQUE (NR_DOCUMENTO),
  CONSTRAINT CK_CLIENTE_TP_PESSOA CHECK (TP_PESSOA IN ('F','J')),
  CONSTRAINT CK_CLIENTE_NR_DOCUMENTO CHECK (NR_DOCUMENTO REGEXP '^[0-9]+$'),
  CONSTRAINT CK_CLIENTE_NR_TELEFONE CHECK (NR_TELEFONE REGEXP '^[0-9]{10,11}$'),
  CONSTRAINT CK_CLIENTE_NR_CEP CHECK (NR_CEP REGEXP '^[0-9]{8}$'),
  CONSTRAINT CK_CLIENTE_IN_AUTORIZADO_PRAZO CHECK (IN_AUTORIZADO_PRAZO IN (0,1)),
  CONSTRAINT CK_CLIENTE_DOC_TAMANHO CHECK ((TP_PESSOA = 'F' AND CHAR_LENGTH(NR_DOCUMENTO) = 11) OR (TP_PESSOA = 'J' AND CHAR_LENGTH(NR_DOCUMENTO) = 14))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PRODUTO: Item que o estabelecimento compra, armazena ou vende — corte de carne, peça inteira recebida do fornecedor, produto de mercearia, bebida ou preparado — identificado por nome único e pertencente a uma categoria. Difere de LOTE, que é uma remessa específica do produto.
CREATE TABLE PRODUTO (
  ID_PRODUTO INT NOT NULL AUTO_INCREMENT,
  NM_PRODUTO VARCHAR(100) NOT NULL,
  ID_CATEGORIA INT NOT NULL,
  TP_UNIDADE_VENDA CHAR(2) NOT NULL,
  VL_PRECO_VENDA DECIMAL(10,2) NULL,
  QT_ESTOQUE_MINIMO DECIMAL(10,3) NULL,
  IN_VENDAVEL TINYINT(1) NOT NULL DEFAULT 1,
  IN_ATIVO TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT PK_PRODUTO PRIMARY KEY (ID_PRODUTO),
  CONSTRAINT UQ_PRODUTO_NM_PRODUTO UNIQUE (NM_PRODUTO),
  CONSTRAINT FK_PRODUTO_ID_CATEGORIA FOREIGN KEY (ID_CATEGORIA) REFERENCES CATEGORIA (ID_CATEGORIA),
  CONSTRAINT CK_PRODUTO_TP_UNIDADE_VENDA CHECK (TP_UNIDADE_VENDA IN ('KG','UN')),
  CONSTRAINT CK_PRODUTO_VL_PRECO_VENDA CHECK (VL_PRECO_VENDA >= 0),
  CONSTRAINT CK_PRODUTO_QT_ESTOQUE_MINIMO CHECK (QT_ESTOQUE_MINIMO >= 0),
  CONSTRAINT CK_PRODUTO_IN_VENDAVEL CHECK (IN_VENDAVEL IN (0,1)),
  CONSTRAINT CK_PRODUTO_IN_ATIVO CHECK (IN_ATIVO IN (0,1)),
  CONSTRAINT CK_PRODUTO_PRECO_VENDAVEL CHECK (IN_VENDAVEL = 0 OR VL_PRECO_VENDA IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PEDIDO_COMPRA: Solicitação de mercadorias feita pelo estabelecimento a um fornecedor, com data, prazo de entrega combinado e, depois do recebimento, nota fiscal e eventual divergência. Difere de VENDA porque é compra (entrada), não venda (saída).
CREATE TABLE PEDIDO_COMPRA (
  ID_PEDIDO_COMPRA INT NOT NULL AUTO_INCREMENT,
  ID_FORNECEDOR INT NOT NULL,
  ID_FUNCIONARIO INT NOT NULL,
  DT_PEDIDO DATE NOT NULL,
  DT_PREVISTA_ENTREGA DATE NOT NULL,
  DT_RECEBIMENTO DATE NULL,
  NR_NOTA_FISCAL VARCHAR(20) NULL,
  ST_PEDIDO VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
  DS_DIVERGENCIA VARCHAR(255) NULL,
  CONSTRAINT PK_PEDIDO_COMPRA PRIMARY KEY (ID_PEDIDO_COMPRA),
  CONSTRAINT FK_PEDIDO_COMPRA_ID_FORNECEDOR FOREIGN KEY (ID_FORNECEDOR) REFERENCES FORNECEDOR (ID_FORNECEDOR),
  CONSTRAINT FK_PEDIDO_COMPRA_ID_FUNCIONARIO FOREIGN KEY (ID_FUNCIONARIO) REFERENCES FUNCIONARIO (ID_FUNCIONARIO),
  CONSTRAINT CK_PEDIDO_COMPRA_ST_PEDIDO CHECK (ST_PEDIDO IN ('PENDENTE','RECEBIDO','RECEBIDO_DIVERGENTE','CANCELADO')),
  CONSTRAINT CK_PEDIDO_DATAS CHECK (DT_PREVISTA_ENTREGA >= DT_PEDIDO AND (DT_RECEBIMENTO IS NULL OR DT_RECEBIMENTO >= DT_PEDIDO)),
  CONSTRAINT CK_PEDIDO_RECEBIMENTO CHECK (ST_PEDIDO NOT IN ('RECEBIDO','RECEBIDO_DIVERGENTE') OR (DT_RECEBIMENTO IS NOT NULL AND NR_NOTA_FISCAL IS NOT NULL)),
  CONSTRAINT CK_PEDIDO_DIVERGENCIA CHECK (ST_PEDIDO <> 'RECEBIDO_DIVERGENTE' OR DS_DIVERGENCIA IS NOT NULL),
  KEY IDX_PEDIDO_DT (DT_PEDIDO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ITEM_PEDIDO_COMPRA: Entidade associativa do relacionamento contém (PEDIDO_COMPRA × PRODUTO): registra cada produto solicitado em um pedido, com a quantidade pedida e o preço combinado. Existe porque a quantidade e o preço só fazem sentido para o par pedido-produto e porque cada item origina lotes.
CREATE TABLE ITEM_PEDIDO_COMPRA (
  ID_PEDIDO_COMPRA INT NOT NULL,
  ID_PRODUTO INT NOT NULL,
  QT_PEDIDA DECIMAL(10,3) NOT NULL,
  VL_UNITARIO_COMPRA DECIMAL(10,2) NOT NULL,
  CONSTRAINT PK_ITEM_PEDIDO_COMPRA PRIMARY KEY (ID_PEDIDO_COMPRA, ID_PRODUTO),
  CONSTRAINT FK_ITEM_PEDIDO_COMPRA_ID_PEDIDO_COMPRA FOREIGN KEY (ID_PEDIDO_COMPRA) REFERENCES PEDIDO_COMPRA (ID_PEDIDO_COMPRA),
  CONSTRAINT FK_ITEM_PEDIDO_COMPRA_ID_PRODUTO FOREIGN KEY (ID_PRODUTO) REFERENCES PRODUTO (ID_PRODUTO),
  CONSTRAINT CK_ITEM_PEDIDO_COMPRA_QT_PEDIDA CHECK (QT_PEDIDA > 0),
  CONSTRAINT CK_ITEM_PEDIDO_COMPRA_VL_UNITARIO_COMPRA CHECK (VL_UNITARIO_COMPRA >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- LOTE: Remessa de um produto recebida em um pedido de compra, identificada pelo número impresso na embalagem, pela validade e pelo registro de inspeção sanitária. Difere de PRODUTO (o item em si) por representar uma partida física específica, o que permite rastrear procedência e validade (problema P6).
CREATE TABLE LOTE (
  ID_LOTE INT NOT NULL AUTO_INCREMENT,
  ID_PEDIDO_COMPRA INT NOT NULL,
  ID_PRODUTO INT NOT NULL,
  NR_LOTE VARCHAR(30) NULL,
  DT_VALIDADE DATE NULL,
  NR_REGISTRO_INSPECAO VARCHAR(20) NULL,
  CONSTRAINT PK_LOTE PRIMARY KEY (ID_LOTE),
  CONSTRAINT UQ_LOTE_ITEM_NR UNIQUE (ID_PEDIDO_COMPRA, ID_PRODUTO, NR_LOTE),
  CONSTRAINT FK_LOTE_ITEM FOREIGN KEY (ID_PEDIDO_COMPRA, ID_PRODUTO) REFERENCES ITEM_PEDIDO_COMPRA (ID_PEDIDO_COMPRA, ID_PRODUTO),
  KEY IDX_LOTE_VALIDADE (DT_VALIDADE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- MOVIMENTACAO_ESTOQUE: Registro de uma variação no saldo de um produto — entrada por compra, saída ou entrada por desossa, descarte de vencido ou ajuste de contagem —, com quantidade, data e responsável. Difere de ITEM_VENDA porque a venda não gera movimentação: o saldo considera as vendas separadamente (RN23). Resolve os problemas P2, P4 e P6.
CREATE TABLE MOVIMENTACAO_ESTOQUE (
  ID_MOVIMENTACAO INT NOT NULL AUTO_INCREMENT,
  ID_PRODUTO INT NOT NULL,
  ID_LOTE INT NULL,
  ID_FUNCIONARIO INT NOT NULL,
  DT_HORA_MOVIMENTACAO DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  TP_SENTIDO CHAR(1) NOT NULL,
  TP_MOTIVO VARCHAR(10) NOT NULL,
  QT_MOVIMENTADA DECIMAL(10,3) NOT NULL,
  DS_OBSERVACAO VARCHAR(255) NULL,
  CONSTRAINT PK_MOVIMENTACAO_ESTOQUE PRIMARY KEY (ID_MOVIMENTACAO),
  CONSTRAINT FK_MOVIMENTACAO_ESTOQUE_ID_PRODUTO FOREIGN KEY (ID_PRODUTO) REFERENCES PRODUTO (ID_PRODUTO),
  CONSTRAINT FK_MOVIMENTACAO_ESTOQUE_ID_LOTE FOREIGN KEY (ID_LOTE) REFERENCES LOTE (ID_LOTE),
  CONSTRAINT FK_MOVIMENTACAO_ESTOQUE_ID_FUNCIONARIO FOREIGN KEY (ID_FUNCIONARIO) REFERENCES FUNCIONARIO (ID_FUNCIONARIO),
  CONSTRAINT CK_MOVIMENTACAO_ESTOQUE_TP_SENTIDO CHECK (TP_SENTIDO IN ('E','S')),
  CONSTRAINT CK_MOVIMENTACAO_ESTOQUE_TP_MOTIVO CHECK (TP_MOTIVO IN ('COMPRA','DESOSSA','DESCARTE','AJUSTE')),
  CONSTRAINT CK_MOVIMENTACAO_ESTOQUE_QT_MOVIMENTADA CHECK (QT_MOVIMENTADA > 0),
  CONSTRAINT CK_MOV_MOTIVO_SENTIDO CHECK ((TP_MOTIVO <> 'COMPRA' OR TP_SENTIDO = 'E') AND (TP_MOTIVO <> 'DESCARTE' OR TP_SENTIDO = 'S')),
  CONSTRAINT CK_MOV_LOTE_OBRIGATORIO CHECK (TP_MOTIVO = 'AJUSTE' OR ID_LOTE IS NOT NULL),
  KEY IDX_MOV_PRODUTO_DATA (ID_PRODUTO, DT_HORA_MOVIMENTACAO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- VENDA: Operação de venda de produtos a um comprador — no balcão, por telefone ou por WhatsApp —, com forma de pagamento única, eventual desconto autorizado e, se a prazo, vencimento e baixa. Inclui a encomenda (venda registrada para atendimento futuro) e a venda cancelada, que permanecem no histórico (RN18). Resolve o problema P5 (fiado/boleto fora do sistema).
CREATE TABLE VENDA (
  ID_VENDA INT NOT NULL AUTO_INCREMENT,
  ID_CLIENTE INT NULL,
  ID_FUNCIONARIO INT NOT NULL,
  ID_FUNCIONARIO_AUTORIZADOR INT NULL,
  DT_HORA_VENDA DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  TP_CANAL VARCHAR(10) NOT NULL,
  TP_FORMA_PAGAMENTO VARCHAR(20) NOT NULL,
  ST_VENDA VARCHAR(12) NOT NULL DEFAULT 'CONCLUIDA',
  VL_DESCONTO DECIMAL(10,2) NOT NULL DEFAULT 0,
  DT_VENCIMENTO DATE NULL,
  DT_PAGAMENTO DATE NULL,
  NR_CUPOM_FISCAL VARCHAR(20) NULL,
  DT_PREVISTA_ATENDIMENTO DATE NULL,
  CONSTRAINT PK_VENDA PRIMARY KEY (ID_VENDA),
  CONSTRAINT FK_VENDA_ID_CLIENTE FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTE (ID_CLIENTE),
  CONSTRAINT FK_VENDA_ID_FUNCIONARIO FOREIGN KEY (ID_FUNCIONARIO) REFERENCES FUNCIONARIO (ID_FUNCIONARIO),
  CONSTRAINT FK_VENDA_ID_FUNCIONARIO_AUTORIZADOR FOREIGN KEY (ID_FUNCIONARIO_AUTORIZADOR) REFERENCES FUNCIONARIO (ID_FUNCIONARIO),
  CONSTRAINT CK_VENDA_TP_CANAL CHECK (TP_CANAL IN ('BALCAO','TELEFONE','WHATSAPP')),
  CONSTRAINT CK_VENDA_TP_FORMA_PAGAMENTO CHECK (TP_FORMA_PAGAMENTO IN ('DINHEIRO','PIX','CARTAO_CREDITO','CARTAO_DEBITO','VALE_ALIMENTACAO','BOLETO','FIADO')),
  CONSTRAINT CK_VENDA_ST_VENDA CHECK (ST_VENDA IN ('CONCLUIDA','ENCOMENDADA','CANCELADA')),
  CONSTRAINT CK_VENDA_VL_DESCONTO CHECK (VL_DESCONTO >= 0),
  CONSTRAINT CK_VENDA_PRAZO_EXIGE_CLIENTE CHECK (TP_FORMA_PAGAMENTO NOT IN ('BOLETO','FIADO') OR (ID_CLIENTE IS NOT NULL AND DT_VENCIMENTO IS NOT NULL)),
  CONSTRAINT CK_VENDA_VENCIMENTO_SO_PRAZO CHECK (TP_FORMA_PAGAMENTO IN ('BOLETO','FIADO') OR DT_VENCIMENTO IS NULL),
  CONSTRAINT CK_VENDA_DESCONTO_AUTORIZADO CHECK (VL_DESCONTO = 0 OR ID_FUNCIONARIO_AUTORIZADOR IS NOT NULL),
  CONSTRAINT CK_VENDA_ENCOMENDA_DATA CHECK (ST_VENDA <> 'ENCOMENDADA' OR DT_PREVISTA_ATENDIMENTO IS NOT NULL),
  CONSTRAINT CK_VENDA_DATAS CHECK ((DT_VENCIMENTO IS NULL OR DT_VENCIMENTO >= DATE(DT_HORA_VENDA)) AND (DT_PAGAMENTO IS NULL OR DT_PAGAMENTO >= DATE(DT_HORA_VENDA))),
  KEY IDX_VENDA_DT_HORA (DT_HORA_VENDA),
  KEY IDX_VENDA_PRAZO (TP_FORMA_PAGAMENTO, DT_PAGAMENTO, DT_VENCIMENTO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ITEM_VENDA: Tabela que implementa o relacionamento compõe (VENDA × PRODUTO): registra cada produto vendido em uma venda, com o peso ou quantidade vendidos e o preço unitário praticado naquele momento. O preço é guardado aqui porque o preço vigente do produto muda com o tempo.
CREATE TABLE ITEM_VENDA (
  ID_VENDA INT NOT NULL,
  ID_PRODUTO INT NOT NULL,
  QT_VENDIDA DECIMAL(10,3) NOT NULL,
  VL_UNITARIO_VENDA DECIMAL(10,2) NOT NULL,
  CONSTRAINT PK_ITEM_VENDA PRIMARY KEY (ID_VENDA, ID_PRODUTO),
  CONSTRAINT FK_ITEM_VENDA_ID_VENDA FOREIGN KEY (ID_VENDA) REFERENCES VENDA (ID_VENDA),
  CONSTRAINT FK_ITEM_VENDA_ID_PRODUTO FOREIGN KEY (ID_PRODUTO) REFERENCES PRODUTO (ID_PRODUTO),
  CONSTRAINT CK_ITEM_VENDA_QT_VENDIDA CHECK (QT_VENDIDA > 0),
  CONSTRAINT CK_ITEM_VENDA_VL_UNITARIO_VENDA CHECK (VL_UNITARIO_VENDA >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ENTREGA: Deslocamento de uma venda até o endereço do comprador (delivery), realizado por um entregador, com endereço de entrega, horários de saída e de recebimento e situação. Difere de VENDA porque nem toda venda é entregue: é a parte logística opcional de uma venda por telefone ou WhatsApp.
CREATE TABLE ENTREGA (
  ID_ENTREGA INT NOT NULL AUTO_INCREMENT,
  ID_VENDA INT NOT NULL,
  ID_FUNCIONARIO_ENTREGADOR INT NOT NULL,
  DS_LOGRADOURO VARCHAR(100) NOT NULL,
  NR_ENDERECO VARCHAR(10) NOT NULL,
  NM_BAIRRO VARCHAR(60) NOT NULL,
  NR_CEP CHAR(8) NOT NULL,
  ST_ENTREGA VARCHAR(10) NOT NULL DEFAULT 'PENDENTE',
  DT_HORA_SAIDA DATETIME NULL,
  DT_HORA_ENTREGA DATETIME NULL,
  CONSTRAINT PK_ENTREGA PRIMARY KEY (ID_ENTREGA),
  CONSTRAINT UQ_ENTREGA_ID_VENDA UNIQUE (ID_VENDA),
  CONSTRAINT FK_ENTREGA_ID_VENDA FOREIGN KEY (ID_VENDA) REFERENCES VENDA (ID_VENDA),
  CONSTRAINT FK_ENTREGA_ID_FUNCIONARIO_ENTREGADOR FOREIGN KEY (ID_FUNCIONARIO_ENTREGADOR) REFERENCES FUNCIONARIO (ID_FUNCIONARIO),
  CONSTRAINT CK_ENTREGA_NR_CEP CHECK (NR_CEP REGEXP '^[0-9]{8}$'),
  CONSTRAINT CK_ENTREGA_ST_ENTREGA CHECK (ST_ENTREGA IN ('PENDENTE','EM_ROTA','ENTREGUE')),
  CONSTRAINT CK_ENTREGA_HORARIOS CHECK (DT_HORA_ENTREGA IS NULL OR (DT_HORA_SAIDA IS NOT NULL AND DT_HORA_ENTREGA >= DT_HORA_SAIDA)),
  CONSTRAINT CK_ENTREGA_ENTREGUE CHECK (ST_ENTREGA <> 'ENTREGUE' OR DT_HORA_ENTREGA IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- VIEW: saldo de estoque por produto = entradas - saídas (MOVIMENTACAO_ESTOQUE) - quantidades vendidas (ITEM_VENDA, exceto canceladas) — RN23
CREATE VIEW VW_SALDO_ESTOQUE AS
SELECT p.ID_PRODUTO, p.NM_PRODUTO,
       COALESCE((SELECT SUM(CASE m.TP_SENTIDO WHEN 'E' THEN m.QT_MOVIMENTADA ELSE -m.QT_MOVIMENTADA END)
                 FROM MOVIMENTACAO_ESTOQUE m WHERE m.ID_PRODUTO = p.ID_PRODUTO),0)
     - COALESCE((SELECT SUM(i.QT_VENDIDA) FROM ITEM_VENDA i JOIN VENDA v ON v.ID_VENDA = i.ID_VENDA
                 WHERE i.ID_PRODUTO = p.ID_PRODUTO AND v.ST_VENDA <> 'CANCELADA'),0) AS QT_SALDO
FROM PRODUTO p;

-- VIEW: total de cada venda (valor bruto, desconto e líquido) — total é derivado, não armazenado
CREATE VIEW VW_TOTAL_VENDA AS
SELECT v.ID_VENDA, SUM(i.QT_VENDIDA * i.VL_UNITARIO_VENDA) AS VL_BRUTO, v.VL_DESCONTO,
       SUM(i.QT_VENDIDA * i.VL_UNITARIO_VENDA) - v.VL_DESCONTO AS VL_LIQUIDO
FROM VENDA v JOIN ITEM_VENDA i ON i.ID_VENDA = v.ID_VENDA
GROUP BY v.ID_VENDA, v.VL_DESCONTO;

-- =====================================================================================
-- 3) INSERT INTO  (carga da massa de dados, na ordem das dependencias de FK)
-- =====================================================================================

-- Funcionario
INSERT INTO FUNCIONARIO (NM_FUNCIONARIO, TP_FUNCAO, NR_TELEFONE, IN_ATIVO) VALUES
  ('Carolina Mendes Rotineira', 'PROPRIETARIO', '11977001001', 1),
  ('Jose Carlos Pereira', 'ACOUGUEIRO', '11977001002', 1),
  ('Antonio Ferreira Lima', 'ACOUGUEIRO', '11977001003', 1),
  ('Marcos Vinicius Souza', 'ACOUGUEIRO', '11977001004', 1),
  ('Paulo Roberto Alves', 'ACOUGUEIRO', '11977001005', 1),
  ('Edilson Rodrigues Dias', 'ACOUGUEIRO', '11977001006', 1),
  ('Fernanda Oliveira Santos', 'BALCONISTA', '11977001007', 1),
  ('Juliana Costa Ramos', 'BALCONISTA', '11977001008', 1),
  ('Ricardo Nunes Barbosa', 'CAIXA', '11977001009', 1),
  ('Patricia Gomes Teixeira', 'CAIXA', '11977001010', 1),
  ('Luiz Henrique Martins', 'AJUDANTE_GERAL', '11977001011', 1),
  ('Diego Almeida Rocha', 'ENTREGADOR', '11977001012', 1),
  ('Sandra Regina Fonseca', 'ADMIN_FINANCEIRO', '11977001013', 1);

-- Fornecedor (CNPJ nao constava na carga anterior: fica NULL, coluna aceita nulo)
INSERT INTO FORNECEDOR (NM_FORNECEDOR, NR_CNPJ, NR_TELEFONE, IN_HABITUAL) VALUES
  ('Frigorifico Boi Forte Ltda', NULL, '11988001122', 1),
  ('Granja Penas Douradas Ltda', NULL, '11988002233', 1),
  ('Suinos do Vale Agropecuaria', NULL, '11988003344', 1),
  ('Distribuidora Sabor e Cia', NULL, '11988004455', 1),
  ('Congelados Polar Distribuicao', NULL, '11988005566', 1),
  ('Bebidas Fonte Clara Ltda', NULL, '11988006677', 1);

-- Categoria
INSERT INTO CATEGORIA (NM_CATEGORIA, DS_REGRA_ARMAZENAMENTO, IN_PERECIVEL, IN_EXIGE_INSPECAO) VALUES
  ('Carne Bovina', 'Camara fria 0 a 4 C, uso em ate 3 dias apos abertura', 1, 1),
  ('Carne Suina', 'Camara fria 0 a 4 C, uso em ate 3 dias apos abertura', 1, 1),
  ('Aves', 'Camara fria 0 a 4 C, uso em ate 2 dias apos abertura', 1, 1),
  ('Congelados', 'Freezer -18 C, nao recongelar apos descongelo', 1, 0),
  ('Mercearia', 'Ambiente seco e arejado', 0, 0),
  ('Massas', 'Ambiente seco, ao abrigo de umidade', 0, 0),
  ('Bebidas', 'Ambiente ou refrigerado conforme o item', 0, 0),
  ('Rotisseria e Churrasco', 'Refrigerado, consumo em ate 24h apos preparo', 1, 0);

-- Cliente (bairro e CEP sao ficticios: o endereco antigo era um campo unico, sem esses dados)
INSERT INTO CLIENTE (NM_CLIENTE, TP_PESSOA, NR_DOCUMENTO, NR_TELEFONE, DS_LOGRADOURO, NR_ENDERECO, NM_BAIRRO, NR_CEP, IN_AUTORIZADO_PRAZO) VALUES
  ('Mariana Souza Lima', 'F', '11122233344', '11966001001', 'Rua das Acacias', '120', 'Jardim Alegre', '13001237', 1),
  ('Joao Pedro Castro', 'F', '22233344455', '11966001002', 'Rua das Palmeiras', '45', 'Vila Nova', '13002474', 0),
  ('Restaurante Sabor Caseiro Ltda', 'J', '11222333000155', '11966001003', 'Av. Central', '900', 'Bela Vista', '13003711', 1),
  ('Beatriz Andrade Reis', 'F', '33344455566', '11966001004', 'Rua Dois de Maio', '88', 'Santo Antonio', '13004948', 0),
  ('Padaria Pao Dourado Ltda', 'J', '22333444000166', '11966001005', 'Rua das Flores', '230', 'Industrial', '13006185', 1),
  ('Lucas Gabriel Moreira', 'F', '44455566677', '11966001006', 'Rua Bela Vista', '15', 'Parque das Flores', '13007422', 0),
  ('Camila Fernandes Pires', 'F', '55566677788', '11966001007', 'Rua Sao Jose', '310', 'Centro', '13008659', 0),
  ('Hotel Pousada Boa Estadia Ltda', 'J', '33444555000177', '11966001008', 'Av. das Nacoes', '500', 'Jardim Alegre', '13009896', 1),
  ('Rafael Augusto Nogueira', 'F', '66677788899', '11966001009', 'Rua Vinte de Abril', '77', 'Vila Nova', '13011133', 0),
  ('Vanessa Cristina Barros', 'F', '77788899900', '11966001010', 'Rua das Hortensias', '64', 'Bela Vista', '13012370', 0),
  ('Gustavo Henrique Lacerda', 'F', '88899900011', '11966001011', 'Rua do Comercio', '12', 'Santo Antonio', '13013607', 0),
  ('Ana Paula Siqueira', 'F', '99900011122', '11966001012', 'Rua Jardim Alegre', '33', 'Industrial', '13014844', 0),
  ('Felipe Tavares Monteiro', 'F', '10011122233', '11966001013', 'Rua Industrial', '190', 'Parque das Flores', '13016081', 0),
  ('Larissa Pinheiro Costa', 'F', '12121212121', '11966001014', 'Rua das Oliveiras', '58', 'Centro', '13017318', 0),
  ('Eduardo Martins Vieira', 'F', '13131313131', '11966001015', 'Rua Santo Antonio', '402', 'Jardim Alegre', '13018555', 0),
  ('Churrascaria Fogo Brasa Ltda', 'J', '44555666000188', '11966001016', 'Av. Brasil', '1500', 'Vila Nova', '13019792', 1),
  ('Isabela Cardoso Farias', 'F', '14141414141', '11966001017', 'Rua Nove de Julho', '21', 'Bela Vista', '13021029', 0),
  ('Thiago Ribeiro Correa', 'F', '15151515151', '11966001018', 'Rua Marechal Deodoro', '155', 'Santo Antonio', '13022266', 0),
  ('Renata Alves Pacheco', 'F', '16161616161', '11966001019', 'Rua Ipe Amarelo', '40', 'Industrial', '13023503', 0),
  ('Marcelo Souza Prado', 'F', '17171717171', '11966001020', 'Rua Cedro Rosa', '81', 'Parque das Flores', '13024740', 0);

-- Produto (o saldo deixou de ser coluna: vem de MOVIMENTACAO_ESTOQUE, ver abaixo)
INSERT INTO PRODUTO (NM_PRODUTO, ID_CATEGORIA, TP_UNIDADE_VENDA, VL_PRECO_VENDA, QT_ESTOQUE_MINIMO, IN_VENDAVEL, IN_ATIVO) VALUES
  ('Picanha bovina', 1, 'KG', 69.90, 15.00, 1, 1),
  ('Alcatra bovina', 1, 'KG', 42.90, 20.00, 1, 1),
  ('Costela bovina', 1, 'KG', 32.50, 18.00, 1, 1),
  ('Fraldinha bovina', 1, 'KG', 39.90, 12.00, 1, 1),
  ('File mignon bovino', 1, 'KG', 79.90, 10.00, 1, 1),
  ('Patinho bovino moido', 1, 'KG', 36.90, 25.00, 1, 1),
  ('Pernil suino', 2, 'KG', 24.90, 15.00, 1, 1),
  ('Lombo suino', 2, 'KG', 28.90, 12.00, 1, 1),
  ('Costelinha suina', 2, 'KG', 26.90, 10.00, 1, 1),
  ('Linguica toscana', 2, 'KG', 22.90, 20.00, 1, 1),
  ('Bacon fatiado', 2, 'KG', 34.90, 8.00, 1, 1),
  ('Frango inteiro', 3, 'KG', 13.90, 30.00, 1, 1),
  ('Coxa e sobrecoxa de frango', 3, 'KG', 15.90, 25.00, 1, 1),
  ('Peito de frango', 3, 'KG', 18.90, 25.00, 1, 1),
  ('Asa de frango', 3, 'KG', 14.90, 15.00, 1, 1),
  ('Hamburguer congelado 1kg', 4, 'UN', 24.90, 10.00, 1, 1),
  ('Nuggets congelados 1kg', 4, 'UN', 22.90, 10.00, 1, 1),
  ('Batata congelada 1kg', 4, 'UN', 14.90, 15.00, 1, 1),
  ('Arroz tipo 1 5kg', 5, 'UN', 28.90, 10.00, 1, 1),
  ('Feijao carioca 1kg', 5, 'UN', 8.90, 20.00, 1, 1),
  ('Sal refinado 1kg', 5, 'UN', 3.50, 15.00, 1, 1),
  ('Oleo de soja 900ml', 5, 'UN', 7.90, 20.00, 1, 1),
  ('Macarrao espaguete 500g', 6, 'UN', 5.90, 20.00, 1, 1),
  ('Molho de tomate 340g', 6, 'UN', 4.50, 20.00, 1, 1),
  ('Refrigerante cola 2L', 7, 'UN', 9.90, 24.00, 1, 1),
  ('Agua mineral 500ml', 7, 'UN', 2.50, 48.00, 1, 1),
  ('Cerveja pilsen lata 350ml', 7, 'UN', 4.90, 48.00, 1, 1),
  ('Suco de laranja 1L', 7, 'UN', 8.90, 15.00, 1, 1),
  ('Frango assado rotisseria', 8, 'KG', 24.90, 5.00, 1, 1),
  ('Espetinho misto', 8, 'UN', 7.90, 20.00, 1, 1);

-- Pedido de Compra (recebidos ganham DT_RECEBIMENTO = data prevista e nota fiscal ficticia)
INSERT INTO PEDIDO_COMPRA (ID_FORNECEDOR, ID_FUNCIONARIO, DT_PEDIDO, DT_PREVISTA_ENTREGA, DT_RECEBIMENTO, NR_NOTA_FISCAL, ST_PEDIDO, DS_DIVERGENCIA) VALUES
  (1, 1, '2026-10-01', '2026-10-04', '2026-10-04', 'NF-1001', 'RECEBIDO', NULL),
  (2, 1, '2026-10-03', '2026-10-04', '2026-10-04', 'NF-1002', 'RECEBIDO', NULL),
  (3, 1, '2026-10-06', '2026-10-07', '2026-10-07', 'NF-1003', 'RECEBIDO', NULL),
  (4, 1, '2026-10-08', '2026-10-11', '2026-10-11', 'NF-1004', 'RECEBIDO', NULL),
  (5, 1, '2026-10-10', '2026-10-12', '2026-10-12', 'NF-1005', 'RECEBIDO', NULL),
  (6, 1, '2026-10-13', '2026-10-14', '2026-10-14', 'NF-1006', 'RECEBIDO', NULL),
  (1, 1, '2026-10-15', '2026-10-16', '2026-10-16', 'NF-1007', 'RECEBIDO', NULL),
  (2, 1, '2026-10-18', '2026-10-19', NULL, NULL, 'PENDENTE', NULL),
  (3, 1, '2026-10-20', '2026-10-21', NULL, NULL, 'CANCELADO', NULL),
  (4, 1, '2026-10-22', '2026-10-25', NULL, NULL, 'PENDENTE', NULL);

-- Item do Pedido de Compra (entidade associativa 'contem')
INSERT INTO ITEM_PEDIDO_COMPRA (ID_PEDIDO_COMPRA, ID_PRODUTO, QT_PEDIDA, VL_UNITARIO_COMPRA) VALUES
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

-- Lote: um por item de pedido ja recebido (origina)
INSERT INTO LOTE (ID_PEDIDO_COMPRA, ID_PRODUTO, NR_LOTE, DT_VALIDADE, NR_REGISTRO_INSPECAO) VALUES
  (1, 22, 'L01-22', '2027-10-04', NULL),
  (1, 24, 'L01-24', '2027-07-01', NULL),
  (2, 8, 'L02-08', '2026-10-09', 'SIF-2022'),
  (2, 17, 'L02-17', '2027-02-01', NULL),
  (3, 8, 'L03-08', '2026-10-12', 'SIF-2033'),
  (3, 15, 'L03-15', '2026-10-11', 'SIF-2033'),
  (3, 19, 'L03-19', '2027-10-07', NULL),
  (4, 25, 'L04-25', '2027-04-09', NULL),
  (4, 11, 'L04-11', '2026-10-16', 'SIF-2044'),
  (5, 26, 'L05-26', '2027-04-10', NULL),
  (5, 2, 'L05-02', '2026-10-17', 'SIF-2055'),
  (5, 24, 'L05-24', '2027-07-09', NULL),
  (6, 19, 'L06-19', '2027-10-14', NULL),
  (6, 7, 'L06-07', '2026-10-19', 'SIF-2066'),
  (6, 23, 'L06-23', '2027-07-11', NULL),
  (7, 9, 'L07-09', '2026-10-21', 'SIF-2011'),
  (7, 15, 'L07-15', '2026-10-20', 'SIF-2011'),
  (7, 21, 'L07-21', '2027-10-16', NULL);

-- Movimentacao de estoque: AJUSTE de abertura (leva o saldo ao valor do antigo estoque_atual) + COMPRA de cada lote recebido
INSERT INTO MOVIMENTACAO_ESTOQUE (ID_PRODUTO, ID_LOTE, ID_FUNCIONARIO, DT_HORA_MOVIMENTACAO, TP_SENTIDO, TP_MOTIVO, QT_MOVIMENTADA, DS_OBSERVACAO) VALUES
  (1, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 8.687, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (2, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 45.093, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (3, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 28.127, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (4, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 22.100, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (5, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 19.581, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (6, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 43.783, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (7, NULL, 1, '2026-09-30 07:00:00', 'S', 'AJUSTE', 14.859, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (8, NULL, 1, '2026-09-30 07:00:00', 'S', 'AJUSTE', 40.028, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (9, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 11.064, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (10, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 37.297, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (11, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 5.077, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (12, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 31.499, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (13, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 37.840, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (14, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 31.429, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (15, NULL, 1, '2026-09-30 07:00:00', 'S', 'AJUSTE', 8.667, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (16, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 55.00, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (17, NULL, 1, '2026-09-30 07:00:00', 'S', 'AJUSTE', 8.55, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (18, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 53.00, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (19, NULL, 1, '2026-09-30 07:00:00', 'S', 'AJUSTE', 1.87, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (20, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 62.00, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (21, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 24.08, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (22, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 40.96, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (23, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 5.67, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (24, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 22.96, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (25, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 34.70, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (26, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 34.63, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (27, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 73.00, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (28, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 58.00, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (29, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 8.082, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (30, NULL, 1, '2026-09-30 07:00:00', 'E', 'AJUSTE', 44.00, 'Saldo de abertura (contagem fisica) ao implantar o controle de estoque'),
  (22, 1, 1, '2026-10-04 08:00:00', 'E', 'COMPRA', 8.04, 'Recebimento do pedido de compra 1'),
  (24, 2, 1, '2026-10-04 08:00:00', 'E', 'COMPRA', 6.04, 'Recebimento do pedido de compra 1'),
  (8, 3, 1, '2026-10-04 08:00:00', 'E', 'COMPRA', 24.64, 'Recebimento do pedido de compra 2'),
  (17, 4, 1, '2026-10-04 08:00:00', 'E', 'COMPRA', 29.55, 'Recebimento do pedido de compra 2'),
  (8, 5, 1, '2026-10-07 08:00:00', 'E', 'COMPRA', 35.43, 'Recebimento do pedido de compra 3'),
  (15, 6, 1, '2026-10-07 08:00:00', 'E', 'COMPRA', 10.59, 'Recebimento do pedido de compra 3'),
  (19, 7, 1, '2026-10-07 08:00:00', 'E', 'COMPRA', 14.73, 'Recebimento do pedido de compra 3'),
  (25, 8, 1, '2026-10-11 08:00:00', 'E', 'COMPRA', 18.3, 'Recebimento do pedido de compra 4'),
  (11, 9, 1, '2026-10-11 08:00:00', 'E', 'COMPRA', 17.04, 'Recebimento do pedido de compra 4'),
  (26, 10, 1, '2026-10-12 08:00:00', 'E', 'COMPRA', 9.37, 'Recebimento do pedido de compra 5'),
  (2, 11, 1, '2026-10-12 08:00:00', 'E', 'COMPRA', 7.76, 'Recebimento do pedido de compra 5'),
  (24, 12, 1, '2026-10-12 08:00:00', 'E', 'COMPRA', 27.0, 'Recebimento do pedido de compra 5'),
  (19, 13, 1, '2026-10-14 08:00:00', 'E', 'COMPRA', 28.14, 'Recebimento do pedido de compra 6'),
  (7, 14, 1, '2026-10-14 08:00:00', 'E', 'COMPRA', 39.48, 'Recebimento do pedido de compra 6'),
  (23, 15, 1, '2026-10-14 08:00:00', 'E', 'COMPRA', 35.33, 'Recebimento do pedido de compra 6'),
  (9, 16, 1, '2026-10-16 08:00:00', 'E', 'COMPRA', 10.69, 'Recebimento do pedido de compra 7'),
  (15, 17, 1, '2026-10-16 08:00:00', 'E', 'COMPRA', 28.46, 'Recebimento do pedido de compra 7'),
  (21, 18, 1, '2026-10-16 08:00:00', 'E', 'COMPRA', 28.92, 'Recebimento do pedido de compra 7');

-- Venda (o antigo canal 'delivery' virou TELEFONE/WHATSAPP + uma linha em ENTREGA; valor_total deixou de ser coluna: ver VW_TOTAL_VENDA)
INSERT INTO VENDA (ID_CLIENTE, ID_FUNCIONARIO, ID_FUNCIONARIO_AUTORIZADOR, DT_HORA_VENDA, TP_CANAL, TP_FORMA_PAGAMENTO, ST_VENDA, VL_DESCONTO, DT_VENCIMENTO, DT_PAGAMENTO, NR_CUPOM_FISCAL, DT_PREVISTA_ATENDIMENTO) VALUES
  (NULL, 3, NULL, '2026-10-01 16:45:00', 'WHATSAPP', 'PIX', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 3, NULL, '2026-10-02 09:15:00', 'WHATSAPP', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (14, 2, NULL, '2026-10-03 19:30:00', 'TELEFONE', 'PIX', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 2, NULL, '2026-10-04 17:15:00', 'BALCAO', 'VALE_ALIMENTACAO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (3, 10, NULL, '2026-10-05 08:30:00', 'BALCAO', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (7, 5, NULL, '2026-10-06 15:45:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-21', NULL, NULL, NULL),
  (NULL, 8, 1, '2026-10-07 16:15:00', 'BALCAO', 'DINHEIRO', 'CONCLUIDA', 1.25, NULL, NULL, NULL, NULL),
  (16, 5, NULL, '2026-10-08 17:45:00', 'BALCAO', 'PIX', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (11, 8, NULL, '2026-10-09 18:00:00', 'TELEFONE', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (18, 5, NULL, '2026-10-10 10:00:00', 'TELEFONE', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 7, NULL, '2026-10-11 07:15:00', 'TELEFONE', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 6, NULL, '2026-10-12 11:15:00', 'BALCAO', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (6, 5, NULL, '2026-10-13 15:15:00', 'BALCAO', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 6, NULL, '2026-10-14 07:00:00', 'TELEFONE', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 2, NULL, '2026-10-15 09:30:00', 'TELEFONE', 'DINHEIRO', 'CANCELADA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 10, NULL, '2026-10-16 09:30:00', 'BALCAO', 'PIX', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (4, 11, NULL, '2026-10-17 11:00:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-11-01', NULL, NULL, NULL),
  (NULL, 3, NULL, '2026-10-18 11:00:00', 'BALCAO', 'DINHEIRO', 'CANCELADA', 0.00, NULL, NULL, NULL, NULL),
  (5, 8, NULL, '2026-10-19 13:00:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-11-03', NULL, NULL, NULL),
  (NULL, 10, NULL, '2026-10-20 12:15:00', 'WHATSAPP', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 2, NULL, '2026-10-21 07:15:00', 'TELEFONE', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (8, 4, NULL, '2026-10-22 14:15:00', 'BALCAO', 'FIADO', 'CONCLUIDA', 0.00, '2026-11-21', '2026-10-29', NULL, NULL),
  (NULL, 9, NULL, '2026-10-23 07:00:00', 'BALCAO', 'CARTAO_CREDITO', 'CANCELADA', 0.00, NULL, NULL, NULL, NULL),
  (18, 3, NULL, '2026-10-24 11:00:00', 'WHATSAPP', 'BOLETO', 'CONCLUIDA', 0.00, '2026-11-08', '2026-10-31', NULL, NULL),
  (14, 11, NULL, '2026-10-01 17:00:00', 'TELEFONE', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-16', NULL, NULL, NULL),
  (NULL, 5, NULL, '2026-10-02 16:30:00', 'TELEFONE', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 9, NULL, '2026-10-03 15:45:00', 'TELEFONE', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 10, NULL, '2026-10-04 09:00:00', 'BALCAO', 'VALE_ALIMENTACAO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (1, 3, NULL, '2026-10-05 10:45:00', 'TELEFONE', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 6, NULL, '2026-10-06 15:30:00', 'TELEFONE', 'VALE_ALIMENTACAO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (3, 10, NULL, '2026-10-07 19:45:00', 'TELEFONE', 'FIADO', 'CONCLUIDA', 0.00, '2026-11-06', NULL, NULL, NULL),
  (NULL, 2, NULL, '2026-10-08 08:45:00', 'TELEFONE', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (18, 3, 1, '2026-10-09 12:30:00', 'TELEFONE', 'BOLETO', 'CONCLUIDA', 6.28, '2026-10-24', NULL, NULL, NULL),
  (NULL, 9, 1, '2026-10-10 18:15:00', 'TELEFONE', 'VALE_ALIMENTACAO', 'CANCELADA', 17.06, NULL, NULL, NULL, NULL),
  (NULL, 2, NULL, '2026-10-11 10:45:00', 'BALCAO', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (1, 10, NULL, '2026-10-12 08:00:00', 'BALCAO', 'FIADO', 'CONCLUIDA', 0.00, '2026-11-11', '2026-10-19', NULL, NULL),
  (4, 6, NULL, '2026-10-13 19:30:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-28', NULL, NULL, NULL),
  (8, 6, NULL, '2026-10-14 13:15:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-29', NULL, NULL, NULL),
  (NULL, 5, NULL, '2026-10-15 17:30:00', 'BALCAO', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 5, NULL, '2026-10-16 17:30:00', 'WHATSAPP', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (2, 6, NULL, '2026-10-17 19:45:00', 'WHATSAPP', 'FIADO', 'CONCLUIDA', 0.00, '2026-11-16', '2026-10-24', NULL, NULL),
  (14, 10, NULL, '2026-10-18 15:00:00', 'WHATSAPP', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (8, 11, NULL, '2026-10-19 19:00:00', 'BALCAO', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (18, 10, NULL, '2026-10-20 11:15:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-11-04', '2026-10-27', NULL, NULL),
  (NULL, 10, NULL, '2026-10-21 08:15:00', 'BALCAO', 'CARTAO_CREDITO', 'CANCELADA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 7, NULL, '2026-10-22 09:45:00', 'BALCAO', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 9, NULL, '2026-10-23 08:00:00', 'BALCAO', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 3, NULL, '2026-10-24 16:15:00', 'WHATSAPP', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (6, 8, NULL, '2026-10-01 10:30:00', 'TELEFONE', 'VALE_ALIMENTACAO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (15, 11, NULL, '2026-10-02 11:00:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-17', NULL, NULL, NULL),
  (NULL, 10, NULL, '2026-10-03 13:00:00', 'WHATSAPP', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 8, 1, '2026-10-04 18:30:00', 'TELEFONE', 'CARTAO_CREDITO', 'CONCLUIDA', 13.92, NULL, NULL, NULL, NULL),
  (1, 8, NULL, '2026-10-05 12:30:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-20', NULL, NULL, NULL),
  (NULL, 4, NULL, '2026-10-06 16:45:00', 'WHATSAPP', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 7, NULL, '2026-10-07 17:45:00', 'WHATSAPP', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (12, 7, NULL, '2026-10-08 07:45:00', 'TELEFONE', 'VALE_ALIMENTACAO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (1, 9, NULL, '2026-10-09 07:15:00', 'TELEFONE', 'VALE_ALIMENTACAO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 11, NULL, '2026-10-10 09:45:00', 'WHATSAPP', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (17, 3, NULL, '2026-10-11 09:00:00', 'BALCAO', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (18, 4, NULL, '2026-10-12 09:45:00', 'WHATSAPP', 'VALE_ALIMENTACAO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 4, NULL, '2026-10-13 13:00:00', 'BALCAO', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 5, NULL, '2026-10-14 08:45:00', 'BALCAO', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 4, NULL, '2026-10-15 12:45:00', 'BALCAO', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (10, 8, NULL, '2026-10-16 13:00:00', 'WHATSAPP', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-31', '2026-10-23', NULL, NULL),
  (6, 5, NULL, '2026-10-17 13:15:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-11-01', NULL, NULL, NULL),
  (NULL, 4, NULL, '2026-10-18 14:15:00', 'BALCAO', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 4, 1, '2026-10-19 17:15:00', 'BALCAO', 'VALE_ALIMENTACAO', 'CONCLUIDA', 5.43, NULL, NULL, NULL, NULL),
  (13, 11, NULL, '2026-10-20 12:30:00', 'WHATSAPP', 'CARTAO_CREDITO', 'CANCELADA', 0.00, NULL, NULL, NULL, NULL),
  (7, 2, NULL, '2026-10-21 11:15:00', 'WHATSAPP', 'VALE_ALIMENTACAO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 2, NULL, '2026-10-22 14:00:00', 'WHATSAPP', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 11, NULL, '2026-10-23 15:30:00', 'BALCAO', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (13, 2, NULL, '2026-10-24 10:45:00', 'WHATSAPP', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (8, 2, NULL, '2026-10-01 11:45:00', 'TELEFONE', 'FIADO', 'CONCLUIDA', 0.00, '2026-10-31', '2026-10-08', NULL, NULL),
  (2, 9, NULL, '2026-10-02 17:45:00', 'BALCAO', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (5, 5, NULL, '2026-10-03 13:45:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-18', '2026-10-10', NULL, NULL),
  (NULL, 4, NULL, '2026-10-04 07:30:00', 'BALCAO', 'PIX', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (4, 3, NULL, '2026-10-05 17:30:00', 'BALCAO', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (18, 10, 1, '2026-10-06 10:15:00', 'WHATSAPP', 'PIX', 'CONCLUIDA', 6.65, NULL, NULL, NULL, NULL),
  (NULL, 11, NULL, '2026-10-07 09:15:00', 'WHATSAPP', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (5, 9, NULL, '2026-10-08 10:30:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-23', NULL, NULL, NULL),
  (17, 7, NULL, '2026-10-09 14:15:00', 'WHATSAPP', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-24', NULL, NULL, NULL),
  (3, 4, NULL, '2026-10-10 17:00:00', 'TELEFONE', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 5, NULL, '2026-10-11 16:30:00', 'TELEFONE', 'DINHEIRO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 4, NULL, '2026-10-12 19:15:00', 'TELEFONE', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (4, 8, NULL, '2026-10-13 14:00:00', 'BALCAO', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-28', NULL, NULL, NULL),
  (2, 3, NULL, '2026-10-14 13:30:00', 'WHATSAPP', 'BOLETO', 'CONCLUIDA', 0.00, '2026-10-29', NULL, NULL, NULL),
  (NULL, 11, NULL, '2026-10-15 12:30:00', 'BALCAO', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 11, NULL, '2026-10-16 11:00:00', 'BALCAO', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (14, 5, NULL, '2026-10-17 17:00:00', 'BALCAO', 'CARTAO_DEBITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL),
  (NULL, 7, NULL, '2026-10-18 09:15:00', 'WHATSAPP', 'CARTAO_CREDITO', 'CONCLUIDA', 0.00, NULL, NULL, NULL, NULL);

-- Item de Venda (entidade associativa 'vende')
INSERT INTO ITEM_VENDA (ID_VENDA, ID_PRODUTO, QT_VENDIDA, VL_UNITARIO_VENDA) VALUES
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

-- Entrega: uma por venda delivery concluida (endereco do cliente; sem cliente, endereco ficticio)
INSERT INTO ENTREGA (ID_VENDA, ID_FUNCIONARIO_ENTREGADOR, DS_LOGRADOURO, NR_ENDERECO, NM_BAIRRO, NR_CEP, ST_ENTREGA, DT_HORA_SAIDA, DT_HORA_ENTREGA) VALUES
  (2, 12, 'Rua das Mangueiras', '150', 'Jardim Alegre', '13021450', 'ENTREGUE', '2026-10-02 09:35:00', '2026-10-02 10:20:00'),
  (3, 12, 'Rua das Oliveiras', '58', 'Centro', '13017318', 'ENTREGUE', '2026-10-03 19:50:00', '2026-10-03 20:35:00'),
  (9, 12, 'Rua do Comercio', '12', 'Santo Antonio', '13013607', 'ENTREGUE', '2026-10-09 18:20:00', '2026-10-09 19:05:00'),
  (20, 12, 'Rua das Mangueiras', '150', 'Jardim Alegre', '13021450', 'ENTREGUE', '2026-10-20 12:35:00', '2026-10-20 13:20:00'),
  (21, 12, 'Rua do Bosque', '88', 'Vila Nova', '13021880', 'ENTREGUE', '2026-10-21 07:35:00', '2026-10-21 08:20:00'),
  (24, 12, 'Rua Marechal Deodoro', '155', 'Santo Antonio', '13022266', 'ENTREGUE', '2026-10-24 11:20:00', '2026-10-24 12:05:00'),
  (25, 12, 'Rua das Oliveiras', '58', 'Centro', '13017318', 'ENTREGUE', '2026-10-01 17:20:00', '2026-10-01 18:05:00'),
  (27, 12, 'Rua do Bosque', '88', 'Vila Nova', '13021880', 'ENTREGUE', '2026-10-03 16:05:00', '2026-10-03 16:50:00'),
  (31, 12, 'Av. Central', '900', 'Bela Vista', '13003711', 'ENTREGUE', '2026-10-07 20:05:00', '2026-10-07 20:50:00'),
  (49, 12, 'Rua Bela Vista', '15', 'Parque das Flores', '13007422', 'ENTREGUE', '2026-10-01 10:50:00', '2026-10-01 11:35:00'),
  (54, 12, 'Rua do Bosque', '88', 'Vila Nova', '13021880', 'ENTREGUE', '2026-10-06 17:05:00', '2026-10-06 17:50:00'),
  (57, 12, 'Rua das Acacias', '120', 'Jardim Alegre', '13001237', 'ENTREGUE', '2026-10-09 07:35:00', '2026-10-09 08:20:00'),
  (58, 12, 'Rua das Mangueiras', '150', 'Jardim Alegre', '13021450', 'ENTREGUE', '2026-10-10 10:05:00', '2026-10-10 10:50:00'),
  (64, 12, 'Rua das Hortensias', '64', 'Bela Vista', '13012370', 'ENTREGUE', '2026-10-16 13:20:00', '2026-10-16 14:05:00'),
  (73, 12, 'Av. das Nacoes', '500', 'Jardim Alegre', '13009896', 'ENTREGUE', '2026-10-01 12:05:00', '2026-10-01 12:50:00'),
  (86, 12, 'Rua das Palmeiras', '45', 'Vila Nova', '13002474', 'ENTREGUE', '2026-10-14 13:50:00', '2026-10-14 14:35:00');

-- =====================================================================================
-- 4) SELECT com JOIN  (consultas que cruzam multiplas tabelas)
-- =====================================================================================

-- 4.1 Vendas recentes com nome do cliente (quando houver) e do funcionario que atendeu
SELECT
    v.ID_VENDA,
    v.DT_HORA_VENDA,
    v.TP_CANAL,
    COALESCE(c.NM_CLIENTE, '(sem cadastro)') AS CLIENTE,
    f.NM_FUNCIONARIO                         AS ATENDIDO_POR,
    v.TP_FORMA_PAGAMENTO,
    v.ST_VENDA
FROM VENDA v
JOIN FUNCIONARIO f  ON f.ID_FUNCIONARIO = v.ID_FUNCIONARIO
LEFT JOIN CLIENTE c ON c.ID_CLIENTE = v.ID_CLIENTE
ORDER BY v.DT_HORA_VENDA DESC
LIMIT 20;

-- 4.2 Itens vendidos com nome do produto e categoria (4 tabelas)
SELECT
    v.ID_VENDA,
    v.DT_HORA_VENDA,
    p.NM_PRODUTO,
    cat.NM_CATEGORIA,
    i.QT_VENDIDA,
    i.VL_UNITARIO_VENDA,
    ROUND(i.QT_VENDIDA * i.VL_UNITARIO_VENDA, 2) AS SUBTOTAL_ITEM
FROM ITEM_VENDA i
JOIN VENDA v      ON v.ID_VENDA = i.ID_VENDA
JOIN PRODUTO p    ON p.ID_PRODUTO = i.ID_PRODUTO
JOIN CATEGORIA cat ON cat.ID_CATEGORIA = p.ID_CATEGORIA
ORDER BY v.DT_HORA_VENDA DESC
LIMIT 20;

-- 4.3 Pedidos de compra com fornecedor, funcionario responsavel e custo total do pedido
SELECT
    pc.ID_PEDIDO_COMPRA,
    f.NM_FORNECEDOR,
    fu.NM_FUNCIONARIO AS COMPRADO_POR,
    pc.DT_PEDIDO,
    pc.DT_PREVISTA_ENTREGA,
    pc.ST_PEDIDO,
    ROUND(SUM(i.QT_PEDIDA * i.VL_UNITARIO_COMPRA), 2) AS CUSTO_TOTAL_PEDIDO
FROM PEDIDO_COMPRA pc
JOIN FORNECEDOR f  ON f.ID_FORNECEDOR = pc.ID_FORNECEDOR
JOIN FUNCIONARIO fu ON fu.ID_FUNCIONARIO = pc.ID_FUNCIONARIO
JOIN ITEM_PEDIDO_COMPRA i ON i.ID_PEDIDO_COMPRA = pc.ID_PEDIDO_COMPRA
GROUP BY pc.ID_PEDIDO_COMPRA, f.NM_FORNECEDOR, fu.NM_FUNCIONARIO, pc.DT_PEDIDO,
         pc.DT_PREVISTA_ENTREGA, pc.ST_PEDIDO
ORDER BY pc.DT_PEDIDO;

-- 4.4 Clientes autorizados a prazo e o total que ja compraram no fiado (mesmo pago)
SELECT
    c.ID_CLIENTE,
    c.NM_CLIENTE,
    c.IN_AUTORIZADO_PRAZO,
    COUNT(v.ID_VENDA)                    AS QT_VENDAS_FIADO,
    COALESCE(SUM(t.VL_LIQUIDO), 0)       AS TOTAL_FIADO
FROM CLIENTE c
LEFT JOIN VENDA v
       ON v.ID_CLIENTE = c.ID_CLIENTE
      AND v.TP_FORMA_PAGAMENTO = 'FIADO'
LEFT JOIN VW_TOTAL_VENDA t ON t.ID_VENDA = v.ID_VENDA
WHERE c.IN_AUTORIZADO_PRAZO = 1
GROUP BY c.ID_CLIENTE, c.NM_CLIENTE, c.IN_AUTORIZADO_PRAZO
ORDER BY TOTAL_FIADO DESC;

-- 4.5 Entregas com a venda, o cliente e o entregador (4 tabelas)
SELECT
    e.ID_ENTREGA,
    v.ID_VENDA,
    COALESCE(c.NM_CLIENTE, '(sem cadastro)') AS CLIENTE,
    fu.NM_FUNCIONARIO                        AS ENTREGADOR,
    e.NM_BAIRRO,
    e.DT_HORA_SAIDA,
    e.DT_HORA_ENTREGA,
    TIMESTAMPDIFF(MINUTE, e.DT_HORA_SAIDA, e.DT_HORA_ENTREGA) AS MIN_ENTREGA
FROM ENTREGA e
JOIN VENDA v        ON v.ID_VENDA = e.ID_VENDA
JOIN FUNCIONARIO fu ON fu.ID_FUNCIONARIO = e.ID_FUNCIONARIO_ENTREGADOR
LEFT JOIN CLIENTE c ON c.ID_CLIENTE = v.ID_CLIENTE
ORDER BY e.DT_HORA_SAIDA DESC;

-- 4.6 Lotes com produto, categoria, pedido de origem e fornecedor (5 tabelas)
SELECT
    l.ID_LOTE,
    l.NR_LOTE,
    p.NM_PRODUTO,
    cat.NM_CATEGORIA,
    pc.ID_PEDIDO_COMPRA,
    f.NM_FORNECEDOR,
    l.DT_VALIDADE,
    l.NR_REGISTRO_INSPECAO
FROM LOTE l
JOIN PRODUTO p        ON p.ID_PRODUTO = l.ID_PRODUTO
JOIN CATEGORIA cat    ON cat.ID_CATEGORIA = p.ID_CATEGORIA
JOIN PEDIDO_COMPRA pc ON pc.ID_PEDIDO_COMPRA = l.ID_PEDIDO_COMPRA
JOIN FORNECEDOR f     ON f.ID_FORNECEDOR = pc.ID_FORNECEDOR
ORDER BY l.DT_VALIDADE;


-- =====================================================================================
-- 5) UPDATE
-- =====================================================================================

-- 5.1 Reajuste de 5% no preco de venda de toda a categoria "Carne Bovina"
UPDATE PRODUTO p
JOIN CATEGORIA cat ON cat.ID_CATEGORIA = p.ID_CATEGORIA
SET p.VL_PRECO_VENDA = ROUND(p.VL_PRECO_VENDA * 1.05, 2)
WHERE cat.NM_CATEGORIA = 'Carne Bovina';

-- 5.2 Baixa manual de pagamento: registra a data de pagamento dos fiados em aberto
-- com vencimento ate 06/11/2026 que o cliente foi quitar na loja (rotina da
-- responsavel financeira; "pago" = DT_PAGAMENTO preenchida)
UPDATE VENDA
SET DT_PAGAMENTO = '2026-11-06'
WHERE TP_FORMA_PAGAMENTO = 'FIADO'
  AND DT_PAGAMENTO IS NULL
  AND ST_VENDA <> 'CANCELADA'
  AND DT_VENCIMENTO <= '2026-11-06';

-- 5.3 Correcao cadastral: atualiza o telefone de um fornecedor
UPDATE FORNECEDOR
SET NR_TELEFONE = '11999887766'
WHERE NM_FORNECEDOR = 'Frigorifico Boi Forte Ltda';

-- 5.4 Recebimento do pedido de compra 10: o pedido passa a RECEBIDO (com data e nota
-- fiscal, exigidas pelo CHECK), cada item gera um LOTE e cada lote gera uma
-- MOVIMENTACAO_ESTOQUE de entrada por COMPRA -- o saldo em VW_SALDO_ESTOQUE sobe
-- sozinho (resolve P2: hoje as entradas nao geram nenhum registro de estoque)
UPDATE PEDIDO_COMPRA
SET ST_PEDIDO = 'RECEBIDO', DT_RECEBIMENTO = '2026-10-26', NR_NOTA_FISCAL = 'NF-1010'
WHERE ID_PEDIDO_COMPRA = 10;

INSERT INTO LOTE (ID_PEDIDO_COMPRA, ID_PRODUTO, NR_LOTE, DT_VALIDADE, NR_REGISTRO_INSPECAO)
SELECT i.ID_PEDIDO_COMPRA, i.ID_PRODUTO, CONCAT('L10-', LPAD(i.ID_PRODUTO, 2, '0')),
       DATE_ADD('2026-10-26', INTERVAL 180 DAY), NULL
FROM ITEM_PEDIDO_COMPRA i
WHERE i.ID_PEDIDO_COMPRA = 10;

INSERT INTO MOVIMENTACAO_ESTOQUE
       (ID_PRODUTO, ID_LOTE, ID_FUNCIONARIO, DT_HORA_MOVIMENTACAO, TP_SENTIDO, TP_MOTIVO, QT_MOVIMENTADA, DS_OBSERVACAO)
SELECT i.ID_PRODUTO, l.ID_LOTE, pc.ID_FUNCIONARIO, '2026-10-26 08:00:00', 'E', 'COMPRA',
       i.QT_PEDIDA, 'Recebimento do pedido de compra 10'
FROM ITEM_PEDIDO_COMPRA i
JOIN PEDIDO_COMPRA pc ON pc.ID_PEDIDO_COMPRA = i.ID_PEDIDO_COMPRA
JOIN LOTE l ON l.ID_PEDIDO_COMPRA = i.ID_PEDIDO_COMPRA AND l.ID_PRODUTO = i.ID_PRODUTO
WHERE i.ID_PEDIDO_COMPRA = 10;


-- =====================================================================================
-- 6) DELETE
-- =====================================================================================

-- 6.1 Remove um pedido de compra cancelado e, antes, seus itens (as FKs nao tem
-- ON DELETE CASCADE: o filho sai primeiro)
DELETE FROM ITEM_PEDIDO_COMPRA
WHERE ID_PEDIDO_COMPRA IN (SELECT ID_PEDIDO_COMPRA FROM PEDIDO_COMPRA WHERE ST_PEDIDO = 'CANCELADO');

DELETE FROM PEDIDO_COMPRA
WHERE ST_PEDIDO = 'CANCELADO';

-- 6.2 Remove um cliente cadastrado por engano, que nunca teve nenhuma venda
-- (sem FK pendente, entao o DELETE e seguro)
DELETE FROM CLIENTE
WHERE NM_CLIENTE = 'Marcelo Souza Prado'
  AND NOT EXISTS (
        SELECT 1 FROM VENDA v WHERE v.ID_CLIENTE = CLIENTE.ID_CLIENTE
  );

-- 6.3 Remove vendas canceladas com mais de 60 dias (limpeza de dados operacionais sem
-- valor de auditoria): primeiro entrega e itens, depois a venda
DELETE FROM ENTREGA
WHERE ID_VENDA IN (SELECT ID_VENDA FROM VENDA
                   WHERE ST_VENDA = 'CANCELADA' AND DT_HORA_VENDA < '2026-09-01 00:00:00');

DELETE FROM ITEM_VENDA
WHERE ID_VENDA IN (SELECT ID_VENDA FROM VENDA
                   WHERE ST_VENDA = 'CANCELADA' AND DT_HORA_VENDA < '2026-09-01 00:00:00');

DELETE FROM VENDA
WHERE ST_VENDA = 'CANCELADA'
  AND DT_HORA_VENDA < '2026-09-01 00:00:00';


-- =====================================================================================
-- 7) CONSULTAS GERENCIAIS
-- Problemas de gestao (levantamento de campo):
--   P1 - Fornecedores e cotacoes fora do sistema (so na agenda do celular)
--   P2 - Estoque sem saldo automatico e sem registro de entradas
--   P3 - Estoque minimo nao parametrizado
--   P4 - Desossa sem rastreabilidade de rendimento/perda
--   P5 - Controle de fiado/boleto em planilha manual, com baixa manual
--   P6 - Validade, lotes e perdas sem rastreabilidade
-- =====================================================================================

-- G01 — Quais produtos estao hoje abaixo do estoque minimo?
-- Atende: P3 (ruptura de estoque sem controle automatizado)
SELECT
    p.ID_PRODUTO,
    p.NM_PRODUTO,
    cat.NM_CATEGORIA,
    s.QT_SALDO,
    p.QT_ESTOQUE_MINIMO,
    (p.QT_ESTOQUE_MINIMO - s.QT_SALDO) AS FALTA_PARA_O_MINIMO
FROM PRODUTO p
JOIN CATEGORIA cat        ON cat.ID_CATEGORIA = p.ID_CATEGORIA
JOIN VW_SALDO_ESTOQUE s   ON s.ID_PRODUTO = p.ID_PRODUTO
WHERE p.IN_ATIVO = 1
  AND s.QT_SALDO < p.QT_ESTOQUE_MINIMO
ORDER BY FALTA_PARA_O_MINIMO DESC;

-- G02 — Qual o faturamento (vendas concluidas) por forma de pagamento no periodo?
-- Atende: P5 (visibilidade sobre dinheiro/pix/cartao/fiado/boleto, hoje so em planilha)
SELECT
    v.TP_FORMA_PAGAMENTO,
    COUNT(*)                     AS QT_VENDAS,
    ROUND(SUM(t.VL_LIQUIDO), 2)  AS FATURAMENTO
FROM VENDA v
JOIN VW_TOTAL_VENDA t ON t.ID_VENDA = v.ID_VENDA
WHERE v.ST_VENDA = 'CONCLUIDA'
  AND v.DT_HORA_VENDA BETWEEN '2026-10-01 00:00:00' AND '2026-10-24 23:59:59'
GROUP BY v.TP_FORMA_PAGAMENTO
ORDER BY FATURAMENTO DESC;

-- G03 — Qual o faturamento liquido diario no periodo (para acompanhar o volume de
-- atendimentos/dia que o dono relatou)?
-- Atende: visao gerencial geral de volume e faturamento por dia (KPI faturamento liquido)
SELECT
    DATE(v.DT_HORA_VENDA)         AS DIA,
    COUNT(*)                      AS QT_VENDAS,
    ROUND(SUM(t.VL_LIQUIDO), 2)   AS FATURAMENTO_DIA
FROM VENDA v
JOIN VW_TOTAL_VENDA t ON t.ID_VENDA = v.ID_VENDA
WHERE v.ST_VENDA = 'CONCLUIDA'
GROUP BY DATE(v.DT_HORA_VENDA)
ORDER BY DIA;

-- G04 — Quanto cada cliente deve atualmente em fiado ou boleto (nao pago)?
-- Atende: P5 (controle de valores devidos, hoje em planilha com baixa manual)
SELECT
    c.ID_CLIENTE,
    c.NM_CLIENTE,
    c.NR_TELEFONE,
    COUNT(v.ID_VENDA)             AS QT_VENDAS_EM_ABERTO,
    ROUND(SUM(t.VL_LIQUIDO), 2)   AS VALOR_DEVIDO
FROM CLIENTE c
JOIN VENDA v          ON v.ID_CLIENTE = c.ID_CLIENTE
JOIN VW_TOTAL_VENDA t ON t.ID_VENDA = v.ID_VENDA
WHERE v.TP_FORMA_PAGAMENTO IN ('FIADO', 'BOLETO')
  AND v.DT_PAGAMENTO IS NULL
  AND v.ST_VENDA <> 'CANCELADA'
GROUP BY c.ID_CLIENTE, c.NM_CLIENTE, c.NR_TELEFONE
ORDER BY VALOR_DEVIDO DESC;

-- G05 — Quais clientes cadastrados nunca fizeram nenhuma compra?
-- Atende: gestao do cadastro de clientes (historico de compras; RN09, sem problema numerado)
SELECT
    c.ID_CLIENTE,
    c.NM_CLIENTE,
    c.NR_TELEFONE,
    c.IN_AUTORIZADO_PRAZO
FROM CLIENTE c
LEFT JOIN VENDA v ON v.ID_CLIENTE = c.ID_CLIENTE
WHERE v.ID_VENDA IS NULL;

-- G06 — Quais os 5 produtos mais vendidos (em valor) no periodo?
-- Atende: visao gerencial de mix de produtos / giro (KPI mix de produtos)
SELECT
    p.ID_PRODUTO,
    p.NM_PRODUTO,
    cat.NM_CATEGORIA,
    ROUND(SUM(i.QT_VENDIDA), 3)                           AS QT_TOTAL_VENDIDA,
    ROUND(SUM(i.QT_VENDIDA * i.VL_UNITARIO_VENDA), 2)     AS VALOR_TOTAL_VENDIDO
FROM ITEM_VENDA i
JOIN VENDA v       ON v.ID_VENDA = i.ID_VENDA
JOIN PRODUTO p     ON p.ID_PRODUTO = i.ID_PRODUTO
JOIN CATEGORIA cat ON cat.ID_CATEGORIA = p.ID_CATEGORIA
WHERE v.ST_VENDA = 'CONCLUIDA'
GROUP BY p.ID_PRODUTO, p.NM_PRODUTO, cat.NM_CATEGORIA
ORDER BY VALOR_TOTAL_VENDIDO DESC
LIMIT 5;

-- G07 — Qual o custo total de compras por fornecedor no periodo?
-- Atende: P1 (hoje nao ha visao nenhuma de gasto por fornecedor, so agenda de celular)
SELECT
    f.ID_FORNECEDOR,
    f.NM_FORNECEDOR,
    COUNT(DISTINCT pc.ID_PEDIDO_COMPRA)                  AS QT_PEDIDOS,
    ROUND(SUM(i.QT_PEDIDA * i.VL_UNITARIO_COMPRA), 2)    AS CUSTO_TOTAL
FROM FORNECEDOR f
JOIN PEDIDO_COMPRA pc        ON pc.ID_FORNECEDOR = f.ID_FORNECEDOR
JOIN ITEM_PEDIDO_COMPRA i    ON i.ID_PEDIDO_COMPRA = pc.ID_PEDIDO_COMPRA
WHERE pc.ST_PEDIDO <> 'CANCELADO'
GROUP BY f.ID_FORNECEDOR, f.NM_FORNECEDOR
ORDER BY CUSTO_TOTAL DESC;

-- G08 — Qual o percentual de vendas canceladas por canal?
-- Atende: visao gerencial de qualidade de atendimento por canal (balcao/telefone/whatsapp)
SELECT
    TP_CANAL,
    COUNT(*)                                                         AS TOTAL_VENDAS,
    SUM(CASE WHEN ST_VENDA = 'CANCELADA' THEN 1 ELSE 0 END)          AS CANCELADAS,
    ROUND(100 * SUM(CASE WHEN ST_VENDA = 'CANCELADA' THEN 1 ELSE 0 END)
              / COUNT(*), 1)                                          AS PCT_CANCELAMENTO
FROM VENDA
GROUP BY TP_CANAL
ORDER BY PCT_CANCELAMENTO DESC;

-- G09 — Qual o saldo atual de cada produto (entradas - saidas - vendido)?
-- Atende: P2 (saldo automatico, calculado a partir das movimentacoes e das vendas)
SELECT s.ID_PRODUTO, s.NM_PRODUTO, s.QT_SALDO
FROM VW_SALDO_ESTOQUE s
ORDER BY s.NM_PRODUTO;

-- G10 — Quais lotes ja estao vencidos ou vencem nos 7 dias seguintes a 24/10/2026
-- (ultimo dia de vendas da carga), e de qual fornecedor vieram?
-- Atende: P6 (validade e procedencia dos lotes, hoje sem rastreabilidade)
SELECT
    l.ID_LOTE,
    l.NR_LOTE,
    p.NM_PRODUTO,
    f.NM_FORNECEDOR,
    l.DT_VALIDADE,
    DATEDIFF(l.DT_VALIDADE, '2026-10-24') AS DIAS_PARA_VENCER
FROM LOTE l
JOIN PRODUTO p        ON p.ID_PRODUTO = l.ID_PRODUTO
JOIN PEDIDO_COMPRA pc ON pc.ID_PEDIDO_COMPRA = l.ID_PEDIDO_COMPRA
JOIN FORNECEDOR f     ON f.ID_FORNECEDOR = pc.ID_FORNECEDOR
WHERE l.DT_VALIDADE <= DATE_ADD('2026-10-24', INTERVAL 7 DAY)
ORDER BY l.DT_VALIDADE;

-- G11 — Qual o prazo medio real de entrega (pedido -> recebimento) por fornecedor?
-- Atende: P1 (KPI prazo medio de entrega do fornecedor)
SELECT
    f.NM_FORNECEDOR,
    COUNT(*)                                          AS QT_PEDIDOS_RECEBIDOS,
    ROUND(AVG(DATEDIFF(pc.DT_RECEBIMENTO, pc.DT_PEDIDO)), 1) AS PRAZO_MEDIO_DIAS
FROM FORNECEDOR f
JOIN PEDIDO_COMPRA pc ON pc.ID_FORNECEDOR = f.ID_FORNECEDOR
WHERE pc.DT_RECEBIMENTO IS NOT NULL
GROUP BY f.ID_FORNECEDOR, f.NM_FORNECEDOR
ORDER BY PRAZO_MEDIO_DIAS DESC;

-- G12 — Qual o tempo medio entre saida e entrega do delivery, por entregador?
-- Atende: KPI tempo de entrega (logistica do delivery)
SELECT
    fu.NM_FUNCIONARIO AS ENTREGADOR,
    COUNT(*)          AS QT_ENTREGAS,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, e.DT_HORA_SAIDA, e.DT_HORA_ENTREGA)), 1) AS MIN_MEDIO
FROM ENTREGA e
JOIN FUNCIONARIO fu ON fu.ID_FUNCIONARIO = e.ID_FUNCIONARIO_ENTREGADOR
WHERE e.ST_ENTREGA = 'ENTREGUE'
GROUP BY fu.ID_FUNCIONARIO, fu.NM_FUNCIONARIO;


-- =====================================================================================
-- 8) CONSULTAS DE AUDITORIA
-- Verificam consistencia e integridade dos dados (regras de negocio entre tabelas
-- diferentes, que um CHECK/FK simples nao cobre). A01 devolve linhas de proposito (venda
-- fiado para cliente nao autorizado, presente na carga); as demais devem devolver 0 linhas.
-- =====================================================================================

-- A01 — Existe alguma venda fiado para cliente que nao esta autorizado a prazo?
-- Atende: P5 (falha de controle que hoje passa batido na planilha manual; RN02)
SELECT
    v.ID_VENDA,
    v.DT_HORA_VENDA,
    c.ID_CLIENTE,
    c.NM_CLIENTE,
    c.IN_AUTORIZADO_PRAZO,
    v.TP_FORMA_PAGAMENTO,
    t.VL_LIQUIDO
FROM VENDA v
JOIN CLIENTE c        ON c.ID_CLIENTE = v.ID_CLIENTE
JOIN VW_TOTAL_VENDA t ON t.ID_VENDA = v.ID_VENDA
WHERE v.TP_FORMA_PAGAMENTO = 'FIADO'
  AND c.IN_AUTORIZADO_PRAZO = 0;

-- A02 — Existe alguma venda sem nenhum item (ou com desconto maior que o total dos itens)?
-- Atende: consistencia financeira do caixa (RN19)
SELECT v.ID_VENDA, v.DT_HORA_VENDA, v.VL_DESCONTO, t.VL_BRUTO
FROM VENDA v
LEFT JOIN VW_TOTAL_VENDA t ON t.ID_VENDA = v.ID_VENDA
WHERE t.ID_VENDA IS NULL
   OR t.VL_LIQUIDO < 0;

-- A03 — Existe desconto concedido por alguem que nao e o proprietario?
-- Atende: P5 / controle de descontos (RN03)
SELECT v.ID_VENDA, a.NM_FUNCIONARIO AS AUTORIZADOR, a.TP_FUNCAO, v.VL_DESCONTO
FROM VENDA v
JOIN FUNCIONARIO a ON a.ID_FUNCIONARIO = v.ID_FUNCIONARIO_AUTORIZADOR
WHERE a.TP_FUNCAO <> 'PROPRIETARIO';

-- A04 — Existe algum produto sem nenhuma venda concluida nos ultimos 30 dias da carga
-- (desde 24/09/2026) com saldo em estoque maior que zero (indicio de encalhe/perda)?
-- Atende: P2 (giro de estoque, complementa o controle de minimo)
SELECT
    p.ID_PRODUTO,
    p.NM_PRODUTO,
    s.QT_SALDO,
    MAX(v.DT_HORA_VENDA) AS ULTIMA_VENDA
FROM PRODUTO p
JOIN VW_SALDO_ESTOQUE s ON s.ID_PRODUTO = p.ID_PRODUTO
LEFT JOIN ITEM_VENDA i  ON i.ID_PRODUTO = p.ID_PRODUTO
LEFT JOIN VENDA v       ON v.ID_VENDA = i.ID_VENDA AND v.ST_VENDA = 'CONCLUIDA'
WHERE s.QT_SALDO > 0
GROUP BY p.ID_PRODUTO, p.NM_PRODUTO, s.QT_SALDO
HAVING ULTIMA_VENDA IS NULL OR ULTIMA_VENDA < '2026-09-24 00:00:00'
ORDER BY ULTIMA_VENDA;

-- A05 — Existe pedido de compra sem nenhum item lancado em ITEM_PEDIDO_COMPRA?
-- Atende: integridade de negocio (pedido "vazio" nao deveria existir; RN19)
SELECT pc.ID_PEDIDO_COMPRA, pc.DT_PEDIDO, pc.ST_PEDIDO
FROM PEDIDO_COMPRA pc
LEFT JOIN ITEM_PEDIDO_COMPRA i ON i.ID_PEDIDO_COMPRA = pc.ID_PEDIDO_COMPRA
WHERE i.ID_PEDIDO_COMPRA IS NULL;

-- A06 — Existe item de venda de produto vendido por unidade (UN) com quantidade
-- fracionada, ou de produto marcado como nao vendavel?
-- Atende: qualidade do cadastro de produtos e do lancamento de itens (RN01, RN24)
SELECT i.ID_VENDA, i.ID_PRODUTO, p.NM_PRODUTO, p.TP_UNIDADE_VENDA, i.QT_VENDIDA
FROM ITEM_VENDA i
JOIN PRODUTO p ON p.ID_PRODUTO = i.ID_PRODUTO
WHERE p.IN_VENDAVEL = 0
   OR (p.TP_UNIDADE_VENDA = 'UN' AND i.QT_VENDIDA <> FLOOR(i.QT_VENDIDA));

-- A07 — Existe entrega de venda de balcao, ou com entregador que nao tem a funcao ENTREGADOR?
-- Atende: controle da logistica do delivery (RN22)
SELECT e.ID_ENTREGA, v.ID_VENDA, v.TP_CANAL, fu.NM_FUNCIONARIO, fu.TP_FUNCAO
FROM ENTREGA e
JOIN VENDA v        ON v.ID_VENDA = e.ID_VENDA
JOIN FUNCIONARIO fu ON fu.ID_FUNCIONARIO = e.ID_FUNCIONARIO_ENTREGADOR
WHERE v.TP_CANAL = 'BALCAO'
   OR fu.TP_FUNCAO <> 'ENTREGADOR';

-- A08 — Existe lote de categoria perecivel sem validade, ou de categoria que exige
-- inspecao sem registro de inspecao?
-- Atende: P6 (rastreabilidade sanitaria; RN10, RN16)
SELECT l.ID_LOTE, l.NR_LOTE, p.NM_PRODUTO, cat.NM_CATEGORIA
FROM LOTE l
JOIN PRODUTO p     ON p.ID_PRODUTO = l.ID_PRODUTO
JOIN CATEGORIA cat ON cat.ID_CATEGORIA = p.ID_CATEGORIA
WHERE (cat.IN_PERECIVEL = 1 AND l.DT_VALIDADE IS NULL)
   OR (cat.IN_EXIGE_INSPECAO = 1
       AND (l.NR_REGISTRO_INSPECAO IS NULL OR l.NR_REGISTRO_INSPECAO = ''));

-- A09 — Existe produto com saldo de estoque negativo?
-- Atende: P2 (o saldo calculado nunca deveria ficar abaixo de zero; RN23)
SELECT * FROM VW_SALDO_ESTOQUE WHERE QT_SALDO < 0;

-- A10 — Existe venda a prazo (boleto/fiado) com vencimento fora do limite
-- (boleto > 15 dias ou fiado > 30 dias depois da venda)?
-- Atende: P5 (prazo concedido acima da regra; RN05)
SELECT v.ID_VENDA, v.TP_FORMA_PAGAMENTO,
       DATEDIFF(v.DT_VENCIMENTO, DATE(v.DT_HORA_VENDA)) AS DIAS_PRAZO
FROM VENDA v
WHERE (v.TP_FORMA_PAGAMENTO = 'BOLETO' AND DATEDIFF(v.DT_VENCIMENTO, DATE(v.DT_HORA_VENDA)) > 15)
   OR (v.TP_FORMA_PAGAMENTO = 'FIADO'  AND DATEDIFF(v.DT_VENCIMENTO, DATE(v.DT_HORA_VENDA)) > 30);

