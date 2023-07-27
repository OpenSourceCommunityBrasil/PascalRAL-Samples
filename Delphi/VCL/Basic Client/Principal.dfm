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
  OldCreateOrder = True
  PixelsPerInch = 96
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
    BaseURL = 'localhost:8000'
    ConnectTimeout = 0
    RequestTimeout = 0
    UseSSL = False
    UserAgent = 'RALClient 0.2.0 - alpha; Engine Indy 10.6.2.5366'
    Left = 56
    Top = 72
  end
  object basic: TRALClientBasicAuth
    UserName = 'testeuser'
    Password = 'testepass'
    Left = 112
    Top = 72
  end
end
