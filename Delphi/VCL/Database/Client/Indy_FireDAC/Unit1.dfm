object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 309
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object DBGrid1: TDBGrid
    Left = 8
    Top = 8
    Width = 505
    Height = 232
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object Button1: TButton
    Left = 8
    Top = 246
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 89
    Top = 246
    Width = 88
    Height = 25
    Caption = 'Apply Updates'
    TabOrder = 2
    OnClick = Button2Click
  end
  object RALIndyClientMT1: TRALIndyClientMT
    BaseURL.Strings = (
      'localhost:8000')
    ConnectTimeout = 30000
    CompressType = ctNone
    CriptoOptions.CriptType = crNone
    KeepAlive = True
    RequestTimeout = 10000
    UserAgent = 'RALClient 0.9.8 - alpha; Engine Indy 10.6.2.0'
    ExecBehavior = ebMultiThread
    RequestLifeCicle = False
    Left = 552
    Top = 64
  end
  object DataSource1: TDataSource
    DataSet = RALDBFDMemTable1
    Left = 552
    Top = 8
  end
  object RALDBFDMemTable1: TRALDBFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    RALConnection = RALDBConnection1
    ParamCheck = True
    Params = <>
    SQL.Strings = (
      'select * from clientes')
    Storage = RALDBStorageBINLink1
    UpdateMode = upWhereAll
    UpdateTable = 'clientes'
    Left = 552
    Top = 120
  end
  object RALDBConnection1: TRALDBConnection
    Client = RALIndyClientMT1
    ModuleRoute = '/db'
    Left = 552
    Top = 176
  end
  object RALDBStorageBINLink1: TRALDBStorageBINLink
    FieldCharCase = fcNone
    Left = 552
    Top = 232
  end
end
