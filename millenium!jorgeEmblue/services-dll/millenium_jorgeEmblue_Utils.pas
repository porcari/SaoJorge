unit millenium_jorgeEmblue_Utils;

interface
uses SysUtils,RESTClient,logfiles,wtsintf,JSON,UTF8,Variants,wtsServerObjs,IniFiles,ResUnit;

type
  TRestEmblue = class
  private
    fToken,fURLBase:String;
  public
    constructor Create(const AToken,AURLBase:String);
    function Post(const AJson:String):String;
    function Get():String;
    function Put(const AJson:String):String;
    function Delete(const AJson:String):String;
  private
  function RESTClientCenter(const AToken,ATypecall,AURLBase:String;AJson:String=''):String;
  end;

function IncializaLog(ADataPool:IwtsDataPool;const AIntegracao,ATransId:String):String;
Procedure FinalizaLog(ADataPool:IwtsDataPool;const AIdLog,AQTDProcessados,AStatus:String);
Procedure GravaItemLog(ADataPool:IwtsDataPool;const AIdLog,ACodigo,AObs:String;const Adata:TDateTime);
Procedure LimpaLog(ADataPool:IwtsDataPool);

implementation

{TRestEmblue}
constructor  TRestEmblue.Create(const AToken,AURLBase:String);
begin
  fToken := AToken;
  fURLBase := AURLBase;
end;

function TRestEmblue.Post(const AJson:String):String;
begin
  result := RestClientCenter(fToken,'POST',fURLBase,AJson);
end;

function TRestEmblue.Get():String;
begin
  result := RestClientCenter(fToken,'GET',fURLBase);
end;

function TRestEmblue.Put(const AJson:String):String;
begin
  result := RestClientCenter(fToken,'PUT',fURLBase,AJson);
end;

function TRestEmblue.Delete(const AJson:String):String;
begin
  result := RestClientCenter(fToken,'DELETE',fURLBase,AJson);
end;     

function TRestEmblue.RestClientCenter(const AToken,ATypecall,AURLBase:String;AJson:String=''):String;
    procedure addLogEmblue(url,headers,tipo,request,response:String;erro:string='');
    begin
      if erro<>'' then
        AddLog(0,PChar('ERRO: '+erro),'REST_EMBLUE');

      AddLog(0,PChar('URL: '+url),'REST_EMBLUE');
      AddLog(0,PChar('HEADERS: '+headers),'REST_EMBLUE');
      AddLog(0,PChar('TIPO: '+tipo),'REST_EMBLUE');
      AddLog(0,PChar('REQUEST: '+request),'REST_EMBLUE');
      AddLog(0,PChar('RESPONSE: '+response),'REST_EMBLUE');
      AddLog(0,PChar('-------------'),'REST_EMBLUE');
    end;

var x:Integer;
    RESTClient: TRESTClient;
    jarr:TJSONarray;
    sres,URLBase:string;
    arquivoDeControle:TIniFile;
begin
  Result := '';
  AJson := utf8encode(AJson);
  URLBase := AURLBase;

  if URLBase[Length(URLBase)]='/' then
    SetLength(URLBase,length(URLBase)-1);

  RESTClient := TRESTClient.Create('');
  try
    RESTClient.Headers := 'Accept:*/*'#13+
                          'Content-Type:application/json'#13+
                          'Authorization:Basic '+AToken;
    for x := 0 to 2 do
    begin
      try
        try
          Result := '';

          if UpperCase(ATypecall)='GET' then
            Result := RESTClient.Get(AURLBase)
          else
          if UpperCase(ATypecall)='PUT' then
            Result := RESTClient.Put(AURLBase,AJson,'')
          else
          if UpperCase(ATypecall)='POST' then
            Result := RESTClient.Post(AURLBase,AJson,'')
          else
          if UpperCase(ATypecall)='DELETE' then
            Result := RESTClient.Delete(AURLBase,AJson,'');

          addLogEmblue(AURLBase,RESTClient.Headers,ATypecall,AJson,Result);
        except
          on E:Exception do
          begin
            begin
              addLogEmblue(AURLBase,RESTClient.Headers,ATypecall,AJson,Result,e.message);
              raise Exception.Create(e.message);
            end;
          end;
        end;
        Break;
      except
        on E:Exception do
        begin
          begin
            if (x>1) then
              raise Exception.Create(e.message);
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(RESTClient);
  end;
end;

function IncializaLog(ADataPool:IwtsDataPool;const AIntegracao,ATransId:String):String;
var cmd01:IwtsCommand;
begin
  result := '';

  cmd01 := ADataPool.Open('millenium');
  cmd01.Dim('EBL_DATA_INICIO',Now);
  cmd01.Dim('EBL_INTEGRACAO',AIntegracao);
  cmd01.Dim('EBL_TRANS_ID',ATransId);
  cmd01.execute('INSERT INTO EBL_LOGS ( EBL_DATA_INICIO, EBL_INTEGRACAO, EBL_TRANS_ID) '+
                '              VALUES (:EBL_DATA_INICIO,:EBL_INTEGRACAO,:EBL_TRANS_ID) '+
                '#RETURN (EBL_LOG) ');
  result := cmd01.AsString['EBL_LOG'];
end;

Procedure FinalizaLog(ADataPool:IwtsDataPool;const AIdLog,AQTDProcessados,AStatus:String);
var cmd01:IwtsCommand;
begin
  cmd01 := ADataPool.Open('millenium');

  cmd01.Dim('EBL_LOG',AIdLog);
  cmd01.Dim('EBL_DATA_FINAL',Now);
  cmd01.Dim('EBL_REGISTROS_PROCESSADOS',AQTDProcessados);
  cmd01.Dim('STATUS_ULTIMO_PROCESSO',AStatus);
  cmd01.execute('UPDATE EBL_LOGS SET EBL_DATA_FINAL=:EBL_DATA_FINAL,EBL_REGISTROS_PROCESSADOS=:EBL_REGISTROS_PROCESSADOS,EBL_STATUS_ULTIMO_PROCESSO=:STATUS_ULTIMO_PROCESSO '+
                'WHERE EBL_LOG=:EBL_LOG ');
end;

Procedure GravaItemLog(ADataPool:IwtsDataPool;const AIdLog,ACodigo,AObs:String;const Adata:TDateTime);
var cmd01:IwtsCommand;
begin
  cmd01 := ADataPool.Open('millenium');

  cmd01.Dim('EBL_LOG',AIdLog);
  cmd01.Dim('EBL_CODIGO',ACodigo);
  cmd01.Dim('EBL_OBS',AObs);
  cmd01.Dim('EBL_DATA',Adata);
  cmd01.execute('INSERT INTO EBL_ITENS_LOGS ( EBL_LOG, EBL_CODIGO, EBL_OBS, EBL_DATA) '+
                '                    VALUES (:EBL_LOG,:EBL_CODIGO,:EBL_OBS,:EBL_DATA) '+
                '#RETURN (EBL_ITEM_LOG) ');
end;

Procedure LimpaLog(ADataPool:IwtsDataPool);
var cmd01:IwtsCommand;
begin
  cmd01 := ADataPool.Open('millenium');

  cmd01.Dim('DATA_CORTE',VarToDateTime(Now-15));
  cmd01.execute('DELETE FROM EBL_LOGS '+
                'WHERE EBL_DATA_INICIO<:DATA_CORTE');

  cmd01.execute('DELETE FROM EBL_ITENS_LOGS '+
                'WHERE NOT EXISTS (SELECT EBL_LOG '+
                '                  FROM EBL_LOGS '+
                '                  WHERE EBL_LOG=EBL_LOG)');
end;

end.
