object fprincipal: Tfprincipal
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Bridge'
  ClientHeight = 225
  ClientWidth = 582
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 13
  object PageControl1: TPageControl
    AlignWithMargins = True
    Left = 50
    Top = 3
    Width = 529
    Height = 219
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Servidor'
      object Label1: TLabel
        Left = 16
        Top = 8
        Width = 30
        Height = 13
        Caption = 'Porta:'
      end
      object bIniciarServer: TSpeedButton
        Left = 204
        Top = 128
        Width = 121
        Height = 41
        Caption = 'Iniciar'
        OnClick = bIniciarServerClick
      end
      object Label2: TLabel
        Left = 16
        Top = 34
        Width = 67
        Height = 13
        Caption = 'Autentica'#231#227'o:'
      end
      object eServerPorta: TEdit
        Left = 89
        Top = 5
        Width = 121
        Height = 21
        NumbersOnly = True
        TabOrder = 0
      end
      object RadioButton1: TRadioButton
        Left = 89
        Top = 32
        Width = 56
        Height = 17
        Caption = 'JWT'
        Checked = True
        TabOrder = 1
        TabStop = True
      end
      object RadioButton2: TRadioButton
        Left = 151
        Top = 32
        Width = 56
        Height = 17
        Caption = 'Basic'
        TabOrder = 2
      end
      object RadioButton3: TRadioButton
        Left = 216
        Top = 32
        Width = 65
        Height = 17
        Caption = 'Nenhuma'
        TabOrder = 3
      end
      object CheckBox1: TCheckBox
        Left = 16
        Top = 60
        Width = 129
        Height = 17
        Caption = 'Adicionar Swagger'
        TabOrder = 4
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Usu'#225'rios'
      ImageIndex = 1
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 521
        Height = 34
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitWidth = 530
        object Label3: TLabel
          Left = 8
          Top = 9
          Width = 40
          Height = 13
          Caption = 'Usu'#225'rio:'
        end
        object Label4: TLabel
          Left = 216
          Top = 9
          Width = 34
          Height = 13
          Caption = 'Senha:'
        end
        object bGravarUsuario: TSpeedButton
          Left = 423
          Top = 5
          Width = 90
          Height = 23
          Caption = 'Gravar'
        end
        object eUserUsuario: TEdit
          Left = 54
          Top = 5
          Width = 155
          Height = 21
          TabOrder = 0
        end
        object ePassUsuario: TEdit
          Left = 262
          Top = 5
          Width = 155
          Height = 21
          TabOrder = 1
        end
      end
      object DBGrid1: TDBGrid
        Left = 0
        Top = 34
        Width = 521
        Height = 157
        Align = alClient
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'Tahoma'
        TitleFont.Style = []
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 47
    Height = 225
    Align = alLeft
    BevelOuter = bvNone
    Color = 16744448
    ParentBackground = False
    TabOrder = 1
    object Image1: TImage
      Left = 7
      Top = 7
      Width = 32
      Height = 32
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D49484452000000200000
        00200806000000737A7AF40000001974455874536F6674776172650041646F62
        6520496D616765526561647971C9653C000008AC4944415478DAAD970D5093F7
        1DC7BFCF6B9227892090F0A2022AA8880A8254ADD7A9B5EB6EB5B86EB5375BCF
        76EEDC5D777BF16A6BBBCEAE753BAB763BDD61CF2B6EADF3BAB9EABA595D9DAD
        2FB5D6D75A2D0C4410310410480242024908499EE7C97ECF1350D66A0B6DB9FB
        DD2326FEBF9FDFF7F7F27F6430F21FF1E4931961296D0C2C661650238884FA21
        1862C87BFE8A813E8F8CE4306604DF652FACC95F2E08CC5363F3126726E7E502
        BD7EC48201C4FA0208FAFD68BC1EAA9463EA1F67BD7C6D377D5FFD460056CEB6
        9B5716F101299532B652C67204FDC110384185A5DF0DC3A851686CE52026D961
        B5B060D428FA437D908C2C361F7459769EF606BF0A00FBF1EA8255263EF63396
        C18CB4E90948C99B4419F7201608420DFA110CF8E16B6D8248005C4A366C7939
        00B9A00E7C1EA0EFB67BC81D46AD0EC9ECF6920DCED76FE7CA9D00A49A670A82
        49F993913E350135E57FA64C5908162B3D2D70B4F2B09023A2A08091C3E8EF0B
        C2606260EA7341B45A214A1204930189D34BE06EF2A2B7A501939FAB35D3B97D
        C30548AE5B3FFF46E6FD73214DB90B5D4777C377FE005851248004F06939B04F
        99A83BA2F4F642A66730D0079F9B1C319B61B098619DF503180B1E043C756878
        772726ADF93485CEED1A2E80BDE699224F428203308CC6A882C514F752FD3D24
        EAC0A5DF6F813181056FB140B468199BC01B0D183DE7DB40523E60CD85DA741A
        4AFD7E70D11ED43BA298FA52532A9DDB317C80674B3C49B65628B28A982C5357
        08304C9887D1B31F86BFFA08BC67FF01965521489471A20DD6B98FC138610E94
        DAFD509B3FA26A2B6079119C68C0D5DA2E4C7EB171E400B68C0E280AFD168BD1
        812A54398A1875B990F92D980BBF0B4B5A22C09BA8B221280D8749F824181205
        47EB80E32904F0020F47452B72D68F14606D892775BC8F4435FD980E1123082D
        3395FE52838972E918FFF876C8479E20100B85A88B322C478E71600882E57938
        CFD5A37C5A0A4C6071FCCDAB9653077DC16100147BC6E4F641735F17D7203008
        436E283262E13EA43F4200173752E6461217756122D09F2C47108208E7894AFC
        EB411B949E18426E1F5846A98ECACCF60D2B9DAFDF11E0CAD3059E8C690AA251
        668870EC160C39A14442485DFC3B28756F90E060F624CE0C3AA00118D078E434
        76DD930A898E9A909544101C3A3A9BF1ECD25AF31D015AD64CF4A4164B88C89C
        DE0771ED2100144AB41FB67B5743751E88D79DA5BA1300C368E2AC0EA495C571
        E03DEC5A60C7DCEC459899BD106E8F0B1F55EEC0530F55A4DC09C0B669ED4F0F
        7F3FE9E2CC6C3BED7B83014A8CA3DA33F155A6C6FB412580A4BB7F0CD5738A32
        176FD65D07D100A839DDED2EF82795409A713F9CCD95A86A7C1FFD720F2D2F2F
        5E58D6943A148059F0F49F32C74D2E6AB2252590A356F86511D33A0E6151C736
        64DA7B21584D90C19138434004118D2061D652C077591F53F09CDEFD918E4EB4
        3ADB10295C047EE67CD4351CC7B5B6D3944004022F90313C7ABADD58F7C3461D
        805DBCF9D02A5630BEA4A86AC6E23985C8CB4E869796A6B79FCE8E02ED7EAD2B
        FF82C537CA9199EC8531D90C991C516405D6A2072853172030E86F6CC2A51A1F
        B21E7A14EE716371D579128EF633104994D72682CAA335264F93D1E96EB90920
        956E3911CCCF4EC5B8AC29F8CFE9B3B0D02E371B25486609816E174659E8C231
        5A11500D98E23A80FBDCDB312ED1472046B276017C551568B91E414DCE2FF09A
        AB04BB5779B0F7D4CF295B735C984439AD37E866631846DF0DAE6627D62D8B03
        242F7FEDD48D65F373916D4FC407D51E9C6FF4431405188D22F2ED1239624737
        39D21D023AC9150F4D71FAE51DF88EFB55729C4168C18BB4091F412818C6CB7B
        2E61D3D24B3876F955CA5C8A8F2289B29AB8161C03819AB3F95A03F5401CC05E
        BAE5434F7AC61818791577659B303D6B343A4256B491F57B8F9E81D56CA1FBDD
        044932C26434432437325345D0446162828AEB1D01D4B4461151381C3C538B6D
        4F9CC739C71E72C0A48FA526CC32030E5073F2228FC69ABA5B00DFDBFAA1272B
        2B0B91A8025951C1D38E9F6CE730372711D5D78338D510A07F6C2047E88AB548
        989F2B22CF26A3A64DC1155AAE0A35254F9989B474F69FB884571E3F8AEAB623
        74CE2D002D38BD07340001572AAAFF1F20272797B61E6D371A3195369D4C4F6A
        4A4C18ADA2708C1129B60C1839197C2C885AB7827A4FFC408ED3B2A33FD3C102
        CDFCDBC7AAB061C53F71ED4605D92EEA996BA25A703C0B392AA3B3BD337AE158
        EB1FDE7CC5B5550758B2F5B8273F6F9AFEA1264E03464F0A351E11DAFB08FBB1
        6E491EFE76D14F4274181BAFAB261EAF310190037BDEAFC4FA153BD1D6EB2451
        919C89AFE43E7F10ED2D1DE18FDF6BDFB6AFBCF35DD2A5D1417B1C60CB714FC1
        8C2272204A82EAC0DE8F6F3C2D1482E8A7917BF2EE341CB91AA02662E34DC5DC
        0A0DC0201AF1D7839FE0373FDA066FA8873236A0DB4DAF664E77B8E26457D9BE
        728F267C83A29B823A0CE18126FCC053523C9BF67E54DF70B181DD3F189A0B61
        02585E9C84B3CDE19BB60F0A330325D07A60D7814FF0DC8ADFA2D1E185ABC51B
        AE39EB2BDBB7C3FD39610CBC1FDE7460DEDC7B1089680E2871178638A0F54584
        A274AA05552E592FC167B3E7C866A381C11BFB2E625EDA9270D5B958D93B5F20
        3CF43A4E9EF393CD6B0AE62F593B764CB620D27B9F1C23089A06FDDAD5763E41
        44E9CD68618E0487578DD75F13D64BA16D36201496515BDF143EF6CEDEB2EAB7
        5EF852E1A100124506457AE1A3BF2A9DBEF0E15F66664D34248C4A8CBBA1DFFD
        044020B3C7897005A0DBAD8D9D26DCD1E547555D43F8C2E1B7CBAAF76E1EB6F0
        5000BAB6A0FD97CA4A41AB0529331F7BBE74C2EC07568F1F3FD1906A4BD3C731
        4A8E146408F0D3400874EF343477A2B2B63E7CEDECA1B2FFBEB569C4C2B77B23
        FA1C48D1F25F976616DFB77AECD82C437A7A26A6A4F1F8F44A0B2E5F75849B2F
        1E23E18D5F59F876007704295EBE6E497AE1C235DA55DA7CE1F0D68ABF6FFCF7
        D715FE2280DB81240FC06040B4EBEB0A0F07E0B320A681DF43DF84F0E0CFFF00
        00D7003576A54B920000000049454E44AE426082}
    end
  end
  object pooler: TRALSynopseServer
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
    CORSOptions.AllowOrigin = '*'
    CORSOptions.MaxAge = 86400
    CriptoOptions.CriptType = crNone
    IPConfig.IPv4Bind = '0.0.0.0'
    IPConfig.IPv6Bind = '::'
    IPConfig.IPv6Enabled = False
    ResponsePages = <
      item
        StatusCode = 400
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.1' +
            '0-4 alpha</title></head><body><h1>400 - BadRequest</h1><p>The se' +
            'rver informs that it doesn'#39't like the input params</p></body></h' +
            'tml>')
      end
      item
        StatusCode = 401
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.1' +
            '0-4 alpha</title></head><body><h1>401 - Unauthorized</h1><p>The ' +
            'server informs that it doesn'#39't know you</p></body></html>')
      end
      item
        StatusCode = 403
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.1' +
            '0-4 alpha</title></head><body><h1>403 - Forbidden</h1><p>The ser' +
            'ver informs that it doesn'#39't want you to access</p></body></html>')
      end
      item
        StatusCode = 404
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.1' +
            '0-4 alpha</title></head><body><h1>404 - Not Found</h1><p>The ser' +
            'ver informs that the page you'#39're requesting doesn'#39't exist in thi' +
            's reality</p></body></html>')
      end
      item
        StatusCode = 415
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.1' +
            '0-4 alpha</title></head><body><h1>415 - Unsuported Media Type</h' +
            '1><p>The server informs that it doesn'#39't know what you'#39're asking<' +
            '/p></body></html>')
      end
      item
        StatusCode = 500
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.1' +
            '0-4 alpha</title></head><body><h1>500 - Internal Server Error</h' +
            '1><p>The server made something that it shouldn'#39't</p></body></htm' +
            'l>')
      end
      item
        StatusCode = 501
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.1' +
            '0-4 alpha</title></head><body><h1>501 - Not Implemented</h1><p>T' +
            'he server informs that it doesn'#39't exist</p></body></html>')
      end
      item
        StatusCode = 503
        Page.Strings = (
          
            '<!DOCTYPE html><html lang="en-US"><head><title>RALServer - 0.9.1' +
            '0-4 alpha</title></head><body><h1>503 - Service Unavailable</h1>' +
            '<p>The server informs that it doesn'#39't want to work now and you s' +
            'hould try later</p></body></html>')
      end>
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
    Left = 480
    Top = 120
  end
  object jwt: TRALServerJWTAuth
    Algorithm = tjaHSHA256
    AuthRoute.Description.Strings = (
      'Get a JWT Token')
    AuthRoute.InputParams = <>
    AuthRoute.Route = '/gettoken'
    ExpirationSecs = 1800
    JSONKey = 'token'
    Left = 376
    Top = 80
  end
  object basic: TRALServerBasicAuth
    AuthDialog = True
    Left = 424
    Top = 128
  end
  object swagger: TRALSwaggerModule
    Server = pooler
    Domain = '/swagger'
    AllowCORSVerbs = False
    PostmanTag = False
    ShowCustomNames = False
    Left = 286
    Top = 99
  end
end
