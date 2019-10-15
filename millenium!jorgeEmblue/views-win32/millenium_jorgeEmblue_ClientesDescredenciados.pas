unit millenium_jorgeEmblue_ClientesDescredenciados;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  dmbase, ExtCtrls, Db, wtsMethodView, wtsMethodFrame, ComCtrls, Menus,
  wtsStream, wtsClient, wtsPainter, dmPanel, LinkList, WTSGridFrame, ResUnit,
  StatusPanel, StdCtrls, Excel2000, OleServer, Grids, wdDBGrids, PalDBGrid,
  DBGrids;

type
  TFClientesDescredenciados = class(TDMBase)
    lst_Botoes: TLinkList;
    dmPnl_Principal: TdmPanel;
    dmPnl_Planilha: TdmPanel;
    dmspltr1: TdmSplitter;
    dlgOpen_carregarPlanilha: TOpenDialog;
    ds1: TDataSource;
    dbgrdxEmails: TDBGridEx;
    wtsprmsvw1: TwtsParamsView;
    strngfldwtsprmsvw1EMAIL: TStringField;
    mv1: TwtsMethodView;
    procedure lst_BotoesLinks0Click(Sender: TObject);
    procedure lst_BotoesLinks1Click(Sender: TObject);
  private
    FStatusPanel: TStatusPanel;
    FileName: string;
    procedure CarregaDadosPlanilha(AFileName: string);

    { Private declarations }
  public
    { Public declarations }
  end;

var
  FClientesDescredenciados: TFClientesDescredenciados;
  Coluna: array[0..1] of string = ('EMAIL', 'NOME');

implementation

{$R *.DFM}
procedure TFClientesDescredenciados.lst_BotoesLinks0Click(Sender: TObject);
begin
  dlgOpen_carregarPlanilha.Title := 'Abrir Planilha';
  dlgOpen_carregarPlanilha.DefaultExt := '*.xlsx|*.xls|*.csv';
  dlgOpen_carregarPlanilha.Filter := 'Excel|*.xls;*.xlsx;*.csv';
  if dlgOpen_carregarPlanilha.Execute then
  begin
    FileName := dlgOpen_carregarPlanilha.FileName;
    CarregaDadosPlanilha(dlgOpen_carregarPlanilha.FileName);
  end
end;

procedure TFClientesDescredenciados.CarregaDadosPlanilha(AFileName: string);
var
  sh, x, y, i: Integer;
  listCampos: TStringList;
  EApp: TExcelApplication;
  _Wsh: _Worksheet;
  _Wkb: _WorkBook;
  MVdescadstros: TwtsRecordset;
  teste: string;
begin
  EApp := TExcelApplication.Create(nil);
  try
    try
      EApp.ConnectKind := ckNewInstance;
      try
        EApp.Connect;
      except
        MessageDlg('Excel não instalado', mtError, [mbOK], 0);
        Exit;
      end;

      FStatusPanel := TStatusPanel.Create(self);
      FStatusPanel.Align := alClient;
      try
        EApp.Workbooks.Open(AFileName, null, null, null, null, null, null, null, null, null, null, null, null, GetUserDefaultLCID);
        _Wkb := EApp.ActiveWorkbook;
        for sh := 1 to 1 do
        begin
          _Wsh := _Wkb.Sheets.Item[sh] as _WorkSheet;

          listCampos := TStringList.Create;
          try
            ExtractStrings([';'], [' '], PChar(VarToStr(_Wsh.Cells.Item[1, 1].Value)), listCampos);
            if listCampos.Count <> 1 then
              raise exception.create('Planilha com numero de colunas diferente do suportado! (suportado = 1 colunas) ');
            if listCampos[0] <> 'EMAIL' then
              raise exception.create('A coluna deve corresponder o nome e-mail (EMAIL)');

            dmPnl_Planilha.Caption := 'Planinha ' + AFileName;
            wtsprmsvw1.Close;
            wtsprmsvw1.Open;
            wtsprmsvw1.Clear;

            for i := 2 to _Wsh.Rows.Count do
            begin
              if VarToStr(_Wsh.Cells.Item[i, 1].Value)<>'' then
              begin
                listCampos := TStringList.Create;
                try
                  ExtractStrings([';'], [' '], PChar(VarToStr(_Wsh.Cells.Item[i, 1].Value)), listCampos);

                  wtsprmsvw1.Append;
                  wtsprmsvw1.FieldValues['EMAIL'] := listCampos[0];

                finally
                  FreeAndNil(listCampos);
                end;
              end
              else
                Break;
            end;
          finally
            FreeAndNil(listCampos);
          end;
        end;
      finally
        FreeAndNil(FStatusPanel);
      end;

      wtsprmsvw1.Post;
      dbgrdxEmails.Refresh;
    finally
      EApp.Quit;
      EApp.Disconnect;
      FreeAndNil(EApp);
    end;
  except
    on e: exception do
    begin
      MessageDlg(PChar('Erro no carregamento da planilha: ' + e.message), mtError, [mbOK], 0);
      if FStatusPanel <> nil then
        FreeAndNil(FStatusPanel);
    end;
  end;
end;

procedure TFClientesDescredenciados.lst_BotoesLinks1Click(Sender: TObject);
var email:String;
    v:Variant;
begin
  try
    if wtsprmsvw1.Eof then
      Exit;
    FStatusPanel := TStatusPanel.Create(self);
    FStatusPanel.Align := alClient;
    try
      wtsprmsvw1.DisableControls;
      wtsprmsvw1.First;
      while not wtsprmsvw1.Eof do
      begin
        email := wtsprmsvw1.FieldValues['EMAIL'];
        wtsCall('MILLENIUM!JORGEEMBLUE.CLIENTES.DESCADASTRAR', ['EMAIL'], [email], v);
        wtsprmsvw1.Next
      end;
      wtsprmsvw1.Clear;
      wtsprmsvw1.First;
      wtsprmsvw1.Close;
      wtsprmsvw1.Open;
      wtsprmsvw1.Clear;
      wtsprmsvw1.Open;
      mv1.Clear;
      dbgrdxEmails.Refresh;

      dmPnl_Planilha.Caption := 'Planinha ';
    finally
      wtsprmsvw1.EnableControls;
      FreeAndNil(FStatusPanel);
    end;


  except
    on e: exception do
    begin
      MessageDlg(PChar('Erro no executar descredenciamentos: ' + e.message), mtError, [mbOK], 0);
      if FStatusPanel <> nil then
        FreeAndNil(FStatusPanel);
    end;
  end;
end;

initialization
  RegisterDocClass(TFClientesDescredenciados);

end.

