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
  object lePort: TLabeledEdit
    Left = 8
    Top = 18
    Width = 89
    Height = 21
    EditLabel.Width = 20
    EditLabel.Height = 13
    EditLabel.Caption = 'Port'
    TabOrder = 2
    Text = ''
  end
  object Memo1: TMemo
    Left = 8
    Top = 72
    Width = 105
    Height = 130
    ReadOnly = True
    TabOrder = 3
    WordWrap = False
  end
  object Server: TRALSynopseServer
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
    PoolCount = 32
    QueueSize = 1000
    SSL.Enabled = False
    Left = 192
    Top = 8
  end
end
