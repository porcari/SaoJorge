unit millenium_jorgeOracle_clientes;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, oracle_utils, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles;

procedure Importar(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);

    function buscaDDD(const fone: string): string;
    var numeroFone: string;
    begin
      result :='';
      if fone<>'' then
      begin
        numeroFone := Unformat(fone);
        if numeroFone[1] = '0' then
          result := Copy(numeroFone, 2, 3)
        else
          result := Copy(numeroFone, 1, 2);
      end;
    end;

    function buscaFone(const fone: string): string;
    var numeroFone: string;
    begin
      result :='';
      if fone<>'' then
      begin
        numeroFone := Unformat(fone);
        result := Copy(numeroFone, 3, 15);
      end;
    end;
var cmd01: IwtsCommand;
    cliente, requestPedido, responsePedido, enderecos,vitOracle,result: IwtsWriteData;
    jarr: TJSONarray;
    grantType, accessToken, sres, urlBase, urlRest, ddd, fone, nome, contato,json,idCliente: string;
    total: Double;
    userAtacado: Boolean;
    i, x,vitrine: Integer;
begin
  try
    cliente := DataPool.CreateRecordset('MILLENIUM_ECO.CLIENTES.CLIENTES');

    cmd01 := DataPool.Open('millenium');

    cmd01.execute('SELECT VDO.USUARIO_WEBSERVICE, ' +
                  '       VDO.SENHA_WEBSERVICE, ' +
                  '       VDO.URL_WEBSERVICE, ' +
                  '       V.VITRINE ' +
                  'FROM VITRINE V ' +
                  'INNER JOIN VITRINE_DADOS_ORACLE VDO ON VDO.VITRINE = V.VITRINE ' +
                  'WHERE V.EXPORTADOR ="14"');

    vitOracle := cmd01.CreateRecordset();

    if vitOracle.EOF then
      raise Exception.Create('Dados adicionais da integração Oracle não encontrado!');

    if vitOracle.RecordCount<>1 then
      raise Exception.Create('Existe mais de uma vitrine Oracle. Processo não suportado!');

    grantType := 'grant_type=password&username=' + vitOracle.GetFieldAsString('USUARIO_WEBSERVICE') + '&password=' + vitOracle.GetFieldAsString('SENHA_WEBSERVICE');
    urlBase := vitOracle.GetFieldAsString('URL_WEBSERVICE');
    vitrine := vitOracle.GetFieldByName('VITRINE');
    urlRest := '';
    accessToken := '';

    sres := RestClientCenter(accessToken, grantType, 'Get', urlBase, PChar('/ccadmin/v1/profiles/?q=email co "' + VarToStr(Input.GetParamByName('EMAIL')) + '"'));
    jarr := ParseJSON(PChar(utf8.UTF8ToString(sres)));
    try
      if jarr.Field['items'].Count = 0 then
        raise Exception.Create('Cliente não encontrado!');

      for i := 0 to jarr.Field['items'].Count - 1 do
      begin
        ddd := '';
        fone := '';
        cliente.Clear;

        idCliente := vartostr(jarr.Field['items'].Child[i].Field['id'].Value);      

        if vartostr(jarr.Field['items'].Child[i].Field['lastName'].Value) <> '' then
          nome := vartostr(jarr.Field['items'].Child[i].Field['firstName'].Value) + ' ' + vartostr(jarr.Field['items'].Child[i].Field['lastName'].Value)
        else
          nome := vartostr(jarr.Field['items'].Child[i].Field['firstName'].Value);

        if jarr.Field['items'].Child[i].Field['shippingAddress'].JsonText <> 'null' then
        begin
          ddd := buscaDDD(jarr.Field['items'].Child[i].Field['shippingAddress'].Field['phoneNumber'].Value);
          fone := buscafone(jarr.Field['items'].Child[i].Field['shippingAddress'].Field['phoneNumber'].Value);
        end;

        cliente.New;
        cliente.SetFieldByName('NOME', AnsiUpperCase(AbreviaNome(nome, 120)));
        cliente.SetFieldByName('FANTASIA', '');
        cliente.SetFieldByName('OBS', 'INTEGRAÇÂO ORACLE');
        cliente.SetFieldByName('DATA_ANIVERSARIO', '');
        cliente.SetFieldByName('DDD_CEL', ddd);
        cliente.SetFieldByName('CEL', fone);
        cliente.SetFieldByName('E_MAIL', vartostr(jarr.Field['items'].Child[i].Field['email'].Value));
        cliente.SetFieldByName('E_MAIL_NFE', vartostr(jarr.Field['items'].Child[i].Field['email'].Value));
        cliente.SetFieldByName('TIPO_SEXO', 'U');
        cliente.SetFieldByName('UFIE', '');
        cliente.SetFieldByName('VITRINE', vitrine);

        if VarToBool(jarr.Field['items'].Child[i].Field['pessoaJuridica'].Value) then
        begin
          cliente.SetFieldByName('CNPJ', VarToStr(jarr.Field['items'].Child[i].Field['pjCnpj'].Value));
          cliente.SetFieldByName('IE', VarToStr(jarr.Field['items'].Child[i].Field['pjInscricaoEstadual'].Value));
          cliente.SetFieldByName('PF_PJ', 'PJ');
        end
        else
        begin
          cliente.SetFieldByName('RG', '');
          cliente.SetFieldByName('CPF', VarToStr(jarr.Field['items'].Child[i].Field['pjCpfDoResponsavel'].Value));
          cliente.SetFieldByName('PF_PJ', 'PF');
        end;

        if VarToStr(jarr.Field['items'].Child[i].Field['receiveEmail'].Value)='yes' then
          cliente.SetFieldByName('MALAELETRONICA',true)
        else
          cliente.SetFieldByName('MALAELETRONICA',false);

        //Endereços
        enderecos := DataPool.CreateRecordset('MILLENIUM_ECO.CLIENTES.ENDERECO');
        for x := 0 to jarr.Field['items'].Child[i].Field['shippingAddresses'].Count - 1 do
        begin
          contato := '';
          if (jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['firstName'] <> nil) and (jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['lastName'] <> nil) then
            contato := vartostr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['firstName'].Value) + ' ' + vartostr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['lastName'].Value);

          enderecos.New;
          enderecos.SetFieldByName('LOGRADOURO', copy(AnsiUpperCase(VarToStr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['address1'].Value)), 1, 60));
          enderecos.SetFieldByName('NUMERO', copy(AnsiUpperCase(VarToStr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['address2'].Value)), 1, 10));
          enderecos.SetFieldByName('COMPLEMENTO', copy(AnsiUpperCase(VarToStr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['address3'].Value)), 1, 200));
          enderecos.SetFieldByName('BAIRRO', copy(AnsiUpperCase(VarToStr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['county'].Value)), 1, 20));
          enderecos.SetFieldByName('CIDADE', copy(RemoveAcentos(AnsiUpperCase(VarToStr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['city'].Value))), 1, 40));
          enderecos.SetFieldByName('ESTADO', copy(AnsiUpperCase(VarToStr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['state'].Value)), 1, 3));
          enderecos.SetFieldByName('NOME_PAIS', 'BRASIL');
          enderecos.SetFieldByName('CEP', copy(Unformat(VarToStr(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['postalCode'].Value)), 1, 9));
          enderecos.SetFieldByName('CONTATO', contato);
          if jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['phoneNumber'].JsonText<>'null' then
          begin
            enderecos.SetFieldByName('DDD', buscaDDD(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['phoneNumber'].Value));
            enderecos.SetFieldByName('FONE', buscaFone(jarr.Field['items'].Child[i].Field['shippingAddresses'].Child[x].Field['phoneNumber'].Value));
          end;
          enderecos.SetFieldByName('TIPO_SEXO', 'U');
          enderecos.Add; 
        end;
        cliente.SetFieldByName('ENDERECO', enderecos);
        cliente.Add;

        try
          result := Call('MILLENIUM_ECO.CLIENTES.INCLUIROUALTERAR', cliente, true, '', urlRest);

          if (not VarToBool(jarr.Field['items'].Child[i].Field['usr_importado'].Value)) and
             VarToBool(jarr.Field['items'].Child[i].Field['pessoaJuridica'].Value) then
          begin
            try
              //evento para workflow
              cmd01.Dim('CLIENTE',result.GetFieldByName('CLIENTE'));
              cmd01.Dim('EMAIL',result.GetFieldByName('CLIENTE'));
              cmd01.execute('#CALL MILLENIUM!JORGEORACLE.CLIENTES.EV_INCLUIRCLIENTE(CLIENTE=:CLIENTE,EMAIL=:EMAIL)');
            except
              on E: Exception do
              begin
                raise Exception.Create('Erro ao disparar evento do cliente ' + E.Message);
              end;
            end;

            json := '{"usr_importado" : true}';
            try
              RestClientCenter(accessToken, grantType, 'Put', urlBase, PChar('/ccadmin/v1/profiles/'+idCliente),json);
            except
              on E: Exception do
              begin
                AddLog(0,'Erro ao marcar cliente como importado ' + cliente.GetFieldAsString('NOME') + ' ' + E.Message,'ERRO_IMPORTADOR_CLIENTE');
              end;
            end;
          end;
        except
          on E: Exception do
          begin
            raise Exception.Create('Erro ao importar cliente ' + E.Message);
          end;
        end;
      end;
    finally
      FreeAndNil(jarr);
    end;
  except
    on E: Exception do
    begin
      AddLog(0,'Erro ao carregar cliente ' + cliente.GetFieldAsString('NOME') + ' ' + E.Message,'ERRO_IMPORTADOR_CLIENTE');
      raise Exception.Create('Erro ao carregar cliente ' + cliente.GetFieldAsString('NOME') + ' ' + E.Message);
    end;
  end;
