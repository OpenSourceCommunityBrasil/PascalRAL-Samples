/// Demo de HTTP/2 no PascalRAL: servidor e cliente no mesmo aplicativo.
///
/// Mostra quatro coisas, cada uma numa aba:
///   1. o servidor subindo nos tres modos que o RAL oferece, inclusive o
///      http.sys, que e' o unico que serve HTTP/2;
///   2. rotas comuns respondendo, com parametros tipados e com erro;
///   3. os DOIS stacks de banco do RAL sobre a mesma conexao - o DAO
///      (TRALFDQuery) e o DBWare (TRALDBModule + TRALDBFDMemTable);
///   4. a matriz do manual - ShareConnection x HTTPVersion nas quatro
///      combinacoes -, medida e desenhada.
///
/// Servidor e cliente juntos num exe so' para o demo rodar com um duplo
/// clique. As conexoes sao TCP de verdade, e e' isso que esta' sendo medido.
unit Principal;

interface

uses
  Winapi.Windows, Winapi.ShellAPI, Winapi.WinHTTP, System.SysUtils,
  System.Classes,
  System.SyncObjs, System.Diagnostics, System.IOUtils, System.DateUtils,
  System.StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.DBGrids, Vcl.Graphics, Vcl.Dialogs,
  Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.DApt,
  FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.Stan.Param,

  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse,
  RALParams, RALSynopseServer, RALClient, RALnetHTTPClient, RALIndyClient,
  RALDBConnection, RALDBModule, RALDBBase,
  RALDBFireDAC, RALDBFiredacDAO, RALDBFiredacMemTable, RALStorageBIN,

  UDemoRelay;

const
  PORTA_SERVIDOR = 8443;
  PORTA_RELAY    = 8444;
  ROTA_LENTA_MS  = 20;

  { PARA A LINHA USAR O PING NATIVO DO WINDOWS, tres numeros tem de conversar:
    o WinHTTP so' comeca a pingar depois do intervalo de SILENCIO e recusa
    intervalo abaixo de 5000 ms; o relay nao pode ceifar antes disso; e a
    pausa tem de durar mais do que o relay espera. Com a pausa padrao de
    600 ms nada disso cabe, entao a linha usa o batimento imitado - e a coluna
    de avisos diz qual dos dois rodou, sempre. }
  PAUSA_MIN_NATIVA = 8000;
  OCIOSO_NATIVO    = 6500;

  { Os quatro rotulos, numa constante so': a grade, o grafico e a ordem da
    medicao tem de concordar, e concordar por construcao e' melhor do que
    concordar por disciplina. }
  ROTULOS_CELULA: array [0 .. 4] of string = (
    'Indy 1.1 - 1 socket por cliente',
    'netHTTP sem share  h2',
    'netHTTP com share  1.1', 'netHTTP com share  h2',
    'netHTTP com share  h2  + mantida viva');
  { os mesmos, curtos, porque no grafico o rotulo divide a largura com a
    barra. Ficam no mesmo lugar para nao se afastarem sem ninguem ver. }
  ROTULOS_CURTO: array [0 .. 4] of string = (
    'Indy  1.1', 'net  solo h2', 'net  share 1.1', 'net  share h2',
    'net  h2 viva');

