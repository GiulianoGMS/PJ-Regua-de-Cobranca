CREATE OR REPLACE PROCEDURE NAGP_EMAIL_REGUA_COBRANCA (psEmail              VARCHAR2, 
                                                      psEnviaTICopia        VARCHAR2, 
                                                      psEnviaCARCopia       VARCHAR2, 
                                                      psEnviaFinFornecCopia VARCHAR2, 
                                                      psNivelRegua          NUMBER) AS

    vsQtd            NUMBER(30);
    vsEmail          VARCHAR2(200);
    psComprador      VARCHAR2(2000);
    psRepresentante  VARCHAR2(2000);
    vsTable          CLOB := EMPTY_CLOB();
    vsHtml           CLOB := EMPTY_CLOB();
    psEmailTI        VARCHAR2(1000);
    psNroAcordo      NUMBER(30);
    psDiasVencto     NUMBER(10);
    psEmailCAR       VARCHAR2(2000);
    psEmailFinFornec VARCHAR2(3000);
    
BEGIN
    -- Envia para TI em copia
    IF psEnviaTICopia = 'S' 
      THEN
        psEmailTI := fEmailTI();
    END IF;
    -- Envia para CAR em copia
    IF psEnviaCARCopia = 'S'
      THEN
        psEmailCAR := fEmailCAR();
    END IF;
    
    -- Quantidade de acordos
    SELECT COUNT(DISTINCT A.NRO_ACORDO), MAX(INITCAP(COMPRADOR)), MAX(INITCAP(A.NOME_REPRES)), MAX(EMAIL_FIN_FORNEC)
      INTO vsQtd, psComprador, psRepresentante, psEmailFinFornec
      FROM NAGV_BASE_REGUA_COBRANCA A
     WHERE A.NIVEL_REGUA = psNivelRegua
       AND A.EMAIL_REP = psEmail;

    IF vsQtd = 0 THEN
       RETURN; -- não há acordos
    END IF;
    
    -- Envia para Fin Fornec em copia
    IF psEnviaFinFornecCopia = 'N'
      THEN
        psEmailFinFornec := NULL;
    END IF;

    -- Pega dados do Fornecedor
   vsEmail := psEmail;

    -- Monta as linhas da tabela
    -- o LOOP vai lupar apenas para agregar os dados!
    -- O email será um agrupado (unico)
    
    FOR t IN (
        SELECT DISTINCT
             NRO_ACORDO,
             DESCACORDO,
             TIPO_ACORDO,
             PARCELA NROPARCELA,
             DTAVENCIMENTO,
             VLR_PARC_ABERTO, X.DIAS_ATE_VENC
        FROM NAGV_BASE_REGUA_COBRANCA X
       WHERE EMAIL_REP   = psEmail
         AND NIVEL_REGUA = psNivelRegua
       ORDER BY DTAVENCIMENTO,
                NRO_ACORDO,
                PARCELA
    )
    LOOP
      psNroAcordo := t.Nro_Acordo;
      psDiasVencto := t.DIAS_ATE_VENC;
      
        vsTable := vsTable ||

         '<tr>
            <td style="padding:10px;border-bottom:1px solid #f3f4f6;">' || t.NRO_ACORDO || '</td>
            <td style="padding:10px;border-bottom:1px solid #f3f4f6;">' || t.DESCACORDO || '</td>
            <td style="padding:10px;border-bottom:1px solid #f3f4f6;">' || t.TIPO_ACORDO || '</td>
            <td style="padding:10px;border-bottom:1px solid #f3f4f6;text-align:center;">' || t.NROPARCELA || '</td>
            <td style="padding:10px;border-bottom:1px solid #f3f4f6;">' || TO_CHAR(t.DTAVENCIMENTO,'DD/MM/YYYY') || '</td>
            <td style="padding:10px;border-bottom:1px solid #f3f4f6;text-align:right;">' || t.VLR_PARC_ABERTO || '</td>
          </tr>';
       
    END LOOP;

    -- Monta o corpo completo do e-mail
    vsHtml := 
            '<!doctype html>
            <html lang="pt-BR">
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width,initial-scale=1">
            </head>

            <body style="margin:0;padding:0;background:#f3f4f6;font-family:Arial,Helvetica,sans-serif;color:#111;">

            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f3f4f6;padding:24px 0;">
            <tr>
            <td align="center">

            <table role="presentation" width="1100" style="max-width:1100px;background:#ffffff;border-radius:8px;overflow:hidden;box-shadow:0 6px 18px rgba(17,24,39,0.08);">

            <tr>
            <td style="padding:24px 28px;background:linear-gradient(90deg,#dc2626,#ef4444);color:#fff;">
            <table role="presentation" width="100%">
            <tr>
            <td>
            <img src="https://blog.nagumo.com.br/wp-content/uploads/2023/04/Horizontal_positivo800px.png" width="120">
            </td>
            <td align="right" style="background:#ffffff;color:#111827;">
            <strong style="font-size:14px;">Administração Nagumo</strong><br>
            <span style="font-size:10px;color:#9ca3af;letter-spacing:0.5px;">
            Régua de Cobrança
            </span>
            </td>
            </tr>
            </table>
            </td>
            </tr>

            <tr>
            <td style="padding:24px 28px 12px 28px;">

            <h2 style="margin:0 0 12px 0;font-size:20px;color:#0b2545;">
            Prezado(a), '||psRepresentante||'
            </h2>

            <p style="margin:0 0 12px 0;font-size:14px;color:#374151;line-height:1.6;">
            Identificamos que há parcelas de acordos em aberto vinculados à sua empresa.
            </p>

            <p style="margin:0 0 12px 0;font-size:14px;color:#dc2626;line-height:1.6;">
            <strong>'||
            CASE WHEN psNivelRegua < 4 THEN 'Solicitamos, por gentileza, a regularização dos pagamentos para não sofrer bloqueio do pedido em '
            || psDiasVencto ||' dias.'
                 ELSE '...Pendente Falconi definir mensagem no D+15...'
                   END||'
            </strong>
            </p>

            <p style="margin:0;font-size:14px;color:#374151;line-height:1.6;">
            Parcelas em aberto:
            </p>

            </td>
            </tr>

            <tr>
            <td style="padding:18px 28px;">

            <table role="presentation" width="100%" cellpadding="10" cellspacing="0" style="border-collapse:collapse;">

            <thead>
            <tr>
            <th style="text-align:left;font-size:12px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Número Acordo</th>
            <th style="text-align:left;font-size:12px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Descrição do Acordo</th>
            <th style="text-align:left;font-size:12px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Tipo</th>
            <th style="text-align:center;font-size:12px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Parcela</th>
            <th style="text-align:left;font-size:12px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Vencimento</th>
            <th style="text-align:right;font-size:12px;color:#6b7280;border-bottom:1px solid #e5e7eb;">Valor Aberto</th>
            </tr>
            </thead>

            <tbody>'
            || vsTable ||
            '</tbody>

            </table>

            </td>
            </tr>

            <tr>
            <td style="padding:0 28px 24px 28px;">

            <p style="font-size:14px;color:#374151;line-height:1.6;">
            Caso o pagamento já tenha sido realizado, favor desconsiderar este e-mail.
            </p>

            <p style="font-size:14px;color:#374151;line-height:1.6;">
            Em caso de dúvidas ou necessidade de suporte, contate
            <b>lista.contasareceber@nagumocombr.onmicrosoft.com</b>.
            </p>

            <p style="font-size:14px;color:#374151;line-height:1.6;">
            Atenciosamente,<br>
            <strong>Administração Nagumo</strong>
            </p>

            </td>
            </tr>

            <tr>
            <td style="padding:18px 28px;background:#f9fafb;border-top:1px solid #eef2f7;">
            <table role="presentation" width="100%">
            <tr>
            <td style="font-size:12px;color:#9ca3af;">
            Enviado automaticamente, não responda este e-mail.
            </td>
            <td align="right" style="font-size:12px;color:#9ca3af;">'
            || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI') ||
            '</td>
            </tr>
            </table>
            </td>
            </tr>

            </table>

            </td>
            </tr>
            </table>

            </body>
            </html>';
    
    IF vsEmail IS NOT NULL THEN

    -- Envia apenas 1 e-mail consolidado
    CONSINCO.SP_ENVIA_EMAIL(
        CONSINCO.C5_TP_PARAM_SMTP(1),
        psEmailTI||vsEmail,
        'Nagumo - Acordos Comerciais - Pendências de Pagamentos',
        vsHtml,
        'N');
        
     -- Grava log

    INSERT INTO NAGT_LOG_ENVIO_ACO_EMAIL (
        NRO_ACORDO,
        COD_COMPRADOR,
        EMAIL_DESTINO,
        QTDE_ACORDOS,
        HTML_EMAIL,
        DATA_ENVIO
    ) VALUES (
        psNroAcordo,
        0,
        psEmailFinFornec||psEmailCAR||psEmailTI||vsEmail,
        vsQtd,
        vsHtml,
        SYSDATE
        
    );
    COMMIT;
    
    END IF;
    
END;
