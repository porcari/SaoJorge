object FClientesDescredenciados: TFClientesDescredenciados
  Left = 379
  Top = 157
  Width = 1088
  Height = 563
  Caption = 'Descadastrar Clientes (EXCEL EmBlue)'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lst_Botoes: TLinkList
    Left = 0
    Top = 493
    Width = 1072
    Height = 31
    Links = <
      item
        Down = False
        Caption = 'Carregar Planilha'
        ShortCut = 0
        OnClick = lst_BotoesLinks0Click
      end
      item
        Down = False
        Caption = 'Descredenciar'
        ShortCut = 0
        OnClick = lst_BotoesLinks1Click
      end>
    LinksHeight = 24
    LinksSpacing = 3
    LinksMargin = 2
    ShortCutPos = scpLeft
    ShowtCutColor = clRed
    List = False
    ListSmall = False
    AutoSize = False
    Margin = 2
    TabOrder = 0
    Align = alBottom
  end
  object dmPnl_Principal: TdmPanel
    Left = 0
    Top = 0
    Width = 1072
    Height = 493
    Style = psBackground
    Align = alClient
    Caption = 'dmPnl_Principal'
    ShowCaption = False
    TabOrder = 1
    object dmspltr1: TdmSplitter
      Left = 14
      Top = 14
      Width = 3
      Height = 465
      Cursor = crHSplit
    end
    object dmPnl_Planilha: TdmPanel
      Left = 17
      Top = 14
      Width = 1041
      Height = 465
      Style = psHeader
      Align = alClient
      Caption = 'Planilha'
      ShowCaption = True
      TabOrder = 0
      object dbgrdxEmails: TDBGridEx
        Left = 3
        Top = 23
        Width = 1035
        Height = 439
        Align = alClient
        Columns = <
          item
            Expanded = False
            FieldName = 'EMAIL'
            Visible = True
            AutoHeight = True
          end>
        DataSource = ds1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        DefaultRowHeight = 24
        Options = [dgeTitles, dgeProportionalColResize, dgeFooter, dgeShowFocus]
        TabOrder = 0
        NoCustomCFG = False
        Columns = <
          item
            Expanded = False
            FieldName = 'EMAIL'
            Visible = True
            AutoHeight = True
          end>
      end
    end
  end
  object dlgOpen_carregarPlanilha: TOpenDialog
    DefaultExt = '*.xlsx|*.xls'
    Filter = 'Excel|*.xls;*.xlsx'
    Title = 'Abrir Planilha'
    Left = 464
    Top = 344
  end
  object ds1: TDataSource
    DataSet = wtsprmsvw1
    Left = 223
    Top = 164
  end
  object wtsprmsvw1: TwtsParamsView
    ObjectView = False
    MethodView = mv1
    Left = 315
    Top = 156
    object strngfldwtsprmsvw1EMAIL: TStringField
      FieldName = 'EMAIL'
      Size = 250
    end
  end
  object mv1: TwtsMethodView
    ObjectView = False
    Transaction = 'MILLENIUM!JORGEEMBLUE.CLIENTES.DESCADASTRAR'
    DataSource = ds1
    Left = 147
    Top = 156
  end
end
