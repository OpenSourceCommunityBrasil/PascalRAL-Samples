object fPrincipal: TfPrincipal
  Left = 0
  Top = 0
  Caption = 'RAL Basic Server'
  ClientHeight = 75
  ClientWidth = 268
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object ToggleSwitch1: TToggleSwitch
    Left = 8
    Top = 8
    Width = 72
    Height = 20
    TabOrder = 0
    OnClick = ToggleSwitch1Click
  end
  object Server: TRALIndyServer
    Active = False
    Port = 8000
    Routes = <
      item
        DisplayName = 'ping'
        Document = 'ping'
        RouteList = <>
        AllowedMethods = [amALL]
        SkipAuthMethods = []
        Callback = False
        OnReply = ping
      end>
    ServerStatus.Strings = (
      '<html>'
      '<body>'
      '<h1>Server OnLine</h1>'
      '</body>'
      '</html>')
    ShowServerStatus = True
    Left = 129
    Top = 8
  end
end
