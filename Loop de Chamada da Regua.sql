BEGIN
  FOR email IN (SELECT DISTINCT XX.EMAIL_REP FROM NAGV_BASE_REGUA_COBRANCA XX) 
 
   LOOP
   -- Variaveis Abertas
   -- Nivel 1
   NAGP_EMAIL_REGUA_COBRANCA(psEmail               => email.EMAIL,
                             psEnviaTICopia        => 'N',
                             psEnviaCARCopia       => 'N',
                             psEnviaFinFornecCopia => 'N',
                             psEnviaCompCopia      => 'N',
                             psEmailDir            => 'N',
                             psNivelRegua          => 1);
   -- Nivel 2
   NAGP_EMAIL_REGUA_COBRANCA(psEmail               => email.EMAIL,
                             psEnviaTICopia        => 'N',
                             psEnviaCARCopia       => 'S',
                             psEnviaFinFornecCopia => 'S',
                             psEnviaCompCopia      => 'S',
                             psEmailDir            => 'N',
                             psNivelRegua          => 2);
   -- Nivel 3               
   NAGP_EMAIL_REGUA_COBRANCA(psEmail               => email.EMAIL,
                             psEnviaTICopia        => 'N',
                             psEnviaCARCopia       => 'S',
                             psEnviaFinFornecCopia => 'S',
                             psEnviaCompCopia      => 'S',
                             psEmailDir            => 'N',
                             psNivelRegua          => 3);
   -- Nivel 4  
   NAGP_EMAIL_REGUA_COBRANCA(psEmail               => email.EMAIL,
                             psEnviaTICopia        => 'S',
                             psEnviaCARCopia       => 'S',
                             psEnviaFinFornecCopia => 'S',
                             psEnviaCompCopia      => 'S',
                             psEmailDir            => 'S',
                             psNivelRegua          => 4);                      
   
   END LOOP;
 
 END;
