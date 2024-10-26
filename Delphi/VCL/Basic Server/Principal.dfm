object fPrincipal: TfPrincipal
  Left = 0
  Top = 0
  Caption = 'RAL Basic Server'
  ClientHeight = 203
  ClientWidth = 403
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 53
    Width = 34
    Height = 13
    Caption = 'Routes'
  end
  object Label2: TLabel
    Left = 119
    Top = 53
    Width = 17
    Height = 13
    Caption = 'Log'
  end
  object lServerPath: TLabel
    Left = 286
    Top = 34
    Width = 54
    Height = 13
    Caption = 'ServerPath'
  end
  object ToggleSwitch1: TToggleSwitch
    Left = 323
    Top = 8
    Width = 72
    Height = 20
    TabOrder = 0
    OnClick = ToggleSwitch1Click
  end
  object Memo2: TMemo
    Left = 119
    Top = 72
    Width = 282
    Height = 130
    Lines.Strings = (
      'Memo2')
    TabOrder = 1
  end
  object ListView1: TListView
    Left = 8
    Top = 72
    Width = 105
    Height = 130
    Columns = <>
    TabOrder = 2
    ViewStyle = vsList
  end
  object lePort: TLabeledEdit
    Left = 8
    Top = 18
    Width = 89
    Height = 21
    EditLabel.Width = 20
    EditLabel.Height = 13
    EditLabel.Caption = 'Port'
    TabOrder = 3
  end
  object Server: TRALIndyServer
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
    Routes = <>
    Security.BruteForce.ExpirationTime = 1800000
    Security.BruteForce.MaxTry = 3
    Security.FloodTimeInterval = 30
    Security.Options = []
    ServerStatus.Strings = (
      
        '<!DOCTYPE html><html lang="en-us"><head><title>RALServer - 0.9.7' +
        ' - alpha</title></head><body><h1>Server OnLine</h1><h4>Version: ' +
        '0.9.7 - alpha</h4><h4>Engine: %ralengine%</h4></body></html>')
    ShowServerStatus = True
    SSL.Enabled = False
    SSL.SSLOptions.Mode = sslmUnassigned
    SSL.SSLOptions.VerifyMode = []
    SSL.SSLOptions.VerifyDepth = 0
    Left = 192
    Top = 16
  end
end
