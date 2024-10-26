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
  object server: TRALIndyServer
    Active = False
    CompressType = ctGZip
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
    ResponsePages = <
      item
        StatusCode = 400
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.8' +
            ' - alpha</title></head><body><h1>400 - BadRequest</h1><p>The ser' +
            'ver informs that it doesn'#39't like the input params</p></body></ht' +
            'ml>')
      end
      item
        StatusCode = 401
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.8' +
            ' - alpha</title></head><body><h1>401 - Unauthorized</h1><p>The s' +
            'erver informs that it doesn'#39't know you</p></body></html>')
      end
      item
        StatusCode = 403
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.8' +
            ' - alpha</title></head><body><h1>403 - Forbidden</h1><p>The serv' +
            'er informs that it doesn'#39't want you to access</p></body></html>')
      end
      item
        StatusCode = 404
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.8' +
            ' - alpha</title></head><body><h1>404 - Not Found</h1><p>The serv' +
            'er informs that the page you'#39're requesting doesn'#39't exist in this' +
            ' reality</p></body></html>')
      end
      item
        StatusCode = 415
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.8' +
            ' - alpha</title></head><body><h1>415 - Unsuported Media Type</h1' +
            '><p>The server informs that it doesn'#39't know what you'#39're asking</' +
            'p></body></html>')
      end
      item
        StatusCode = 500
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.8' +
            ' - alpha</title></head><body><h1>500 - Internal Server Error</h1' +
            '><p>The server made something that it shouldn'#39't</p></body></html' +
            '>')
      end
      item
        StatusCode = 501
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.8' +
            ' - alpha</title></head><body><h1>501 - Not Implemented</h1><p>Th' +
            'e server informs that it doesn'#39't exist</p></body></html>')
      end
      item
        StatusCode = 503
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.8' +
            ' - alpha</title></head><body><h1>503 - Service Unavailable</h1><' +
            'p>The server informs that it doesn'#39't want to work now and you sh' +
            'ould try later</p></body></html>')
      end>
    Port = 8000
    Routes = <
      item
        InputParams = <>
        Route = '/ping'
        AllowedMethods = [amGET]
        AllowURIParams = False
        Callback = False
        Name = 'ping'
        SkipAuthMethods = []
        URIParams = <>
        OnReply = serverRoutes_pingReply
      end>
    Security.BruteForce.ExpirationTime = 1800000
    Security.BruteForce.MaxTry = 3
    Security.FloodTimeInterval = 30
    Security.Options = []
    ShowServerStatus = True
    SSL.Enabled = False
    SSL.SSLOptions.Mode = sslmUnassigned
    SSL.SSLOptions.VerifyMode = []
    SSL.SSLOptions.VerifyDepth = 0
    Left = 32
    Top = 24
  end
  object RALDBStorageBINLink1: TRALDBStorageBINLink
    FieldCharCase = fcNone
    Left = 64
    Top = 88
  end
  object RALDBModule1: TRALDBModule
    Server = server
    Domain = '/db'
    DatabaseLink = RALDBFireDACLink1
    DatabaseType = dtSQLite
    Port = 0
    StorageOutPut = RALDBStorageJSONLink1
    Left = 120
    Top = 24
  end
  object RALDBFireDACLink1: TRALDBFireDACLink
    Left = 240
    Top = 24
  end
  object RALDBStorageJSONLink1: TRALDBStorageJSONLink
    FieldCharCase = fcNone
    FormatOptions.CustomDateTimeFormat = 'dd/mm/yyyy hh:nn:ss:zzz'
    FormatOptions.DateTimeFormat = dtfISO8601
    JSONType = jtDBWare
    Left = 224
    Top = 88
  end
end
