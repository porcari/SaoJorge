unit millenium_jorgeEmblue_Integracoes;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles, millenium_jorgeEmblue_Utils;

procedure Executar(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    Integracoes,Envio,Retorno,ItensLog,ItensErro,ItensErroOld,result,Data:IwtsWriteData;
    IdLog,QTDProcessados:String;
begin
  try
    cmd01 := DataPool.Open('millenium');
    Envio := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.ENVIO');

    cmd01.execute('SELECT V.EBL_INTEGRACAO, '+
                  '       V.EBL_DESCRICAO, '+
                  '       V.EBL_TOKEN, '+
                  '       V.EBL_URL, '+
                  '       V.EBL_MODELO, '+
                  '       V.EBL_TRANS_ID '+
                  'FROM EBL_INTEGRACOES V ');

    Integracoes := cmd01.CreateRecordset();
    Integracoes.First;
    while not Integracoes.EOF do
    begin
      try
        //vamos gerar cabeçalho do log
        IdLog := IncializaLog(DataPool,Integracoes.AsString['EBL_INTEGRACAO'],Integracoes.AsString['EBL_TRANS_ID']);
        DataPool.CommitAllRetain;


        Envio.New;
        Envio.Value['TRANS_ID'] := Integracoes.AsString['EBL_TRANS_ID'];
        Envio.Value['TOKEN'] := Integracoes.AsString['EBL_TOKEN'];
        Envio.Value['URL'] := Integracoes.AsString['EBL_URL'];
        Envio.Add;
        Data := DataPool.CreateRecordset(Pchar('MILLENIUM!JORGEEMBLUE.'+Integracoes.AsString['EBL_MODELO']));
        Data.New;
        Data.SetFieldByName('ENVIO',Envio);
        Data.Add;

        result := Call('MILLENIUM!JORGEEMBLUE.'+Integracoes.AsString['EBL_MODELO'],Data,true,'','');
        Retorno := result.GetFieldAsData('RETORNO') AS IwtsWriteData;

        Retorno.First;
        QTDProcessados := Retorno.AsString['QTD_REGISTROS_PROCESSADOS'];
        ItensLog := Retorno.AsData['ITENS_LOG'] as IwtsWriteData;
        ItensErro := Retorno.AsData['ITENS_ERRO'] as IwtsWriteData;

        cmd01.Dim('EBL_INTEGRACAO',Integracoes.AsString['EBL_INTEGRACAO']);
        cmd01.Dim('TRANS_ID',Retorno.AsString['TRANS_ID']);
        cmd01.Dim('STATUS_ULTIMO_PROCESSO','Finalizado com sucesso!'); 
        cmd01.execute('UPDATE EBL_INTEGRACOES SET EBL_TRANS_ID=:TRANS_ID,EBL_STATUS_ULTIMO_PROCESSO=:STATUS_ULTIMO_PROCESSO '+
                      'WHERE EBL_INTEGRACAO=:EBL_INTEGRACAO ');


        //CARREGAR ITENS COM ERRO OLD
        cmd01.Dim('EBL_INTEGRACAO',Integracoes.AsString['EBL_INTEGRACAO']);
        cmd01.execute('SELECT EBL_ITEM_ERRO, '+
                      '       EBL_CODIGO, '+
                      '       EBL_TENTATIVAS '+
                      'FROM EBL_ITENS_ERRO '+
                      'WHERE EBL_INTEGRACAO=:EBL_INTEGRACAO ');
        ItensErroOld := cmd01.CreateRecordset;

        //LIMPAR ERROS
        cmd01.Dim('EBL_INTEGRACAO',Integracoes.AsString['EBL_INTEGRACAO']);
        cmd01.execute('DELETE FROM EBL_ITENS_ERRO '+
                      'WHERE EBL_INTEGRACAO=:EBL_INTEGRACAO AND '+
                      '      EBL_STATUS<>"AG_LIBERACAO" ');

        //PROCESSAR ERROS NEW
        ItensErro.First;
        while not ItensErro.EOF do
        begin
          if ItensErroOld.Locate(['EBL_CODIGO'],[ItensErro.AsString['CODIGO']]) then
          begin
            cmd01.Dim('EBL_DATA',now);
            cmd01.Dim('EBL_ITEM_ERRO',ItensErroOld.AsString['EBL_ITEM_ERRO']);
            cmd01.Dim('EBL_TENTATIVAS',ItensErroOld.Value['EBL_TENTATIVAS']+1);
            if ItensErroOld.Value['EBL_TENTATIVAS']>4 then
              cmd01.Dim('EBL_STATUS','AG_LIBERACAO')
            else
              cmd01.Dim('EBL_STATUS','REPROCESSANDO');
            cmd01.execute('UPDATE INTO EBL_ITENS_ERRO SET EBL_STATUS=:EBL_STATUS,EBL_DATA=:EBL_DATA,EBL_TENTATIVAS=:EBL_TENTATIVAS) '+
                          'WHERE EBL_ITEM_ERRO=:EBL_ITEM_ERRO ');
          end
          else
          begin
            cmd01.Dim('EBL_INTEGRACAO',Integracoes.AsString['EBL_INTEGRACAO']);
            cmd01.Dim('EBL_CODIGO',ItensErro.AsString['CODIGO']);
            cmd01.Dim('EBL_STATUS','REPROCESSANDO');
            cmd01.Dim('EBL_DATA',now);
            cmd01.Dim('EBL_TENTATIVAS',1);
            cmd01.execute('INSERT INTO EBL_ITENS_ERRO ( EBL_INTEGRACAO, EBL_CODIGO, EBL_STATUS, EBL_DATA, EBL_TENTATIVAS) '+
                          '                    VALUES (:EBL_INTEGRACAO,:EBL_CODIGO,:EBL_STATUS,:EBL_DATA,:EBL_TENTATIVAS) '+
                          '#RETURN (EBL_ITEM_ERRO) ');
          end;

          ItensErro.Next;
        end;

        ItensLog.First;
        while not ItensLog.EOF do
        begin
          //gera log do item
          GravaItemLog(DataPool,IdLog,ItensLog.AsString['CODIGO'],ItensLog.AsString['OBS'],ItensLog.Value['DATA']);

          ItensLog.Next;
        end;

        //finaliza o cabeçalho do log
        FinalizaLog(DataPool,IdLog,QTDProcessados);
        LimpaLog(DataPool);
        DataPool.CommitAllRetain;
      except
        on E: Exception do
        begin
          addlog(0,'Erro na integração emblue no integrador '+Integracoes.AsString['EBL_INTEGRACAO']+': '+e.Message,'EMBLUE_INTEGRACAO');

          cmd01.Dim('EBL_INTEGRACAO',Integracoes.AsString['EBL_INTEGRACAO']);
          cmd01.Dim('STATUS_ULTIMO_PROCESSO',copy('Com erro: '+E.Message,0,150));
          cmd01.execute('UPDATE EBL_INTEGRACOES SET EBL_STATUS_ULTIMO_PROCESSO=:STATUS_ULTIMO_PROCESSO '+
                        'WHERE EBL_INTEGRACAO=:EBL_INTEGRACAO ');
        end;
      end;
      Integracoes.Next;
    end;
  except
    on E: Exception do
    begin
      addlog(0,'Erro na integração emblue: '+e.Message,'EMBLUE_INTEGRACAO');

      cmd01.Dim('STATUS_ULTIMO_PROCESSO',copy('Com erro geral: '+E.Message,0,150));
      cmd01.execute('UPDATE EBL_INTEGRACOES SET EBL_STATUS_ULTIMO_PROCESSO=:STATUS_ULTIMO_PROCESSO ');
    end;
  end;
end;

initialization
  wtsRegisterProc('INTEGRACOES.Executar',Executar);

end.

