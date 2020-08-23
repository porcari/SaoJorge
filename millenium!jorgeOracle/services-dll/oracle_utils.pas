unit oracle_utils;

interface

uses
  SysUtils, RESTClient, logfiles, wtsintf, JSON, UTF8, Variants, wtsServerObjs,
  IniFiles;

function RESTClientCenter(const token, typecall, urlBase, url: string; json: string = ''): string;

function IntfVal(const especializado, complemento: string): string;

function ValorStr(const valor: string): string;

function CarregaAtributos(const aAtributos: IwtsWriteData): string;

implementation

function RestClientCenter(const token, typecall, urlBase, url: string; json: string = ''): string;

  procedure addLogOracle(url, headers, tipo, request, response: string; erro: string = '');
  begin
    if erro <> '' then
      AddLog(0, PChar('ERRO: ' + erro), 'REST_ORACLE');

    AddLog(0, PChar('URL: ' + url), 'REST_ORACLE');
    AddLog(0, PChar('HEADERS: ' + headers), 'REST_ORACLE');
    AddLog(0, PChar('TIPO: ' + tipo), 'REST_ORACLE');
    AddLog(0, PChar('REQUEST: ' + request), 'REST_ORACLE');
    AddLog(0, PChar('RESPONSE: ' + response), 'REST_ORACLE');
    AddLog(0, PChar('-------------'), 'REST_ORACLE');
  end;

var
  x: Integer;
  RESTClient: TRESTClient;
  jarr: TJSONarray;
  sres, tokenType, arquivoNome, accessToken: string;
  arquivoDeControle: TIniFile;
begin
  Result := '';
  RESTClient := TRESTClient.Create('');
  try
    if accessToken = '' then
    begin
      //vamos tentar resgatar o token em cache primeiro
      try
        arquivoNome := ExtractFilePath(ParamStr(0)) + 'ccardlog\ORACLE_TOKEN2.ini';
        if FileExists(arquivoNome) then
        begin
          arquivoDeControle := TIniFile.Create(arquivoNome);
          try
            accessToken := arquivoDeControle.ReadString('TOKEN_ACESSO', 'TOKEN_PARTE1', '');
            accessToken := accessToken + arquivoDeControle.ReadString('TOKEN_ACESSO', 'TOKEN_PARTE2', '');
            accessToken := accessToken + arquivoDeControle.ReadString('TOKEN_ACESSO', 'TOKEN_PARTE3', '');
          finally
            arquivoDeControle.Free
          end;
        end;
      except
        on E: Exception do
        begin
          begin
            //não vamos parar o processo porque este ponto é apenas para performance
            AddLog(0, 'Erro ao carregar token de acesso pelo cache: ' + e.message, 'REST_ORACLE');
          end;
        end;
      end;
    end;

    for x := 0 to 5 do
    begin
      if accessToken = '' then
      begin
        try
          //Authorization
          RESTClient.Headers := 'Content-Type: application/x-www-form-urlencoded';

          sres := RESTClient.Post(Pchar(urlBase + '/ccadmin/v1/login'), 'grant_type=password&username=sao_jorge@saojorge.com.br&password=@Com0710@Com2303', '');

          addLogOracle(urlBase + '/ccadmin/v1/login', RESTClient.Headers, 'Post', 'grant_type=client_credentials', sres);
          jarr := ParseJSON(PChar(utf8.UTF8ToString(sres)));
          try
            tokenType := jarr.Field['token_type'].Value;
            accessToken := AnsiUpperCase(tokenType[1]) + copy(tokenType, 2, length(tokenType)) + ' ' + VarToStr(jarr.Field['access_token'].Value);
          finally
            FreeAndNil(jarr);
          end;

          try
            arquivoNome := ExtractFilePath(ParamStr(0)) + 'ccardlog\ORACLE_TOKEN2.ini';
            arquivoDeControle := TIniFile.Create(arquivoNome);
            try
              arquivoDeControle.WriteString('TOKEN_ACESSO', 'TOKEN_PARTE1', copy(accessToken, 0, 1000));
              arquivoDeControle.WriteString('TOKEN_ACESSO', 'TOKEN_PARTE2', copy(accessToken, 1001, 1000));
              arquivoDeControle.WriteString('TOKEN_ACESSO', 'TOKEN_PARTE3', copy(accessToken, 2001, 1000));
            finally
              arquivoDeControle.Free;
            end;
          except
            on E: Exception do
            begin
              begin
                //não vamos parar o processo porque este ponto é apenas para performance
                AddLog(0, 'Erro ao gravar token de acesso pelo cache: ' + e.message, 'REST_ORACLE');
              end;
            end;
          end;
        except
          on E: Exception do
          begin
            begin
              addLogOracle(urlBase + '/ccadmin/v1/login', RESTClient.Headers, 'Post', 'grant_type=client_credentials', sres, e.message);
              raise Exception.Create('Erro ao carregar token de acesso: ' + e.message);
            end;
          end;
        end;
      end;

      try
        Result := '';
        RESTClient.Headers := 'Authorization: ' + accessToken + ''#13 + 'X-CCAsset-Language: pt_BR'#13 + 'Content-Type: application/json';

        if UpperCase(typecall) = 'GET' then
        begin
          RESTClient.Headers := 'Authorization: ' + accessToken;
          Result := RESTClient.Get(urlBase + url);
        end
        else if UpperCase(typecall) = 'PUT' then
          Result := RESTClient.Put(urlBase + url, json, '')
        else if UpperCase(typecall) = 'POST' then
          Result := RESTClient.Post(urlBase + url, json, '')
        else if UpperCase(typecall) = 'DELETE' then
          Result := RESTClient.Delete(urlBase + url, json, '');

        addLogOracle(urlBase + url, RESTClient.Headers, typecall, json, Result);
        Break;
      except
        on E: Exception do
        begin
          begin
            jarr := ParseJSON(PChar(utf8.UTF8ToString(Result)));
            try
              if (jarr.Field['errorCode'] <> nil) and (VarToStr(jarr.Field['errorCode'].Value) = '60006000') and (x < 5) then
              begin
                accessToken := '';
              end
              else
              begin
                addLogOracle(urlBase + url, RESTClient.Headers, typecall, json, Result, e.message);
                raise Exception.Create(e.message);
              end;
            finally
              FreeAndNil(jarr);
            end;
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(RESTClient);
  end;
