object RALForm1: TRALForm1
  Left = 0
  Top = 0
  Caption = 'RAL - StandAlone Application'
  ClientHeight = 149
  ClientWidth = 312
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 13
  object lInfo: TLabel
    Left = 8
    Top = 8
    Width = 292
    Height = 57
    Caption = 
      'Remember to chage DBModule Database link between FireDAC and Zeo' +
      's to test native binary traffic'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object JWTAuth: TRALServerJWTAuth
    Algorithm = tjaHSHA256
    AuthRoute.Description.Strings = (
      'Get a JWT Token')
    AuthRoute.InputParams = <>
    AuthRoute.Route = '/'
    ExpirationSecs = 1800
    JSONKey = 'testeJWT'
    SignSecretKey = 'testeJWT'
    Left = 128
    Top = 88
  end
  object DBModule: TRALDBModule
    Server = server
    Domain = '/db'
    DatabaseLink = 'FireDAC'
    DatabaseType = dtSQLite
    Port = 0
    Left = 64
    Top = 88
  end
  object StorageBIN: TRALStorageBINLink
    FieldCharCase = fcNone
    Left = 256
    Top = 48
  end
  object StorageJSON: TRALStorageJSONLink
    FieldCharCase = fcNone
    FormatOptions.CustomDateTimeFormat = 'dd/mm/yyyy hh:nn:ss.zzz'
    FormatOptions.DateTimeFormat = dtfISO8601
    JSONType = jtDBWare
    Left = 256
    Top = 96
  end
  object server: TRALSynopseServer
    Active = False
    CompressType = ctNone
    CookieLife = 30
    CORSOptions.AllowHeaders.Strings = (
      'Content-Type'
      'Origin'
      'Accept'
      'Authorization'
      'Content-Encoding'
      'Accept-Encoding')
    CORSOptions.AllowOrigin = '*'
    CORSOptions.MaxAge = 86400
    CriptoOptions.CriptType = crNone
    IPConfig.IPv4Bind = '0.0.0.0'
    IPConfig.IPv6Bind = '::'
    IPConfig.IPv6Enabled = False
    ResponsePages = <>
    Port = 8000
    Routes = <>
    Security.BruteForce.ExpirationTime = 1800000
    Security.BruteForce.MaxTry = 3
    Security.FloodTimeInterval = 30
    Security.Options = []
    ShowServerStatus = True
    PoolCount = 32
    QueueSize = 1000
    SSL.Enabled = False
    Left = 8
    Top = 88
  end
end
