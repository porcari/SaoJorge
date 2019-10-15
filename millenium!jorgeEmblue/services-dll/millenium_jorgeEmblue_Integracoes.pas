unit millenium_jorgeEmblue_Integracoes;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles, millenium_jorgeEmblue_Utils;

procedure Executar(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    Integracoes,Envio,Retorno,Atributos,ItensLog,ItensErro,ItensErroOld,result,Data:IwtsWriteData;
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
        //vamos gerar cabe�alho do log
        IdLog := IncializaLog(DataPool,Integracoes.AsString['EBL_INTEGRACAO'],Integracoes.AsString['EBL_TRANS_ID']);
        DataPool.CommitAllRetain;

        cmd01.Dim('TRANS_ID',Integracoes.AsString['EBL_TRANS_ID']);
        cmd01.Dim('INTEGRACAO',Integracoes.AsString['EBL_INTEGRACAO']);
        cmd01.Execute('#CALL MILLENIUM!JORGEEMBLUE.'+Integracoes.AsString['EBL_MODELO']+'.LISTAR(TRANS_ID=:TRANS_ID,INTEGRACAO=:INTEGRACAO) ');
        Atributos := cmd01.CreateRecordset();

        QTDProcessados := IntToStr(Atributos.RecordCount);

        Envio.New;
        Envio.Value['TRANS_ID'] := Integracoes.AsString['EBL_TRANS_ID'];
        Envio.Value['TOKEN'] := Integracoes.AsString['EBL_TOKEN'];
        Envio.Value['URL'] := Integracoes.AsString['EBL_URL'];
        Envio.Add;
        Data := DataPool.CreateRecordset(Pchar('MILLENIUM!JORGEEMBLUE.'+Integracoes.AsString['EBL_MODELO']+'.ENVIAR'));
        Data.New;
        Data.SetFieldByName('ENVIO',Envio);
        Data.SetFieldByName('ATRIBUTOS',Atributos);
        Data.Add;

        result := Call('MILLENIUM!JORGEEMBLUE.'+Integracoes.AsString['EBL_MODELO']+'.ENVIAR',Data,true,'','');
        Retorno := result.GetFieldAsData('RETORNO') AS IwtsWriteData;

        Retorno.First;
        ItensLog := Retorno.AsData['ITENS_LOG'] as IwtsWriteData;
        ItensErro := Retorno.AsData['ITENS_ERRO'] as IwtsWriteData;

        cmd01.Dim('EBL_INTEGRACAO',Integracoes.AsString['EBL_INTEGRACAO']);
        cmd01.Dim('TRANS_ID',Retorno.AsString['TRANS_ID']);
        cmd01.execute('UPDATE EBL_INTEGRACOES SET EBL_TRANS_ID=:TRANS_ID '+
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
                      '      EBL_STATUS="REPROCESSANDO" ');

        //PROCESSAR ERROS NEW
        ItensErro.First;
        while not ItensErro.EOF do
        begin
          if ItensErroOld.Locate(['EBL_CODIGO'],[ItensErro.AsString['CODIGO']]) then
          begin
            cmd01.Dim('EBL_TENTATIVAS',ItensErroOld.Value['EBL_TENTATIVAS']+1);
            if ItensErroOld.Value['EBL_TENTATIVAS']>4 then
              cmd01.Dim('EBL_STATUS','AG_LIBERACAO')
            else
              cmd01.Dim('EBL_STATUS','REPROCESSANDO');
          end
          else
          begin
            cmd01.Dim('EBL_TENTATIVAS',1);
            cmd01.Dim('EBL_STATUS','REPROCESSANDO');
          end;

          cmd01.Dim('EBL_INTEGRACAO',Integracoes.AsString['EBL_INTEGRACAO']);
          cmd01.Dim('EBL_CODIGO',ItensErro.AsString['CODIGO']);
          cmd01.Dim('EBL_OBS',ItensErro.AsString['OBS']);
          cmd01.Dim('EBL_DATA',now);

          cmd01.execute('INSERT INTO EBL_ITENS_ERRO ( EBL_INTEGRACAO, EBL_CODIGO, EBL_STATUS, EBL_DATA, EBL_TENTATIVAS, EBL_OBS) '+
                        '                    VALUES (:EBL_INTEGRACAO,:EBL_CODIGO,:EBL_STATUS,:EBL_DATA,:EBL_TENTATIVAS,:EBL_OBS) '+
                        '#RETURN (EBL_ITEM_ERRO) ');

          ItensErro.Next;
        end;

        ItensLog.First;
        while not ItensLog.EOF do
        begin
          //gera log do item
          GravaItemLog(DataPool,IdLog,ItensLog.AsString['CODIGO'],ItensLog.AsString['OBS'],ItensLog.Value['DATA']);

          ItensLog.Next;
        end;

        //finaliza o cabe�alho do log
        FinalizaLog(DataPool,IdLog,QTDProcessados,'Finalizado com Sucesso');
        LimpaLog(DataPool);
        DataPool.CommitAllRetain;
      except
        on E: Exception do
        begin
          addlog(0,'Erro na integra��o emblue no integrador '+Integracoes.AsString['EBL_INTEGRACAO']+': '+e.Message,'EMBLUE_INTEGRACAO');
          FinalizaLog(DataPool,IdLog,QTDProcessados,copy('Com erro: '+E.Message,0,150));
        end;
      end;
      Integracoes.Next;
    end;
  except
    on E: Exception do
    begin
      addlog(0,'Erro na integra��o emblue: '+e.Message,'EMBLUE_INTEGRACAO');
    end;
  end;
end;

initialization
  wtsRegisterProc('INTEGRACOES.Executar',Executar);

end.

