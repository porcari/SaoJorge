unit millenium_jorgeEmblue_Clientes;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles, millenium_jorgeEmblue_Utils;

procedure Enviar(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    ClientesMillennium,Envio,Retorno,ItensLog,ItensErro:IwtsWriteData;
    TransId:Integer;
    i: Integer;
begin
  try
    try
      cmd01 := DataPool.Open('millenium');
      Retorno := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.RETORNO');
      ItensLog := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.ITENS_LOG');
      ItensErro := DataPool.CreateRecordset('MILLENIUM!JORGEEMBLUE.INTEGRACOES.ITENS_ERRO');
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
          cmd01.Dim('EMAIL',ClientesMillennium.Value['EMAIL']);
          cmd01.Dim('NOME',ClientesMillennium.Value['NOME']);
          cmd01.Dim('CPF_CNPJ',ClientesMillennium.Value['CPF_CNPJ']);
          cmd01.Dim('CEP',ClientesMillennium.Value['CEP']);
          cmd01.Execute('#CALL MILLENIUM!JORGEEMBLUE.CLIENTES.ATUALIZAREMBLUE(URL=:URL,TOKEN=:TOKEN,EMAIL=:EMAIL,NOME=:NOME,CPF_CNPJ=:CPF_CNPJ,CEP=:CEP)');

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
    json:String;
begin
  RestEmBlue := TRestEmblue.Create(Input.AsString['TOKEN'],Input.AsString['URL']);
  try
    json := '{"email": "'+Input.AsString['EMAIL']+'", '+
            ' "eventName": "ev_incluiroualterar", '+
            ' "attributes": {"nome": "'+Input.AsString['NOME']+'",'+
            '                "cpf_cnpj": "'+Input.AsString['CPF_CNPJ']+'",'+
            '                "cep": "'+Input.AsString['CEP']+'"}}';

    RestEmBlue.Post(json);
  finally
    FreeAndNil(RestEmBlue);
  end;
end;

initialization
  wtsRegisterProc('CLIENTES.Enviar',Enviar);
  wtsRegisterProc('CLIENTES.AtualizarEmblue',AtualizarEmblue);

end.

