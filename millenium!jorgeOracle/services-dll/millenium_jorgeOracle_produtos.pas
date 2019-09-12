unit millenium_jorgeOracle_produtos;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, oracle_utils, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles;

procedure AtualizaEAN(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    estoque,vitOracle,sku: IwtsWriteData;
    jarr,jarr2: TJSONarray;
    token,sres,urlBase,id_produto,json: string;
    i,x,pag,vitrine,total,processados: Integer;
    produto_ativo:Boolean;
begin
  cmd01 := DataPool.Open('millenium');

  cmd01.execute('SELECT VDO.TOKEN_WEBSERVICE, ' +
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

  token := vitOracle.GetFieldAsString('TOKEN_WEBSERVICE');
  urlBase := vitOracle.GetFieldAsString('URL_WEBSERVICE');
  vitrine := vitOracle.GetFieldByName('VITRINE');

  AddLog(0,'INICIO ','_SKU_GTIN_ORACLE');

  AddLog(0,'CARREGANDO ','_SKU_GTIN_ORACLE');

  cmd01.Dim('VITRINE',vitrine);
  cmd01.Execute('#CALL MILLENIUM_ECO.PRODUTOS.LISTAVITRINE(VITRINE=:VITRINE,TRANS_ID=-1)');

  total := 0;
  processados := 0;

  cmd01.First;
  while not cmd01.EOF do
  begin
    inc(total);
    cmd01.Next;
  end;
  AddLog(0,'CARREGADO, '+IntToStr(total)+' produtos','_SKU_GTIN_ORACLE');

  cmd01.First;
  while not cmd01.EOF do
  begin
    inc(processados);
    AddLog(0,'PROCESSADOS '+IntToStr(processados)+' de '+IntToStr(total)+' produtos: '+FloatToStr((processados*100)/total)+'%','_SKU_GTIN_ORACLE');
    sku := cmd01.GetFieldAsData('SKU') as IwtsWriteData;
    sku.First;
    while not sku.EOF do
    begin
      for x := 0 to 6 do
      begin
        try
          if sku.GetFieldAsString('ID_EXTERNO') <> '' then
          begin
            if sku.GetFieldAsString('BARRA')<>'' then
            begin
              json := '{"x_gtin":"'+sku.GetFieldAsString('BARRA')+'"}';
              RestClientCenter(token,'Put',urlBase,PChar('/ccadmin/v1/skus/'+sku.GetFieldAsString('ID_EXTERNO')),json);
              AddLog(0,'SKU: '+sku.GetFieldAsString('VITRINE_PRODUTO_SKU')+' Processado Gtin:'+sku.GetFieldAsString('BARRA'),'_SKU_GTIN_ORACLE');
            end
            else
              AddLog(0,'SKU: '+sku.GetFieldAsString('VITRINE_PRODUTO_SKU')+' sem EAN','_SKU_GTIN_ORACLE');
          end
          else
            AddLog(0,'SKU: '+sku.GetFieldAsString('VITRINE_PRODUTO_SKU')+' sem id externo','_SKU_GTIN_ORACLE');

          Break;
        except
          on E: Exception do
          begin
            AddLog(0,'SKU: '+sku.GetFieldAsString('VITRINE_PRODUTO_SKU')+' erro: '+e.Message,'_SKU_GTIN_ORACLE');
          end;
        end;
      end;
      sku.Next;
    end;
    cmd01.Next;
  end;
  AddLog(0,'FIM ','_SKU_GTIN_ORACLE');
end;

initialization
  wtsRegisterProc('PRODUTOS.ATUALIZAEAN', AtualizaEAN);

end.

