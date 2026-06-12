CREATE OR REPLACE FUNCTION fEmailDiretoria 

  RETURN VARCHAR2 AS
  retorno VARCHAR2(300); 

BEGIN

  SELECT 'email_diretoria@...;' INTO retorno FROM DUAL;
 
  RETURN retorno;

END;
