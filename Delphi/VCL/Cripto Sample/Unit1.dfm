object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 409
  ClientWidth = 506
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object Label1: TLabel
    Left = 0
    Top = 0
    Width = 506
    Height = 15
    Align = alTop
    Caption = 'Input'
    ExplicitWidth = 28
  end
  object Label2: TLabel
    Left = 0
    Top = 46
    Width = 506
    Height = 15
    Align = alTop
    Caption = 'Hashes'
    ExplicitWidth = 38
  end
  object Label3: TLabel
    Left = 0
    Top = 125
    Width = 506
    Height = 15
    Align = alTop
    Caption = 'Encrypt'
    ExplicitWidth = 40
  end
  object Label4: TLabel
    Left = 0
    Top = 173
    Width = 506
    Height = 15
    Align = alTop
    Caption = 'Decrypt'
    ExplicitWidth = 41
  end
  object Label5: TLabel
    Left = 0
    Top = 221
    Width = 506
    Height = 15
    Align = alTop
    Caption = 'Base64'
    ExplicitWidth = 36
  end
  object Memo1: TMemo
    Left = 0
    Top = 269
    Width = 506
    Height = 140
    Align = alClient
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object FlowPanel1: TFlowPanel
    Left = 0
    Top = 15
    Width = 506
    Height = 31
    Align = alTop
    AutoSize = True
    Padding.Left = 5
    Padding.Right = 5
    TabOrder = 1
    ExplicitTop = 0
    object Edit1: TEdit
      AlignWithMargins = True
      Left = 9
      Top = 4
      Width = 121
      Height = 23
      TabOrder = 0
      TextHint = 'Text'
    end
    object Edit2: TEdit
      AlignWithMargins = True
      Left = 136
      Top = 4
      Width = 121
      Height = 23
      TabOrder = 1
      TextHint = 'Key'
    end
  end
  object FlowPanel2: TFlowPanel
    Left = 0
    Top = 61
    Width = 506
    Height = 64
    Align = alTop
    AutoSize = True
    Padding.Left = 5
    Padding.Right = 5
    TabOrder = 2
    ExplicitTop = 41
    object Button1: TButton
      AlignWithMargins = True
      Left = 9
      Top = 4
      Width = 105
      Height = 25
      Caption = 'HMACSHA2_224'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      AlignWithMargins = True
      Left = 120
      Top = 4
      Width = 105
      Height = 25
      Caption = 'HMACSHA2_256'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      AlignWithMargins = True
      Left = 231
      Top = 4
      Width = 105
      Height = 25
      Caption = 'HMACSHA2_384'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Button4: TButton
      AlignWithMargins = True
      Left = 342
      Top = 4
      Width = 105
      Height = 25
      Caption = 'HMACSHA2_512'
      TabOrder = 3
      OnClick = Button4Click
    end
    object Button5: TButton
      AlignWithMargins = True
      Left = 9
      Top = 35
      Width = 121
      Height = 25
      Caption = 'HMACSHA2_512_224'
      TabOrder = 4
      OnClick = Button5Click
    end
    object Button6: TButton
      AlignWithMargins = True
      Left = 136
      Top = 35
      Width = 121
      Height = 25
      Caption = 'HMACSHA2_512_256'
      TabOrder = 5
      OnClick = Button6Click
    end
  end
  object FlowPanel3: TFlowPanel
    Left = 0
    Top = 140
    Width = 506
    Height = 33
    Align = alTop
    AutoSize = True
    Padding.Left = 5
    Padding.Right = 5
    TabOrder = 3
    ExplicitTop = 95
    object Button7: TButton
      AlignWithMargins = True
      Left = 9
      Top = 4
      Width = 60
      Height = 25
      Caption = 'AES128'
      TabOrder = 0
      OnClick = Button7Click
    end
    object Button8: TButton
      AlignWithMargins = True
      Left = 75
      Top = 4
      Width = 60
      Height = 25
      Caption = 'AES192'
      TabOrder = 1
      OnClick = Button8Click
    end
    object Button9: TButton
      AlignWithMargins = True
      Left = 141
      Top = 4
      Width = 60
      Height = 25
      Caption = 'AES256'
      TabOrder = 2
      OnClick = Button9Click
    end
  end
  object FlowPanel4: TFlowPanel
    Left = 0
    Top = 188
    Width = 506
    Height = 33
    Align = alTop
    AutoSize = True
    Padding.Left = 5
    Padding.Right = 5
    TabOrder = 4
    ExplicitTop = 128
    object Button10: TButton
      AlignWithMargins = True
      Left = 9
      Top = 4
      Width = 60
      Height = 25
      Caption = 'AES128'
      TabOrder = 0
      OnClick = Button10Click
    end
    object Button11: TButton
      AlignWithMargins = True
      Left = 75
      Top = 4
      Width = 60
      Height = 25
      Caption = 'AES192'
      TabOrder = 1
      OnClick = Button11Click
    end
    object Button12: TButton
      AlignWithMargins = True
      Left = 141
      Top = 4
      Width = 60
      Height = 25
      Caption = 'AES256'
      TabOrder = 2
      OnClick = Button12Click
    end
  end
  object FlowPanel5: TFlowPanel
    Left = 0
    Top = 236
    Width = 506
    Height = 33
    Align = alTop
    AutoSize = True
    Padding.Left = 5
    Padding.Right = 5
    TabOrder = 5
    ExplicitTop = 161
    object Button13: TButton
      AlignWithMargins = True
      Left = 9
      Top = 4
      Width = 60
      Height = 25
      Caption = 'Encode'
      TabOrder = 0
      OnClick = Button13Click
    end
    object Button14: TButton
      AlignWithMargins = True
      Left = 75
      Top = 4
      Width = 60
      Height = 25
      Caption = 'Decode'
      TabOrder = 1
      OnClick = Button14Click
    end
  end
end
