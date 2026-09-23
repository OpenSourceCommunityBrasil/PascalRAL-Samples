/// Servidor do benchmark HTTP/2 do PascalRAL.
///
/// E' o mesmo benchmark do QuicBenchmark ao lado, com os motores trocados: aqui
/// o servidor e' o TRALSynopseServer (mORMot2) e o cliente e' o netHTTP. As
/// rotas, o banco e a tela sao os mesmos, de proposito - o que muda e' o
/// transporte, e e' isso que esta' sendo comparado.
///
/// Sobe as rotas que o cliente usa (ping, params, multipart, eco, lento),
/// publica o banco Firebird pelos DOIS stacks de banco do RAL - o DAO
/// (TRALFDConnection, consumido por TRALFDQuery) e o DBWare (TRALDBModule,
/// consumido por TRALDBFDMemTable) - e cria o banco de teste com 2000
/// registros quando ele nao existe.
///
/// HTTP/2 SO' EXISTE NO MODO http.sys, e so' sobre TLS. mORMot2 nao tem HTTP/2
/// proprio: quem tem e' o kernel do Windows. E o certificado desse modo nao vem
/// de arquivo nenhum - mora na loja da maquina, amarrado a' porta pelo "netsh
/// http add sslcert" que o botao "Preparar http.sys" roda elevado, uma vez. Os
/// outros dois modos sobem em http simples, e servem de linha de base HTTP/1.1.
unit UServidor;

interface

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.Classes,
  System.SyncObjs, System.DateUtils, System.IOUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Phys,
  FireDAC.Phys.IBBase, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Comp.Client, FireDAC.Comp.DataSet,

  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse,
  RALParams, RALCompress, RALCompressZLib, RALCripto, RALCriptoAES,
  RALSynopseServer,
  { os storages so' existem no executavel que os liga - sem RALStorageBIN o
    DBWare responde "Storage 1 not declared in uses" a todo opensql }
  RALStorage, RALStorageBIN, RALStorageJSON,
  RALDBModule, RALDBBase, RALDBFireDAC, RALDBFiredacDAO;

