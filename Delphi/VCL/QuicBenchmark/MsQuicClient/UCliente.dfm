object fCliente: TfCliente
  Left = 0
  Top = 0
  Caption = 'PascalRAL - MsQuic Benchmark - Cliente'
  ClientHeight = 640
  ClientWidth = 980
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
    Width = 980
    Height = 130
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object gbConexao: TGroupBox
      Left = 8
      Top = 4
      Width = 964
      Height = 120
      Caption = ' Conex'#227'o (vale para as tr'#234's abas) '
      TabOrder = 0
      object lbHost: TLabel
        Left = 12
        Top = 22
        Width = 25
        Height = 15
        Caption = 'Host'
      end
      object edHost: TEdit
        Left = 12
        Top = 40
        Width = 150
        Height = 23
        TabOrder = 0
        Text = '127.0.0.1'
      end
      object lbPorta: TLabel
        Left = 170
        Top = 22
        Width = 55
        Height = 15
        Caption = 'Porta UDP'
      end
      object edPorta: TEdit
        Left = 170
        Top = 40
        Width = 60
        Height = 23
        TabOrder = 1
        Text = '8443'
      end
      object lbTimeout: TLabel
        Left = 238
        Top = 22
        Width = 69
        Height = 15
        Caption = 'Timeout (ms)'
      end
      object edTimeout: TEdit
        Left = 238
        Top = 40
        Width = 70
        Height = 23
        TabOrder = 2
        Text = '15000'
      end
      object lbCompress: TLabel
        Left = 320
        Top = 22
        Width = 66
        Height = 15
        Caption = 'Compress'#227'o'
      end
      object cbCompress: TComboBox
        Left = 320
        Top = 40
        Width = 100
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 3
        Text = 'Nenhuma'
        Items.Strings = (
          'Nenhuma'
          'gzip'
          'deflate'
          'zlib')
      end
      object lbCripto: TLabel
        Left = 430
        Top = 22
        Width = 69
        Height = 15
        Caption = 'Criptografia'
      end
      object cbCripto: TComboBox
        Left = 430
        Top = 40
        Width = 100
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 4
        Text = 'Nenhuma'
        Items.Strings = (
          'Nenhuma'
          'AES128'
          'AES192'
          'AES256')
      end
      object lbChaveCripto: TLabel
        Left = 540
        Top = 22
        Width = 173
        Height = 15
        Caption = 'Chave da cripto (a mesma do servidor)'
      end
      object edChaveCripto: TEdit
        Left = 540
        Top = 40
        Width = 200
        Height = 23
        TabOrder = 5
      end
      object ckValidar: TCheckBox
        Left = 12
        Top = 86
        Width = 150
        Height = 17
        Caption = 'Validar certificado'
        TabOrder = 6
      end
      object lbPin: TLabel
        Left = 170
        Top = 68
        Width = 320
        Height = 15
        Caption = 'Pin do certificado (SHA-256, opcional - aceita s'#243' aquele certificado)'
      end
      object edPin: TEdit
        Left = 170
        Top = 86
        Width = 400
        Height = 23
        TabOrder = 7
      end
      object lbConexao: TLabel
        Left = 580
        Top = 68
        Width = 200
        Height = 15
        Caption = 'Conex'#227'o QUIC (ShareConnection)'
      end
      object cbConexao: TComboBox
        Left = 580
        Top = 86
        Width = 300
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 8
        Text = 'Uma conex'#227'o por thread'
        Items.Strings = (
          'Uma conex'#227'o por thread'
          'Uma conex'#227'o por cliente, multiplexada')
      end
    end
  end
  object pgAbas: TPageControl
    Left = 0
    Top = 130
    Width = 980
    Height = 510
    ActivePage = tsBench
    Align = alClient
    TabOrder = 1
    object tsBench: TTabSheet
      Caption = 'Benchmark'
      object pnBenchTopo: TPanel
        Left = 0
        Top = 0
        Width = 972
        Height = 150
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lbClientes: TLabel
          Left = 12
          Top = 10
          Width = 105
          Height = 15
          Caption = 'Clientes (m'#225'quinas)'
        end
        object edClientes: TEdit
          Left = 12
          Top = 28
          Width = 100
          Height = 23
          TabOrder = 0
          Text = '10'
        end
        object lbSimultaneas: TLabel
          Left = 124
          Top = 10
          Width = 128
          Height = 15
          Caption = 'Simult'#226'neas por cliente'
        end
        object edSimultaneas: TEdit
          Left = 124
          Top = 28
          Width = 100
          Height = 23
          TabOrder = 1
          Text = '3'
        end
        object lbRajadas: TLabel
          Left = 270
          Top = 10
          Width = 44
          Height = 15
          Caption = 'Rajadas'
        end
        object edRajadas: TEdit
          Left = 270
          Top = 28
          Width = 100
          Height = 23
          TabOrder = 2
          Text = '50'
        end
        object lbRota: TLabel
          Left = 382
          Top = 10
          Width = 26
          Height = 15
          Caption = 'Rota'
        end
        object cbRota: TComboBox
          Left = 382
          Top = 28
          Width = 100
          Height = 23
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 3
          Text = 'ping'
          Items.Strings = (
            'ping'
            'lento')
        end
        object btIniciar: TButton
          Left = 504
          Top = 26
          Width = 100
          Height = 27
          Caption = 'Iniciar'
          TabOrder = 4
          OnClick = btIniciarClick
        end
        object btParar: TButton
          Left = 612
          Top = 26
          Width = 100
          Height = 27
          Caption = 'Parar'
          TabOrder = 5
          OnClick = btPararClick
        end
        object pbProgresso: TProgressBar
          Left = 12
          Top = 60
          Width = 666
          Height = 17
          TabOrder = 6
        end
        object lbEnviadas: TLabel
          Left = 12
          Top = 86
          Width = 200
          Height = 15
          Caption = 'Enviadas: 0'
        end
        object lbErros: TLabel
          Left = 270
          Top = 86
          Width = 200
          Height = 15
          Caption = 'Erros: 0'
        end
        object lbVazao: TLabel
          Left = 470
          Top = 86
          Width = 200
          Height = 15
          Caption = 'Vaz'#227'o: -'
        end
        object lbTempos: TLabel
          Left = 12
          Top = 108
          Width = 400
          Height = 15
          Caption = 'Tempo de resposta: -'
        end
        object lbDecorrido: TLabel
          Left = 470
          Top = 108
          Width = 200
          Height = 15
          Caption = 'Decorrido: -'
        end
      end
      object mmBench: TMemo
        Left = 0
        Top = 150
        Width = 972
        Height = 330
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
    end
    object tsTestes: TTabSheet
      Caption = 'Testes'
      object pnTestesTopo: TPanel
        Left = 0
        Top = 0
        Width = 972
        Height = 44
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object btPing: TButton
          Left = 12
          Top = 8
          Width = 110
          Height = 27
          Caption = 'Ping pong'
          TabOrder = 0
          OnClick = btPingClick
        end
        object btParams: TButton
          Left = 130
          Top = 8
          Width = 110
          Height = 27
          Caption = 'Par'#226'metros'
          TabOrder = 1
          OnClick = btParamsClick
        end
        object btMultipart: TButton
          Left = 248
          Top = 8
          Width = 110
          Height = 27
          Caption = 'Multipart'
          TabOrder = 2
          OnClick = btMultipartClick
        end
        object btEco: TButton
          Left = 366
          Top = 8
          Width = 110
          Height = 27
          Caption = 'Eco (20 KB)'
          TabOrder = 3
          OnClick = btEcoClick
        end
        object btLimpar: TButton
          Left = 484
          Top = 8
          Width = 110
          Height = 27
          Caption = 'Limpar'
          TabOrder = 4
          OnClick = btLimparClick
        end
      end
      object mmTestes: TMemo
        Left = 0
        Top = 44
        Width = 972
        Height = 436
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 1
      end
    end
    object tsBanco: TTabSheet
      Caption = 'Banco (Firebird)'
      object pnBancoTopo: TPanel
        Left = 0
        Top = 0
        Width = 972
        Height = 44
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lbSQL: TLabel
          Left = 12
          Top = 14
          Width = 23
          Height = 15
          Caption = 'SQL'
        end
        object edSQL: TEdit
          Left = 44
          Top = 10
          Width = 600
          Height = 23
          TabOrder = 0
          Text = 'select * from BENCH order by ID'
        end
      end
      object pnDAO: TPanel
        Left = 0
        Top = 44
        Width = 484
        Height = 436
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 1
        object pnDAOTopo: TPanel
          Left = 0
          Top = 0
          Width = 484
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          Caption = ''
          TabOrder = 0
          object btAbrirDAO: TButton
            Left = 8
            Top = 6
            Width = 110
            Height = 27
            Caption = 'DAO: Open'
            TabOrder = 0
            OnClick = btAbrirDAOClick
          end
          object btGravarDAO: TButton
            Left = 124
            Top = 6
            Width = 130
            Height = 27
            Caption = 'DAO: ApplyUpdates'
            TabOrder = 1
            OnClick = btGravarDAOClick
          end
          object lbDAO: TLabel
            Left = 262
            Top = 12
            Width = 200
            Height = 15
            Caption = 'TRALFDQuery'
          end
        end
        object gridDAO: TDBGrid
          Left = 0
          Top = 40
          Width = 484
          Height = 396
          Align = alClient
          DataSource = dsDAO
          TabOrder = 1
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = 'Segoe UI'
          TitleFont.Style = []
        end
      end
      object spBanco: TSplitter
        Left = 484
        Top = 44
        Width = 4
        Height = 436
      end
      object pnDBW: TPanel
        Left = 488
        Top = 44
        Width = 484
        Height = 436
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 2
        object pnDBWTopo: TPanel
          Left = 0
          Top = 0
          Width = 484
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          Caption = ''
          TabOrder = 0
          object btAbrirDBW: TButton
            Left = 8
            Top = 6
            Width = 110
            Height = 27
            Caption = 'DBWare: Open'
            TabOrder = 0
            OnClick = btAbrirDBWClick
          end
          object btGravarDBW: TButton
            Left = 124
            Top = 6
            Width = 150
            Height = 27
            Caption = 'DBWare: ApplyUpdates'
            TabOrder = 1
            OnClick = btGravarDBWClick
          end
          object lbDBW: TLabel
            Left = 282
            Top = 12
            Width = 200
            Height = 15
            Caption = 'TRALDBFDMemTable'
          end
        end
        object gridDBW: TDBGrid
          Left = 0
          Top = 40
          Width = 484
          Height = 396
          Align = alClient
          DataSource = dsDBW
          TabOrder = 1
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = 'Segoe UI'
          TitleFont.Style = []
        end
      end
    end
  end
  object dsDAO: TDataSource
    Left = 880
    Top = 560
  end
  object dsDBW: TDataSource
    Left = 920
    Top = 560
  end
  object tmBench: TTimer
    Enabled = False
    Interval = 250
    OnTimer = tmBenchTimer
    Left = 840
    Top = 560
  end
end