type
  { TStringGrid nao tem ReadOnly, e sem goEditing nem da' para MARCAR o texto
    de uma celula para copiar - o clique so' seleciona a celula inteira. O
    editor embutido resolve os dois: ele aparece, deixa selecionar e copiar, e
    nasce somente-leitura. A grade fica clicavel e intocavel, que e' o que se
    quer de um resultado de medicao. }
  TRALGradeLeitura = class(TStringGrid)
  protected
    function CreateEditor: TInplaceEdit; override;
  end;

  { Uma celula da matriz: o que foi pedido e o que foi medido.

    Abertas e Pico sao coisas diferentes e as duas importam - ver o comentario
    longo na secao de velocidade. H2 conta quantas RESPOSTAS voltaram em
    HTTP/2, que e' o unico jeito honesto de rotular a linha: pedir rhv2 nao e'
    obter rhv2. }
  TDemoCelula = record
    Engine: string;     // 'netHTTP' ou 'Indy'
    Share: boolean;
    { manter a conexao viva durante as pausas, em vez de deixa-la esfriar.
      Sao DOIS mecanismos e eles se excluem: MantemViva e' o batimento
      imitado pelo demo (ver TDemoTrabalhador.Espera); PingNativo e' o
      WINHTTP_OPTION_HTTP2_KEEPALIVE, em que quem manda os frames PING e' o
      proprio Windows e o demo nao faz nada alem de pedir. }
    MantemViva: boolean;
    PingNativo: boolean;
    Versao: TRALHTTPVersion;
    Abertas: Integer;   // conexoes que o relay aceitou durante a medicao
    Pico: Integer;      // quantas existiram AO MESMO TEMPO
    Ms: Integer;
    Ok: Integer;
    Erros: Integer;
    H2: Integer;
    Erro1: string;      // a primeira falha, quando houve
  end;

  TfPrincipal = class(TForm)
    pcPrincipal: TPageControl;

    tsServidor: TTabSheet;
    gbConfig: TGroupBox;
    lbModo: TLabel;
    cbModo: TComboBox;
    lbPorta: TLabel;
    edPorta: TEdit;
    chTLS: TCheckBox;
    btLigar: TButton;
    btPreparar: TButton;
    lbEstado: TLabel;
    mmLog: TMemo;

    tsRotas: TTabSheet;
    gbRotas: TGroupBox;
    btPing: TButton;
    btSoma: TButton;
    btItens: TButton;
    btErro: TButton;
    mmRotas: TMemo;

    tsBanco: TTabSheet;
    gbDAO: TGroupBox;
    mmSQLDAO: TMemo;
    btAbrirDAO: TButton;
    btGravarDAO: TButton;
    grDAO: TDBGrid;
    dsDAO: TDataSource;
    gbDBWare: TGroupBox;
    mmSQLDBWare: TMemo;
    btAbrirDBWare: TButton;
    btGravarDBWare: TButton;
    grDBWare: TDBGrid;
    dsDBWare: TDataSource;
    lbBanco: TLabel;

    tsVelocidade: TTabSheet;
    gbCenario: TGroupBox;
    lbClientes: TLabel;
    edClientes: TEdit;
    lbPedidos: TLabel;
    edPedidos: TEdit;
    lbSimultaneos: TLabel;
    edSimultaneos: TEdit;
    lbPausa: TLabel;
    edPausa: TEdit;
    lbLatencia: TLabel;
    edLatencia: TEdit;
    btComparar: TButton;
    lbAviso: TLabel;
    sgResultado: TRALGradeLeitura;
    pbGrafico: TPaintBox;
    mmExplica: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btLigarClick(Sender: TObject);
    procedure btPrepararClick(Sender: TObject);
    procedure btPingClick(Sender: TObject);
    procedure btSomaClick(Sender: TObject);
    procedure btItensClick(Sender: TObject);
    procedure btErroClick(Sender: TObject);
    procedure btAbrirDAOClick(Sender: TObject);
    procedure btGravarDAOClick(Sender: TObject);
    procedure btAbrirDBWareClick(Sender: TObject);
    procedure btGravarDBWareClick(Sender: TObject);
    procedure btCompararClick(Sender: TObject);
    procedure cbModoChange(Sender: TObject);
    procedure pbGraficoPaint(Sender: TObject);
  private
    { --- servidor --- }
    FServer: TRALSynopseServer;
    FConnDAO: TRALFDConnection;   // publica a rota DAO
    FModulo: TRALDBModule;        // publica as rotas DBWare
    FBanco: string;
    FRequisicoes: Integer;
    FProtocoloConferido: boolean;

    { --- cliente --- }
    FQryDAO: TRALFDQuery;
    FConnDBWare: TRALDBConnection;
    FTabDBWare: TRALDBFDMemTable;
    FStorage: TRALStorageBINLink;
    FCliDAO: TRALClient;
    FCliDBWare: TRALClient;

    { --- medicao --- }
    FRelay: TDemoRelay;
    FCelulas: array [0 .. 4] of TDemoCelula;
    FMedido: boolean;

    procedure Log(const ATexto: string);
    procedure AtualizaEstado;
    function ModoEscolhido: TRALSynopseMode;
    function BaseURL(APorta: Integer): string;
    function PreparadoParaHTTP2: boolean;

    procedure CriaBanco;
    procedure CriaRotas;
    function NovoCliente(APorta: Integer; AVersao: TRALHTTPVersion;
                         ACompartilha: boolean): TRALClient;
    procedure ChamaRota(const ARota: string; AParams: array of string);

    { handlers do servidor }
    procedure RotaPing(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaSoma(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaItens(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaErro(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaLenta(ARequest: TRALRequest; AResponse: TRALResponse);

    { Uma celula da matriz. ACelula entra dizendo o que medir (Share e
      Versao) e volta com o que foi medido - inclusive quantos pedidos
      deram certo: medicao em que metade falhou nao mede nada, e esconder
      isso seria mostrar um numero bonito e falso. }
    procedure MedeCelula(var ACelula: TDemoCelula; APorta: Word;
                         AClientes, APedidos, ASimultaneos, APausa: Integer);
    /// Sobe o relay numa porta NOVA para cada medicao - ver o comentario no
    /// btCompararClick sobre o pool de conexoes do WinHTTP.
    procedure NovoCaminho(APorta: Word; ALatencia: Integer);
    /// O texto da coluna de avisos - vazio quando nao ha' o que avisar
    function AvisoDaCelula(const ACelula: TDemoCelula): string;
  public
  end;

var
  fPrincipal: TfPrincipal;

implementation

{$R *.dfm}

uses
  System.Types, System.Math;

type
  { so' para alcancar o ReadOnly, que TCustomEdit declara em protected }
  TEditorAberto = class(TCustomEdit);

function TRALGradeLeitura.CreateEditor: TInplaceEdit;
begin
  Result := inherited CreateEditor;
  TEditorAberto(Result).ReadOnly := True;
end;

var
  { -1 ainda nao perguntado, 0 nao, 1 sim }
  vPingNativo: Integer = -1;

{ ESTE Windows tem WINHTTP_OPTION_HTTP2_KEEPALIVE?

  E' a mesma pergunta que o engine netHTTP faz ao configurar o transporte,
  e aqui ela aparece porque a linha precisa SABER, antes de medir, qual dos
  dois mecanismos vai usar - e a coluna de avisos precisa dizer qual foi.

  Medido em 2026-09-15: Windows 11 24H2 (build 26100) tem; Windows 10 22H2
  (build 19045) nao. Onde nao tem, WinHttpSetOption devolve False e nao mexe
  na sessao - o HTTP/2 continua funcionando, so' que sem ping. }
function PingNativoDoWindows: boolean;
const
  OPT_HTTP2_KEEPALIVE = 164;
var
  vSessao: HINTERNET;
  vMs: DWORD;
begin
  if vPingNativo < 0 then
  begin
    vPingNativo := 0;
    vSessao := WinHttpOpen('sonda', WINHTTP_ACCESS_TYPE_NO_PROXY, nil, nil, 0);
    if vSessao <> nil then
    begin
      vMs := MINKEEPALIVEMS;
      if WinHttpSetOption(vSessao, OPT_HTTP2_KEEPALIVE, @vMs, SizeOf(vMs)) then
        vPingNativo := 1;
      WinHttpCloseHandle(vSessao);
    end;
  end;
  Result := vPingNativo = 1;
end;

{ ---------------------------------------------------------------- servidor -- }

procedure TfPrincipal.Log(const ATexto: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      mmLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz  ', Now) + ATexto);
      if mmLog.Lines.Count > 500 then
        mmLog.Lines.Delete(0);
    end);
end;

function TfPrincipal.ModoEscolhido: TRALSynopseMode;
begin
  case cbModo.ItemIndex of
    1: Result := smAsync;
    2: Result := smHttpSys;
  else
    Result := smThreads;
  end;
end;

function TfPrincipal.BaseURL(APorta: Integer): string;
begin
  { localhost, e nao 127.0.0.1: e' o nome que o http.sys aceita sem reserva de
    porta, e e' o CN do certificado que o LEIAME manda criar }
  if chTLS.Checked then
    Result := 'https://localhost:' + IntToStr(APorta)
  else
    Result := 'http://localhost:' + IntToStr(APorta);
end;

{ HTTP/2 so' existe sobre TLS, e no Windows so' pelo http.sys. Isso aqui nao
  prova que o certificado esta' amarrado na porta - so' que a configuracao
  pedida pode chegar la'. }
function TfPrincipal.PreparadoParaHTTP2: boolean;
begin
  Result := chTLS.Checked and (ModoEscolhido = smHttpSys);
end;

procedure TfPrincipal.AtualizaEstado;
var
  vTxt: string;
begin
  if (FServer <> nil) and FServer.Active then
  begin
    vTxt := Format('ATIVO  -  %s  -  modo %s  -  %s',
      [BaseURL(PORTA_SERVIDOR), cbModo.Text,
       IfThen(PreparadoParaHTTP2, 'pode negociar HTTP/2', 'HTTP/1.1')]);
    lbEstado.Font.Color := clGreen;
    btLigar.Caption := 'Desligar';
  end
  else
  begin
    vTxt := 'parado';
    lbEstado.Font.Color := clMaroon;
    btLigar.Caption := 'Ligar';
  end;
  lbEstado.Caption := vTxt;

  cbModo.Enabled := (FServer = nil) or (not FServer.Active);
  edPorta.Enabled := cbModo.Enabled;
  { TLS so' faz sentido onde este demo TEM certificado, que e' o http.sys -
    ver cbModoChange }
  chTLS.Enabled := cbModo.Enabled and (ModoEscolhido = smHttpSys);
end;

{ O MODO MANDA NO TLS, e nao o contrario.

  O http.sys e' o unico modo em que este demo consegue falar TLS, porque o
  certificado dele nao vem de arquivo nenhum: mora na loja da maquina,
  amarrado a' porta pelo "netsh http add sslcert" que o botao Preparar roda.
  Os modos de socket leem SSL.CertificateFile e SSL.PrivateKeyFile, que aqui
  estao vazios.

  Deixar a caixa marcada ao trocar de modo dava exatamente isto, e so' na
  hora de subir:
      ENetSock: TCrtSocket.DoTlsAfter: TLS failed
                [ESChannel AfterBind: no Certificate available]
  - verdadeiro, e inutil para quem so' queria trocar de modo. }
procedure TfPrincipal.cbModoChange(Sender: TObject);
begin
  if ModoEscolhido = smHttpSys then
  begin
    chTLS.Checked := True;
  end
  else
  begin
    if chTLS.Checked then
      Log('TLS desligado: fora do http.sys ele precisa de SSL.CertificateFile, ' +
          'e este demo nao tem arquivo de certificado');
    chTLS.Checked := False;
  end;
  AtualizaEstado;
end;

procedure TfPrincipal.btLigarClick(Sender: TObject);
begin
  if (FServer <> nil) and FServer.Active then
  begin
    FServer.Active := False;

    { O modulo e a conexao DAO nascem junto com o servidor (em CriaRotas) e tem
      de morrer junto: os dois sao componentes NOMEADOS deste form, e ligar de
      novo sem solta-los estourava com "A component named RALConnDemo already
      exists" na segunda vez.

      Os clientes tambem vao embora: eles seguram datasets abertos contra um
      servidor que acabou de sumir. }
    FreeAndNil(FQryDAO);
    FreeAndNil(FTabDBWare);
    FreeAndNil(FConnDBWare);
    FreeAndNil(FStorage);
    FreeAndNil(FCliDAO);
    FreeAndNil(FCliDBWare);
    dsDAO.DataSet := nil;
    dsDBWare.DataSet := nil;

    FreeAndNil(FModulo);
    FreeAndNil(FConnDAO);
    FreeAndNil(FServer);

    FProtocoloConferido := False;
    Log('servidor desligado');
    AtualizaEstado;
    Exit;
  end;

  { A mesma regra de cbModoChange, agora como recusa: a caixa pode ter sido
    marcada por um .dfm antigo ou por codigo, e o lugar de dizer nao e' aqui,
    antes de abrir soquete nenhum. }
  if chTLS.Checked and (ModoEscolhido <> smHttpSys) then
  begin
    ShowMessage('Neste demo o TLS so existe no modo HTTP.sys.' + sLineBreak +
      'Os modos de socket leem o certificado de SSL.CertificateFile, e aqui ' +
      'nao ha arquivo nenhum - o certificado do demo esta na loja da maquina, ' +
      'amarrado a porta pelo netsh.');
    Exit;
  end;

  FServer := TRALSynopseServer.Create(Self);
  try
    FServer.Port := StrToIntDef(edPorta.Text, PORTA_SERVIDOR);
    FServer.Mode := ModoEscolhido;
    FServer.SSL.Enabled := chTLS.Checked;
    { tem de ser o MESMO texto que a reserva do netsh usou }
    FServer.HttpSysDomain := 'localhost';

    CriaRotas;
    FServer.Active := True;
  except
    on E: Exception do
    begin
      Log('NAO SUBIU: ' + E.Message);
      FreeAndNil(FServer);
      AtualizaEstado;
      { sem re-levantar: o log ja' conta o que houve, e uma caixa de excecao
        do Delphi por cima dela nao acrescenta nada a quem roda o demo }
      ShowMessage('O servidor nao subiu:' + sLineBreak + sLineBreak + E.Message);
      Exit;
    end;
  end;

  Log(Format('servidor ativo em %s (modo %s)',
    [BaseURL(FServer.Port), cbModo.Text]));
  if PreparadoParaHTTP2 then
    Log('modo http.sys com TLS: o ALPN pode fechar em h2')
  else if chTLS.Checked then
    Log('TLS ligado, mas HTTP/2 so no modo http.sys')
  else
    Log('sem TLS: HTTP/2 nao acontece (ALPN so existe dentro do TLS)');
  AtualizaEstado;
end;

{ O certificado e a reserva de porta do http.sys precisam de direito de
  administrador. Em vez de exigir que o demo INTEIRO rode elevado - o que seria
  pior -, so' este passo sobe elevado, uma vez. }
procedure TfPrincipal.btPrepararClick(Sender: TObject);
var
  vArq, vCmd: string;
  vLista: TStringList;
begin
  vArq := TPath.Combine(TPath.GetTempPath, 'ral_demo_http2.ps1');
  vLista := TStringList.Create;
  try
    vLista.Add('$ErrorActionPreference = ''Stop''');
    vLista.Add('Write-Host "Preparando HTTP/2 para o demo do PascalRAL..." -ForegroundColor Cyan');
    vLista.Add('$c = New-SelfSignedCertificate -DnsName localhost -CertStoreLocation Cert:\LocalMachine\My');
    vLista.Add('Write-Host "certificado: $($c.Thumbprint)"');
    vLista.Add('# confiavel nesta maquina, senao o cliente recusa o autoassinado');
    vLista.Add('$r = New-Object System.Security.Cryptography.X509Certificates.X509Store ''Root'',''LocalMachine''');
    vLista.Add('$r.Open(''ReadWrite''); $r.Add($c); $r.Close()');
    vLista.Add('$app = ''{7b2a1c43-9d5e-4f60-8a71-b2c3d4e5f607}''');
    vLista.Add(Format('netsh http add sslcert ipport=127.0.0.1:%d certhash=$($c.Thumbprint) appid=$app',
      [PORTA_SERVIDOR]));
    vLista.Add(Format('netsh http add sslcert ipport=[::1]:%d certhash=$($c.Thumbprint) appid=$app',
      [PORTA_SERVIDOR]));
    vLista.Add(Format('netsh http add urlacl url=https://localhost:%d/ user=$env:USERNAME',
      [PORTA_SERVIDOR]));
    vLista.Add('Write-Host "" ; Write-Host "Pronto. Pode fechar esta janela." -ForegroundColor Green');
    vLista.Add('Read-Host "ENTER para fechar"');
    vLista.SaveToFile(vArq, TEncoding.UTF8);
  finally
    vLista.Free;
  end;

  vCmd := Format('-NoProfile -ExecutionPolicy Bypass -File "%s"', [vArq]);
  { "runas" e' o que pede a elevacao ao Windows }
  ShellExecute(Handle, 'runas', 'powershell.exe', PChar(vCmd), nil, SW_SHOWNORMAL);

  Log('pedido de preparacao enviado (confirme o aviso do Windows)');
  Log('o que ele faz: cria certificado para localhost, torna confiavel,');
  Log('amarra na porta ' + IntToStr(PORTA_SERVIDOR) + ' e reserva a URL');
end;

{ ------------------------------------------------------------------ rotas -- }

procedure TfPrincipal.RotaPing(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  Inc(FRequisicoes);
  AResponse.Answer(HTTP_OK, 'pong');
end;

{ Parametros tipados: e' o RAL que converte, e um valor invalido vira erro em
  vez de virar zero em silencio. }
procedure TfPrincipal.RotaSoma(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vA, vB: Int64;
begin
  Inc(FRequisicoes);
  vA := ARequest.ParamByName('a').AsInteger;
  vB := ARequest.ParamByName('b').AsInteger;
  AResponse.Answer(HTTP_OK, Format('{"a":%d,"b":%d,"soma":%d}', [vA, vB, vA + vB]));
end;

{ Uma rota comum que le' o banco: mostra que rota e banco convivem no mesmo
  servidor, cada um pelo seu caminho. }
procedure TfPrincipal.RotaItens(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vCon: TFDConnection;
  vQry: TFDQuery;
  vJson: string;
begin
  Inc(FRequisicoes);
  { conexao por requisicao: o servidor atende em varias threads, e um TFDQuery
    compartilhado entre elas corrompe em producao sem falhar em teste }
  vCon := TFDConnection.Create(nil);
  vQry := TFDQuery.Create(nil);
  try
    vCon.LoginPrompt := False;
    vCon.Params.Add('DriverID=SQLite');
    vCon.Params.Add('Database=' + FBanco);
    vQry.Connection := vCon;
    vQry.SQL.Text := 'SELECT ID, DESCRICAO, PRECO FROM ITENS ORDER BY ID';
    vQry.Open;

    vJson := '[';
    while not vQry.Eof do
    begin
      if Length(vJson) > 1 then
        vJson := vJson + ',';
      vJson := vJson + Format('{"id":%d,"descricao":"%s","preco":%s}',
        [vQry.FieldByName('ID').AsInteger,
         vQry.FieldByName('DESCRICAO').AsString,
         FormatFloat('0.00', vQry.FieldByName('PRECO').AsFloat,
                     TFormatSettings.Invariant)]);
      vQry.Next;
    end;
    vJson := vJson + ']';

    AResponse.Answer(HTTP_OK, vJson, rctAPPLICATIONJSON);
  finally
    vQry.Free;
    vCon.Free;
  end;
end;

procedure TfPrincipal.RotaErro(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  Inc(FRequisicoes);
  raise Exception.Create('erro de proposito, para mostrar o contrato de erro');
end;

{ O trabalho que a comparacao mede. Precisa custar ALGUM tempo, senao a rede e'
  a unica coisa medida e o paralelismo nao aparece. }
procedure TfPrincipal.RotaLenta(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  Inc(FRequisicoes);
  Sleep(ROTA_LENTA_MS);
  AResponse.Answer(HTTP_OK, 'ok');
end;

procedure TfPrincipal.CriaRotas;
begin
  FServer.CreateRoute('ping', RotaPing, 'responde pong');
  FServer.CreateRoute('soma', RotaSoma, 'soma dois inteiros');
  FServer.CreateRoute('itens', RotaItens, 'lista os itens do banco');
  FServer.CreateRoute('erro', RotaErro, 'estoura de proposito');
  FServer.CreateRoute('lento', RotaLenta, 'demora, para medir paralelismo');

  { --- stack 1: DAO. O TRALFDConnection publica sozinho a rota que o
        TRALFDQuery do cliente consome. --- }
  FConnDAO := TRALFDConnection.Create(Self);
  FConnDAO.Name := 'RALConnDemo';
  FConnDAO.LoginPrompt := False;
  FConnDAO.Params.Clear;
  FConnDAO.Params.Add('DriverID=SQLite');
  FConnDAO.Params.Add('Database=' + FBanco);
  FConnDAO.Connected := True;
  FConnDAO.RALServer := FServer;

  { --- stack 2: DBWare. O TRALDBModule publica as rotas sob /db, e o cliente
        usa TRALDBConnection + TRALDBFDMemTable. --- }
  FModulo := TRALDBModule.Create(Self);
  FModulo.Domain := '/db';
  FModulo.DatabaseLink := 'FireDAC';
  FModulo.Database := FBanco;
  FModulo.DatabaseType := dtSQLite;
  FModulo.Server := FServer;
end;

{ ------------------------------------------------------------------ banco -- }

procedure TfPrincipal.CriaBanco;
var
  vCon: TFDConnection;
begin
  FBanco := TPath.Combine(ExtractFilePath(ParamStr(0)), 'demo_http2.db');
  lbBanco.Caption := 'banco: ' + FBanco;
  if FileExists(FBanco) then
    Exit;

  vCon := TFDConnection.Create(nil);
  try
    vCon.LoginPrompt := False;
    vCon.Params.Add('DriverID=SQLite');
    vCon.Params.Add('Database=' + FBanco);
    vCon.Connected := True;
    vCon.ExecSQL('CREATE TABLE ITENS (' +
                 ' ID INTEGER PRIMARY KEY,' +
                 ' DESCRICAO VARCHAR(60),' +
                 ' QUANTIDADE DOUBLE,' +
                 ' PRECO NUMERIC(15,4))');
    vCon.ExecSQL('INSERT INTO ITENS VALUES (1, ''arroz'',    2.5,  19.9012)');
    vCon.ExecSQL('INSERT INTO ITENS VALUES (2, ''feijao'',   1.0,   8.4900)');
    vCon.ExecSQL('INSERT INTO ITENS VALUES (3, ''cafe'',     3.0,  32.7500)');
    vCon.ExecSQL('INSERT INTO ITENS VALUES (4, ''acucar'',   5.0,   4.1900)');
    vCon.ExecSQL('INSERT INTO ITENS VALUES (5, ''macarrao'', 12.0,  3.5000)');
  finally
    vCon.Free;
  end;
end;

function TfPrincipal.NovoCliente(APorta: Integer; AVersao: TRALHTTPVersion;
  ACompartilha: boolean): TRALClient;
begin
  Result := TRALClient.Create(Self);
  { netHTTP e' o unico engine do RAL que fala HTTP/2 - ver SupportsHTTP2 }
  Result.EngineType := 'netHTTP';
  Result.BaseURL.Text := BaseURL(APorta);
  Result.HTTPVersion := AVersao;
  Result.ShareConnection := ACompartilha;
  Result.ConnectTimeout := 15000;
  Result.RequestTimeout := 60000;
end;

procedure TfPrincipal.ChamaRota(const ARota: string; AParams: array of string);
var
  vCli: TRALClient;
  vResp: TRALResponse;
  vRelogio: TStopwatch;
  vInt: Integer;
  vVersao: string;
begin
  if (FServer = nil) or (not FServer.Active) then
  begin
    mmRotas.Lines.Add('>> ligue o servidor na primeira aba');
    Exit;
  end;

  { Uma vez por sessao de cliques, so' para situar quem esta' lendo o log. O
    protocolo de verdade vem em CADA resposta, logo abaixo. }
  if not FProtocoloConferido then
  begin
    FProtocoloConferido := True;
    if PreparadoParaHTTP2 then
      mmRotas.Lines.Add('>> http.sys com TLS: o ALPN pode fechar em h2 - ' +
        'cada linha abaixo diz o que fechou')
    else if chTLS.Checked then
      mmRotas.Lines.Add('>> TLS ligado, mas HTTP/2 so no modo http.sys')
    else
      mmRotas.Lines.Add('>> sem TLS: HTTP/1.1, porque o HTTP/2 se negocia ' +
        'por ALPN, que so existe dentro do TLS');
    mmRotas.Lines.Add('');
  end;

  vCli := NovoCliente(PORTA_SERVIDOR, rhv2, True);
  try
    vInt := 0;
    while vInt < Length(AParams) - 1 do
    begin
      vCli.Request.Params.AddParam(AParams[vInt], AParams[vInt + 1], rpkQUERY);
      Inc(vInt, 2);
    end;

    vResp := nil;
    vRelogio := TStopwatch.StartNew;
    try
      vCli.Get(ARota, vResp);
      vRelogio.Stop;

      { O QUE FOI NEGOCIADO, nao o que foi pedido. No Windows o engine
        netHTTP pergunta isto ao proprio WinHTTP
        (WINHTTP_OPTION_HTTP_PROTOCOL_USED) em vez de ler a linha de status,
        que uma resposta HTTP/2 nao tem - era por isso que o demo precisava
        de uma unit so' para descobrir o protocolo, e nao precisa mais. }
      case vResp.ProtocolVersion of
        rhv2:  vVersao := 'HTTP/2';
        rhv11: vVersao := 'HTTP/1.1';
        rhv10: vVersao := 'HTTP/1.0';
      else
        vVersao := 'o transporte nao soube dizer';
      end;

      mmRotas.Lines.Add(Format('GET /%s  ->  %d  em %d ms  [%s]',
        [ARota, vResp.StatusCode, vRelogio.ElapsedMilliseconds, vVersao]));
      mmRotas.Lines.Add('    ' + vResp.ResponseText);
    except
      on E: Exception do
      begin
        vRelogio.Stop;
        mmRotas.Lines.Add(Format('GET /%s  ->  EXCECAO em %d ms',
          [ARota, vRelogio.ElapsedMilliseconds]));
        mmRotas.Lines.Add('    ' + E.Message);
      end;
    end;
    vResp.Free;
  finally
    vCli.Free;
  end;
  mmRotas.Lines.Add('');
end;

procedure TfPrincipal.btPingClick(Sender: TObject);
begin
  ChamaRota('ping', []);
end;

procedure TfPrincipal.btSomaClick(Sender: TObject);
begin
  ChamaRota('soma', ['a', '40', 'b', '2']);
end;

procedure TfPrincipal.btItensClick(Sender: TObject);
begin
  ChamaRota('itens', []);
end;

procedure TfPrincipal.btErroClick(Sender: TObject);
begin
  ChamaRota('erro', []);
end;

{ --- DAO: TRALFDQuery, que e' um dataset comum apontado para um TRALClient --- }

procedure TfPrincipal.btAbrirDAOClick(Sender: TObject);
begin
  if (FServer = nil) or (not FServer.Active) then
  begin
    ShowMessage('Ligue o servidor na primeira aba.');
    Exit;
  end;

  if FCliDAO = nil then
    FCliDAO := NovoCliente(PORTA_SERVIDOR, rhv2, True);

  if FQryDAO = nil then
  begin
    FQryDAO := TRALFDQuery.Create(Self);
    FQryDAO.RALClient := FCliDAO;
    FQryDAO.RALFDConnectionServer := 'RALConnDemo';
    { OBRIGATORIO: o padrao e' ebMultiThread, que volta ANTES dos dados
      chegarem - e ai o dataset aparece vazio, de forma intermitente }
    FQryDAO.QueryBehavior := ebSingleThread;
    dsDAO.DataSet := FQryDAO;
  end;

  FQryDAO.Close;
  FQryDAO.SQL.Text := mmSQLDAO.Lines.Text;
  FQryDAO.OpenRemote;
  Log(Format('DAO: %d registros', [FQryDAO.RecordCount]));
end;

procedure TfPrincipal.btGravarDAOClick(Sender: TObject);
begin
  if (FQryDAO = nil) or (not FQryDAO.Active) then
  begin
    ShowMessage('Abra a consulta primeiro.');
    Exit;
  end;
  { grava no servidor o que foi editado na grade - o caminho de volta do DAO }
  FQryDAO.ApplyUpdatesRemote;
  Log('DAO: alteracoes gravadas no servidor');
  FQryDAO.Close;
  FQryDAO.OpenRemote;
end;

{ --- DBWare: TRALDBModule no servidor, TRALDBFDMemTable no cliente --- }

procedure TfPrincipal.btAbrirDBWareClick(Sender: TObject);
var
  vFim: TDateTime;
begin
  if (FServer = nil) or (not FServer.Active) then
  begin
    ShowMessage('Ligue o servidor na primeira aba.');
    Exit;
  end;

  if FCliDBWare = nil then
    FCliDBWare := NovoCliente(PORTA_SERVIDOR, rhv2, True);

  if FTabDBWare = nil then
  begin
    FStorage := TRALStorageBINLink.Create(Self);
    FConnDBWare := TRALDBConnection.Create(Self);
    FConnDBWare.Client := FCliDBWare;
    FConnDBWare.ModuleRoute := '/db';

    FTabDBWare := TRALDBFDMemTable.Create(Self);
    FTabDBWare.RALConnection := FConnDBWare;
    FTabDBWare.Storage := FStorage;
    dsDBWare.DataSet := FTabDBWare;
  end;

  FTabDBWare.Close;
  FTabDBWare.SQL.Text := mmSQLDBWare.Lines.Text;
  FTabDBWare.Open;

  { este stack abre em segundo plano: Open volta antes dos dados. Esperar aqui
    e' o que deixa o Log dizer a verdade. }
  vFim := IncSecond(Now, 15);
  while (not FTabDBWare.Active) and (Now < vFim) do
  begin
    Application.ProcessMessages;
    Sleep(20);
  end;

  if not FTabDBWare.Active then
  begin
    Log('DBWare: nao abriu dentro do tempo');
    Exit;
  end;

  { PARA GRAVAR DE VOLTA faltam duas coisas que o memtable nao tem como
    adivinhar: qual tabela atualizar e qual campo e' a chave. Sem a tabela o
    proprio Post estoura com emDBUpdateSQLMissing; sem a chave o UPDATE sairia
    sem WHERE que preste. Com as duas, o RAL monta sozinho o
      update ITENS set DESCRICAO = :DESCRICAO, PRECO = :PRECO where (ID = :OLD_ID)
    - e e' por isso que o ID precisa estar no SELECT. }
  FTabDBWare.UpdateTable := 'ITENS';
  FTabDBWare.UpdateMode := upWhereKeyOnly;
  if FTabDBWare.FindField('ID') <> nil then
    FTabDBWare.FieldByName('ID').ProviderFlags := [pfInKey];

  Log(Format('DBWare: %d registros', [FTabDBWare.RecordCount]));
end;

{ O caminho de volta do DBWare - o mesmo papel que o ApplyUpdatesRemote faz
  no DAO, por outro desenho: aqui o dataset e' local (um memtable), o Post
  monta o SQL de cada linha alterada num cache, e o ApplyUpdates envia o
  cache inteiro numa requisicao. }
procedure TfPrincipal.btGravarDBWareClick(Sender: TObject);
begin
  if (FTabDBWare = nil) or (not FTabDBWare.Active) then
  begin
    ShowMessage('Abra a consulta primeiro.');
    Exit;
  end;

  { o que esta' sendo digitado na grade ainda nao virou SQL: quem monta o
    comando e o guarda no cache e' o Post }
  if FTabDBWare.State in dsEditModes then
    FTabDBWare.Post;

  FTabDBWare.ApplyUpdates;
  Log('DBWare: alteracoes enviadas ao servidor');

  { reabrir e' o que PROVA que foi: o memtable e' local e continuaria
    mostrando o valor editado mesmo se o servidor tivesse recusado }
  btAbrirDBWareClick(Sender);
end;

{ ------------------------------------------------------------- velocidade -- }

{ A MATRIZ DO MANUAL: ShareConnection x HTTPVersion, as quatro combinacoes.

  Os dois eixos compram coisas DIFERENTES, e nenhum faz o trabalho do outro:

    ShareConnection economiza HANDSHAKE. Um transporte para todos os clientes
    que apontam para o mesmo lugar com a mesma configuracao, em vez de um por
    dataset. Isso vale em HTTP/1.1 tambem.

    HTTP/2 economiza CONEXAO SIMULTANEA. Varios pedidos no ar sobre a MESMA
    conexao, cada um num stream. Sem compartilhar nao existe conexao unica
    para multiplexar, e o ganho simplesmente nao aparece.

  Por isso a leitura e' em duas colunas: ABERTAS e' quantas vezes se pagou
  TCP+TLS, PICO e' quantas existiram ao mesmo tempo. Sao respostas a perguntas
  diferentes - 53 abertas com pico 2 e' um cliente abrindo e fechando uma de
  cada vez; 2 abertas com pico 2 e' o mesmo trabalho sem pagar handshake -, e
  e' o par que decide.

  A celula "sem share + h2" costuma ser a pior das quatro, e nao por acaso:
  cada cliente ganha o seu proprio transporte, nenhum deles e' limitado a uma
  conexao, e as conexoes h2 ainda ficam abertas. E' o custo do HTTP/2 sem o
  beneficio dele. }

type
  { Um lote de medicao: os clientes, os contadores e nada mais.

    A CONCORRENCIA E' SEPARADA DA QUANTIDADE DE CLIENTES, de proposito. Com 20
    clientes e 4 simultaneos ha' 20 TRALClient e so' 4 pedidos no ar - que e' o
    desenho de um aplicativo de verdade (um cliente por dataset) e e' a unica
    forma de ver o que o compartilhamento faz sob HTTP/1.1: reaproveitar
    conexao morna em vez de abrir uma fria por cliente. }
  TDemoLote = class
  private
    FClientes: array of TRALClient;
    FMantemViva: boolean;
    FTrava: TCriticalSection;
    FOk: Integer;
    FErros: Integer;
    FH2: Integer;
    FErro1: string;
  public
    constructor Create(const AURL, AEngine: string; AVersao: TRALHTTPVersion;
                       AShare, AMantemViva: boolean;
                       AClientes, AKeepAliveMs: Integer);
    destructor Destroy; override;
    procedure Conta(AResp: TRALResponse; const AErro: string);

    property Ok: Integer read FOk;
    property Erros: Integer read FErros;
    property H2: Integer read FH2;
    property Erro1: string read FErro1;
    property MantemViva: boolean read FMantemViva;
  end;

  { Cada trabalhador e' dono de uma FATIA dos clientes - o de indice K cuida
    dos clientes K, K+P, K+2P... - e nenhum cliente e' tocado por dois ao mesmo
    tempo. Nao e' detalhe de estilo: TRALClient.Request e' UM objeto por
    cliente, entao dois pedidos simultaneos no mesmo cliente montariam a
    requisicao um por cima do outro. Uma fila comum com rodizio deixaria isso
    acontecer assim que um trabalhador atrasasse uma volta. }
  TDemoTrabalhador = class(TThread)
  private
    FLote: TDemoLote;
    FLargada: TEvent;
    FPrimeiro: Integer;
    FPasso: Integer;
    FPedidos: Integer;
    FPausa: Integer;
  protected
    { A pausa entre rodadas - lisa, ou com batimento quando o lote pede para
      manter a conexao viva. Ver o corpo. }
    procedure Espera;
    procedure Execute; override;
  public
    constructor Create(ALote: TDemoLote; ALargada: TEvent;
                       APrimeiro, APasso, APedidos, APausa: Integer);
  end;

{ TDemoLote }

constructor TDemoLote.Create(const AURL, AEngine: string; AVersao: TRALHTTPVersion;
  AShare, AMantemViva: boolean; AClientes, AKeepAliveMs: Integer);
var
  vInt: Integer;
begin
  inherited Create;
  FMantemViva := AMantemViva;
  FTrava := TCriticalSection.Create;
  SetLength(FClientes, AClientes);
  for vInt := 0 to AClientes - 1 do
  begin
    FClientes[vInt] := TRALClient.Create(nil);
    { Todos os clientes do lote nascem IGUAIS de proposito: a configuracao e'
      o que forma a chave do pool, entao ou compartilham todos ou nenhum.

      O engine varia entre LINHAS, nao dentro de uma: netHTTP e' o unico que
      fala HTTP/2 no Windows (ver SupportsHTTP2), e o Indy serve de linha de
      base porque nao sabe compartilhar nada - um socket por objeto, que e'
      de onde a maioria das aplicacoes esta' vindo. }
    FClientes[vInt].EngineType := AEngine;
    FClientes[vInt].BaseURL.Text := AURL;
    FClientes[vInt].HTTPVersion := AVersao;
    FClientes[vInt].ShareConnection := AShare;
    FClientes[vInt].ConnectTimeout := 15000;
    FClientes[vInt].RequestTimeout := 60000;
    { zero desliga; acima disso quem mantem a conexao viva e' o Windows, com
      frames PING de HTTP/2 - o demo nao manda nada. O RAL eleva ao piso do
      engine, entao nao ha' o que conferir aqui. }
    FClientes[vInt].KeepAliveInterval := AKeepAliveMs;
  end;
end;

destructor TDemoLote.Destroy;
var
  vInt: Integer;
begin
  for vInt := 0 to High(FClientes) do
    FClientes[vInt].Free;
  FTrava.Free;
  inherited;
end;

procedure TDemoLote.Conta(AResp: TRALResponse; const AErro: string);
begin
  FTrava.Enter;
  try
    if (AErro = '') and (AResp <> nil) and (AResp.StatusCode = HTTP_OK) then
    begin
      Inc(FOk);
      { o protocolo vem da RESPOSTA, nao do que foi pedido: no Windows o engine
        pergunta ao WinHTTP qual foi negociado de verdade, porque a linha de
        status - que e' de onde o RTL le' - nao existe em HTTP/2 }
      if AResp.ProtocolVersion = rhv2 then
        Inc(FH2);
    end
    else
    begin
      Inc(FErros);
      if FErro1 = '' then
      begin
        if AErro <> '' then
          FErro1 := AErro
        else if AResp <> nil then
          FErro1 := Format('status %d', [AResp.StatusCode])
        else
          FErro1 := 'resposta nil';
      end;
    end;
  finally
    FTrava.Leave;
  end;
end;

{ TDemoTrabalhador }

constructor TDemoTrabalhador.Create(ALote: TDemoLote; ALargada: TEvent;
  APrimeiro, APasso, APedidos, APausa: Integer);
begin
  FLote := ALote;
  FLargada := ALargada;
  FPrimeiro := APrimeiro;
  FPasso := APasso;
  FPedidos := APedidos;
  FPausa := APausa;
  FreeOnTerminate := False;
  inherited Create(False);
end;

{ A PAUSA, E O QUE A ATRAVESSA.

  Lisa, a conexao morre: o relay derruba o que ficar ocioso, como faz todo
  servidor, todo proxy e todo NAT de operadora. A rodada seguinte paga
  handshake de novo.

  Com batimento, nao morre - trafego e' trafego, e quem conta ociosidade nao
  distingue um pedido de trabalho de um pedido de sinal de vida. E' o que o
  KeepAliveInterval faz no engine OkHttp, sozinho e melhor: la' sao frames
  PING de HTTP/2, que nem viram requisicao, e a conexao ainda cai sozinha
  quando o pong nao volta. O netHTTP nao tem essa propriedade
  (SupportsKeepAliveInterval e' False), entao aqui isto e' EMULADO com um
  pedido leve - que e', exatamente, o heartbeat que muita aplicacao ja' faz
  a mao.

  So' o trabalhador 0 bate: a conexao e' uma so', um batimento basta. E os
  pedidos de batimento NAO entram na conta - nao sao trabalho, sao o preco de
  manter a linha aberta. }
procedure TDemoTrabalhador.Espera;
var
  vFim: UInt64;
  vIntervalo, vFatia: Integer;
  vResp: TRALResponse;
begin
  if (not FLote.MantemViva) or (FPrimeiro <> 0) then
  begin
    Sleep(FPausa);
    Exit;
  end;

  { um terco da pausa: tem de ser MENOR que o tempo ocioso que derruba, e
    esse e' metade da pausa - ver btCompararClick }
  vIntervalo := FPausa div 3;
  if vIntervalo < 50 then
    vIntervalo := 50;

  { o relogio manda, e nao a contagem de fatias: cada batimento gasta um
    tempinho, e sem isto a pausa iria crescendo rodada a rodada }
  vFim := GetTickCount64 + UInt64(FPausa);
  while GetTickCount64 < vFim do
  begin
    vFatia := vFim - GetTickCount64;
    if vFatia > vIntervalo then
      vFatia := vIntervalo;
    Sleep(vFatia);
    if GetTickCount64 >= vFim then
      Break;

    vResp := nil;
    try
      FLote.FClientes[0].Get('ping', vResp);
    except
      // um batimento perdido nao invalida a medicao; o proximo vem
    end;
    vResp.Free;
  end;
end;

procedure TDemoTrabalhador.Execute;
var
  vResp: TRALResponse;
  vRodada, vIdx: Integer;
begin
  FLargada.WaitFor(INFINITE);
  for vRodada := 0 to FPedidos - 1 do
  begin
    { A PAUSA ENTRE RODADAS existe para as conexoes ESFRIAREM.

      Sem ela o HTTP/1.1 sai medido melhor do que e': as suas conexoes
      ficam quentes do comeco ao fim da rajada e o handshake e' pago uma
      vez na vida. Num aplicativo de verdade o operador pensa, anda, troca
      de tela - e o servidor, o proxy ou a operadora derrubam o que estava
      ocioso. Ai' a proxima rodada paga UMA conexao quando ha' share+h2 e
      paga UMA POR CLIENTE quando nao ha'.

      Quem derruba, aqui, e' o relay - TempoOciosoMs -, que e' exatamente
      o papel do keep-alive timeout de um servidor. }
    if (vRodada > 0) and (FPausa > 0) then
      Espera;

    vIdx := FPrimeiro;
    while vIdx <= High(FLote.FClientes) do
    begin
      vResp := nil;
      try
        FLote.FClientes[vIdx].Get('lento', vResp);
        FLote.Conta(vResp, '');
      except
        on E: Exception do
          FLote.Conta(nil, E.ClassName + ': ' + E.Message);
      end;
      vResp.Free;
      Inc(vIdx, FPasso);
    end;
  end;
end;

procedure TfPrincipal.NovoCaminho(APorta: Word; ALatencia: Integer);
begin
  FRelay.Desligar;
  FRelay.Ligar(APorta, StrToIntDef(edPorta.Text, PORTA_SERVIDOR), ALatencia);
end;

procedure TfPrincipal.MedeCelula(var ACelula: TDemoCelula; APorta: Word;
  AClientes, APedidos, ASimultaneos, APausa: Integer);
var
  vLote: TDemoLote;
  vLargada: TEvent;
  vThreads: array of TDemoTrabalhador;
  vInt: Integer;
  vRelogio: TStopwatch;
begin
  if ASimultaneos > AClientes then
    ASimultaneos := AClientes;
  if ASimultaneos < 1 then
    ASimultaneos := 1;

  vLargada := TEvent.Create(nil, True, False, '');
  vLote := TDemoLote.Create(BaseURL(APorta), ACelula.Engine, ACelula.Versao,
                            ACelula.Share, ACelula.MantemViva, AClientes,
                            IfThen(ACelula.PingNativo, MINKEEPALIVEMS, 0));
  try
    SetLength(vThreads, ASimultaneos);
    for vInt := 0 to ASimultaneos - 1 do
      vThreads[vInt] := TDemoTrabalhador.Create(vLote, vLargada, vInt,
                                                ASimultaneos, APedidos, APausa);
    Sleep(150);     // todas chegam ao WaitFor antes da largada
    FRelay.Zerar;   // conta o que a MEDICAO abrir

    vRelogio := TStopwatch.StartNew;
    vLargada.SetEvent;
    for vInt := 0 to ASimultaneos - 1 do
      vThreads[vInt].WaitFor;
    vRelogio.Stop;

    for vInt := 0 to ASimultaneos - 1 do
      vThreads[vInt].Free;

    { o tempo relatado e' o de TRABALHO: as pausas sao ociosidade simulada,
      iguais nas quatro celulas, e deixa-las dentro do numero so' diluiria
      a diferenca que a medicao existe para mostrar. Todos os trabalhadores
      dormem as mesmas pausas ao mesmo tempo, entao descontar o nominal e'
      exato o bastante. }
    ACelula.Ms := vRelogio.ElapsedMilliseconds - APausa * (APedidos - 1);
    if ACelula.Ms < 0 then
      ACelula.Ms := 0;
    ACelula.Abertas := FRelay.Conexoes;
    ACelula.Pico := FRelay.Pico;
    ACelula.Ok := vLote.Ok;
    ACelula.Erros := vLote.Erros;
    ACelula.H2 := vLote.H2;
    ACelula.Erro1 := vLote.Erro1;
  finally
    vLote.Free;
    vLargada.Free;
  end;
end;

{ A COLUNA DE AVISOS. Uma coluna fixa contando quantas respostas vieram em h2
  nao dizia nada nas linhas que nem pediram h2 - mas a pergunta que ela
  protegia continua valendo, e aparece aqui, so' quando ha' o que avisar:
  pedir rhv2 e receber 1.1 e' uma medicao valida com o rotulo errado, e isso
  nao pode passar em silencio. }
function TfPrincipal.AvisoDaCelula(const ACelula: TDemoCelula): string;
begin
  if (ACelula.Erros > 0) and SameText(ACelula.Engine, 'Indy') and
     (ACelula.Ok = 0) then
    { a falha classica desta linha: o engine Indy fala TLS por OpenSSL, e o
      Windows nao traz o par que ele carrega }
    Result := 'Indy nao subiu - ponha libeay32.dll e ssleay32.dll ' +
              '(OpenSSL 1.0.2) ao lado do exe. ' + ACelula.Erro1
  else if ACelula.Erros > 0 then
    Result := Format('%d falhas: %s', [ACelula.Erros, ACelula.Erro1])
  else if (ACelula.Versao = rhv2) and (ACelula.H2 < ACelula.Ok) then
    Result := Format('pediu h2, mas %d de %d respostas vieram em 1.1',
                     [ACelula.Ok - ACelula.H2, ACelula.Ok])
  else if ACelula.PingNativo then
    Result := 'ping NATIVO do Windows (WinHTTP, opcao 164)'
  else if ACelula.MantemViva and PingNativoDoWindows then
    { vale dizer que a maquina TEM o recurso e a medicao nao o usou, senao
      quem esta' num Windows 11 conclui que ele nao existe }
    Result := Format('batimento imitado; este Windows tem o ping nativo - ' +
                     'ponha a pausa em %d ms ou mais', [PAUSA_MIN_NATIVA])
  else if ACelula.MantemViva then
    Result := 'batimento imitado (este Windows nao tem a opcao 164)'
  else
    Result := '';
end;

procedure TfPrincipal.btCompararClick(Sender: TObject);
const
  { a ordem conta a historia: os dois sem compartilhar primeiro, os dois com
    compartilhar depois, e dentro de cada par 1.1 antes de h2 }
  M_ENGINE: array [0 .. 4] of string =
    ('Indy', 'netHTTP', 'netHTTP', 'netHTTP', 'netHTTP');
  M_SHARE: array [0 .. 4] of boolean = (False, False, True, True, True);
  M_VER: array [0 .. 4] of TRALHTTPVersion =
    (rhv11, rhv2, rhv11, rhv2, rhv2);
  { so' o ultimo degrau mantem a conexao viva: e' identico ao anterior em
    tudo o mais, entao a diferenca entre as duas linhas e' EXATAMENTE o que
    manter a conexao aberta compra }
  M_VIVA: array [0 .. 4] of boolean = (False, False, False, False, True);
var
  vClientes, vPedidos, vSimult, vLatencia, vPausa, vInt, vTotal: Integer;
  vPorta: Word;
begin
  if (FServer = nil) or (not FServer.Active) then
  begin
    ShowMessage('Ligue o servidor na primeira aba.');
    Exit;
  end;

  vClientes := StrToIntDef(edClientes.Text, 40);
  vPedidos := StrToIntDef(edPedidos.Text, 10);
  vSimult := StrToIntDef(edSimultaneos.Text, 10);
  vLatencia := StrToIntDef(edLatencia.Text, 120);
  vPausa := StrToIntDef(edPausa.Text, 600);
  if vClientes < 1 then
    vClientes := 1;
  if vPedidos < 1 then
    vPedidos := 1;
  vTotal := vClientes * vPedidos;
  vPorta := PORTA_RELAY;

  FMedido := False;
  pbGrafico.Invalidate;
  btComparar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    Log(Format('matriz: %d clientes x %d pedidos = %d requisicoes, %d simultaneas',
      [vClientes, vPedidos, vTotal, vSimult]));
    if not PreparadoParaHTTP2 then
      Log('sem http.sys+TLS: as quatro celulas vao negociar HTTP/1.1');

    for vInt := 0 to 4 do
    begin
      FCelulas[vInt].Engine := M_ENGINE[vInt];
      FCelulas[vInt].Share := M_SHARE[vInt];
      FCelulas[vInt].Versao := M_VER[vInt];
      { OS DOIS MECANISMOS SE EXCLUEM, e o nativo so' entra quando os numeros
        deixam: sem a opcao no Windows, ou com pausa curta demais para o
        WinHTTP chegar a pingar, a linha usa o batimento imitado. }
      FCelulas[vInt].PingNativo := M_VIVA[vInt] and PingNativoDoWindows and
                                   (vPausa >= PAUSA_MIN_NATIVA);
      FCelulas[vInt].MantemViva := M_VIVA[vInt] and
                                   (not FCelulas[vInt].PingNativo);

      { CADA celula numa PORTA NOVA: o WinHTTP mantem pool de conexao no
        processo inteiro, e sem isso a celula seguinte herdaria uma conexao
        quente da anterior - e "conexao fria" mediria conexao quente. }
      NovoCaminho(vPorta, vLatencia);
      { o relay derruba o que ficar ocioso por metade da pausa: assim toda
        conexao chega FRIA na rodada seguinte, em qualquer das celulas.
        Na linha do ping nativo ele espera MAIS do que o intervalo do ping -
        senao ceifaria a conexao antes de o Windows chegar a defende-la, e a
        medicao diria que o recurso nao funciona quando quem nao deixou foi
        o proprio medidor. }
      if FCelulas[vInt].PingNativo then
        FRelay.TempoOciosoMs := OCIOSO_NATIVO
      else
        FRelay.TempoOciosoMs := vPausa div 2;
      MedeCelula(FCelulas[vInt], vPorta, vClientes, vPedidos, vSimult, vPausa);
      Inc(vPorta);

      { ESFRIA TUDO ANTES DA PROXIMA LINHA. Derrubar a escuta mata o que
        ainda estivesse aberto, e a espera da' tempo de o cliente perceber.
        Sem isso a celula seguinte comecaria com conexao quente herdada -
        que e' o erro classico de medicao aqui, e favorece justamente quem
        abriu mais conexoes na celula anterior. }
      FRelay.Desligar;
      if vPausa > 0 then
        Sleep(vPausa);

      sgResultado.Cells[0, vInt + 1] := ROTULOS_CELULA[vInt];
      sgResultado.Cells[1, vInt + 1] := IntToStr(FCelulas[vInt].Abertas);
      sgResultado.Cells[2, vInt + 1] := IntToStr(FCelulas[vInt].Pico);
      sgResultado.Cells[3, vInt + 1] := IntToStr(FCelulas[vInt].Ms);
      sgResultado.Cells[4, vInt + 1] :=
        Format('%d / %d', [FCelulas[vInt].Ok, vTotal]);
      sgResultado.Cells[5, vInt + 1] := AvisoDaCelula(FCelulas[vInt]);

      Application.ProcessMessages; // a tabela vai preenchendo a olhos vistos
    end;

    FMedido := True;
    pbGrafico.Invalidate;
    Log('matriz medida');
  finally
    FRelay.Desligar;
    Screen.Cursor := crDefault;
    btComparar.Enabled := True;
  end;
end;

{ --------------------------------------------------------------- grafico -- }

{ Tres blocos, um por metrica, porque as tres tem UNIDADES diferentes e
  empilhar tudo numa escala so' seria bonito e mentiroso. Em todas o menor
  vence, e o vencedor e' o unico colorido: a barra que se destaca e' a resposta.

  Nao ha' legenda de cores de proposito - cada barra ja' traz o seu rotulo e o
  seu numero ao lado, e uma legenda so' acrescentaria um lugar a mais para o
  olho ter de ir. }
procedure TfPrincipal.pbGraficoPaint(Sender: TObject);
const
  COR_FUNDO   = TColor($00FAFAF8);
  COR_BARRA   = TColor($00D2D2D2);
  COR_VENCE   = TColor($00626B0B); // petroleo
  COR_TRILHA  = TColor($00E8E8E8);
  COR_APAGADO = TColor($00808080);
  LARG_ROTULO = 108;
  LARG_VALOR  = 60;
  ALT_BARRA   = 20;
  ESP_BARRA   = 8;
  TOPO_BARRAS = 32;

  procedure Bloco(AEsq, ALarg: Integer; const ATitulo: string;
                  const AValores: array of Integer; const ASufixo: string);
  var
    vCv: TCanvas;
    vInt, vMax, vLarg, vTopo, vMenor: Integer;
    vRet: TRect;
  begin
    vCv := pbGrafico.Canvas;

    vCv.Brush.Style := bsClear;
    vCv.Font.Style := [fsBold];
    vCv.Font.Color := clWindowText;
    vCv.TextOut(AEsq, 8, ATitulo);
    vCv.Font.Style := [];

    vMax := 0;
    vMenor := MaxInt;
    for vInt := 0 to High(AValores) do
    begin
      if AValores[vInt] > vMax then
        vMax := AValores[vInt];
      if AValores[vInt] < vMenor then
        vMenor := AValores[vInt];
    end;
    if vMax <= 0 then
      vMax := 1;

    for vInt := 0 to High(AValores) do
    begin
      vTopo := TOPO_BARRAS + vInt * (ALT_BARRA + ESP_BARRA);

      vCv.Brush.Style := bsClear;
      vCv.Font.Color := COR_APAGADO;
      vCv.TextOut(AEsq, vTopo + 3, ROTULOS_CURTO[vInt]);

      { a trilha inteira desenhada primeiro: sem ela uma barra curta fica
        solta no branco e nao da' para ver de que ela e' fracao }
      vRet := Rect(AEsq + LARG_ROTULO, vTopo,
                   AEsq + ALarg - LARG_VALOR, vTopo + ALT_BARRA);
      vCv.Brush.Style := bsSolid;
      vCv.Brush.Color := COR_TRILHA;
      vCv.FillRect(vRet);

      vLarg := Round((vRet.Right - vRet.Left) * AValores[vInt] / vMax);
      if (vLarg < 2) and (AValores[vInt] > 0) then
        vLarg := 2; // um valor que existe nunca desaparece
      vRet.Right := vRet.Left + vLarg;
      if AValores[vInt] = vMenor then
        vCv.Brush.Color := COR_VENCE
      else
        vCv.Brush.Color := COR_BARRA;
      vCv.FillRect(vRet);

      vCv.Brush.Style := bsClear;
      if AValores[vInt] = vMenor then
      begin
        vCv.Font.Color := COR_VENCE;
        vCv.Font.Style := [fsBold];
      end
      else
        vCv.Font.Color := clWindowText;
      vCv.TextOut(AEsq + ALarg - LARG_VALOR + 6, vTopo + 4,
                  IntToStr(AValores[vInt]) + ASufixo);
      vCv.Font.Style := [];
    end;
  end;

var
  vCv: TCanvas;
  vAbertas, vPico, vMs: array [0 .. 4] of Integer;
  vInt, vLarg: Integer;
  vTxt: string;
begin
  vCv := pbGrafico.Canvas;
  vCv.Brush.Style := bsSolid;
  vCv.Brush.Color := COR_FUNDO;
  vCv.FillRect(pbGrafico.ClientRect);

  if not FMedido then
  begin
    vCv.Brush.Style := bsClear;
    vCv.Font.Color := COR_APAGADO;
    vTxt := 'Clique em "Medir as quatro" - o grafico das tres metricas aparece aqui.';
    vCv.TextOut((pbGrafico.Width - vCv.TextWidth(vTxt)) div 2,
                pbGrafico.Height div 2 - 8, vTxt);
    Exit;
  end;

  for vInt := 0 to 4 do
  begin
    vAbertas[vInt] := FCelulas[vInt].Abertas;
    vPico[vInt] := FCelulas[vInt].Pico;
    vMs[vInt] := FCelulas[vInt].Ms;
  end;

  vLarg := pbGrafico.Width div 3;
  Bloco(10, vLarg - 20, 'Abertas no total = handshakes pagos', vAbertas, '');
  Bloco(vLarg + 10, vLarg - 20, 'Ao mesmo tempo (pico)', vPico, '');
  Bloco(2 * vLarg + 10, vLarg - 20, 'Tempo total', vMs, ' ms');

  vCv.Brush.Style := bsClear;
  vCv.Font.Color := COR_APAGADO;
  vCv.TextOut(10, TOPO_BARRAS + 5 * (ALT_BARRA + ESP_BARRA) + 8,
    'Menor e melhor nos tres. ABERTAS e o acumulado da medicao inteira; PICO e o ' +
    'maior numero que existiu ao mesmo tempo - por isso pico nunca passa de abertas.');
end;

{ ------------------------------------------------------------------- form -- }

procedure TfPrincipal.FormCreate(Sender: TObject);
var
  vInt: Integer;
begin
  cbModo.Items.Clear;
  cbModo.Items.Add('Threads - uma thread por conexao (padrao)');
  cbModo.Items.Add('Async - IOCP, uma thread para muitas conexoes');
  cbModo.Items.Add('HTTP.sys - kernel do Windows (UNICO com HTTP/2)');
  cbModo.ItemIndex := 2;
  cbModoChange(nil); // e' quem acerta a caixa de TLS ao modo escolhido

  edPorta.Text := IntToStr(PORTA_SERVIDOR);
  edClientes.Text := '40';
  edPedidos.Text := '10';
  edSimultaneos.Text := '10';
  edLatencia.Text := '120';
  edPausa.Text := '600';

  mmSQLDAO.Lines.Text := 'SELECT ID, DESCRICAO, QUANTIDADE, PRECO' + sLineBreak +
                         'FROM ITENS ORDER BY ID';
  mmSQLDBWare.Lines.Text := 'SELECT ID, DESCRICAO, PRECO' + sLineBreak +
                            'FROM ITENS ORDER BY ID';

  { uma linha por celula da matriz, na mesma ordem em que sao medidas }
  sgResultado.ColCount := 6;
  sgResultado.RowCount := 6;
  sgResultado.Cells[0, 0] := 'Celula';
  sgResultado.Cells[1, 0] := 'Abertas no total';
  sgResultado.Cells[2, 0] := 'Ao mesmo tempo';
  sgResultado.Cells[3, 0] := 'Tempo (ms)';
  sgResultado.Cells[4, 0] := 'OK';
  sgResultado.Cells[5, 0] := 'Falhas e avisos';
  sgResultado.ColWidths[0] := 224;
  sgResultado.ColWidths[1] := 116;
  sgResultado.ColWidths[2] := 112;
  sgResultado.ColWidths[3] := 92;
  sgResultado.ColWidths[4] := 84;
  sgResultado.ColWidths[5] := 296;
  for vInt := 0 to 4 do
    sgResultado.Cells[0, vInt + 1] := ROTULOS_CELULA[vInt];

  mmExplica.Lines.Clear;
  mmExplica.Lines.Add('===== A MATRIZ: ShareConnection x HTTPVersion =====');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('A PRIMEIRA LINHA e o ponto de partida, e usa outro engine de proposito: o');
  mmExplica.Lines.Add('Indy nao sabe compartilhar conexao (SupportsSharedConnection = False), entao');
  mmExplica.Lines.Add('e um socket por TRALClient, sempre. E de onde a maioria das aplicacoes vem,');
  mmExplica.Lines.Add('e o unico jeito de ver no Windows quanto custa nao compartilhar - ver (c).');
  mmExplica.Lines.Add('As outras sao o MESMO engine com os interruptores virados, que e o que');
  mmExplica.Lines.Add('isola o efeito de cada um.');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('A ULTIMA LINHA e o degrau que falta na maioria dos projetos. Ela e igual a');
  mmExplica.Lines.Add('anterior em tudo - netHTTP, share, h2 - menos numa coisa: a conexao e');
  mmExplica.Lines.Add('MANTIDA VIVA durante as pausas, entao nao esfria e o handshake e pago UMA');
  mmExplica.Lines.Add('vez na vida do aplicativo, em vez de uma por rodada. A diferenca entre as');
  mmExplica.Lines.Add('duas ultimas linhas e exatamente isso, e nada mais.');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('   No ANDROID isso e uma propriedade: KeepAliveInterval, do engine OkHttp,');
  mmExplica.Lines.Add('   que manda frames PING de HTTP/2 - nem viram requisicao - e ainda derruba');
  mmExplica.Lines.Add('   a conexao quando o pong nao volta, avisando em segundos que a rede caiu.');
  mmExplica.Lines.Add('   No WINDOWS a mesma propriedade funciona desde o Windows 11, por baixo');
  mmExplica.Lines.Add('   com WINHTTP_OPTION_HTTP2_KEEPALIVE: quem manda os frames PING e o');
  mmExplica.Lines.Add('   proprio WinHTTP. Duas diferencas para o Android: o Windows so comeca a');
  mmExplica.Lines.Add('   pingar depois do intervalo de SILENCIO (o OkHttp pinga sempre) e recusa');
  mmExplica.Lines.Add('   intervalo abaixo de 5000 ms, por isso a propriedade eleva ao piso do');
  mmExplica.Lines.Add('   engine na hora da atribuicao. No Windows 10 a opcao nao existe, e la o');
  mmExplica.Lines.Add('   pedido sai em HTTP/2 do mesmo jeito, so que sem ping.');
  mmExplica.Lines.Add('   Esta linha usa o ping NATIVO quando a maquina tem a opcao e a pausa e');
  mmExplica.Lines.Add('   longa o bastante para ele agir; senao cai num batimento imitado com um');
  mmExplica.Lines.Add('   pedido leve. A coluna de avisos diz qual dos dois rodou.');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('Os dois eixos compram coisas DIFERENTES, e um nao faz o trabalho do outro:');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('  ShareConnection economiza HANDSHAKE. Um transporte para todos os clientes');
  mmExplica.Lines.Add('  que apontam para o mesmo lugar com a mesma configuracao, em vez de um por');
  mmExplica.Lines.Add('  dataset. Vale em HTTP/1.1 tambem: olhe a coluna CONEXOES ABERTAS.');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('  HTTP/2 economiza CONEXAO SIMULTANEA. Varios pedidos no ar sobre a MESMA');
  mmExplica.Lines.Add('  conexao, cada um num stream. Olhe a coluna PICO SIMULTANEO.');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('Sem compartilhar nao existe conexao unica para multiplexar, e por isso');
  mmExplica.Lines.Add('"sem share + h2" costuma ser a PIOR das quatro: cada cliente ganha o seu');
  mmExplica.Lines.Add('proprio transporte, nenhum e limitado a uma conexao, e as conexoes h2 ainda');
  mmExplica.Lines.Add('ficam abertas. E o custo do HTTP/2 sem o beneficio dele.');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('===== EM UMA FRASE =====');
  mmExplica.Lines.Add('Se ligar HTTPVersion = rhv2, ligue ShareConnection junto. Separados, um');
  mmExplica.Lines.Add('deles so paga o preco do outro.');
  mmExplica.Lines.Add('');
  mmExplica.Lines.Add('===== DOIS AVISOS HONESTOS =====');
  mmExplica.Lines.Add('a) O custo de abrir conexao e simulado por um relay local, porque em loopback');
  mmExplica.Lines.Add('   TCP+TLS custam microssegundos e nada apareceria. Contra um servidor na');
  mmExplica.Lines.Add('   internet sao dois a tres round-trips - os 120 ms do campo sao um enlace');
  mmExplica.Lines.Add('   comum. ENCAMINHAR nao custa nada: o relay simula distancia, nao banda.');
  mmExplica.Lines.Add('   Ele tambem e quem conta as conexoes, porque contar por fora (netstat)');
  mmExplica.Lines.Add('   engana: conexao ociosa fecha sozinha e TIME_WAIT continua aparecendo.');
  mmExplica.Lines.Add('b) A PAUSA ENTRE RODADAS nao e enfeite. Sem ela o HTTP/1.1 sai melhor do');
  mmExplica.Lines.Add('   que e: as conexoes dele ficam quentes a rajada inteira e o handshake e');
  mmExplica.Lines.Add('   pago uma vez na vida. Num app de verdade o operador pensa e anda, e o');
  mmExplica.Lines.Add('   servidor derruba o keep-alive ocioso - aqui quem derruba e o relay. O');
  mmExplica.Lines.Add('   tempo das pausas nao entra na coluna Tempo: e ociosidade, nao trabalho.');
  mmExplica.Lines.Add('   Ponha 0 para ver o outro extremo, uma rajada unica sem esfriar nada.');
  mmExplica.Lines.Add('c) NO WINDOWS, O ShareConnection NAO MUDA A CONTA DO HTTP/1.1 - e isso e');
  mmExplica.Lines.Add('   medido, nao suposto. O WinHTTP mantem as conexoes 1.1 num pool do');
  mmExplica.Lines.Add('   PROCESSO: cinco TRALClient diferentes, cada um com a sua sessao, sem');
  mmExplica.Lines.Add('   compartilhar nada, abriram UMA conexao so. Ja as conexoes HTTP/2 ficam');
  mmExplica.Lines.Add('   presas a sessao que as negociou: os mesmos cinco clientes abriram CINCO.');
  mmExplica.Lines.Add('   Por isso as duas linhas de 1.1 empatam e as duas de h2 nao: aqui o');
  mmExplica.Lines.Add('   ShareConnection vale por causa do h2, e nao apesar dele. O que ele');
  mmExplica.Lines.Add('   sempre muda, nos dois protocolos, e o pote de cookies e o objeto de');
  mmExplica.Lines.Add('   transporte - um por grupo, em vez de um por dataset.');
  mmExplica.Lines.Add('d) A coluna "respostas em h2" vem da RESPOSTA, nao do que foi pedido. Pedir');
  mmExplica.Lines.Add('   rhv2 nao e obter rhv2: se o servidor nao oferecer h2 no ALPN, o pedido');
  mmExplica.Lines.Add('   volta em 1.1 e isso e uma requisicao bem-sucedida, nao um erro.');

  FRelay := TDemoRelay.Create;
  CriaBanco;
  AtualizaEstado;

  mmRotas.Lines.Add('Ligue o servidor na aba Servidor e clique nos botoes acima.');
end;

procedure TfPrincipal.FormDestroy(Sender: TObject);
begin
  if FRelay <> nil then
    FRelay.Desligar;
  FreeAndNil(FRelay);

  { mesma ordem do desligar: primeiro quem consome, depois quem publica }
  FreeAndNil(FQryDAO);
  FreeAndNil(FTabDBWare);
  FreeAndNil(FConnDBWare);
  FreeAndNil(FStorage);
  FreeAndNil(FCliDAO);
  FreeAndNil(FCliDBWare);
  if FServer <> nil then
    FServer.Active := False;
  FreeAndNil(FModulo);
  FreeAndNil(FConnDAO);
  FreeAndNil(FServer);
end;

initialization
  { a grade da aba 4 e' desta classe, e o leitor do .dfm precisa saber acha-la }
  RegisterClasses([TRALGradeLeitura]);

end.
