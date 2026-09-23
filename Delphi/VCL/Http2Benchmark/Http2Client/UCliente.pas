/// Cliente do benchmark HTTP/2 do PascalRAL, sobre o engine netHTTP.
///
/// E' o mesmo cliente do QuicBenchmark ao lado, com o motor trocado: onde la'
/// ia TRALMsQuicClient sobre QUIC, aqui vai RALnetHTTPClient sobre TCP+TLS, com
/// HTTP/2 negociado por ALPN. As tres abas, as rotas e o banco sao os mesmos, de
/// proposito - o que muda e' o transporte, e e' isso que esta' sendo comparado.
///
///   1. Benchmark: N clientes x M requisicoes simultaneas por cliente x R
///      rajadas, com taxa de erro, vazao e tempo de resposta.
///   2. Testes: ping, parametros, multipart e eco, com a saida num memo.
///   3. Banco: a mesma tabela Firebird pelos dois stacks de banco do RAL, o
///      DAO (TRALFDQuery) e o DBWare (TRALDBFDMemTable), lado a lado.
///
/// DUAS COISAS SO' EXISTEM AQUI, e sao as que fazem a comparacao valer:
///
/// "Versao HTTP" e' o que o cliente PEDE (TRALClient.HTTPVersion); o que o ALPN
/// fechou de verdade vem em TRALResponse.ProtocolVersion, e o benchmark conta
/// quantas respostas voltaram em h2. Pedir nao e' obter - h2 so' acontece sobre
/// TLS e, do lado do servidor, so' no modo http.sys.
///
/// "Esquema" existe porque os modos de socket do servidor sobem em http simples
/// (o certificado do modo http.sys mora na loja da maquina, e os de socket
/// leriam um arquivo que este benchmark nao tem). Com http nao ha ALPN, logo nao
/// ha HTTP/2: e' a linha de base HTTP/1.1.
unit UCliente;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.SyncObjs,
  System.Diagnostics, System.DateUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.Graphics,
  Data.DB,
  { FireDAC.Phys e FireDAC.DApt sao obrigatorios mesmo sem banco local: o
    TRALFDQuery e' um TFDQuery e, ao carregar o resultado, cria um TFDConnection
    que pede a fabrica do gerenciador fisico - sem ela todo Open morre com
    "Object factory for class ... is missing ... TFDPhysXXXDriverLink" }
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.Phys, FireDAC.DApt, FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI,

  RALTypes, RALConsts, RALMIMETypes, RALClient, RALRequest, RALResponse,
  RALParams, RALCompress, RALCompressZLib, RALCripto, RALCriptoAES,
  RALnetHTTPClient,
  RALStorage, RALStorageBIN, RALDBConnection, RALDBFiredacMemTable,
  RALDBFiredacDAO;

