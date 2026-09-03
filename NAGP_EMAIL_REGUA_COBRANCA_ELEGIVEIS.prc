CREATE OR REPLACE PROCEDURE NAGP_EMAIL_REGUA_COBRANCA_ELEGIVEIS (
    psEmail                 VARCHAR2,
    psEnviaTICopia          VARCHAR2,
    psEnviaCARCopia         VARCHAR2,
    psEnviaFinFornecCopia   VARCHAR2,
    psEnviaCompCopia        VARCHAR2,
    psEmailDir              VARCHAR2,
    psNivelRegua            NUMBER ) AS

    vsQtd                  NUMBER(30);
    vsEmail                VARCHAR2(200);

    psComprador            VARCHAR2(2000);
    psRepresentante        VARCHAR2(2000);
    psFornec               VARCHAR2(2000);

    psEmailTI              VARCHAR2(1000);
    psEmailCAR             VARCHAR2(2000);
    psEmailFinFornec       VARCHAR2(3000);
    psEmailComprador       VARCHAR2(3000);
    psEmailDiretoria       VARCHAR2(2000);
    vsQtdDias              NUMBER(10);

    vsHtml                 CLOB := EMPTY_CLOB();

BEGIN

    --------------------------------------------------------------------------
    -- Envia para TI em cópia
    --------------------------------------------------------------------------
    IF psEnviaTICopia = 'S' THEN
        psEmailTI := fEmailTI();
    END IF;
    --------------------------------------------------------------------------
    -- Envia para CAR em cópia
    --------------------------------------------------------------------------
    IF psEnviaCARCopia = 'S' THEN
        psEmailCAR := fEmailCAR();
    END IF;
    --------------------------------------------------------------------------
    -- Envia para Diretoria em cópia
    --------------------------------------------------------------------------
    IF psEmailDir = 'S' THEN
        psEmailDiretoria := fEmailDiretoria();
    END IF;
    --------------------------------------------------------------------------
    -- Busca informações gerais da régua
    --
    -- A consulta considera somente acordos que ainda não tiveram envio
    -- da régua no dia corrente.
    --------------------------------------------------------------------------
    SELECT
        COUNT(DISTINCT A.NRO_ACORDO),
     --   MAX(INITCAP(A.COMPRADOR)),
        --MAX(INITCAP(A.NOME_REPRES)),
        MAX(A.EMAIL_FIN_FORNEC),
        MAX(B.EMAIL),
        MAX(A.FORNECEDOR)
    INTO
        vsQtd,
     --   psComprador,
     --   psRepresentante,
        psEmailFinFornec,
        psEmailComprador,
        psFornec
    FROM NAGV_BASE_REGUA_COBRANCA_ELEGIVEIS A LEFT JOIN NAGT_EMAILCOMPRADORES B ON A.COD_COMPRADOR = B.SEQCOMPRADOR
   WHERE A.NIVEL_REGUA = psNivelRegua
     AND A.EMAIL_REP = psEmail 
     AND NOT EXISTS (
            SELECT 1
              FROM NAGT_LOG_ENVIO_ACO_EMAIL XX
             WHERE XX.NRO_ACORDO = A.NRO_ACORDO
               AND XX.DATA_ENVIO >= TRUNC(SYSDATE)
               AND XX.TIPO = 'Elegiveis'
      )
     -- Se ja enviou o bloqueio e ainda não foi quitado, nao reenvia
     AND NOT EXISTS (
            SELECT 2 FROM FI_TITULO FI WHERE FI.SEQPESSOA = A.COD_FORNECEDOR AND FI.CODESPECIE LIKE 'AC%' AND FI.ABERTOQUITADO = 'A' AND Fi.VLRPAGO < FI.VLRNOMINAL
               AND EXISTS (SELECT 1 FROM NAGT_LOG_ENVIO_ACO_EMAIL AC WHERE AC.NRO_ACORDO = FI.NROTITULO AND AC.PARCELA = FI.NROPARCELA||'/'||FI.QTDPARCELA 
                              AND AC.DATA_ENVIO >= DATE '2026-09-03' AND AC.TIPO = 'Elegiveis' AND AC.EMAIL_DESTINO LIKE '%'||A.EMAIL_REP||'%' HAVING COUNT(1) >= 4))
     ;
    --------------------------------------------------------------------------
    -- Não existem pendências para envio
    --------------------------------------------------------------------------
    IF vsQtd = 0 THEN
        RETURN;
    END IF;
    --------------------------------------------------------------------------
    -- Envia para Financeiro do Fornecedor em cópia
    --------------------------------------------------------------------------
    IF psEnviaFinFornecCopia = 'N' THEN
        psEmailFinFornec := NULL;
    END IF;
    --------------------------------------------------------------------------
    -- Envia para Comprador em cópia
    --------------------------------------------------------------------------
    IF psEnviaCompCopia = 'N' THEN
        psEmailComprador := NULL;
    ELSE
        IF psEmailComprador IS NOT NULL THEN
            psEmailComprador := psEmailComprador || ';';
        END IF;
    END IF;
    --------------------------------------------------------------------------
    -- E-mail principal
    --------------------------------------------------------------------------
    vsEmail := psEmail;
    --------------------------------------------------------------------------
    -- Monta o HTML do e-mail
    --
    -- IMPORTANTE:
    -- O e-mail agora é GENÉRICO.
    --
    -- Não são enviados:
    --   - Número do acordo
    --   - Descrição do acordo
    --   - Tipo do acordo
    --   - Número da parcela
    --   - Data de vencimento
    --   - Valor em aberto
    --
    -- O HTML será utilizado tanto no envio quanto no log.
    --------------------------------------------------------------------------
    vsHtml :=
    '<!doctype html>
    <html lang="pt-BR">

    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
    </head>

    <body
        style="
            margin:0;
            padding:0;
            background:#f3f4f6;
            font-family:Arial,Helvetica,sans-serif;
            color:#111;
        "
    >

        <table
            role="presentation"
            width="100%"
            cellpadding="0"
            cellspacing="0"
            style="
                background:#f3f4f6;
                padding:24px 0;
            "
        >

            <tr>

                <td align="center">

                    <table
                        role="presentation"
                        width="700"
                        style="
                            max-width:700px;
                            background:#ffffff;
                            border-radius:8px;
                            overflow:hidden;
                            box-shadow:0 6px 18px rgba(17,24,39,0.08);
                        "
                    >

                        <!-- CABEÇALHO -->

                <tr>
                    <td
                        style="
                            padding:22px 28px;
                            background:#ffffff;
                            border-bottom:3px solid #0b2545;
                        "
                    >

                        <table
                            role="presentation"
                            width="100%"
                            cellpadding="0"
                            cellspacing="0"
                            border="0"
                        >

                            <tr>

                                <td
                                    valign="middle"
                                >

                                    <img
                                        src="https://blog.nagumo.com.br/wp-content/uploads/2023/04/Horizontal_positivo800px.png"
                                        width="130"
                                        alt="Nagumo"
                                        style="
                                            display:block;
                                            border:0;
                                        "
                                    >

                                </td>

                                <td
                                    align="right"
                                    valign="middle"
                                    style="
                                        color:#0b2545;
                                        font-size:13px;
                                        line-height:18px;
                                    "
                                >

                                    <strong>
                                        Administração Nagumo
                                    </strong>

                                    <br>

                                    <span
                                        style="
                                            font-size:11px;
                                            color:#6b7280;
                                        "
                                    >
                                        Régua de Cobrança
                                    </span>

                                </td>

                            </tr>

                        </table>

                    </td>
                </tr>


                        <!-- CORPO -->

                        <tr>

                            <td
                                style="
                                    padding:28px;
                                "
                            >

                                <h2
                                    style="
                                        margin:0 0 16px 0;
                                        font-size:20px;
                                        color:#0b2545;
                                    "
                                >
                                    Prezado(a),
                                    ' || NVL(psRepresentante, '') || '
                                </h2>


                                <p
                                    style="
                                        margin:0 0 16px 0;
                                        font-size:14px;
                                        color:#374151;
                                        line-height:1.6;
                                    "
                                >

                                    Identificamos que existem
                                    <strong>pendências financeiras</strong>
                                    relacionadas a acordos comerciais
                                    vinculados à sua empresa
                                    (' || NVL(psFornec, '') || ').

                                </p>


                                <p
                                    style="
                                        margin:0 0 16px 0;
                                        font-size:14px;
                                        color:#374151;
                                        line-height:1.6;
                                    "
                                >

                                    Solicitamos, por gentileza, que verifique
                                    as pendências existentes e providencie
                                    a regularização dos pagamentos.

                                </p>';
    --------------------------------------------------------------------------
    -- Mensagem conforme o nível da régua
    --------------------------------------------------------------------------
    IF psNivelRegua < 4 THEN
      
      IF psNivelRegua = 1 THEN
         vsQtdDias := 15;
         ELSIF psNivelRegua = 2 THEN
               vsQtdDias := 10;
               ELSIF psNivelRegua = 3 THEN
                     vsQtdDias := 5;
                 END IF;
                 
        vsHtml := vsHtml ||
        '<p
            style="
                margin:0 0 16px 0;
                font-size:14px;
                color:#dc2626;
                line-height:1.6;
            "
        >

            <strong>
                A regularização é necessária para evitar eventuais
                bloqueios nos pedidos em até '||vsQtdDias||' dias.
            </strong>

        </p>';

    ELSE
        vsHtml := vsHtml ||
        '<p
            style="
                margin:0 0 16px 0;
                font-size:14px;
                color:#dc2626;
                line-height:1.6;
            "
        >

            <strong>
                Informamos que, conforme comunicado anteriormente,
                os pedidos irão permanecer bloqueados até a
                regularização das pendências.
            </strong>

        </p>';

    END IF;
    --------------------------------------------------------------------------
    -- Continuação do HTML
    --------------------------------------------------------------------------
    vsHtml := vsHtml ||
        '<p
            style="
                margin:0 0 16px 0;
                font-size:14px;
                color:#374151;
                line-height:1.6;
            "
        >

            Caso o pagamento já tenha sido realizado,
            favor desconsiderar este e-mail.

        </p>


        <p
            style="
                margin:0 0 16px 0;
                font-size:14px;
                color:#374151;
                line-height:1.6;
            "
        >

            Em caso de dúvidas ou necessidade de suporte,
            contate
            <b>
                lista.contasareceber@nagumocombr.onmicrosoft.com
            </b>.

        </p>


        <p
            style="
                margin:0;
                font-size:14px;
                color:#374151;
                line-height:1.6;
            "
        >

            Atenciosamente,<br>

            <strong>
                Administração Nagumo
            </strong>

        </p>

        </td>

        </tr>


        <!-- RODAPÉ -->

        <tr>

            <td
                style="
                    padding:18px 28px;
                    background:#f9fafb;
                    border-top:1px solid #eef2f7;
                "
            >

                <table
                    role="presentation"
                    width="100%"
                >

                    <tr>

                        <td
                            style="
                                font-size:12px;
                                color:#9ca3af;
                            "
                        >

                            Enviado automaticamente,
                            não responda este e-mail.

                        </td>

                        <td
                            align="right"
                            style="
                                font-size:12px;
                                color:#9ca3af;
                            "
                        >'

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
    --------------------------------------------------------------------------
    -- Grava o log individualmente por acordo/parcela
    --
    -- O e-mail é enviado de forma consolidada, porém o controle continua
    -- sendo gravado individualmente para cada acordo/parcela.
    --------------------------------------------------------------------------
    FOR t IN (
        SELECT DISTINCT
            NRO_ACORDO,
            PARCELA NROPARCELA
        FROM NAGV_BASE_REGUA_COBRANCA_ELEGIVEIS X
       WHERE X.EMAIL_REP = psEmail
          AND X.NIVEL_REGUA = psNivelRegua
          AND NOT EXISTS (
                SELECT 1
                  FROM NAGT_LOG_ENVIO_ACO_EMAIL XX
                 WHERE XX.NRO_ACORDO = X.NRO_ACORDO
                   AND XX.DATA_ENVIO >= TRUNC(SYSDATE)
                   AND XX.TIPO = 'Elegiveis'
          )
   /*            -- Se ja enviou o bloqueio e ainda não foi quitado, nao reenvia
     AND NOT EXISTS (
            SELECT 2 FROM FI_TITULO FI WHERE FI.SEQPESSOA = X.COD_FORNECEDOR AND FI.CODESPECIE LIKE 'AC%' AND FI.ABERTOQUITADO = 'A' AND Fi.VLRPAGO < FI.VLRNOMINAL
               AND EXISTS (SELECT 1 FROM NAGT_LOG_ENVIO_ACO_EMAIL AC WHERE AC.NRO_ACORDO = FI.NROTITULO AND AC.PARCELA = FI.NROPARCELA||'/'||FI.QTDPARCELA 
                              AND AC.DATA_ENVIO >= DATE '2026-08-01' AND AC.TIPO = 'Elegiveis' AND AC.NRO_ACORDO = X.NRO_ACORDO AND AC.EMAIL_DESTINO LIKE '%'||X.EMAIL_REP||'%' HAVING COUNT(1) >= 4))
     */
        ORDER BY
            NRO_ACORDO,
            PARCELA
    )
    LOOP
        ----------------------------------------------------------------------
        -- Grava log
        ----------------------------------------------------------------------
        INSERT INTO NAGT_LOG_ENVIO_ACO_EMAIL (
            NRO_ACORDO,
            COD_COMPRADOR,
            EMAIL_DESTINO,
            QTDE_ACORDOS,
            HTML_EMAIL,
            DATA_ENVIO,
            TIPO,
            PARCELA
        )
        VALUES (
            t.NRO_ACORDO,
            0,
            psEmailComprador
            || psEmailFinFornec
            || psEmailCAR
            || psEmailTI
            || psEmailDiretoria
            || vsEmail,
            vsQtd,
            vsHtml,
            SYSDATE,
            'Elegiveis',
            t.NROPARCELA
        );

    END LOOP;
    --------------------------------------------------------------------------
    -- Envia somente UM e-mail consolidado
    --------------------------------------------------------------------------
    IF vsEmail IS NOT NULL THEN

        CONSINCO.SP_ENVIA_EMAIL(
            CONSINCO.C5_TP_PARAM_SMTP(1),
            psEmailComprador
            || psEmailFinFornec
            || psEmailCAR
            || psEmailTI
            || psEmailDiretoria
            || vsEmail,
            'Nagumo - Acordos Comerciais - Pendências de Pagamentos',
            vsHtml,
            'N'
        );
        ----------------------------------------------------------------------
        -- Confirma tanto o log quanto o envio
        ----------------------------------------------------------------------
        COMMIT;

    END IF;


END;
