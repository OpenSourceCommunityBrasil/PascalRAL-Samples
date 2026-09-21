object fServidor: TfServidor
  Left = 0
  Top = 0
  Caption = 'PascalRAL - MsQuic Benchmark - Servidor'
  ClientHeight = 560
  ClientWidth = 740
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnTopo: TPanel
    Left = 0
    Top = 0
    Width = 740
    Height = 262
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object gbServidor: TGroupBox
      Left = 8
      Top = 6
      Width = 360
      Height = 250
      Caption = ' Servidor QUIC '
      TabOrder = 0
      object lbPorta: TLabel
        Left = 12
        Top = 24
        Width = 55
        Height = 15
        Caption = 'Porta UDP'
      end
      object edPorta: TEdit
        Left = 12
        Top = 42
        Width = 80
        Height = 23
        TabOrder = 0
        Text = '8100'
      end
      object lbPool: TLabel
        Left = 104
        Top = 24
        Width = 118
        Height = 15
        Caption = 'PoolCount (threads)'
      end
      object edPool: TEdit
        Left = 104
        Top = 42
        Width = 60
        Height = 23
        TabOrder = 1
        Text = '1'
      end
      object lbCert: TLabel
        Left = 12
        Top = 72
        Width = 108
        Height = 15
        Caption = 'Certificado (PEM)'
      end
      object edCert: TEdit
        Left = 12
        Top = 90
        Width = 336
        Height = 23
        TabOrder = 2
      end
      object lbChave: TLabel
        Left = 12
        Top = 118
        Width = 111
        Height = 15
        Caption = 'Chave privada (PEM)'
      end
      object edChave: TEdit
        Left = 12
        Top = 136
        Width = 336
        Height = 23
        TabOrder = 3
      end
      object lbCompress: TLabel
        Left = 12
        Top = 166
        Width = 66
        Height = 15
        Caption = 'Compress'#227'o'
      end
      object cbCompress: TComboBox
        Left = 12
        Top = 184
        Width = 100
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 4
        Text = 'Nenhuma'
        Items.Strings = (
          'Nenhuma'
          'gzip'
          'deflate'
          'zlib')
      end
      object lbCripto: TLabel
        Left = 122
        Top = 166
        Width = 69
        Height = 15
        Caption = 'Criptografia'
      end
      object cbCripto: TComboBox
        Left = 122
        Top = 184
        Width = 100
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 5
        Text = 'Nenhuma'
        Items.Strings = (
          'Nenhuma'
          'AES128'
          'AES192'
          'AES256')
      end
      object lbChaveCripto: TLabel
        Left = 232
        Top = 166
        Width = 90
        Height = 15
        Caption = 'Chave da cripto'
      end
      object edChaveCripto: TEdit
        Left = 232
        Top = 184
        Width = 116
        Height = 23
        TabOrder = 6
      end
      object btLigar: TButton
        Left = 12
        Top = 214
        Width = 110
        Height = 27
        Caption = 'Ligar'
        TabOrder = 7
        OnClick = btLigarClick
      end
      object lbStatus: TLabel
        Left = 132
        Top = 220
        Width = 39
        Height = 15
        Caption = 'parado'
      end
    end
    object gbFirebird: TGroupBox
      Left = 376
      Top = 6
      Width = 356
      Height = 250
      Caption = ' Firebird (DAO e DBWare) '
      TabOrder = 1
      object lbFBHost: TLabel
        Left = 12
        Top = 24
        Width = 48
        Height = 15
        Caption = 'Servidor'
      end
      object edFBHost: TEdit
        Left = 12
        Top = 42
        Width = 180
        Height = 23
        TabOrder = 0
        Text = 'localhost'
      end
      object lbFBPorta: TLabel
        Left = 204
        Top = 24
        Width = 30
        Height = 15
        Caption = 'Porta'
      end
      object edFBPorta: TEdit
        Left = 204
        Top = 42
        Width = 60
        Height = 23
        TabOrder = 1
        Text = '3050'
      end
      object lbFBBanco: TLabel
        Left = 12
        Top = 72
        Width = 86
        Height = 15
        Caption = 'Banco (arquivo)'
      end
      object edFBBanco: TEdit
        Left = 12
        Top = 90
        Width = 332
        Height = 23
        TabOrder = 2
      end
      object lbFBUsuario: TLabel
        Left = 12
        Top = 118
        Width = 44
        Height = 15
        Caption = 'Usu'#225'rio'
      end
      object edFBUsuario: TEdit
        Left = 12
        Top = 136
        Width = 140
        Height = 23
        TabOrder = 3
        Text = 'SYSDBA'
      end
      object lbFBSenha: TLabel
        Left = 164
        Top = 118
        Width = 34
        Height = 15
        Caption = 'Senha'
      end
      object edFBSenha: TEdit
        Left = 164
        Top = 136
        Width = 180
        Height = 23
        PasswordChar = '*'
        TabOrder = 4
        Text = 'masterkey'
      end
      object btCriarBanco: TButton
        Left = 12
        Top = 174
        Width = 220
        Height = 27
        Caption = 'Criar banco e 2000 registros'
        TabOrder = 5
        OnClick = btCriarBancoClick
      end
      object lbBanco: TLabel
        Left = 12
        Top = 212
        Width = 300
        Height = 15
        Caption = 'o servidor cria a tabela BENCH se ela n'#227'o existir'
      end
    end
  end
  object mmLog: TMemo
    Left = 0
    Top = 262
    Width = 740
    Height = 298
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object tmContadores: TTimer
    Enabled = False
    OnTimer = tmContadoresTimer
    Left = 600
    Top = 300
  end
end