type
  /// O que a barra de cima define, copiado para quem for usar.
  TConfigCliente = record
    Esquema: string;
    Host: string;
    Porta: Integer;
    Timeout: Integer;
    Versao: TRALHTTPVersion;
    Validar: Boolean;
    Pin: string;
    Compress: TRALCompressType;
    Cripto: TRALCriptoType;
    Chave: string;
    Compartilhar: Boolean;
  end;

  TMaquina = class;

  /// Uma requisicao de cada vez, R vezes, sobre o cliente da sua maquina.
  /// M destes por maquina e' o "M simultaneas por cliente" da tela.
  TTrabalhador = class(TThread)
  private
    FMaquina: TMaquina;
    FRajadas: Integer;
    FRota: string;
  protected
    procedure Execute; override;
  public
    Enviadas: Integer;
    Erros: Integer;
    { quantas RESPOSTAS voltaram em HTTP/2 - a unica medida honesta, ja' que
      pedir rhv2 nao e' obter rhv2 }
    EmH2: Integer;
    SomaTicks: Int64;
    MinTicks: Int64;
    MaxTicks: Int64;
    constructor Create(AMaquina: TMaquina; ARajadas: Integer; const ARota: string);
  end;

  /// Um "cliente" do benchmark: um TRALClient proprio, como se fosse outra
  /// maquina, e M trabalhadores batendo nele ao mesmo tempo.
  TMaquina = class
  private
    FClient: TRALClient;
    FConfig: TConfigCliente;
    function AceitaCertificado(ASender: TObject; const ACert: TRALCertInfo): Boolean;
  public
    Trabalhadores: array of TTrabalhador;
    constructor Create(const AConfig: TConfigCliente; ASimultaneas, ARajadas: Integer;
      const ARota: string);
    destructor Destroy; override;
    property Client: TRALClient read FClient;
  end;

  TfCliente = class(TForm)
    pnTopo: TPanel;
    gbConexao: TGroupBox;
    lbHost: TLabel;
    edHost: TEdit;
    lbPorta: TLabel;
    edPorta: TEdit;
    lbTimeout: TLabel;
    edTimeout: TEdit;
    lbCompress: TLabel;
    cbCompress: TComboBox;
    lbCripto: TLabel;
    cbCripto: TComboBox;
    lbChaveCripto: TLabel;
    edChaveCripto: TEdit;
    lbEsquema: TLabel;
    cbEsquema: TComboBox;
    lbVersao: TLabel;
    cbVersao: TComboBox;
    ckValidar: TCheckBox;
    lbPin: TLabel;
    edPin: TEdit;
    lbConexao: TLabel;
    cbConexao: TComboBox;
    pgAbas: TPageControl;
    tsBench: TTabSheet;
    pnBenchTopo: TPanel;
    lbClientes: TLabel;
    edClientes: TEdit;
    lbSimultaneas: TLabel;
    edSimultaneas: TEdit;
    lbRajadas: TLabel;
    edRajadas: TEdit;
    lbRota: TLabel;
    cbRota: TComboBox;
    btIniciar: TButton;
    btParar: TButton;
    pbProgresso: TProgressBar;
    lbEnviadas: TLabel;
    lbErros: TLabel;
    lbVazao: TLabel;
    lbProtocolo: TLabel;
    lbTempos: TLabel;
    lbDecorrido: TLabel;
    mmBench: TMemo;
    tsTestes: TTabSheet;
    pnTestesTopo: TPanel;
    btPing: TButton;
    btParams: TButton;
    btMultipart: TButton;
    btEco: TButton;
    btLimpar: TButton;
    mmTestes: TMemo;
    tsBanco: TTabSheet;
    pnBancoTopo: TPanel;
    lbSQL: TLabel;
    edSQL: TEdit;
    pnDAO: TPanel;
    pnDAOTopo: TPanel;
    btAbrirDAO: TButton;
    btGravarDAO: TButton;
    lbDAO: TLabel;
    gridDAO: TDBGrid;
    spBanco: TSplitter;
    pnDBW: TPanel;
    pnDBWTopo: TPanel;
    btAbrirDBW: TButton;
    btGravarDBW: TButton;
    lbDBW: TLabel;
    gridDBW: TDBGrid;
    dsDAO: TDataSource;
    dsDBW: TDataSource;
    tmBench: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btIniciarClick(Sender: TObject);
    procedure btPararClick(Sender: TObject);
    procedure tmBenchTimer(Sender: TObject);
    procedure btPingClick(Sender: TObject);
    procedure btParamsClick(Sender: TObject);
    procedure btMultipartClick(Sender: TObject);
    procedure btEcoClick(Sender: TObject);
    procedure btLimparClick(Sender: TObject);
    procedure btAbrirDAOClick(Sender: TObject);
    procedure btGravarDAOClick(Sender: TObject);
    procedure btAbrirDBWClick(Sender: TObject);
    procedure btGravarDBWClick(Sender: TObject);
  private
    FMaquinas: array of TMaquina;
    FInicio: TStopwatch;
    FTotal: Integer;
    // aba de testes
    FCliTestes: TRALClient;
    // aba de banco
    FCliDAO: TRALClient;
    FQryDAO: TRALFDQuery;
    FCliDBW: TRALClient;
    FConnDBW: TRALDBConnection;
    FTabDBW: TRALDBFDMemTable;
    FStorage: TRALStorageBINLink;
    function LerConfig: TConfigCliente;
    function ClienteDeTestes: TRALClient;
    procedure LogTeste(const ATexto: string);
    procedure LogBench(const ATexto: string);
    procedure FinalizarBench;
    procedure LiberarMaquinas;
    procedure OnErroDBW(Sender: TObject; AError: StringRAL);
  public
  end;

/// Um TRALClient sobre o engine netHTTP, com tudo que a barra de cima pede.
function NovoCliente(const AConfig: TConfigCliente): TRALClient;

var
  fCliente: TfCliente;

implementation

{$R *.dfm}

var
  gFeitas: Integer;
  gErros: Integer;
  gEmH2: Integer;
  gConcluidos: Integer;
  gParar: Boolean;

function NovoCliente(const AConfig: TConfigCliente): TRALClient;
begin
  Result := TRALClient.Create(nil);
  Result.EngineType := ENGINENETHTTP;
  { depois do EngineType, sempre: trocar o engine REPOE a versao (um rhv2
    deixado para tras derrubaria um engine que so' fala 1.1) }
  Result.HTTPVersion := AConfig.Versao;
  Result.BaseURL.Text := Format('%s://%s:%d', [AConfig.Esquema, AConfig.Host, AConfig.Porta]);
  Result.ConnectTimeout := AConfig.Timeout;
  Result.RequestTimeout := AConfig.Timeout;
  Result.CompressType := AConfig.Compress;
  Result.CriptoOptions.CriptType := AConfig.Cripto;
  Result.CriptoOptions.Key := StringRAL(AConfig.Chave);
  Result.ShareConnection := AConfig.Compartilhar;
  if AConfig.Validar then
    Result.SSL.Verify := svEngine
  else
    Result.SSL.Verify := svNever;
  if AConfig.Pin <> '' then
    Result.SSL.Pins.Add(AConfig.Pin);
end;

{ ------------------------------------------------------------- TTrabalhador }

constructor TTrabalhador.Create(AMaquina: TMaquina; ARajadas: Integer;
  const ARota: string);
begin
  inherited Create(True);
  FMaquina := AMaquina;
  FRajadas := ARajadas;
  FRota := ARota;
  MinTicks := High(Int64);
  FreeOnTerminate := False;
end;

procedure TTrabalhador.Execute;
var
  vInt: Integer;
  vResp: TRALResponse;
  vOk, vH2: Boolean;
  vRelogio: TStopwatch;
  vTicks: Int64;
begin
  for vInt := 1 to FRajadas do
  begin
    if gParar then
      Break;

    vRelogio := TStopwatch.StartNew;
    vResp := nil;
    vH2 := False;
    try
      { a sobrecarga com "var AResponse" e' sincrona e levanta excecao quando o
        transporte falha; um status diferente de 200 volta normalmente }
      FMaquina.Client.Get(StringRAL(FRota), vResp);
      vOk := (vResp <> nil) and (vResp.StatusCode = HTTP_OK);
      vH2 := (vResp <> nil) and (vResp.ProtocolVersion = rhv2);
    except
      vOk := False;
    end;
    vResp.Free;
    vTicks := vRelogio.ElapsedTicks;

    Inc(Enviadas);
    if not vOk then
      Inc(Erros);
    if vH2 then
      Inc(EmH2);
    SomaTicks := SomaTicks + vTicks;
    if vTicks < MinTicks then
      MinTicks := vTicks;
    if vTicks > MaxTicks then
      MaxTicks := vTicks;

    TInterlocked.Increment(gFeitas);
    if not vOk then
      TInterlocked.Increment(gErros);
    if vH2 then
      TInterlocked.Increment(gEmH2);
  end;
  TInterlocked.Increment(gConcluidos);
end;

{ ----------------------------------------------------------------- TMaquina }

constructor TMaquina.Create(const AConfig: TConfigCliente;
  ASimultaneas, ARajadas: Integer; const ARota: string);
var
  vInt: Integer;
begin
  inherited Create;
  FConfig := AConfig;
  FClient := NovoCliente(AConfig);
  { COM ShareConnection LIGADO o netHTTP junta no mesmo transporte - e por isso
    na mesma conexao TCP, quando fecha em h2 - todo cliente que julgue o
    certificado do mesmo jeito, e todas as maquinas deste processo julgariam
    igual, entao virariam UMA. O evento e' o que distingue: CertPolicyKey leva
    o endereco do metodo E o do objeto, cada maquina julga com o seu, a politica
    passa a ser dela, e ela ganha um transporte proprio, multiplexado pelas suas
    M threads. E' exatamente o que um aparelho com varias telas abertas faz. }
  if AConfig.Compartilhar then
    FClient.OnValidateServerCert := AceitaCertificado;

  SetLength(Trabalhadores, ASimultaneas);
  for vInt := 0 to ASimultaneas - 1 do
    Trabalhadores[vInt] := TTrabalhador.Create(Self, ARajadas, ARota);
end;

destructor TMaquina.Destroy;
var
  vInt: Integer;
begin
  for vInt := 0 to High(Trabalhadores) do
    Trabalhadores[vInt].Free;
  FClient.Free;
  inherited Destroy;
end;

{ A mesma regra que o RAL aplica sozinho, so' que dita pelo evento: pin,
  senao a validacao do sistema quando pedida, senao aceita. }
function TMaquina.AceitaCertificado(ASender: TObject;
  const ACert: TRALCertInfo): Boolean;
begin
  if FConfig.Pin <> '' then
    Result := SameText(string(ACert.Fingerprint),
      string(RALNormalizeFingerprint(StringRAL(FConfig.Pin))))
  else if FConfig.Validar then
    Result := ACert.Trusted
  else
    Result := True;
end;

{ ---------------------------------------------------------------- formulario }

procedure TfCliente.FormCreate(Sender: TObject);
begin
  cbEsquema.ItemIndex := 1;
  cbVersao.ItemIndex := 1;
  cbCompress.ItemIndex := 0;
  cbCripto.ItemIndex := 0;
  cbConexao.ItemIndex := 0;
  cbRota.ItemIndex := 0;
  pgAbas.ActivePage := tsBench;
  btParar.Enabled := False;
end;

procedure TfCliente.FormDestroy(Sender: TObject);
begin
  gParar := True;
  tmBench.Enabled := False;
  LiberarMaquinas;
  FreeAndNil(FQryDAO);
  FreeAndNil(FTabDBW);
  FreeAndNil(FConnDBW);
  FreeAndNil(FStorage);
  FreeAndNil(FCliDAO);
  FreeAndNil(FCliDBW);
  FreeAndNil(FCliTestes);
end;

function TfCliente.LerConfig: TConfigCliente;
begin
  if cbEsquema.ItemIndex = 1 then
    Result.Esquema := 'https'
  else
    Result.Esquema := 'http';
  Result.Host := Trim(edHost.Text);
  Result.Porta := StrToIntDef(edPorta.Text, 8443);
  Result.Timeout := StrToIntDef(edTimeout.Text, 15000);
  if cbVersao.ItemIndex = 1 then
    Result.Versao := rhv2
  else
    Result.Versao := rhv11;
  Result.Validar := ckValidar.Checked;
  Result.Pin := Trim(edPin.Text);
  case cbCompress.ItemIndex of
    1: Result.Compress := ctGZip;
    2: Result.Compress := ctDeflate;
    3: Result.Compress := ctZLib;
  else
    Result.Compress := ctNone;
  end;
  case cbCripto.ItemIndex of
    1: Result.Cripto := crAES128;
    2: Result.Cripto := crAES192;
    3: Result.Cripto := crAES256;
  else
    Result.Cripto := crNone;
  end;
  Result.Chave := edChaveCripto.Text;
  Result.Compartilhar := cbConexao.ItemIndex = 1;
  if (Result.Cripto <> crNone) and (Result.Chave = '') then
    raise Exception.Create('Informe a chave da criptografia - a mesma do servidor.');
  { pedir h2 em http simples nao e' erro, e' so' inutil: sem TLS nao ha ALPN.
    Dizer isso antes vale mais do que deixar a coluna de h2 zerada sem motivo
    aparente. }
  if (Result.Versao = rhv2) and (Result.Esquema = 'http') then
    raise Exception.Create('HTTP/2 s' + #243 + ' existe sobre TLS: escolha o esquema https, ' +
      'ou pe' + #231 + 'a HTTP/1.1.');
end;

procedure TfCliente.LogBench(const ATexto: string);
begin
  mmBench.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + ATexto);
end;

procedure TfCliente.LogTeste(const ATexto: string);
begin
  mmTestes.Lines.Add(ATexto);
end;

{ ----------------------------------------------------------------- benchmark }

procedure TfCliente.LiberarMaquinas;
var
  vInt, vTrab: Integer;
begin
  for vInt := 0 to High(FMaquinas) do
  begin
    for vTrab := 0 to High(FMaquinas[vInt].Trabalhadores) do
      FMaquinas[vInt].Trabalhadores[vTrab].WaitFor;
    FMaquinas[vInt].Free;
  end;
  SetLength(FMaquinas, 0);
end;

procedure TfCliente.btIniciarClick(Sender: TObject);
var
  vCfg: TConfigCliente;
  vClientes, vSimultaneas, vRajadas, vInt, vTrab: Integer;
begin
  vCfg := LerConfig;
  vClientes := StrToIntDef(edClientes.Text, 1);
  vSimultaneas := StrToIntDef(edSimultaneas.Text, 1);
  vRajadas := StrToIntDef(edRajadas.Text, 1);
  if (vClientes < 1) or (vSimultaneas < 1) or (vRajadas < 1) then
    raise Exception.Create('Clientes, simultaneas e rajadas precisam ser maiores que zero.');

  LiberarMaquinas;
  gFeitas := 0;
  gErros := 0;
  gEmH2 := 0;
  gConcluidos := 0;
  gParar := False;
  FTotal := vClientes * vSimultaneas * vRajadas;
  pbProgresso.Max := FTotal;
  pbProgresso.Position := 0;

  LogBench(Format('%d clientes x %d simultaneas x %d rajadas = %d requisicoes em ' +
    '%s /%s, pedindo HTTP/%s, compressao %s, cripto %s, %s',
    [vClientes, vSimultaneas, vRajadas, FTotal, vCfg.Esquema, cbRota.Text,
     cbVersao.Text, cbCompress.Text, cbCripto.Text, cbConexao.Text]));

  SetLength(FMaquinas, vClientes);
  for vInt := 0 to vClientes - 1 do
    FMaquinas[vInt] := TMaquina.Create(vCfg, vSimultaneas, vRajadas, cbRota.Text);

  btIniciar.Enabled := False;
  btParar.Enabled := True;
  FInicio := TStopwatch.StartNew;
  for vInt := 0 to vClientes - 1 do
    for vTrab := 0 to High(FMaquinas[vInt].Trabalhadores) do
      FMaquinas[vInt].Trabalhadores[vTrab].Start;
  tmBench.Enabled := True;
end;

procedure TfCliente.btPararClick(Sender: TObject);
begin
  gParar := True;
  btParar.Enabled := False;
end;

procedure TfCliente.tmBenchTimer(Sender: TObject);
var
  vFeitas, vErros, vTotalTrab, vInt: Integer;
  vMs: Int64;
begin
  vFeitas := gFeitas;
  vErros := gErros;
  vMs := FInicio.ElapsedMilliseconds;
  pbProgresso.Position := vFeitas;
  lbEnviadas.Caption := Format('Enviadas: %d de %d', [vFeitas, FTotal]);
  lbErros.Caption := Format('Erros: %d', [vErros]);
  if vMs > 0 then
    lbVazao.Caption := Format('Vazao: %.0f req/s', [(vFeitas - vErros) / (vMs / 1000)]);
  lbProtocolo.Caption := Format('HTTP/2: %d de %d', [gEmH2, vFeitas]);
  lbDecorrido.Caption := Format('Decorrido: %.1f s', [vMs / 1000]);

  vTotalTrab := 0;
  for vInt := 0 to High(FMaquinas) do
    vTotalTrab := vTotalTrab + Length(FMaquinas[vInt].Trabalhadores);
  if gConcluidos >= vTotalTrab then
    FinalizarBench;
end;

procedure TfCliente.FinalizarBench;
var
  vInt, vTrab, vEnviadas, vErros, vEmH2: Integer;
  vSoma, vMin, vMax: Int64;
  vMs, vMedia, vMinMs, vMaxMs, vVazao, vTaxa: Double;
  vT: TTrabalhador;
begin
  tmBench.Enabled := False;
  vMs := FInicio.ElapsedMilliseconds;

  vEnviadas := 0;
  vErros := 0;
  vEmH2 := 0;
  vSoma := 0;
  vMin := High(Int64);
  vMax := 0;
  for vInt := 0 to High(FMaquinas) do
    for vTrab := 0 to High(FMaquinas[vInt].Trabalhadores) do
    begin
      vT := FMaquinas[vInt].Trabalhadores[vTrab];
      vT.WaitFor;
      Inc(vEnviadas, vT.Enviadas);
      Inc(vErros, vT.Erros);
      Inc(vEmH2, vT.EmH2);
      vSoma := vSoma + vT.SomaTicks;
      if vT.MinTicks < vMin then
        vMin := vT.MinTicks;
      if vT.MaxTicks > vMax then
        vMax := vT.MaxTicks;
    end;
  LiberarMaquinas;

  if vEnviadas > 0 then
  begin
    vMedia := vSoma / TStopwatch.Frequency * 1000 / vEnviadas;
    vMinMs := vMin / TStopwatch.Frequency * 1000;
    vMaxMs := vMax / TStopwatch.Frequency * 1000;
    vTaxa := vErros / vEnviadas * 100;
  end
  else
  begin
    vMedia := 0;
    vMinMs := 0;
    vMaxMs := 0;
    vTaxa := 0;
  end;
  if vMs > 0 then
    vVazao := (vEnviadas - vErros) / (vMs / 1000)
  else
    vVazao := 0;

  lbEnviadas.Caption := Format('Enviadas: %d de %d', [vEnviadas, FTotal]);
  lbErros.Caption := Format('Erros: %d (%.2f%%)', [vErros, vTaxa]);
  lbVazao.Caption := Format('Vazao: %.0f req/s', [vVazao]);
  lbProtocolo.Caption := Format('HTTP/2: %d de %d', [vEmH2, vEnviadas]);
  lbTempos.Caption := Format('Tempo de resposta: media %.2f ms, min %.2f, max %.2f',
    [vMedia, vMinMs, vMaxMs]);
  lbDecorrido.Caption := Format('Decorrido: %.2f s', [vMs / 1000]);
  pbProgresso.Position := vEnviadas;

  LogBench(Format('RESULTADO: %d requisicoes, %d erros (%.2f%%), %d em HTTP/2, ' +
    '%.0f req/s, media %.2f ms, min %.2f, max %.2f, em %.2f s',
    [vEnviadas, vErros, vTaxa, vEmH2, vVazao, vMedia, vMinMs, vMaxMs, vMs / 1000]));
  if (vEmH2 = 0) and (vEnviadas > vErros) then
    LogBench('nenhuma resposta veio em HTTP/2 - confira: esquema https, ' +
      'versao HTTP/2 aqui, e servidor no modo http.sys');

  btIniciar.Enabled := True;
  btParar.Enabled := False;
end;

{ -------------------------------------------------------------------- testes }

function TfCliente.ClienteDeTestes: TRALClient;
begin
  { um cliente novo a cada teste, para a configuracao da barra valer na hora }
  FreeAndNil(FCliTestes);
  FCliTestes := NovoCliente(LerConfig);
  Result := FCliTestes;
end;

procedure TfCliente.btLimparClick(Sender: TObject);
begin
  mmTestes.Clear;
end;

procedure TfCliente.btPingClick(Sender: TObject);
var
  vCli: TRALClient;
  vResp: TRALResponse;
  vRelogio: TStopwatch;
begin
  vCli := ClienteDeTestes;
  vCli.Request.Clear;
  vResp := nil;
  vRelogio := TStopwatch.StartNew;
  try
    vCli.Get('ping', vResp);
    { Protocol e' a face de texto de ProtocolVersion, e vem vazia quando o
      transporte nao soube dizer - nunca um palpite }
    LogTeste(Format('ping: HTTP %d "%s" em %d ms (protocolo negociado: %s, ' +
      'compressao da resposta: %d, cripto: %d)',
      [vResp.StatusCode, string(vResp.ResponseText), vRelogio.ElapsedMilliseconds,
       string(vResp.Protocol), Ord(vResp.ContentCompress), Ord(vResp.ContentCripto)]));
  except
    on e: Exception do
      LogTeste('ping: FALHOU - ' + e.Message);
  end;
  vResp.Free;
end;

procedure TfCliente.btParamsClick(Sender: TObject);
var
  vCli: TRALClient;
  vResp: TRALResponse;
begin
  vCli := ClienteDeTestes;
  vCli.Request.Clear;
  vCli.Request.Params.AddParam('id', '42', rpkQUERY);
  vCli.Request.Params.AddParam('nome', 'Pascal RAL', rpkQUERY);
  vCli.Request.Params.AddParam('campo1', 'valor um', rpkBODY);
  vCli.Request.Params.AddParam('campo2', StringRAL('acentua'#231#227'o e cedilha'), rpkBODY);
  vCli.Request.AddCookie('sessao', 'abc123');
  vResp := nil;
  try
    vCli.Post('params', vResp);
    LogTeste(Format('params: HTTP %d - o servidor recebeu:', [vResp.StatusCode]));
    LogTeste(string(vResp.ResponseText));
  except
    on e: Exception do
      LogTeste('params: FALHOU - ' + e.Message);
  end;
  vResp.Free;
end;

procedure TfCliente.btMultipartClick(Sender: TObject);
var
  vCli: TRALClient;
  vResp: TRALResponse;
  vTexto, vBinario: TMemoryStream;
  vStr: AnsiString;
  vBytes: TBytes;
  vInt: Integer;
begin
  vCli := ClienteDeTestes;
  vCli.Request.Clear;

  vTexto := TMemoryStream.Create;
  vBinario := TMemoryStream.Create;
  try
    vStr := AnsiString(StringOfChar('x', 5000));
    vTexto.WriteBuffer(vStr[1], Length(vStr));
    SetLength(vBytes, 25600);
    for vInt := 0 to High(vBytes) do
      vBytes[vInt] := vInt mod 256;
    vBinario.WriteBuffer(vBytes[0], Length(vBytes));

    vCli.Request.Params.AddParam('descricao', 'dois arquivos e um campo', rpkBODY);
    vCli.Request.AddFile(vTexto, 'texto.txt');
    vCli.Request.AddFile(vBinario, 'binario.bin');
  finally
    vTexto.Free;
    vBinario.Free;
  end;

  vResp := nil;
  try
    vCli.Post('multipart', vResp);
    LogTeste(Format('multipart: HTTP %d - o servidor recebeu:', [vResp.StatusCode]));
    LogTeste(string(vResp.ResponseText));
  except
    on e: Exception do
      LogTeste('multipart: FALHOU - ' + e.Message);
  end;
  vResp.Free;
end;

procedure TfCliente.btEcoClick(Sender: TObject);
var
  vCli: TRALClient;
  vResp: TRALResponse;
  vCorpo: string;
  vRelogio: TStopwatch;
begin
  vCli := ClienteDeTestes;
  vCli.Request.Clear;
  vCorpo := StringOfChar('a', 20000) + ' fim, com a'#231#227'o';
  vCli.Request.ContentType := rctTEXTPLAIN;
  vCli.Request.Params.AddValue(StringRAL(vCorpo), rpkBODY);
  vResp := nil;
  vRelogio := TStopwatch.StartNew;
  try
    vCli.Post('eco', vResp);
    if string(vResp.ResponseText) = vCorpo then
      LogTeste(Format('eco: HTTP %d, %d caracteres voltaram iguais em %d ms (protocolo %s)',
        [vResp.StatusCode, Length(vCorpo), vRelogio.ElapsedMilliseconds,
         string(vResp.Protocol)]))
    else
      LogTeste(Format('eco: HTTP %d, corpo DIFERENTE (%d caracteres voltaram)',
        [vResp.StatusCode, Length(string(vResp.ResponseText))]));
  except
    on e: Exception do
      LogTeste('eco: FALHOU - ' + e.Message);
  end;
  vResp.Free;
end;

{ --------------------------------------------------------------------- banco }

{ DAO: o TRALFDQuery e' um TFDQuery comum apontado para um TRALClient; o
  servidor publica a rota com o nome do seu TRALFDConnection. }
procedure TfCliente.btAbrirDAOClick(Sender: TObject);
var
  vRelogio: TStopwatch;
begin
  if FCliDAO = nil then
    FCliDAO := NovoCliente(LerConfig);
  if FQryDAO = nil then
  begin
    FQryDAO := TRALFDQuery.Create(Self);
    FQryDAO.RALClient := FCliDAO;
    FQryDAO.RALFDConnectionServer := 'RALConnBench';
    { QueryBehavior nasce em ebSingleThread: OpenRemote volta com os dados e
      levanta excecao quando o servidor recusa }
    dsDAO.DataSet := FQryDAO;
  end;

  vRelogio := TStopwatch.StartNew;
  try
    FQryDAO.Close;
    FQryDAO.SQL.Text := edSQL.Text;
    FQryDAO.OpenRemote;
    lbDAO.Caption := Format('%d registros em %d ms', [FQryDAO.RecordCount,
      vRelogio.ElapsedMilliseconds]);
  except
    on e: Exception do
      lbDAO.Caption := 'erro: ' + e.Message;
  end;
end;

procedure TfCliente.btGravarDAOClick(Sender: TObject);
var
  vRelogio: TStopwatch;
begin
  if (FQryDAO = nil) or (not FQryDAO.Active) then
  begin
    lbDAO.Caption := 'abra a consulta primeiro';
    Exit;
  end;
  if FQryDAO.State in dsEditModes then
    FQryDAO.Post;

  vRelogio := TStopwatch.StartNew;
  try
    { o caminho de volta do DAO: as linhas alteradas vao ao servidor, que as
      aplica no Firebird com o FireDAC dele }
    FQryDAO.ApplyUpdatesRemote;
    lbDAO.Caption := Format('gravado em %d ms - reabrindo', [vRelogio.ElapsedMilliseconds]);
    btAbrirDAOClick(Sender);
  except
    on e: Exception do
      lbDAO.Caption := 'erro ao gravar: ' + e.Message;
  end;
end;

procedure TfCliente.OnErroDBW(Sender: TObject; AError: StringRAL);
begin
  lbDBW.Caption := 'erro: ' + string(AError);
end;

{ DBWare: o TRALDBModule no servidor, TRALDBConnection + TRALDBFDMemTable
  aqui. O memtable e' local; Open pede o SQL ao servidor e carrega o
  resultado, e ApplyUpdates manda de volta o SQL de cada linha alterada. }
procedure TfCliente.btAbrirDBWClick(Sender: TObject);
var
  vRelogio: TStopwatch;
begin
  if FCliDBW = nil then
    FCliDBW := NovoCliente(LerConfig);
  if FTabDBW = nil then
  begin
    FStorage := TRALStorageBINLink.Create(Self);
    FConnDBW := TRALDBConnection.Create(Self);
    FConnDBW.Client := FCliDBW;
    FConnDBW.ModuleRoute := '/db';

    FTabDBW := TRALDBFDMemTable.Create(Self);
    FTabDBW.RALConnection := FConnDBW;
    FTabDBW.Storage := FStorage;
    { o memtable nao levanta excecao: um erro do servidor, ou um corpo que nao
      carrega, chega por aqui - sem o evento a consulta so' fica fechada }
    FTabDBW.OnError := OnErroDBW;
    dsDBW.DataSet := FTabDBW;
  end;

  vRelogio := TStopwatch.StartNew;
  try
    FTabDBW.Close;
    FTabDBW.SQL.Text := edSQL.Text;
    lbDBW.Caption := '';
    FTabDBW.Open;
    if not FTabDBW.Active then
    begin
      if lbDBW.Caption = '' then
        lbDBW.Caption := 'nao abriu - veja o servidor';
      Exit;
    end;

    { para gravar de volta o memtable precisa saber a tabela e a chave; com
      as duas o RAL monta o UPDATE ... WHERE ID = :OLD_ID sozinho }
    FTabDBW.UpdateTable := 'BENCH';
    FTabDBW.UpdateMode := upWhereKeyOnly;
    if FTabDBW.FindField('ID') <> nil then
      FTabDBW.FieldByName('ID').ProviderFlags := [pfInKey];

    lbDBW.Caption := Format('%d registros em %d ms', [FTabDBW.RecordCount,
      vRelogio.ElapsedMilliseconds]);
  except
    on e: Exception do
      lbDBW.Caption := 'erro: ' + e.Message;
  end;
end;

procedure TfCliente.btGravarDBWClick(Sender: TObject);
var
  vRelogio: TStopwatch;
begin
  if (FTabDBW = nil) or (not FTabDBW.Active) then
  begin
    lbDBW.Caption := 'abra a consulta primeiro';
    Exit;
  end;
  if FTabDBW.State in dsEditModes then
    FTabDBW.Post;

  vRelogio := TStopwatch.StartNew;
  try
    FTabDBW.ApplyUpdates;
    lbDBW.Caption := Format('gravado em %d ms - reabrindo', [vRelogio.ElapsedMilliseconds]);
    { reabrir e' o que prova que foi: o memtable e' local e continuaria
      mostrando o valor editado mesmo se o servidor tivesse recusado }
    btAbrirDBWClick(Sender);
  except
    on e: Exception do
      lbDBW.Caption := 'erro ao gravar: ' + e.Message;
  end;
end;

end.
