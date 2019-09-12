unit millenium_jorgeOracle_estoques;

interface

implementation

uses
  wtsServerObjs, EcoUtils, SysUtils, ResUnit, oracle_utils, JSON, UTF8, Variants,
  Classes, IdCoderMIME, jpeg, logfiles;

procedure ListarOracle(Input: IwtsInput; Output: IwtsOutput; DataPool: IwtsDataPool);
var cmd01: IwtsCommand;
    estoque,vitOracle: IwtsWriteData;
    jarr,jarr2: TJSONarray;
    token,sres,urlBase,id_produto: string;
    i,x,pag: Integer;
    produto_ativo:Boolean;
begin
  estoque := DataPool.CreateRecordset('MILLENIUM!JORGEORACLE.ESTOQUES.LISTARORACLE',true);

  cmd01 := DataPool.Open('millenium');

  cmd01.execute('SELECT VDO.TOKEN_WEBSERVICE, ' +
                '       VDO.URL_WEBSERVICE ' +
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

  if Input.GetParamAsString('ID_PRODUTO')<>'' then
    sres := RestClientCenter(token,'Get',urlBase,PChar('/ccadmin/v1/inventories?'+
                                                       'type=product&q=id co "'+VarToStr(Input.GetParamByName('ID_PRODUTO'))+'"?'+
                                                       'fields=items.id,items.displayName,items.childSKUs'))
  else
  if (Input.GetParamAsString('PAG_LISTA')<>'') then
  begin
    pag := VarToInt(abs(Input.GetParamByName('PAG_LISTA')));
    sres := RestClientCenter(token,'Get',urlBase,PChar('/ccadmin/v1/inventories?'+
                                                       'type=product&'+
                                                       'limit=10&'+
                                                       'offset='+IntToStr(pag*10)+'&'+
                                                       'fields=items.id,items.displayName,items.childSKUs'));
  end
  else
    sres := RestClientCenter(token,'Get',urlBase,PChar('/ccadmin/v1/inventories?'+
                                                       'type=product&'+
                                                       'sort=items.id&'+
                                                       'fields=items.id,items.displayName,items.childSKUs'));

  jarr := ParseJSON(PChar(utf8.UTF8ToString(sres)));
  try
    if jarr.Field['items'].Count = 0 then
      raise Exception.Create('Cliente não encontrado!');

    for i := 0 to jarr.Field['items'].Count - 1 do
    begin
      for x := 0 to jarr.Field['items'].Child[i].Field['childSKUs'].Count - 1 do
      begin
        estoque.New;
        estoque.SetFieldByName('ID_PRODUTO', vartostr(jarr.Field['items'].Child[i].Field['id'].Value));
        estoque.SetFieldByName('ID_SKU',VarToStr(jarr.Field['items'].Child[i].Field['childSKUs'].Child[x].Field['skuId'].Value));
        estoque.SetFieldByName('DESCRICAO', VarToStr(jarr.Field['items'].Child[i].Field['displayName'].Value));
        estoque.SetFieldByName('ESTOQUE',VarToStr(jarr.Field['items'].Child[i].Field['childSKUs'].Child[x].Field['stockLevel'].Value));
        estoque.SetFieldByName('ESTOQUE_MIN',VarToStr(jarr.Field['items'].Child[i].Field['childSKUs'].Child[x].Field['stockThreshold'].Value));

        if VarToBool(Input.GetParamByName('EXIBER_ATIVO')) then
        begin
          produto_ativo := false;

          if id_produto<>vartostr(jarr.Field['items'].Child[i].Field['id'].Value) then
          begin
            id_produto := vartostr(jarr.Field['items'].Child[i].Field['id'].Value);
            sres := RestClientCenter(token,'Get',urlBase,PChar('/ccadmin/v1/products/'+id_produto+'?fields=active'));

            jarr2 := ParseJSON(PChar(utf8.UTF8ToString(sres)));
            try
              produto_ativo := VarToBool(jarr2.Field['active'].Value)
            finally
              FreeAndNil(jarr2);
            end;
          end;
          estoque.SetFieldByName('PRODUTO_ATIVO', produto_ativo);

          sres := RestClientCenter(token,'Get',urlBase,PChar('/ccadmin/v1/skus/'+VarToStr(jarr.Field['items'].Child[i].Field['childSKUs'].Child[x].Field['skuId'].Value)+'?fields=active'));

          jarr2 := ParseJSON(PChar(utf8.UTF8ToString(sres)));
          try
            estoque.SetFieldByName('SKU_ATIVO', VarToBool(jarr2.Field['active'].Value));
          finally
            FreeAndNil(jarr2);
          end;
        end;

        estoque.Add;
      end;
    end;
    estoque.First;
    Output.AssignData(estoque);
  finally
    FreeAndNil(jarr);
  end;
end;

initialization
  wtsRegisterProc('ESTOQUES.LISTARORACLE', ListarOracle);

end.

