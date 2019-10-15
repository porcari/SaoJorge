object FItensErro: TFItensErro
  Left = 454
  Top = 187
  Width = 1088
  Height = 563
  Caption = 'Itens com Erro'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
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
        Caption = 'Reprocessar Selecionados'
        ShortCut = 0
        OnClick = lst_BotoesLinks0Click
      end
      item
        Down = False
        Caption = 'Não Integrar Selecionados'
        ShortCut = 0
        OnClick = lst_BotoesLinks1Click
      end
      item
        Down = False
        Caption = 'Listar'
        ShortCut = 0
        OnClick = lst_BotoesLinks2Click
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
      Left = 385
      Top = 20
      Width = 3
      Height = 453
      Cursor = crHSplit
    end
    object dmPnl_Filtros: TdmPanel
      Left = 20
      Top = 20
      Width = 365
      Height = 453
      Style = psHeader
      Align = alLeft
      Caption = 'Filtros'
      ShowCaption = True
      TabOrder = 0
      object wtsmthdfrm_Filtros: TwtsMethodFrame
        Left = 3
        Top = 23
        Width = 359
        Height = 427
        Style = psTransparent
        Align = alClient
        Caption = 'wtsmthdfrm_Filtros'
        ShowCaption = False
        TabOrder = 0
        Compact = False
        TabStop = True
        MethodView = mv_Filtros
        ViewType = vtParams
        Active = True
        RegKey = 'SOFTWARE\WINDOOR\METHODFRAME'
        CreateUserInterface = True
        Transparent = False
        LabelWidthLimit = 0
        NoCustomCFG = False
      end
    end
    object dmPnl_Itens: TdmPanel
      Left = 388
      Top = 20
      Width = 664
      Height = 453
      Style = psHeader
      Align = alClient
      Caption = 'Itens'
      ShowCaption = True
      TabOrder = 1
      object wtsgrdfrm_Listar: TwtsGridFrame
        Left = 3
        Top = 23
        Width = 658
        Height = 427
        Align = alClient
        BorderStyle = bsNone
        Attributes.FooterColor = 15463155
        Attributes.GridColor = clWhite
        DataSource = ds_Lista
        TabOrder = 0
        ShowGrouppingPanel = False
      end
    end
  end
  object mv_Filtros: TwtsMethodView
    ObjectView = False
    Transaction = 'MILLENIUM!JORGEEMBLUE.INTEGRACOES.LISTARITENSERRO'
    Left = 92
    Top = 164
  end
  object ds_Lista: TDataSource
    DataSet = mv_Filtros
    Left = 407
    Top = 195
  end
end
