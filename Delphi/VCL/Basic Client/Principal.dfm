object fPrincipal: TfPrincipal
  Left = 0
  Top = 0
  Caption = 'RAL Basic Client'
  ClientHeight = 299
  ClientWidth = 393
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 13
  object lInfo: TLabel
    Left = 23
    Top = 72
    Width = 333
    Height = 114
    Caption = 
      'This example works alongside the Basic Server Sample. It'#39's advis' +
      'ed to run both of them to know how things work.'#13#10#13#10'There'#39's a FMX' +
      ' Basic Client Sample which works indepedantly of our server samp' +
      'le.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    Font.Quality = fqClearType
    ParentFont = False
    WordWrap = True
  end
  object Button1: TButton
    Left = 8
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Clientes'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 89
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Ping'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 170
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Hello'
    TabOrder = 2
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 251
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Error'
    TabOrder = 3
    OnClick = Button4Click
  end
  object cliente: TRALClient
    Authentication = basic
    ConnectTimeout = 30000
    CompressType = ctGZip
    CriptoOptions.CriptType = crNone
    EngineType = 'Indy'
    KeepAlive = True
    RequestTimeout = 10000
    UserAgent = 'RALClient 0.11.0-3 alpha; Engine Indy 10.6.2.0'
    Left = 24
    Top = 240
  end
  object basic: TRALClientBasicAuth
    AutoGetToken = True
    UserName = 'admin'
    Password = 'admin'
    Left = 80
    Top = 240
  end
end
