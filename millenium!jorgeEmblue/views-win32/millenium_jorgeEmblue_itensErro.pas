unit millenium_jorgeEmblue_itensErro;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, dmbase,
  ExtCtrls, Db, wtsMethodView, wtsMethodFrame, ComCtrls, Menus, wtsStream, wtsClient,
  wtsPainter, dmPanel, LinkList, WTSGridFrame,ResUnit,StatusPanel,StdCtrls;

type
  TFItensErro = class(TDMBase)
    lst_Botoes: TLinkList;
    dmPnl_Principal: TdmPanel;
    dmPnl_Filtros: TdmPanel;
    dmPnl_Itens: TdmPanel;
    mv_Filtros: TwtsMethodView;
    wtsmthdfrm_Filtros: TwtsMethodFrame;
    wtsgrdfrm_Listar: TwtsGridFrame;
    dmspltr1: TdmSplitter;
    ds_Lista: TDataSource;
    procedure lst_BotoesLinks1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lst_BotoesLinks0Click(Sender: TObject);
    procedure lst_BotoesLinks2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FItensErro: TFItensErro;

implementation

{$R *.DFM}
procedure TFItensErro.FormCreate(Sender: TObject);
begin
  wtsmthdfrm_Filtros.Post;
  mv_Filtros.Open;
  mv_Filtros.Refresh;
  wtsgrdfrm_Listar.Grid.Columns[1].Width:=800;
end;

procedure TFItensErro.lst_BotoesLinks0Click(Sender: TObject);
var i:Integer;
    v:Variant;
    integracao,codigo:String;
    FSPanel: TStatusPanel;
    L: TLabel;
    procedure RepaintPanel(Msg: string;aFSPanel:TStatusPanel);
    begin
      L := TLabel.Create(Self);

      L.Caption := Msg;
      L.Parent := FSPanel;
      L.Align := alClient;
      L.Transparent := True;
      L.Alignment := taCenter;
      L.ParentFont := True;
      L.Layout := tlCenter;

      FSPanel.Repaint;
    end;
begin
  FSPanel := TStatusPanel.Create(self);
  try
    RepaintPanel('Processando...',FSPanel);

    wtsgrdfrm_Listar.DataSource.DataSet.DisableControls;
    wtsgrdfrm_Listar.DataSource.DataSet.First;
    while not wtsgrdfrm_Listar.DataSource.DataSet.Eof DO
    begin
      if wtsgrdfrm_Listar.Grid.SelectedRows.CurrentRowSelected then
      begin
        integracao := wtsgrdfrm_Listar.DataSource.DataSet.FieldValues['INTEGRACAO'];
        codigo := wtsgrdfrm_Listar.DataSource.DataSet.FieldValues['CODIGO'];
        wtsCall('MILLENIUM!JORGEEMBLUE.INTEGRACOES.REPROCESSARITENSERRO', ['INTEGRACAO','CODIGO'], [integracao,codigo], v);
      end;
      wtsgrdfrm_Listar.DataSource.DataSet.Next;
    end;
    wtsgrdfrm_Listar.DataSource.DataSet.First;
    wtsgrdfrm_Listar.DataSource.DataSet.EnableControls;
    wtsgrdfrm_Listar.Grid.SelectedRows.Refresh;

    mv_Filtros.Refresh;
    mv_Filtros.Edit;
  finally
    FreeAndNil(L);
    FreeAndNil(FSPanel);
  end;
end;

procedure TFItensErro.lst_BotoesLinks1Click(Sender: TObject);
var i:Integer;
    v:Variant;
    integracao,codigo:String;
    FSPanel: TStatusPanel;
    L: TLabel;
    procedure RepaintPanel(Msg: string;aFSPanel:TStatusPanel);
    begin
      L := TLabel.Create(Self);

      L.Caption := Msg;
      L.Parent := FSPanel;
      L.Align := alClient;
      L.Transparent := True;
      L.Alignment := taCenter;
      L.ParentFont := True;
      L.Layout := tlCenter;

      FSPanel.Repaint;
    end;
begin
  FSPanel := TStatusPanel.Create(self);
  try
    RepaintPanel('Processando...',FSPanel);

    wtsgrdfrm_Listar.DataSource.DataSet.DisableControls;
    wtsgrdfrm_Listar.DataSource.DataSet.First;
    while not wtsgrdfrm_Listar.DataSource.DataSet.Eof DO
    begin
      if wtsgrdfrm_Listar.Grid.SelectedRows.CurrentRowSelected then
      begin
        integracao := wtsgrdfrm_Listar.DataSource.DataSet.FieldValues['INTEGRACAO'];
        codigo := wtsgrdfrm_Listar.DataSource.DataSet.FieldValues['CODIGO'];
        wtsCall('MILLENIUM!JORGEEMBLUE.INTEGRACOES.NAOINTEGRARITENSERRO', ['INTEGRACAO','CODIGO'], [integracao,codigo], v);
      end;
      wtsgrdfrm_Listar.DataSource.DataSet.Next;
    end;
    wtsgrdfrm_Listar.DataSource.DataSet.First;
    wtsgrdfrm_Listar.DataSource.DataSet.EnableControls;
    wtsgrdfrm_Listar.Grid.SelectedRows.Refresh;

    mv_Filtros.Refresh;
    mv_Filtros.Edit;
  finally
    FreeAndNil(L);
    FreeAndNil(FSPanel);
  end;
end;

procedure TFItensErro.lst_BotoesLinks2Click(Sender: TObject);
var obs:String;
begin
  obs := '';
  wtsmthdfrm_Filtros.Post;
  if wtsmthdfrm_Filtros.ParamsView.FieldByName('OBS').AsString<>'' then
  begin
    obs := wtsmthdfrm_Filtros.ParamsView.FieldByName('OBS').AsString;
    wtsmthdfrm_Filtros.Edit;
    wtsmthdfrm_Filtros.ParamsView.FieldByName('OBS').Value := '%'+obs+'%';
    wtsmthdfrm_Filtros.Post;
  end;

  wtsmthdfrm_Filtros.Post;
  mv_Filtros.Refresh;

  if obs<>'' then
  begin
    wtsmthdfrm_Filtros.Edit;
    wtsmthdfrm_Filtros.ParamsView.FieldByName('OBS').Value := obs;
    wtsmthdfrm_Filtros.Post;
  end;
  wtsmthdfrm_Filtros.Edit;
end;

initialization
  RegisterDocClass(TFItensErro);
end.
