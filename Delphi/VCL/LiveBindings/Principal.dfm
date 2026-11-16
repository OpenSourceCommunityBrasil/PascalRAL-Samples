object fPrincipal: TfPrincipal
  Left = 0
  Top = 0
  Caption = 'RAL - LiveBindings sobre JSON (TRALJSONBindSourceAdapter)'
  ClientHeight = 400
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object pnlTopo: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 41
    Align = alTop
    TabOrder = 0
    object lblNome: TLabel
      Left = 230
      Top = 13
      Width = 31
      Height = 13
      Caption = 'Nome:'
    end
    object btnCarregar: TButton
      Left = 12
      Top = 8
      Width = 100
      Height = 25
      Caption = 'Carregar'
      TabOrder = 0
      OnClick = btnCarregarClick
    end
    object btnJSON: TButton
      Left = 118
      Top = 8
      Width = 100
      Height = 25
      Caption = 'Ver JSON'
      TabOrder = 1
      OnClick = btnJSONClick
    end
    object edNome: TEdit
      Left = 268
      Top = 10
      Width = 200
      Height = 21
      TabOrder = 2
    end
  end
  object gridPessoas: TStringGrid
    Left = 0
    Top = 41
    Width = 640
    Height = 219
    Align = alClient
    ColCount = 4
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goTabs]
    TabOrder = 1
  end
  object mmJSON: TMemo
    Left = 0
    Top = 260
    Width = 640
    Height = 140
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object RALClient1: TRALClient
    Left = 480
    Top = 80
  end
  object RALJSONBindSourceAdapter1: TRALJSONBindSourceAdapter
    Client = RALClient1
    FieldDefs.Strings = (
      'id:integer'
      'name'
      'score:float'
      'active:boolean')
    Route = 'pessoas'
    Left = 480
    Top = 136
  end
  object AdapterBindSource1: TAdapterBindSource
    AutoActivate = True
    Adapter = RALJSONBindSourceAdapter1
    ScopeMappings = <>
    Left = 480
    Top = 192
  end
  object BindingsList1: TBindingsList
    Methods = <>
    OutputConverters = <>
    Left = 560
    Top = 80
    object LinkGridToDataSource1: TLinkGridToDataSource
      Category = 'Quick Bindings'
      DataSource = AdapterBindSource1
      GridControl = gridPessoas
      Columns = <>
    end
    object LinkControlToFieldNome: TLinkControlToField
      Category = 'Quick Bindings'
      DataSource = AdapterBindSource1
      FieldName = 'name'
      Control = edNome
      Track = True
    end
  end
end
