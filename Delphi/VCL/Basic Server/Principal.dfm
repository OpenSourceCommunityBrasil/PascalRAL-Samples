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
  OnCreate = FormCreate
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
    Text = ''
  end
  object Server: TRALIndyServer
    Active = False
    BruteForceProtection.Enabled = True
    BruteForceProtection.ExpirationMin = 30
    BruteForceProtection.MaxTry = 3
    IPConfig.IPv4Bind = '0.0.0.0'
    IPConfig.IPv6Bind = '::'
    IPConfig.IPv6Enabled = False
    Options = []
    Port = 8000
    Routes = <>
    ServerStatus.Strings = (
      
        '<html><head><title>RALServer - 0.2.0 - alpha</title></head><body' +
        '><h1>Server OnLine</h1><h4>Version: 0.2.0 - alpha</h4><h4>Engine' +
        ': $ralengine;</h4></body></html>')
    SessionTimeout = 0
    ShowServerStatus = True
    CompressType = ctNone
    CORSOptions.Enabled = False
    CORSOptions.AllowOrigin = '*'
    CORSOptions.AllowHeaders.Strings = (
      'Content-Type'
      'Origin'
      'Accept'
      'Authorization'
      'Content-Encoding'
      'Accept-Encoding')
    CORSOptions.MaxAge = 86400
    CriptoOptions.CriptType = crNone
    SSL.Enabled = False
    SSL.SSLOptions.Mode = sslmUnassigned
    SSL.SSLOptions.VerifyMode = []
    SSL.SSLOptions.VerifyDepth = 0
    Left = 216
    Top = 16
  end
end