end;

function IntfVal(const especializado, complemento: string): string;
begin
  Result := '';
  try
    if Interfaces.IntfExists(PChar('MILLENIUM_ECO_ORC_' + especializado + complemento)) then
      result := 'MILLENIUM_ECO_ORC_' + especializado + complemento;
  except
  end;

  if result = '' then
  begin
    if Interfaces.IntfExists(PChar('MILLENIUM_ECO_ORC_DEFAULT' + complemento)) then
      result := 'MILLENIUM_ECO_ORC_DEFAULT' + complemento;
  end;

  if result = '' then
    raise Exception.Create('Interface ' + complemento + ' não encontrada');
end;

function ValorStr(const valor: string): string;
begin
  Result := StringReplace(valor, ',', '.', []);
end;

function carregaAtributos(const aAtributos: IwtsWriteData): string;
var
  valores: IwtsWriteData;
  jsonAtributos, jsonValores: string;
begin
  result := '';
  aAtributos.First;
  while not aAtributos.EOF do
  begin
    valores := aAtributos.GetFieldAsData('VALORES') as IwtsWriteData;
    if valores.RecordCount > 0 then
    begin
      jsonValores := '';
      valores.First;
      while not valores.EOF do
      begin
        if valores.GetFieldAsString('VALOR') <> '' then
          jsonValores := jsonValores + valores.GetFieldAsString('VALOR') + ', ';
        valores.Next;
      end;
      SetLength(jsonValores, length(jsonValores) - 2);
      jsonAtributos := jsonAtributos + ',"' + aAtributos.GetFieldAsString('DESCRICAO') + '":"' + jsonValores + '"';
    end;
    aAtributos.Next
  end;
  result := jsonAtributos;
end;

end.

