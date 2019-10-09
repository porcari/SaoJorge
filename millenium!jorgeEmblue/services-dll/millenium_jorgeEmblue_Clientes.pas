unit millenium_jorgeEmblue_Clientes;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles, millenium_jorgeEmblue_Utils;

procedure Enviar(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    ClientesMillennium,Atributos,Envio,Retorno,ItensLog,ItensErro:IwtsWriteData;
    TransId:Integer;
    i: Integer;
begin
  try
    try
      cmd01 := DataPool.Open('millenium');
      Retorno := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.RETORNO');
      ItensLog := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.ITENS_LOG');
      ItensErro := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.ITENS_ERRO');
      Atributos := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.CLIENTES.ATRIBUTOS');
      Envio := Input.GetParamAsData('ENVIO') as IwtsWriteData;
      ClientesMillennium := Input.GetParamAsData('ATRIBUTOS') as IwtsWriteData;
      TransId := Envio.Value['TRANS_ID'];

      ClientesMillennium.First;
      while not ClientesMillennium.EOF do
      begin
        try
          if TransId<ClientesMillennium.Value['TRANS_ID'] then          
            TransId :=  ClientesMillennium.Value['TRANS_ID'];

          cmd01.Dim('URL',Envio.AsString['URL']);
          cmd01.Dim('TOKEN',Envio.AsString['TOKEN']);

          Atributos.Clear;
          Atributos.New;
          CopyDataToData(ClientesMillennium,Atributos);
          Atributos.Add;
           
          cmd01.Dim('EMAIL',ClientesMillennium.Value['EMAIL']);
          cmd01.Dim('NOME',ClientesMillennium.Value['NOME']);
          cmd01.Dim('ATRIBUTOS',Atributos);
          cmd01.Execute('#CALL MILLENIUM!JORGEEMBLUE.CLIENTES.ATUALIZAREMBLUE(URL=:URL,TOKEN=:TOKEN,ATRIBUTOS=:ATRIBUTOS)');

          ItensLog.New;
          ItensLog.SetFieldByName('CODIGO',ClientesMillennium.AsString['COD_CLIENTE']);
          ItensLog.SetFieldByName('OBS','Sucesso na atualização do cliente '+ClientesMillennium.Value['NOME']);
          ItensLog.SetFieldByName('DATA',now);
          ItensLog.Add;
        except
          on E: Exception do
          begin
            ItensErro.New;
            ItensErro.SetFieldByName('CODIGO',ClientesMillennium.AsString['CLIENTE']);
            ItensErro.SetFieldByName('OBS',copy(ClientesMillennium.AsString['COD_CLIENTE']+' - '+ClientesMillennium.Value['NOME']+' / '+ClientesMillennium.Value['EMAIL'],0,250));
            ItensErro.Add;

            ItensLog.New;
            ItensLog.SetFieldByName('CODIGO',ClientesMillennium.AsString['COD_CLIENTE']);
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
    Retorno.Add;

    Retorno.First;
    Output.NewRecord;
    Output.SetFieldByName('RETORNO',Retorno);
  end;
end;

procedure AtualizarEmblue(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var RestEmBlue:TRestEmblue;
    Atributos:IwtsWriteData;
    json:String;
    i: Integer;
begin
  Atributos := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.CLIENTES.ATRIBUTOS');
  Atributos := Input.GetParamAsData('ATRIBUTOS') as IwtsWriteData;
  RestEmBlue := TRestEmblue.Create(Input.AsString['TOKEN'],Input.AsString['URL']);
  try
    atributos.First;
    while not Atributos.EOF do
    begin
      json := '';
      for i := 0 to Atributos.FieldCount - 1 do
      begin
        json := json + '"'+LowerCase(Atributos.FieldName(i))+'":"'+Atributos.AsString[Pchar(Atributos.FieldName(i))]+'",';
      end;

      SetLength(json,length(json)-1);

      json := '{"email": "'+Atributos.AsString['EMAIL']+'", '+
              ' "eventName": "ev_incluiroualterar", '+
              ' "attributes": {'+json+'}}';

      RestEmBlue.Post(json);
      Atributos.Next;
    end;
  finally
    FreeAndNil(RestEmBlue);
  end;
end;

initialization
  wtsRegisterProc('CLIENTES.Enviar',Enviar);
  wtsRegisterProc('CLIENTES.AtualizarEmblue',AtualizarEmblue);

end.

