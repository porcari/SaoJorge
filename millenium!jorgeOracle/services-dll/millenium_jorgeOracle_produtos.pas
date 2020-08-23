unit millenium_jorgeOracle_produtos;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, oracle_utils, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles;

procedure AtualizaEAN(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    vitOracle,sku: IwtsWriteData;
    token,urlBase,json: string;
    x,vitrine,total,processados: Integer;
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

procedure ListarVinculos(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    produto,vitOracle: IwtsWriteData;
    jarr: TJSONarray;
    token,sres,urlBase: string;
    i,x,vitrine: Integer;
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

  cmd01.Dim('VITRINE',vitrine);
  cmd01.Dim('COD_PRODUTO',Input.GetParamByName('COD_PRODUTO'));
  cmd01.Execute('SELECT SKU.VITRINE, '+
                '       P.COD_PRODUTO, '+
                '       C.COD_COR, '+
                '       P.COD_PRODUTO||"_"||C.COD_COR||"_"||SKU.TAMANHO AS ID, '+
                '       SKU.ID_EXTERNO, '+
                '       (SELECT MAX(VP.ID_EXTERNO) FROM VITRINE_PRODUTOS VP WHERE VP.VITRINE=SKU.VITRINE AND VP.PRODUTO=SKU.PRODUTO) AS ID_EXTERNO_PRODUTO, '+
                '       SKU.INCLUIR, '+
                '       P.DESCRICAO1, '+
                '       CAST("" AS VARCHAR(1000)) AS DESCRICAO_SITE, '+
                '       CAST("F" AS VARCHAR(1)) AS COM_VINCULO_PRODUTO, '+
                '       CAST("F" AS VARCHAR(1)) AS COM_VINCULO_SKU, '+
                '       SKU.PRODUTO,  '+
                '       SKU.COR,  '+
                '       SKU.ESTAMPA,  '+
                '       SKU.TAMANHO '+
                'FROM VITRINE_PRODUTOS_SKU SKU '+
                'INNER JOIN PRODUTOS P ON P.PRODUTO=SKU.PRODUTO '+
                'INNER JOIN CORES C ON C.COR=SKU.COR '+
                'WHERE P.COD_PRODUTO =:COD_PRODUTO AND '+
                '      SKU.VITRINE =:VITRINE ');

  if cmd01.EOF then
    raise Exception.Create('Produto não encontrado');                

  produto := cmd01.CreateRecordset();

  sres := RestClientCenter(token,'Get',urlBase,PChar('/ccadmin/v1/inventories?'+
                                                     'type=product&q=id co "1829972"?'+
                                                     'fields=items.id,items.displayName,items.childSKUs'));
  jarr := ParseJSON(PChar(utf8.UTF8ToString(sres)));
  try
    for i := 0 to jarr.Field['items'].Count - 1 do
    begin
      for x := 0 to jarr.Field['items'].Child[i].Field['childSKUs'].Count - 1 do
      begin
        produto.First;
        if produto.Locate(['ID'],[VarToStr(jarr.Field['items'].Child[i].Field['childSKUs'].Child[x].Field['skuId'].Value)]) then
        begin
          produto.SetFieldByName('COM_VINCULO_PRODUTO','T');
          produto.SetFieldByName('COM_VINCULO_SKU','T');
          produto.SetFieldByName('DESCRICAO_SITE',VarToStr(jarr.Field['items'].Child[i].Field['displayName'].Value));
          produto.Update;
        end;
      end;
    end;
    produto.First;
    Output.AssignData(produto);
  finally
    FreeAndNil(jarr);
  end;
end;

procedure RefazerVinculo(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    produto: IwtsWriteData;
begin
  cmd01 := DataPool.Open('millenium');
  cmd01.Dim('VITRINE',Input.GetParamByName('VITRINE'));
  cmd01.Dim('COD_PRODUTO',Input.GetParamByName('COD_PRODUTO'));
  cmd01.Dim('ID',Input.GetParamByName('ID'));
  cmd01.Execute('SELECT P.COD_PRODUTO, '+
                '       C.COD_COR, '+
                '       P.COD_PRODUTO||"_"||C.COD_COR||"_"||SKU.TAMANHO AS ID, '+
                '       SKU.ID_EXTERNO, '+
                '       (SELECT MAX(VP.ID_EXTERNO) FROM VITRINE_PRODUTOS VP WHERE VP.VITRINE=SKU.VITRINE AND VP.PRODUTO=SKU.PRODUTO) AS ID_EXTERNO_PRODUTO, '+
                '       SKU.INCLUIR, '+
                '       P.DESCRICAO1, '+
                '       CAST("" AS VARCHAR(1000)) AS DESCRICAO_SITE, '+
                '       CAST("F" AS VARCHAR(1)) AS COM_VINCULO_PRODUTO, '+
                '       CAST("F" AS VARCHAR(1)) AS COM_VINCULO_SKU, '+
                '       SKU.VITRINE,  '+
                '       SKU.PRODUTO,  '+
                '       SKU.COR,  '+
                '       SKU.ESTAMPA,  '+
                '       SKU.TAMANHO '+
                'FROM VITRINE_PRODUTOS_SKU SKU '+
                'INNER JOIN PRODUTOS P ON P.PRODUTO=SKU.PRODUTO '+
                'INNER JOIN CORES C ON C.COR=SKU.COR '+
                'WHERE P.COD_PRODUTO =:COD_PRODUTO AND '+
                '      P.COD_PRODUTO||"_"||C.COD_COR||"_"||SKU.TAMANHO =:ID AND '+
                '      SKU.VITRINE =:VITRINE ');

  if cmd01.EOF then
    raise Exception.Create('Produto não encontrado');

  produto := cmd01.CreateRecordset();

  if produto.RecordCount>1 then
    raise Exception.Create('Mais de um sku listado');   

  if VarToBool(Input.GetParamByName('COM_VINCULO_PRODUTO')) then
  begin
    if produto.GetFieldAsString('ID_EXTERNO_PRODUTO')='' then
    begin
      cmd01.Dim('VITRINE',produto.GetFieldAsString('VITRINE'));
      cmd01.Dim('PRODUTO',produto.GetFieldAsString('PRODUTO'));
      cmd01.Dim('ID_EXTERNO',produto.GetFieldAsString('COD_PRODUTO'));
      cmd01.execute('UPDATE VITRINE_PRODUTOS SET ID_EXTERNO=:ID_EXTERNO WHERE VITRINE=:VITRINE AND PRODUTO=:PRODUTO');
    end;
  end
  else
    raise Exception.Create('Produto sem vinculo no site, realizar um publicação da vitrine para que o mesmo seja enviado');


  if VarToBool(Input.GetParamByName('COM_VINCULO_SKU')) then
  begin
    if produto.GetFieldAsString('ID_EXTERNO')<>'' then
      raise Exception.Create('SKU já contempla vinculo, entrar em contato com o millennium');

    cmd01.Dim('VITRINE',produto.GetFieldAsString('VITRINE'));
    cmd01.Dim('PRODUTO',produto.GetFieldAsString('PRODUTO'));
    cmd01.Dim('COR',produto.GetFieldAsString('COR'));
    cmd01.Dim('ESTAMPA',produto.GetFieldAsString('ESTAMPA'));
    cmd01.Dim('TAMANHO',produto.GetFieldAsString('TAMANHO'));
    cmd01.Dim('ID_EXTERNO',produto.GetFieldAsString('ID'));
    cmd01.execute('UPDATE VITRINE_PRODUTOS_SKU '+
                  'SET ID_EXTERNO=:ID '+
                  'WHERE VITRINE=:VITRINE AND '+
                  '      PRODUTO=:PRODUTO AND '+
                  '      COR=:COR AND '+
                  '      ESTAMPA=:ESTAMPA AND '+
                  '      TAMANHO=:TAMANHO');
  end;
end;

initialization
  wtsRegisterProc('PRODUTOS.ATUALIZAEAN', AtualizaEAN);
  wtsRegisterProc('PRODUTOS.LISTAR_VINCULOS', ListarVinculos);
  wtsRegisterProc('PRODUTOS.REFAZERVINCULO', RefazerVinculo);

end.

