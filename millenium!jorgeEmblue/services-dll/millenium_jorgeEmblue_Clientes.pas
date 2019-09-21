unit millenium_jorgeEmblue_Clientes;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles, millenium_jorgeEmblue_Utils;

procedure Enviar(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
    procedure SetField(var AAtributos:IwtsWriteData;const ACampo,AValor:String);
    begin
      AAtributos.New;
      AAtributos.SetFieldByName('NOME',ACampo);
      AAtributos.SetFieldByName('VALOR',AValor);
      AAtributos.Add;
    end;
var cmd01: IwtsCommand;
    ClientesMillennium,Envio,Retorno,ItensLog,ItensErro,Atributos:IwtsWriteData;
    QTDProcessados,TransId:Integer;
    i: Integer;
begin
  try
    try
      cmd01 := DataPool.Open('millenium');
      Retorno := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.RETORNO');
      Atributos := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.CLIENTES.ATRIBUTOS');
      ItensLog := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.ITENS_LOG');
      ItensErro := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.ITENS_ERRO');
      Envio := Input.GetParamAsData('ENVIO') as IwtsWriteData;
      QTDProcessados := 0;
      TransId := Envio.Value['TRANS_ID'];

      cmd01.Dim('TRANS_ID',TransId);
      cmd01.Execute('#CALL MILLENIUM!JORGEEMBLUE.CLIENTES.LISTAR(TRANS_ID=:TRANS_ID) ');
      ClientesMillennium := cmd01.CreateRecordset();

      QTDProcessados := ClientesMillennium.RecordCount;

      ClientesMillennium.First;
      while not ClientesMillennium.EOF do
      begin
        try
          TransId :=  ClientesMillennium.Value['TRANS_ID'];
          Atributos.Clear;
          SetField(Atributos,'nome',ClientesMillennium.AsString['NOME']);

          cmd01.Dim('URL',Envio.AsString['URL']);
          cmd01.Dim('TOKEN',Envio.AsString['TOKEN']);
          cmd01.DimAsData('ATRIBUTOS',Atributos);
          cmd01.Execute('#CALL MILLENIUM!JORGEEMBLUE.CLIENTES.ATUALIZAREMBLUE(URL=:URL,TOKEN=:TOKEN,ATRIBUTOS=:ATRIBUTOS)')
        except
          on E: Exception do
          begin
            ItensErro.New;
            ItensErro.SetFieldByName('CODIGO',ClientesMillennium.AsString['COD_CLIENTE']);
            ItensErro.Add;

            ItensLog.New;
            ItensLog.SetFieldByName('CODIGO','');
            ItensLog.SetFieldByName('OBS','ERRO: '+e.Message);
            ItensLog.SetFieldByName('DATA',now);
            ItensLog.Add;
          end;
        end;
        ClientesMillennium.Next;
      end;
    except
      on E: Exception do
      begin
        ItensLog.New;
        ItensLog.SetFieldByName('CODIGO','');
        ItensLog.SetFieldByName('OBS','ERRO: '+e.Message);
        ItensLog.SetFieldByName('DATA',now);
        ItensLog.Add;
      end;
    end;
  finally
    Retorno.New;
    Retorno.SetFieldByName('TRANS_ID',TransId);
    Retorno.SetFieldByName('ITENS_ERRO',ItensErro);
    Retorno.SetFieldByName('ITENS_LOG',ItensLog);
    Retorno.SetFieldByName('QTD_REGISTROS_PROCESSADOS',QTDProcessados);
    Retorno.Add;

    Retorno.First;
    Output.NewRecord;
    Output.SetFieldByName('RETORNO',Retorno);
  end;
end;

procedure AtualizarEmblue(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var RestEmBlue:TRestEmblue;
    json:String;
begin
  RestEmBlue := TRestEmblue.Create(Input.AsString['TOKEN'],Input.AsString['URL']);
  try
    json := '{"email": "fulanoo@hotmail.com", '+
            ' "eventName": "ev_incluiroualterar", '+
            ' "attributes": {"nome": "evento bbb"}}';

    RestEmBlue.Post(json)
  finally
    FreeAndNil(RestEmBlue);
  end;
end;

initialization
  wtsRegisterProc('CLIENTES.Enviar',Enviar);
  wtsRegisterProc('CLIENTES.AtualizarEmblue',AtualizarEmblue);

end.

