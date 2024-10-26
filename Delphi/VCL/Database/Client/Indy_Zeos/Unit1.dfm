object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 363
  ClientWidth = 447
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 8
    Top = 24
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
    Top = 255
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 89
    Top = 255
    Width = 88
    Height = 25
    Caption = 'Apply Updates'
    TabOrder = 2
    OnClick = Button2Click
  end
  object DBNavigator1: TDBNavigator
    Left = 8
    Top = 223
    Width = 300
    Height = 25
    DataSource = DataSource1
    VisibleButtons = [nbInsert, nbDelete, nbEdit, nbPost]
    TabOrder = 3
  end
  object RALIndyClientMT1: TRALIndyClientMT
    BaseURL.Strings = (
      'localhost:8000')
    ConnectTimeout = 30000
    CompressType = ctGZip
    CriptoOptions.CriptType = crNone
    KeepAlive = True
    RequestTimeout = 10000
    UserAgent = 'RALClient 0.9.8 - alpha; Engine Indy 10.6.2.5311'
    ExecBehavior = ebMultiThread
    RequestLifeCicle = False
    Left = 376
    Top = 56
  end
  object RALDBConnection1: TRALDBConnection
    Client = RALIndyClientMT1
    ModuleRoute = '/db'
    Left = 376
    Top = 112
  end
  object RALDBStorageBINLink1: TRALDBStorageBINLink
    FieldCharCase = fcNone
    Left = 376
    Top = 280
  end
  object DataSource1: TDataSource
    DataSet = RALDBZMemTable1
    Left = 376
  end
  object RALDBStorageJSONLink1: TRALDBStorageJSONLink
    FieldCharCase = fcNone
    FormatOptions.CustomDateTimeFormat = 'dd/mm/yyyy hh:nn:ss:zzz'
    FormatOptions.DateTimeFormat = dtfISO8601
    JSONType = jtDBWare
    Left = 376
    Top = 224
  end
  object RALDBZMemTable1: TRALDBZMemTable
    AfterOpen = RALDBZMemTable1AfterOpen
    ControlsCodePage = cDynamic
    RALConnection = RALDBConnection1
    ParamCheck = True
    Params = <>
    SQL.Strings = (
      'select * from clientes')
    Storage = RALDBStorageBINLink1
    UpdateMode = upWhereAll
    UpdateTable = 'clientes'
    Left = 376
    Top = 168
  end
end
