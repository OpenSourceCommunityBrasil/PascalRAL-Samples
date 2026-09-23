object fPrincipal: TfPrincipal
  Left = 0
  Top = 0
  Caption = 'PascalRAL - Demo HTTP/2'
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
  object pcPrincipal: TPageControl
    Left = 0
    Top = 0
    Width = 980
    Height = 640
    ActivePage = tsServidor
    Align = alClient
    TabOrder = 0
    object tsServidor: TTabSheet
      Caption = '1. Servidor'
      object gbConfig: TGroupBox
        Left = 12
        Top = 12
        Width = 944
        Height = 110
        Caption = ' Como o servidor vai escutar '
        TabOrder = 0
        object lbModo: TLabel
          Left = 16
          Top = 28
          Width = 33
          Height = 15
          Caption = 'Modo:'
        end
        object lbPorta: TLabel
          Left = 540
          Top = 28
          Width = 32
          Height = 15
          Caption = 'Porta:'
        end
        object lbEstado: TLabel
          Left = 16
          Top = 78
          Width = 40
          Height = 15
          Caption = 'parado'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clMaroon
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object cbModo: TComboBox
          Left = 58
          Top = 24
          Width = 466
          Height = 23
          Style = csDropDownList
          TabOrder = 0
          OnChange = cbModoChange
        end
        object edPorta: TEdit
          Left = 578
          Top = 24
          Width = 66
          Height = 23
          TabOrder = 1
          Text = '8443'
        end
        object chTLS: TCheckBox
          Left = 660
          Top = 26
          Width = 150
          Height = 17
          Caption = 'TLS (exigido pelo HTTP/2)'
          Checked = True
          State = cbChecked
          TabOrder = 2
        end
        object btLigar: TButton
          Left = 826
          Top = 22
          Width = 100
          Height = 27
          Caption = 'Ligar'
          TabOrder = 3
          OnClick = btLigarClick
        end
        object btPreparar: TButton
          Left = 660
          Top = 70
          Width = 266
          Height = 27
          Caption = 'Preparar HTTP/2 nesta maquina (pede admin)'
          TabOrder = 4
          OnClick = btPrepararClick
        end
      end
      object mmLog: TMemo
        Left = 12
        Top = 132
        Width = 944
        Height = 460
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
    object tsRotas: TTabSheet
      Caption = '2. Rotas'
      ImageIndex = 1
      object gbRotas: TGroupBox
        Left = 12
        Top = 12
        Width = 944
        Height = 70
        Caption = ' Chamar uma rota do servidor '
        TabOrder = 0
        object btPing: TButton
          Left = 16
          Top = 26
          Width = 150
          Height = 29
          Caption = 'GET /ping'
          TabOrder = 0
          OnClick = btPingClick
        end
        object btSoma: TButton
          Left = 180
          Top = 26
          Width = 190
          Height = 29
          Caption = 'GET /soma?a=40&b=2'
          TabOrder = 1
          OnClick = btSomaClick
        end
        object btItens: TButton
          Left = 384
          Top = 26
          Width = 190
          Height = 29
          Caption = 'GET /itens (le o banco)'
          TabOrder = 2
          OnClick = btItensClick
        end
        object btErro: TButton
          Left = 588
          Top = 26
          Width = 190
          Height = 29
          Caption = 'GET /erro (estoura de proposito)'
          TabOrder = 3
          OnClick = btErroClick
        end
      end
      object mmRotas: TMemo
        Left = 12
        Top = 92
        Width = 944
        Height = 500
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
      Caption = '3. Banco: DAO e DBWare'
      ImageIndex = 2
      object lbBanco: TLabel
        Left = 12
        Top = 574
        Width = 34
        Height = 15
        Caption = 'banco:'
      end
      object gbDAO: TGroupBox
        Left = 12
        Top = 12
        Width = 466
        Height = 552
        Caption = ' DAO - TRALFDQuery sobre TRALFDConnection '
        TabOrder = 0
        object mmSQLDAO: TMemo
          Left = 12
          Top = 24
          Width = 442
          Height = 60
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object btAbrirDAO: TButton
          Left = 12
          Top = 92
          Width = 140
          Height = 27
          Caption = 'Abrir (OpenRemote)'
          TabOrder = 1
          OnClick = btAbrirDAOClick
        end
        object btGravarDAO: TButton
          Left = 162
          Top = 92
          Width = 180
          Height = 27
          Caption = 'Gravar (ApplyUpdatesRemote)'
          TabOrder = 2
          OnClick = btGravarDAOClick
        end
        object grDAO: TDBGrid
          Left = 12
          Top = 128
          Width = 442
          Height = 412
          DataSource = dsDAO
          TabOrder = 3
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = 'Segoe UI'
          TitleFont.Style = []
        end
      end
      object gbDBWare: TGroupBox
        Left = 490
        Top = 12
        Width = 466
        Height = 552
        Caption = ' DBWare - TRALDBFDMemTable sobre TRALDBModule '
        TabOrder = 1
        object mmSQLDBWare: TMemo
          Left = 12
          Top = 24
          Width = 442
          Height = 60
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object btAbrirDBWare: TButton
          Left = 12
          Top = 92
          Width = 140
          Height = 27
          Caption = 'Abrir'
          TabOrder = 1
          OnClick = btAbrirDBWareClick
        end
        object btGravarDBWare: TButton
          Left = 162
          Top = 92
          Width = 180
          Height = 27
          Caption = 'Gravar (ApplyUpdates)'
          TabOrder = 2
          OnClick = btGravarDBWareClick
        end
        object grDBWare: TDBGrid
          Left = 12
          Top = 128
          Width = 442
          Height = 412
          DataSource = dsDBWare
          TabOrder = 3
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -12
          TitleFont.Name = 'Segoe UI'
          TitleFont.Style = []
        end
      end
    end
    object tsVelocidade: TTabSheet
      Caption = '4. HTTP/1.1 x HTTP/2'
      ImageIndex = 3
      object gbCenario: TGroupBox
        Left = 12
        Top = 12
        Width = 944
        Height = 104
        Caption = ' Matriz ShareConnection x HTTPVersion '
        TabOrder = 0
        object lbClientes: TLabel
          Left = 16
          Top = 32
          Width = 52
          Height = 15
          Caption = 'Clientes:'
        end
        object lbPedidos: TLabel
          Left = 148
          Top = 32
          Width = 116
          Height = 15
          Caption = 'Pedidos por cliente:'
        end
        object lbSimultaneos: TLabel
          Left = 344
          Top = 32
          Width = 76
          Height = 15
          Caption = 'Simultaneos:'
        end
        object lbLatencia: TLabel
          Left = 496
          Top = 32
          Width = 160
          Height = 15
          Caption = 'Custo de abrir conexao (ms):'
        end
        object lbPausa: TLabel
          Left = 16
          Top = 66
          Width = 154
          Height = 15
          Caption = 'Pausa entre rodadas (ms):'
        end
        object edPausa: TEdit
          Left = 176
          Top = 62
          Width = 48
          Height = 23
          TabOrder = 4
          Text = '600'
        end
        object lbAviso: TLabel
          Left = 240
          Top = 66
          Width = 676
          Height = 15
          Caption = 
            'Para HTTP/2 de verdade: modo HTTP.sys + TLS (aba 1, botao Prepara' +
            'r). Sem isso as quatro celulas medem HTTP/1.1.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edClientes: TEdit
          Left = 84
          Top = 28
          Width = 48
          Height = 23
          TabOrder = 0
          Text = '40'
        end
        object edPedidos: TEdit
          Left = 280
          Top = 28
          Width = 48
          Height = 23
          TabOrder = 1
          Text = '10'
        end
        object edSimultaneos: TEdit
          Left = 432
          Top = 28
          Width = 48
          Height = 23
          TabOrder = 2
          Text = '10'
        end
        object edLatencia: TEdit
          Left = 658
          Top = 28
          Width = 48
          Height = 23
          TabOrder = 3
          Text = '120'
        end
        object btComparar: TButton
          Left = 724
          Top = 26
          Width = 130
          Height = 27
          Caption = 'Medir as quatro'
          TabOrder = 5
          OnClick = btCompararClick
        end
      end
      object sgResultado: TRALGradeLeitura
        Left = 12
        Top = 118
        Width = 944
        Height = 142
        ColCount = 6
        DefaultRowHeight = 22
        FixedCols = 0
        RowCount = 6
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
        TabOrder = 1
      end
      object pbGrafico: TPaintBox
        Left = 12
        Top = 264
        Width = 944
        Height = 196
        OnPaint = pbGraficoPaint
      end
      object mmExplica: TMemo
        Left = 12
        Top = 468
        Width = 944
        Height = 128
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 2
      end
    end
  end
  object dsDAO: TDataSource
    Left = 420
    Top = 60
  end
  object dsDBWare: TDataSource
    Left = 900
    Top = 60
  end
end
