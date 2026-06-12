-- Critica adicionada em MACV_CONSISTELOTECOMPRA

-- Giuliano 12/06/26
-- Trava Fornec+Representante com Acordos/Parcelas vencidas e não quitadas

SELECT DISTINCT X.SEQGERCOMPRA,
                110 CODIGOCONSIST,
               'Existem Pagamentos/Parcelas de Acordos Vencidas e não Quitadas para o Representante!' DESCRICAO,
               'Rep.: '||R.NOME_REPRES||' Acordo: '||R.NRO_ACORDO||' Parcela: '||R.PARCELA||' Valor.: '||R.VLR_PARC_ABERTO COMPLEMENTO,
               'B' BLOQUEIOLIBERACAO
  FROM MAC_GERCOMPRA X INNER JOIN esp_Mac_GerCompraCompl C ON X.SEQGERCOMPRA = C.SEQGERCOMPRA
                       INNER JOIN MAF_FORNECCONTATO F ON F.SEQFORNECCONTATO = C.SEQFORNECCONTATO
                       INNER JOIN MAC_GERCOMPRAFORN FO ON FO.SEQGERCOMPRA = X.SEQGERCOMPRA
                       INNER JOIN NAGV_BASE_REGUA_COBRANCA R ON R.COD_FORNECEDOR = FO.SEQFORNECEDOR AND UPPER(R.EMAIL_REP) = UPPER(F.EMAILACORDO)
                       
WHERE  X.TIPOLOTE = 'C'
  AND R.DIAS_ATE_VENC < 0
  AND X.SEQGERCOMPRA = 444278; -- Lote Teste para nao travar outros ate definicao
