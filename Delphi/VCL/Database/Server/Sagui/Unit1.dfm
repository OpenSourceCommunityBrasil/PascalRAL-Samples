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
  object JWTAuth: TRALServerJWTAuth
    Algorithm = tjaHSHA256
    AuthRoute.Description.Strings = (
      'Get a JWT Token')
    AuthRoute.InputParams = <>
    AuthRoute.Route = '/'
    ExpirationSecs = 1800
    JSONKey = 'token'
    Left = 40
    Top = 88
  end
  object DBModule: TRALDBModule
    Server = Server
    Domain = '/'
    DatabaseLink = 'FireDAC'
    DatabaseType = dtSQLite
    Port = 0
    Left = 128
    Top = 16
  end
  object StorageBIN: TRALStorageBINLink
    FieldCharCase = fcNone
    Left = 240
    Top = 16
  end
  object StorageJSON: TRALStorageJSONLink
    FieldCharCase = fcNone
    FormatOptions.CustomDateTimeFormat = 'dd/mm/yyyy hh:nn:ss.zzz'
    FormatOptions.DateTimeFormat = dtfISO8601
    JSONType = jtDBWare
    Left = 240
    Top = 72
  end
  object Server: TRALSaguiServer
    Active = False
    Authentication = JWTAuth
    CompressType = ctNone
    CookieLife = 30
    CORSOptions.AllowHeaders.Strings = (
      'Content-Type'
      'Origin'
      'Accept'
      'Authorization'
      'Content-Encoding'
      'Accept-Encoding')
    CORSOptions.MaxAge = 86400
    CriptoOptions.CriptType = crNone
    IPConfig.IPv6Enabled = False
    ResponsePages = <>
    Port = 8000
    Routes = <>
    Security.BruteForce.ExpirationTime = 1800000
    Security.BruteForce.MaxTry = 3
    Security.FloodTimeInterval = 30
    Security.Options = []
    ShowServerStatus = True
    SSL.Enabled = False
    Left = 40
    Top = 16
  end
end
