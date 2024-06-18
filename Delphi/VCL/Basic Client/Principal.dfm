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
  object cliente: TRALIndyClient
    Authentication = basic
    ConnectTimeout = 30000
    CompressType = ctGZip
    CriptoOptions.CriptType = crNone
    KeepAlive = True
    RequestTimeout = 10000
    UserAgent = 'RALClient 0.9.7 - alpha'
    Left = 40
    Top = 80
  end
  object basic: TRALClientBasicAuth
    AutoGetToken = True
    UserName = 'admin'
    Password = 'admin'
    Left = 112
    Top = 80
  end
end
