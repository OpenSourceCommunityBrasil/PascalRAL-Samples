object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'RALClient DataBase Zeos Example'
  ClientHeight = 363
  ClientWidth = 447
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 13
  object Label1: TLabel
    Left = 183
    Top = 243
    Width = 31
    Height = 13
    Caption = 'Label1'
  end
  object DBGrid1: TDBGrid
    Left = 8
    Top = 8
    Width = 320
    Height = 193
    DataSource = DataSource1
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object Button1: TButton
    Left = 8
    Top = 238
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 89
    Top = 238
    Width = 88
    Height = 25
    Caption = 'Apply Updates'
    TabOrder = 2
    OnClick = Button2Click
  end
  object DBNavigator1: TDBNavigator
    Left = 8
    Top = 207
    Width = 300
    Height = 25
    DataSource = DataSource1
    VisibleButtons = [nbInsert, nbDelete, nbEdit, nbPost]
    TabOrder = 3
  end
  object DBMemo1: TDBMemo
    Left = 8
    Top = 266
    Width = 185
    Height = 89
    DataField = 'codigo'
    DataSource = DataSource1
    TabOrder = 4
  end
  object DBMemo2: TDBMemo
    Left = 199
    Top = 266
    Width = 185
    Height = 89
    DataField = 'nome'
    DataSource = DataSource1
    TabOrder = 5
  end
  object RALDBConnection1: TRALDBConnection
    Client = RALClient1
    Left = 376
    Top = 112
  end
  object DataSource1: TDataSource
    DataSet = RALDBZMemTable1
    Left = 376
  end
  object RALDBZMemTable1: TRALDBZMemTable
    AfterOpen = RALDBZMemTable1AfterOpen
    ControlsCodePage = cGET_ACP
    Options = [doCalcDefaults, doCheckRequired]
    RALConnection = RALDBConnection1
    ParamCheck = True
    Params = <>
    SQL.Strings = (
      'select * from clientes')
    Storage = RALStorageBINLink1
    UpdateMode = upWhereAll
    Left = 376
    Top = 168
  end
  object RALClientJWTAuth1: TRALClientJWTAuth
    AutoGetToken = True
    Route = '/gettoken/'
    Left = 368
    Top = 232
  end
  object RALStorageBINLink1: TRALStorageBINLink
    FieldCharCase = fcLower
    Left = 336
    Top = 304
  end
  object RALClient1: TRALClient
    Authentication = RALClientJWTAuth1
    ConnectTimeout = 30000
    CompressType = ctNone
    CriptoOptions.CriptType = crNone
    EngineType = 'Indy'
    KeepAlive = True
    RequestTimeout = 10000
    UserAgent = 'RALClient 0.11.0-9 alpha; Engine Indy 10.6.2.0'
    Left = 376
    Top = 64
  end
  object ZQuery1: TZQuery
    Params = <>
    Left = 224
    Top = 224
  end
  object ZConnection1: TZConnection
    ControlsCodePage = cCP_UTF16
    ClientCodepage = 'No Protocol selected!'
    Catalog = ''
    Properties.Strings = (
      'codepage=No Protocol selected!')
    DisableSavepoints = False
    HostName = ''
    Port = 0
    Database = ''
    User = ''
    Password = ''
    Protocol = 'sqlite'
    Left = 296
    Top = 224
  end
end
