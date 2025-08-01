object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'RALClient DataBase FireDAC Example'
  ClientHeight = 309
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object Label1: TLabel
    Left = 183
    Top = 280
    Width = 34
    Height = 15
    Caption = 'Label1'
  end
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
    Top = 276
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 89
    Top = 276
    Width = 88
    Height = 25
    Caption = 'Apply Updates'
    TabOrder = 2
    OnClick = Button2Click
  end
  object DBNavigator1: TDBNavigator
    Left = 8
    Top = 245
    Width = 300
    Height = 25
    DataSource = DataSource1
    VisibleButtons = [nbInsert, nbDelete, nbEdit, nbPost]
    TabOrder = 3
  end
  object RALClient: TRALClient
    BaseURL.Strings = (
      'localhost:8000')
    ConnectTimeout = 30000
    CompressType = ctNone
    CriptoOptions.CriptType = crNone
    EngineType = 'mORMot2'
    KeepAlive = True
    RequestTimeout = 10000
    UserAgent = 'RALClient 0.11.0-11 alpha; Engine mORMot2 lts-2.3.8878'
    Left = 552
    Top = 64
  end
  object DataSource1: TDataSource
    DataSet = RALDBFDMemTable1
    Left = 552
    Top = 8
  end
  object RALDBFDMemTable1: TRALDBFDMemTable
    FieldOptions.BlobDisplayValue = dvFullText
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
    Storage = RALStorageBINLink1
    UpdateMode = upWhereAll
    UpdateTable = 'clientes'
    Left = 552
    Top = 120
  end
  object RALDBConnection1: TRALDBConnection
    Client = RALClient
    ModuleRoute = '/db'
    Left = 552
    Top = 176
  end
  object RALClientJWTAuth1: TRALClientJWTAuth
    AutoGetToken = True
    JSONKey = 'token'
    Route = '/gettoken'
    Left = 416
    Top = 248
  end
  object RALStorageJSONLink1: TRALStorageJSONLink
    FieldCharCase = fcNone
    FormatOptions.CustomDateTimeFormat = 'dd/mm/yyyy hh:nn:ss.zzz'
    FormatOptions.DateTimeFormat = dtfISO8601
    JSONType = jtDBWare
    Left = 552
    Top = 248
  end
  object RALStorageBINLink1: TRALStorageBINLink
    FieldCharCase = fcNone
    Left = 288
    Top = 256
  end
end