end;


procedure ListarOracle(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    cliente, requestPedido, responsePedido, enderecos,vitOracle: IwtsWriteData;
    jarr: TJSONarray;
    grantType, accessToken, sres, urlBase, urlRest, ddd, fone, nome, contato: string;
    total: Double;
    userAtacado: Boolean;
    i, x,vitrine,pag: Integer;
begin
  cliente := DataPool.CreateRecordset('MILLENIUM!JORGEORACLE.CLIENTES.LISTARORACLE',true);

  cmd01 := DataPool.Open('millenium');

  cmd01.execute('SELECT VDO.USUARIO_WEBSERVICE, ' +
                '       VDO.SENHA_WEBSERVICE, ' +
                '       VDO.URL_WEBSERVICE, ' +
                '       V.VITRINE ' +
                'FROM VITRINE V ' +
                'INNER JOIN VITRINE_DADOS_ORACLE VDO ON VDO.VITRINE = V.VITRINE ' +
                'WHERE V.EXPORTADOR ="14"');

  vitOracle := cmd01.CreateRecordset();

  if vitOracle.EOF then
    raise Exception.Create('Dados adicionais da integração Oracle não encontrado!');

  if vitOracle.RecordCount<>1 then
    raise Exception.Create('Existe mais de uma vitrine Oracle. Processo não suportado!');

  grantType := 'grant_type=password&username=' + vitOracle.GetFieldAsString('USUARIO_WEBSERVICE') + '&password=' + vitOracle.GetFieldAsString('SENHA_WEBSERVICE');
  urlBase := vitOracle.GetFieldAsString('URL_WEBSERVICE');
  vitrine := vitOracle.GetFieldByName('VITRINE');
  urlRest := '';
  accessToken := '';

  if Input.GetParamAsString('EMAIL')<>'' then
    sres := RestClientCenter(accessToken, grantType, 'Get', urlBase, PChar('/ccadmin/v1/profiles?'+
                                                                           'q=email co "' + VarToStr(Input.GetParamByName('EMAIL')) + '"'))
  else
  if (Input.GetParamAsString('PAG_LISTA')<>'') then
  begin
    pag := VarToInt(abs(Input.GetParamByName('PAG_LISTA')));
    sres := RestClientCenter(accessToken, grantType, 'Get', urlBase, PChar('/ccadmin/v1/profiles?'+
                                                                           'limit=100&offset='+IntToStr(pag*100)+'&'+
                                                                           'fields=items.id,items.firstName,items.lastName,items.email,items.user_atacado,items.usr_importado'));
  end
  else
    sres := RestClientCenter(accessToken, grantType, 'Get', urlBase, PChar('/ccadmin/v1/profiles?'+
                                                                           'sort=email&'+
                                                                           'fields=items.id,items.firstName,items.lastName,items.email,items.user_atacado,items.usr_importado'));

  jarr := ParseJSON(PChar(utf8.UTF8ToString(sres)));
  try
    if jarr.Field['items'].Count = 0 then
      raise Exception.Create('Cliente não encontrado!');

    for i := 0 to jarr.Field['items'].Count - 1 do
    begin

      if vartostr(jarr.Field['items'].Child[i].Field['lastName'].Value) <> '' then
        nome := vartostr(jarr.Field['items'].Child[i].Field['firstName'].Value) + ' ' + vartostr(jarr.Field['items'].Child[i].Field['lastName'].Value)
      else
        nome := vartostr(jarr.Field['items'].Child[i].Field['firstName'].Value);

      cliente.New;
      cliente.SetFieldByName('ID', vartostr(jarr.Field['items'].Child[i].Field['id'].Value));
      cliente.SetFieldByName('IMPORTADO', VarToBool(jarr.Field['items'].Child[i].Field['usr_importado'].Value));
      cliente.SetFieldByName('NOME', AnsiUpperCase(AbreviaNome(nome, 120)));
      cliente.SetFieldByName('EMAIL', vartostr(jarr.Field['items'].Child[i].Field['email'].Value));
      cliente.SetFieldByName('ATACADO', VarToBool(jarr.Field['items'].Child[i].Field['user_atacado'].Value));
      cliente.Add;
    end;
    cliente.First;
    Output.AssignData(cliente);
  finally
    FreeAndNil(jarr);
  end;
end;

procedure ImportarClientesNovos(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    cliente, requestPedido, responsePedido, enderecos,vitOracle: IwtsWriteData;
    jarr: TJSONarray;
    grantType, accessToken, sres, urlBase, urlRest, ddd, fone, nome, contato,json: string;
    total: Double;
    userAtacado: Boolean;
    i, x,vitrine,pag: Integer;
begin
  cliente := DataPool.CreateRecordset('MILLENIUM!JORGEORACLE.CLIENTES.LISTARORACLE',true);

  cmd01 := DataPool.Open('millenium');

  cmd01.execute('SELECT VDO.USUARIO_WEBSERVICE, ' +
                '       VDO.SENHA_WEBSERVICE, ' +
                '       VDO.URL_WEBSERVICE, ' +
                '       V.VITRINE ' +
                'FROM VITRINE V ' +
                'INNER JOIN VITRINE_DADOS_ORACLE VDO ON VDO.VITRINE = V.VITRINE ' +
                'WHERE V.EXPORTADOR ="14"');

  vitOracle := cmd01.CreateRecordset();

  if vitOracle.EOF then
    raise Exception.Create('Dados adicionais da integração Oracle não encontrado!');

  if vitOracle.RecordCount<>1 then
    raise Exception.Create('Existe mais de uma vitrine Oracle. Processo não suportado!');

  grantType := 'grant_type=password&username=' + vitOracle.GetFieldAsString('USUARIO_WEBSERVICE') + '&password=' + vitOracle.GetFieldAsString('SENHA_WEBSERVICE');
  urlBase := vitOracle.GetFieldAsString('URL_WEBSERVICE');
  vitrine := vitOracle.GetFieldByName('VITRINE');
  urlRest := '';
  accessToken := '';

  sres := RestClientCenter(accessToken, grantType, 'Get', urlBase, PChar('/ccadmin/v1/profiles?'+
                                                                         '?useAdvancedQParser=true&q=usr_importado eq false&'+
                                                                         'fields=items.id,items.firstName,items.lastName,items.email,items.user_atacado,items.usr_importado'));

  jarr := ParseJSON(PChar(utf8.UTF8ToString(sres)));
  try
    for i := 0 to jarr.Field['items'].Count - 1 do
    begin
      if not VarToBool(jarr.Field['items'].Child[i].Field['usr_importado'].Value) then
      begin
      
        try
          cmd01.Dim('EMAIL',vartostr(jarr.Field['items'].Child[i].Field['email'].Value));
          cmd01.execute('MILLENIUM!JORGEORACLE.CLIENTES.IMPORTAR(EMAIL=:EMAIL)');
        except
          on E: Exception do
          begin
            AddLog(0,'Erro ao importar cliente ' + cliente.GetFieldAsString('NOME') + ' ' + E.Message,'ERRO_IMPORTADOR_CLIENTE');
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(jarr);
  end;
end;
(*
procedure MarcarAtacado(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
  cliente, requestPedido, responsePedido, enderecos,vitOracle: IwtsWriteData;
  jarr: TJSONarray;
  grantType, accessToken, sres, urlBase, urlRest, ddd, fone, nome, contato,json,id: string;
  total: Double;
  userAtacado: Boolean;
  i, x,vitrine,pag: Integer;
begin
  cliente := DataPool.CreateRecordset('MILLENIUM!JORGEORACLE.CLIENTES.LISTARORACLE',true);

  cmd01 := DataPool.Open('millenium');

  cmd01.execute('SELECT VDO.USUARIO_WEBSERVICE, ' +
                '       VDO.SENHA_WEBSERVICE, ' +
                '       VDO.URL_WEBSERVICE, ' +
                '       V.VITRINE ' +
                'FROM VITRINE V ' +
                'INNER JOIN VITRINE_DADOS_ORACLE VDO ON VDO.VITRINE = V.VITRINE ' +
                'WHERE V.EXPORTADOR ="14"');

  vitOracle := cmd01.CreateRecordset();

  if vitOracle.EOF then
    raise Exception.Create('Dados adicionais da integração Oracle não encontrado!');

  if vitOracle.RecordCount<>1 then
    raise Exception.Create('Existe mais de uma vitrine Oracle. Processo não suportado!');

  grantType := 'grant_type=password&username=' + vitOracle.GetFieldAsString('USUARIO_WEBSERVICE') + '&password=' + vitOracle.GetFieldAsString('SENHA_WEBSERVICE');
  urlBase := vitOracle.GetFieldAsString('URL_WEBSERVICE');
  vitrine := vitOracle.GetFieldByName('VITRINE');
  urlRest := '';
  accessToken := '';

  for x := 0 to 255 do
  begin

    sres := RestClientCenter(accessToken, grantType, 'Get', urlBase, PChar('/ccadmin/v1/skus?offset='+FloatToStr(x*250)+'&sort=active'));

    jarr := ParseJSON(PChar(utf8.UTF8ToString(sres)));
    try
      for i := 0 to jarr.Field['items'].Count - 1 do
      begin

        if not VarToBool(jarr.Field['items'].Child[i].Field['active'].Value) then
        begin
          try
            RestClientCenter(accessToken, grantType, 'Put', urlBase, PChar('/ccadmin/v1/skus/'+VarToStr(jarr.Field['items'].Child[i].Field['repositoryId'].Value)),'{"active" :true}');
          except
            on E: Exception do
            begin
              AddLog(0,'Erro ao marcar sku como ativo ' + E.Message,'ERRO_IMPORTADOR_SKU');
            end;
          end;
        end
        else
          AddLog(0,'Erro ao marcar sku como ativo ','ERRO_IMPORTADOR_SKU')
      end;
    finally
      FreeAndNil(jarr);
    end;
  end;
end; *)


procedure MarcarAtacado(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
  cliente, requestPedido, responsePedido, enderecos,vitOracle: IwtsWriteData;
  jarr: TJSONarray;
  grantType, accessToken, sres, urlBase, urlRest, ddd, fone, nome, contato,json,id: string;
  total: Double;
  userAtacado: Boolean;
  i, x,vitrine,pag: Integer;
begin
  cliente := DataPool.CreateRecordset('MILLENIUM!JORGEORACLE.CLIENTES.LISTARORACLE',true);

  cmd01 := DataPool.Open('millenium');

  cmd01.execute('SELECT VDO.USUARIO_WEBSERVICE, ' +
                '       VDO.SENHA_WEBSERVICE, ' +
                '       VDO.URL_WEBSERVICE, ' +
                '       V.VITRINE ' +
                'FROM VITRINE V ' +
                'INNER JOIN VITRINE_DADOS_ORACLE VDO ON VDO.VITRINE = V.VITRINE ' +
                'WHERE V.EXPORTADOR ="14"');

  vitOracle := cmd01.CreateRecordset();

  if vitOracle.EOF then
    raise Exception.Create('Dados adicionais da integração Oracle não encontrado!');

  if vitOracle.RecordCount<>1 then
    raise Exception.Create('Existe mais de uma vitrine Oracle. Processo não suportado!');

  grantType := 'grant_type=password&username=' + vitOracle.GetFieldAsString('USUARIO_WEBSERVICE') + '&password=' + vitOracle.GetFieldAsString('SENHA_WEBSERVICE');
  urlBase := vitOracle.GetFieldAsString('URL_WEBSERVICE');
  vitrine := vitOracle.GetFieldByName('VITRINE');
  urlRest := '';
  accessToken := '';

  id := Input.GetParamAsString('ID');  
  
  json := '{"user_atacado":true}';
  try        
    RestClientCenter(accessToken, grantType, 'Put', urlBase, PChar('/ccadmin/v1/profiles/'+id),json);
  except
    on E: Exception do
    begin
      AddLog(0,'Erro ao marcar cliente ' + cliente.GetFieldAsString('NOME') + ' ' + E.Message,'ERRO_IMPORTADOR_CLIENTE');
    end;
  end; 
end;


initialization
  wtsRegisterProc('CLIENTES.IMPORTAR', Importar);
  wtsRegisterProc('CLIENTES.LISTARORACLE', ListarOracle);
  wtsRegisterProc('CLIENTES.IMPORTARCLIENTESNOVOS', ImportarClientesNovos);
  wtsRegisterProc('CLIENTES.MARCARATACADO', MarcarAtacado);  

end.