type
  TfServidor = class(TForm)
    pnTopo: TPanel;
    gbServidor: TGroupBox;
    lbPorta: TLabel;
    edPorta: TEdit;
    lbPool: TLabel;
    edPool: TEdit;
    lbModo: TLabel;
    cbModo: TComboBox;
    lbDominio: TLabel;
    edDominio: TEdit;
    btPreparar: TButton;
    lbCompress: TLabel;
    cbCompress: TComboBox;
    lbCripto: TLabel;
    cbCripto: TComboBox;
    lbChaveCripto: TLabel;
    edChaveCripto: TEdit;
    btLigar: TButton;
    lbStatus: TLabel;
    lbDica: TLabel;
    gbFirebird: TGroupBox;
    lbFBHost: TLabel;
    edFBHost: TEdit;
    lbFBPorta: TLabel;
    edFBPorta: TEdit;
    lbFBBanco: TLabel;
    edFBBanco: TEdit;
    lbFBUsuario: TLabel;
    edFBUsuario: TEdit;
    lbFBSenha: TLabel;
    edFBSenha: TEdit;
    btCriarBanco: TButton;
    lbBanco: TLabel;
    mmLog: TMemo;
    tmContadores: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btLigarClick(Sender: TObject);
    procedure btPrepararClick(Sender: TObject);
    procedure btCriarBancoClick(Sender: TObject);
    procedure cbModoChange(Sender: TObject);
    procedure tmContadoresTimer(Sender: TObject);
  private
    FServer: TRALSynopseServer;
    FConnDAO: TRALFDConnection;
    FModulo: TRALDBModule;
    { Contadas no OnRequest do servidor, que e' o unico lugar por onde passa
      TUDO - rota, DAO e DBWare -, e por isso mesmo roda em thread de engine:
      incremento atomico ali, leitura no timer. }
    FRequisicoes: Integer;
    FEmH2: Integer;
    { As conexoes distintas que trouxeram essas requisicoes, pela identidade que
      o engine da' em ClientInfo.ConnectionID. A RAZAO entre as duas e' o que
      prova a multiplexacao: 1500 requisicoes em 1 conexao e' h2 fazendo o que
      existe para fazer; 1500 em 30 e' uma conexao por thread.

      Array fixo, e a busca roda SEM TRAVA: o caminho comum e' "ja' vista", com
      um punhado de entradas para varrer, e por uma medicao nao pode pagar um
      lock por requisicao - foi o que o proprio RAL aprendeu tirando os locks
      de TRALSecurity do caminho de cada requisicao. A trava so' aparece ao
      inserir uma conexao nova, que acontece uma vez por conexao; o valor e'
      escrito ANTES do contador subir, entao quem le' nunca ve' uma posicao
      pela metade. }
    FConexoes: array[0 .. 4095] of Int64;
    FConexoesCount: Integer;
    FConexoesCheias: Boolean;
    FLockConexoes: TCriticalSection;
    procedure Log(const ATexto: string);
    function ModoEscolhido: TRALSynopseMode;
    function NovaConexaoFB(ACriar: Boolean): TFDConnection;
    procedure CriarBanco;
    procedure Ligar;
    procedure Desligar;
    function ConectarDAO: Boolean;
    procedure AplicarConfiguracao;
    procedure ContaRequisicao(ARequest: TRALRequest; AResponse: TRALResponse);
    // rotas
    procedure RotaPing(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaParams(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaMultipart(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaEco(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaLenta(ARequest: TRALRequest; AResponse: TRALResponse);
  public
  end;

var
  fServidor: TfServidor;

implementation

{$R *.dfm}

const
  PORTA_PADRAO = 8443;
  ROTA_LENTA_MS = 50;
  REGISTROS = 2000;
  { O appid do netsh e' so' um rotulo, mas tem de ser o MESMO em toda maquina
    onde isto rodou, ou cada preparacao deixa uma amarracao orfa na porta. }
  APPID_NETSH = '{3f9a6c21-58d4-4e7b-9c10-6ad2be5f7413}';

{ ---------------------------------------------------------------- formulario }

procedure TfServidor.FormCreate(Sender: TObject);
var
  vPasta: string;
begin
  FLockConexoes := TCriticalSection.Create;
  vPasta := ExtractFilePath(ParamStr(0));
  edPorta.Text := IntToStr(PORTA_PADRAO);
  edPool.Text := '1';
  { '+' e NAO 'localhost', e a razao e' uma armadilha do http.sys que nao se
    anuncia: o certificado desta preparacao e' amarrado por ENDERECO
    (netsh ... ipport=), e um prefixo por NOME so' e' servido quando ha
    amarracao por SNI (netsh ... hostnameport=). Com so' a primeira, o TLS
    fecha, o pedido chega ao kernel e ele responde 503 sem entregar a
    ninguem - com a URL registrada e a fila ativa, o que faz o erro parecer
    do servidor. Medido com um HttpListener do .NET, sem RAL no meio: pelo
    nome, 503; pelo curinga forte, 200. O '+' tambem e' o que faz valer por
    qualquer interface, que e' o que um benchmark medido de outra maquina
    precisa. }
  edDominio.Text := '+';
  edFBBanco.Text := vPasta + 'benchmark.fdb';
  cbModo.ItemIndex := 2;
  cbCompress.ItemIndex := 0;
  cbCripto.ItemIndex := 0;
  cbModoChange(nil);
end;

procedure TfServidor.FormDestroy(Sender: TObject);
begin
  { Desligar primeiro: a trava ainda e' usada por qualquer requisicao que esteja
    a caminho, e o servidor so' para de aceitar quando ele para }
  Desligar;
  FreeAndNil(FLockConexoes);
end;

procedure TfServidor.Log(const ATexto: string);
begin
  mmLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + '  ' + ATexto);
end;

function TfServidor.ModoEscolhido: TRALSynopseMode;
begin
  case cbModo.ItemIndex of
    0: Result := smThreads;
    1: Result := smAsync;
  else
    Result := smHttpSys;
  end;
end;

{ O MODO MANDA NO TLS, e nao o contrario: o http.sys pega o certificado da loja
  da maquina, e os modos de socket o leriam de SSL.CertificateFile - que este
  benchmark nao tem. Dizer isso aqui e' mais barato do que deixar alguem
  descobrir na hora de subir, com "ESChannel AfterBind: no Certificate
  available". }
procedure TfServidor.cbModoChange(Sender: TObject);
begin
  edDominio.Enabled := ModoEscolhido = smHttpSys;
  btPreparar.Enabled := edDominio.Enabled;
  if ModoEscolhido = smHttpSys then
    lbDica.Caption := 'http.sys: https, e HTTP/2 pelo ALPN. Rode "Preparar http.sys" ' +
      'uma vez por porta. "+" vale por qualquer interface; um nome exige SNI.'
  else
    lbDica.Caption := 'Modo de socket: http simples, HTTP/1.1 - a linha de base. ' +
      'HTTP/2 so existe no modo http.sys.';
end;

{ --------------------------------------------------------------------- banco }

function TfServidor.NovaConexaoFB(ACriar: Boolean): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  Result.LoginPrompt := False;
  Result.Params.Clear;
  Result.Params.Add('DriverID=FB');
  Result.Params.Add('Server=' + edFBHost.Text);
  Result.Params.Add('Port=' + edFBPorta.Text);
  Result.Params.Add('Database=' + edFBBanco.Text);
  Result.Params.Add('User_Name=' + edFBUsuario.Text);
  Result.Params.Add('Password=' + edFBSenha.Text);
  Result.Params.Add('Protocol=TCPIP');
  Result.Params.Add('CharacterSet=UTF8');
  if ACriar then
    Result.Params.Add('CreateDatabase=Yes');
end;

{ Uma tabela com seis colunas de tipos diferentes - inteiro, texto, numerico
  com decimais, data e hora, booleano e texto longo - porque cada uma delas
  atravessa o fio de um jeito nos dois stacks de banco. }
procedure TfServidor.CriarBanco;
var
  vCon: TFDConnection;
  vQry: TFDQuery;
  vInt: Integer;
begin
  Log('criando ' + edFBBanco.Text + ' ...');
  vCon := NovaConexaoFB(not FileExists(edFBBanco.Text));
  try
    vCon.Connected := True;
    vQry := TFDQuery.Create(nil);
    try
      vQry.Connection := vCon;
      vQry.SQL.Text := 'select count(*) from RDB$RELATIONS where RDB$RELATION_NAME = ''BENCH''';
      vQry.Open;
      if vQry.Fields[0].AsInteger = 0 then
      begin
        vQry.Close;
        vQry.ExecSQL(
          'CREATE TABLE BENCH (' +
          '  ID INTEGER NOT NULL PRIMARY KEY,' +
          '  NOME VARCHAR(60),' +
          '  VALOR NUMERIC(15,2),' +
          '  DATA_CAD TIMESTAMP,' +
          '  ATIVO BOOLEAN,' +
          '  OBS VARCHAR(200))');
        vCon.Commit;
      end;

      vQry.Close;
      vQry.SQL.Text := 'select count(*) from BENCH';
      vQry.Open;
      if vQry.Fields[0].AsInteger >= REGISTROS then
      begin
        Log(Format('tabela BENCH ja' + ' tem %d registros', [vQry.Fields[0].AsInteger]));
        Exit;
      end;
      vQry.Close;

      { Array DML: um round trip para os 2000, em vez de 2000 }
      vQry.SQL.Text := 'insert into BENCH (ID, NOME, VALOR, DATA_CAD, ATIVO, OBS) ' +
                       'values (:ID, :NOME, :VALOR, :DATA_CAD, :ATIVO, :OBS)';
      vQry.Params.ArraySize := REGISTROS;
      for vInt := 0 to REGISTROS - 1 do
      begin
        vQry.Params[0].AsIntegers[vInt] := vInt + 1;
        vQry.Params[1].AsStrings[vInt] := Format('Cliente %.4d', [vInt + 1]);
        vQry.Params[2].AsCurrencys[vInt] := (vInt + 1) * 1.25;
        vQry.Params[3].AsDateTimes[vInt] := IncMinute(EncodeDate(2026, 1, 1), vInt * 7);
        vQry.Params[4].AsBooleans[vInt] := (vInt mod 3) <> 0;
        vQry.Params[5].AsStrings[vInt] := Format('Registro %d gerado pelo benchmark, com acentua'#231#227'o', [vInt + 1]);
      end;
      vCon.StartTransaction;
      vQry.Execute(REGISTROS, 0);
      vCon.Commit;
      Log(Format('tabela BENCH criada com %d registros', [REGISTROS]));
    finally
      vQry.Free;
    end;
  finally
    vCon.Free;
  end;
end;

procedure TfServidor.btCriarBancoClick(Sender: TObject);
begin
  try
    CriarBanco;
    lbBanco.Caption := 'banco pronto';
    { O DAO abre a conexao dele na subida do servidor. Criar o banco DEPOIS de
      ligar deixava o servidor no ar com a rota do DAO publicada e sem conexao,
      e a aba Banco do cliente respondendo erro ate' alguem desconfiar de que
      era preciso religar. Aqui a religacao e' de uma conexao so'. }
    if (FServer <> nil) and FServer.Active and (not FConnDAO.Connected) then
      if ConectarDAO then
        Log('DAO reconectado ao banco - a aba Banco do cliente ja' + #39 + ' responde');
  except
    on e: Exception do
    begin
      Log('ERRO ao criar o banco: ' + e.Message);
      lbBanco.Caption := 'erro - veja o log';
    end;
  end;
end;

{ ------------------------------------------------------------------ http.sys }

{ O certificado e a reserva de porta do http.sys precisam de direito de
  administrador. Em vez de exigir que o benchmark INTEIRO rode elevado - o que
  seria pior -, so' este passo sobe elevado, uma vez. Ele tambem grava pin.txt
  ao lado do executavel, porque a impressao digital e' o que o cliente pede no
  campo Pin para aceitar um autoassinado sem desligar a validacao.

  DUAS COISAS QUE ESTE SCRIPT APRENDEU NA PRATICA:

  1. Ele APAGA antes de amarrar. O netsh recusa uma amarracao que ja' existe
     ("Falha ao adicionar... ja existe"), e o efeito e' pior do que um erro: o
     certificado novo fica na loja, a porta continua com o VELHO, e a segunda
     preparacao parece nao ter feito nada.
  2. Ele amarra por ENDERECO (ipport 0.0.0.0 e [::], que valem para qualquer
     interface) E por NOME (hostnameport, que e' a amarracao por SNI). Sem a
     segunda, um prefixo por nome - https://localhost:porta/ - NAO e' servido:
     o TLS fecha, o pedido chega ao kernel e ele responde 503 sem entregar a
     ninguem, com a URL registrada e a fila ativa. Fica com cara de servidor
     quebrado e nao e': medido com um HttpListener do .NET, sem RAL no meio. }
procedure TfServidor.btPrepararClick(Sender: TObject);
var
  vArq, vCmd, vPasta: string;
  vPorta: Integer;
  vLista: TStringList;

  procedure Netsh(const ACmd: string);
  begin
    { cada netsh escreve o que fez e segue: um "ja existe" ou um "nao existe"
      no meio nao pode abortar o resto da preparacao }
    vLista.Add('Write-Host ("  " + ((' + ACmd + ' 2>&1) -join " "))');
  end;

begin
  vPorta := StrToIntDef(edPorta.Text, PORTA_PADRAO);
  vPasta := ExtractFilePath(ParamStr(0));
  vArq := TPath.Combine(TPath.GetTempPath, 'ral_bench_http2.ps1');
  vLista := TStringList.Create;
  try
    vLista.Add('$ErrorActionPreference = ''Continue''');
    vLista.Add('Write-Host "Preparando o http.sys para o benchmark HTTP/2 do PascalRAL..." -ForegroundColor Cyan');
    { o nome da maquina entra junto para um cliente da rede poder validar pelo
      nome; por IP, quem resolve e' o Pin }
    vLista.Add('$c = New-SelfSignedCertificate -DnsName ''localhost'', $env:COMPUTERNAME ' +
               '-CertStoreLocation Cert:\LocalMachine\My');
    vLista.Add('Write-Host "certificado: $($c.Thumbprint)"');
    vLista.Add('# confiavel nesta maquina, senao o cliente recusa o autoassinado');
    vLista.Add('$r = New-Object System.Security.Cryptography.X509Certificates.X509Store ''Root'',''LocalMachine''');
    vLista.Add('$r.Open(''ReadWrite''); $r.Add($c); $r.Close()');
    vLista.Add('$app = ''' + APPID_NETSH + '''');

    vLista.Add('Write-Host "limpando amarracoes anteriores da porta..."');
    Netsh(Format('netsh http delete sslcert ipport=0.0.0.0:%d', [vPorta]));
    Netsh(Format('netsh http delete sslcert "ipport=[::]:%d"', [vPorta]));
    Netsh(Format('netsh http delete sslcert ipport=127.0.0.1:%d', [vPorta]));
    Netsh(Format('netsh http delete sslcert "ipport=[::1]:%d"', [vPorta]));
    Netsh(Format('netsh http delete sslcert hostnameport=localhost:%d', [vPorta]));

    vLista.Add('Write-Host "amarrando o certificado..."');
    Netsh(Format('netsh http add sslcert ipport=0.0.0.0:%d certhash=$($c.Thumbprint) appid=$app', [vPorta]));
    Netsh(Format('netsh http add sslcert "ipport=[::]:%d" certhash=$($c.Thumbprint) appid=$app', [vPorta]));
    Netsh(Format('netsh http add sslcert hostnameport=localhost:%d certhash=$($c.Thumbprint) ' +
                 'appid=$app certstorename=MY', [vPorta]));

    vLista.Add('Write-Host "reservando as URLs..."');
    Netsh(Format('netsh http delete urlacl "url=https://+:%d/"', [vPorta]));
    Netsh(Format('netsh http add urlacl "url=https://+:%d/" user=$env:USERDOMAIN\$env:USERNAME', [vPorta]));
    Netsh(Format('netsh http delete urlacl url=https://localhost:%d/', [vPorta]));
    Netsh(Format('netsh http add urlacl url=https://localhost:%d/ user=$env:USERDOMAIN\$env:USERNAME', [vPorta]));

    vLista.Add('# a impressao digital do certificado, que e o campo Pin do cliente');
    vLista.Add('$sha = [System.Security.Cryptography.SHA256]::Create().ComputeHash($c.RawData)');
    vLista.Add('$pin = ($sha | ForEach-Object { $_.ToString("X2") }) -join '':''');
    vLista.Add(Format('Set-Content -Path "%spin.txt" -Value $pin -Encoding ascii', [vPasta]));
    vLista.Add('Write-Host ""');
    vLista.Add('Write-Host "Pin (SHA-256) para o campo Pin do cliente:" -ForegroundColor Yellow');
    vLista.Add('Write-Host $pin');
    vLista.Add(Format('Write-Host "gravado tambem em %spin.txt"', [vPasta]));
    vLista.Add('Write-Host "" ; Write-Host "Pronto. Pode fechar esta janela." -ForegroundColor Green');
    vLista.Add('Read-Host "ENTER para fechar"');
    vLista.SaveToFile(vArq, TEncoding.UTF8);
  finally
    vLista.Free;
  end;

  vCmd := Format('-NoProfile -ExecutionPolicy Bypass -File "%s"', [vArq]);
  { "runas" e' o que pede a elevacao ao Windows - e a elevacao abre janela
    propria, nao tem como ser na desta }
  ShellExecute(Handle, 'runas', 'powershell.exe', PChar(vCmd), nil, SW_SHOWNORMAL);

  Log('pedido de preparacao enviado (confirme o aviso do Windows)');
  Log(Format('o que ele faz, na porta %d: cria o certificado, torna confiavel, ' +
    'reamarra por endereco e por nome, reserva https://+ e https://localhost, ' +
    'e grava pin.txt aqui ao lado', [vPorta]));
end;

{ ------------------------------------------------------------------ servidor }

{ A conexao do DAO, que e' a UNICA do servidor que abre na hora - o DBWare pede
  a dele ao pool a cada requisicao, e por isso nem sabe que o banco faltava.

  Ela e' opcional PARA O BENCHMARK: /ping e /lento nao passam por banco nenhum,
  entao uma falha aqui nao pode derrubar o servidor - vira log, e so' a aba
  Banco do cliente fica sem resposta. }
function TfServidor.ConectarDAO: Boolean;
begin
  Result := False;
  try
    FConnDAO.Connected := False;
    FConnDAO.Params.Clear;
    FConnDAO.Params.Add('DriverID=FB');
    FConnDAO.Params.Add('Server=' + edFBHost.Text);
    FConnDAO.Params.Add('Port=' + edFBPorta.Text);
    FConnDAO.Params.Add('Database=' + edFBBanco.Text);
    FConnDAO.Params.Add('User_Name=' + edFBUsuario.Text);
    FConnDAO.Params.Add('Password=' + edFBSenha.Text);
    FConnDAO.Params.Add('Protocol=TCPIP');
    FConnDAO.Params.Add('CharacterSet=UTF8');
    FConnDAO.Connected := True;
    FConnDAO.RALServer := FServer;
    Result := True;
  except
    on e: Exception do
      Log('Firebird fora do ar para o DAO (' + e.Message + ') - as rotas ' +
          'funcionam, a aba Banco do cliente nao');
  end;
end;

procedure TfServidor.AplicarConfiguracao;
begin
  FServer.Port := StrToIntDef(edPorta.Text, PORTA_PADRAO);
  FServer.PoolCount := StrToIntDef(edPool.Text, 1);
  FServer.Mode := ModoEscolhido;
  { tem de ser o MESMO texto que a reserva do netsh usou: o http.sys casa
    prefixo por prefixo, e um "+" nao e' coberto por uma reserva de "localhost" }
  FServer.HttpSysDomain := StringRAL(edDominio.Text);
  { TLS so' onde este benchmark TEM certificado, que e' o http.sys - e sem TLS
    nao ha ALPN, logo nao ha HTTP/2 }
  FServer.SSL.Enabled := ModoEscolhido = smHttpSys;
  { O servidor decide a compressao da resposta quando CompressType nao e'
    ctNone; com ctNone quem decide e' o Accept-Encoding do cliente. }
  case cbCompress.ItemIndex of
    1: FServer.CompressType := ctGZip;
    2: FServer.CompressType := ctDeflate;
    3: FServer.CompressType := ctZLib;
  else
    FServer.CompressType := ctNone;
  end;
  case cbCripto.ItemIndex of
    1: FServer.CriptoOptions.CriptType := crAES128;
    2: FServer.CriptoOptions.CriptType := crAES192;
    3: FServer.CriptoOptions.CriptType := crAES256;
  else
    FServer.CriptoOptions.CriptType := crNone;
  end;
  FServer.CriptoOptions.Key := StringRAL(edChaveCripto.Text);
end;

procedure TfServidor.Ligar;
var
  vEsquema: string;
begin
  if (cbCripto.ItemIndex > 0) and (edChaveCripto.Text = '') then
    raise Exception.Create('Informe a chave da criptografia.');

  if FServer = nil then
  begin
    FServer := TRALSynopseServer.Create(Self);
    { o unico lugar por onde passa toda requisicao - rota, DAO e DBWare }
    FServer.OnRequest := ContaRequisicao;
    FServer.CreateRoute('ping', RotaPing, 'responde pong');
    FServer.CreateRoute('params', RotaParams, 'devolve os parametros recebidos');
    FServer.CreateRoute('multipart', RotaMultipart, 'lista as partes recebidas');
    FServer.CreateRoute('eco', RotaEco, 'devolve o corpo recebido');
    FServer.CreateRoute('lento', RotaLenta, 'demora, para medir paralelismo');

    { --- stack 1: DAO. O TRALFDConnection publica sozinho a rota que o
          TRALFDQuery do cliente consome; o nome do componente e' a rota, e o
          cliente o informa em RALFDConnectionServer. --- }
    FConnDAO := TRALFDConnection.Create(Self);
    FConnDAO.Name := 'RALConnBench';
    FConnDAO.LoginPrompt := False;

    { --- stack 2: DBWare. O TRALDBModule publica opensql, execsql,
          applyupdates e companhia sob /db; o cliente usa TRALDBConnection +
          TRALDBFDMemTable. --- }
    FModulo := TRALDBModule.Create(Self);
    FModulo.Domain := '/db';
    FModulo.DatabaseLink := 'FireDAC';
    FModulo.DatabaseType := dtFirebird;
    { pool de conexoes de banco ligado: sem ele cada requisicao abre e fecha
      uma conexao com o Firebird, e e' isso que o benchmark mediria }
    FModulo.PoolOptions.Enabled := True;
  end;

  AplicarConfiguracao;

  ConectarDAO;

  { O modulo DBWare nao conecta agora: cada requisicao pede uma conexao ao pool,
    e e' la' que uma falha do Firebird aparece - como HTTP 500 na aba Banco. }
  FModulo.Hostname := StringRAL(edFBHost.Text);
  FModulo.Port := StrToIntDef(edFBPorta.Text, 3050);
  FModulo.Database := StringRAL(edFBBanco.Text);
  FModulo.Username := StringRAL(edFBUsuario.Text);
  FModulo.Password := StringRAL(edFBSenha.Text);
  FModulo.Server := FServer;

  { zerados a cada subida: as conexoes de uma medicao anterior morreram com o
    servidor, e conta-las de novo so' estragaria a razao }
  FRequisicoes := 0;
  FEmH2 := 0;
  FConexoesCount := 0;
  FConexoesCheias := False;
  FServer.Active := True;

  if FServer.SSL.Enabled then
    vEsquema := 'https'
  else
    vEsquema := 'http';
  Log(Format('servidor no ar em %s://%s:%d - mORMot2 %s - modo %s - PoolCount %d - ' +
    'compressao %s - cripto %s',
    [vEsquema, edDominio.Text, FServer.Port, FServer.Engine, cbModo.Text,
     FServer.PoolCount, cbCompress.Text, cbCripto.Text]));
  if ModoEscolhido = smHttpSys then
    Log('modo http.sys com TLS: o ALPN pode fechar em h2 - o contador de HTTP/2 ' +
        'no status diz quantas requisicoes realmente chegaram assim')
  else
    Log('modo de socket: sem TLS nao ha ALPN, logo tudo chega em HTTP/1.1');
  Log('rotas: /ping /params /multipart /eco /lento, DAO em /RALConnBench, DBWare em /db');
  btLigar.Caption := 'Desligar';
  cbModo.Enabled := False;
  edPorta.Enabled := False;
  lbStatus.Caption := 'no ar';
  tmContadores.Enabled := True;
end;

procedure TfServidor.Desligar;
begin
  tmContadores.Enabled := False;
  if (FServer <> nil) and FServer.Active then
  begin
    FServer.Active := False;
    Log('servidor desligado');
  end;
  if FConnDAO <> nil then
    FConnDAO.Connected := False;
  btLigar.Caption := 'Ligar';
  cbModo.Enabled := True;
  edPorta.Enabled := True;
  lbStatus.Caption := 'parado';
end;

procedure TfServidor.btLigarClick(Sender: TObject);
begin
  try
    if (FServer <> nil) and FServer.Active then
      Desligar
    else
      Ligar;
  except
    on e: Exception do
    begin
      Log('ERRO: ' + e.Message);
      { AddUrl volta 5 quando falta a reserva, e essa e' a falha de estreia
        deste modo - dizer o que fazer vale mais do que repetir o codigo }
      if (ModoEscolhido = smHttpSys) and (Pos('5', e.Message) > 0) then
        Log('se o erro for "acesso negado" (5), rode "Preparar http.sys" - falta ' +
            'a reserva da URL e/ou o certificado amarrado na porta');
      Desligar;
      lbStatus.Caption := 'erro - veja o log';
    end;
  end;
end;

{ A razao requisicoes/conexoes e' a leitura que interessa, entao ela vem
  pronta - com uma conexao so', a divisao e' o numero de requisicoes que
  viajaram multiplexadas nela. }
procedure TfServidor.tmContadoresTimer(Sender: TObject);
var
  vReqs, vConns: Integer;
  vSufixo: string;
begin
  if (FServer = nil) or (not FServer.Active) then
    Exit;

  vReqs := FRequisicoes;
  vConns := FConexoesCount;
  if FConexoesCheias then
    vSufixo := '+'
  else
    vSufixo := '';

  { Sem o "no ar" na frente: quem diz isso e' o botao, que esta' escrito
    "Desligar", e o espaco cabe a' conta - que e' o que se olha. }
  if vConns > 0 then
    lbStatus.Caption := Format('%d req / %d%s conn (%.1f req/conn) - %d h2',
      [vReqs, vConns, vSufixo, vReqs / vConns, FEmH2])
  else
    lbStatus.Caption := Format('%d req - %d h2', [vReqs, FEmH2]);
end;

{ --------------------------------------------------------------------- rotas }

{ Roda em thread de engine, uma vez por requisicao, antes da rota - por isso
  so' conta. ProtocolVersion e' o que o ALPN fechou de verdade, e no http.sys
  vem da flag do driver, nao da linha de pedido (que continua dizendo 1.1 mesmo
  em h2). ConnectionID e' a conexao que trouxe a requisicao, e 0 significa que
  o engine nao sabe dizer - nunca "uma conexao a mais". }
procedure TfServidor.ContaRequisicao(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vInt, vCount: Integer;
  vConn: Int64;
begin
  TInterlocked.Increment(FRequisicoes);
  if ARequest.ProtocolVersion = rhv2 then
    TInterlocked.Increment(FEmH2);

  vConn := ARequest.ClientInfo.ConnectionID;
  if vConn = 0 then
    Exit;

  { o caminho comum, sem trava: uma leitura do contador e uma varredura curta }
  vCount := FConexoesCount;
  for vInt := 0 to vCount - 1 do
    if FConexoes[vInt] = vConn then
      Exit;

  FLockConexoes.Enter;
  try
    { reconfere sob trava - duas threads podem ter chegado juntas com a mesma }
    for vInt := 0 to FConexoesCount - 1 do
      if FConexoes[vInt] = vConn then
        Exit;
    if FConexoesCount > High(FConexoes) then
      FConexoesCheias := True
    else
    begin
      FConexoes[FConexoesCount] := vConn;
      TInterlocked.Increment(FConexoesCount);
    end;
  finally
    FLockConexoes.Leave;
  end;
end;

procedure TfServidor.RotaPing(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
end;

{ Devolve, uma por linha, o que chegou: query, campos e corpo. E' o que prova
  que parametros atravessam compressao e criptografia sem se perder. }
procedure TfServidor.RotaParams(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vInt: Integer;
  vParam: TRALParam;
  vSaida: string;
begin
  vSaida := '';
  for vInt := 0 to ARequest.Params.Count - 1 do
  begin
    vParam := ARequest.Params.Index[vInt];
    case vParam.Kind of
      rpkQUERY: vSaida := vSaida + 'query ';
      rpkBODY: vSaida := vSaida + 'body ';
      rpkFIELD: vSaida := vSaida + 'field ';
      rpkCOOKIE: vSaida := vSaida + 'cookie ';
    else
      Continue;
    end;
    vSaida := vSaida + string(vParam.ParamName) + '=' + string(vParam.AsString) + sLineBreak;
  end;
  AResponse.Answer(HTTP_OK, StringRAL(vSaida), rctTEXTPLAIN);
end;

procedure TfServidor.RotaMultipart(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vInt: Integer;
  vParam: TRALParam;
  vSaida: string;
  vTotal: Int64;
begin
  vSaida := '';
  vTotal := 0;
  for vInt := 0 to ARequest.Params.Count - 1 do
  begin
    vParam := ARequest.Params.Index[vInt];
    if not (vParam.Kind in [rpkBODY, rpkFIELD]) then
      Continue;
    vSaida := vSaida + Format('parte %s: %d bytes, tipo %s, arquivo "%s"',
      [string(vParam.ParamName), vParam.Size, string(vParam.ContentType),
       string(vParam.FileName)]) + sLineBreak;
    vTotal := vTotal + vParam.Size;
  end;
  vSaida := vSaida + Format('total: %d bytes', [vTotal]);
  AResponse.Answer(HTTP_OK, StringRAL(vSaida), rctTEXTPLAIN);
end;

procedure TfServidor.RotaEco(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, ARequest.RequestText, rctTEXTPLAIN);
end;

{ Uma rota que espera. Com PoolCount = 1 duas destas ao mesmo tempo demoram o
  dobro - e' o que o campo PoolCount da tela deixa ver. }
procedure TfServidor.RotaLenta(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  Sleep(ROTA_LENTA_MS);
  AResponse.Answer(HTTP_OK, 'ok', rctTEXTPLAIN);
end;

end.
