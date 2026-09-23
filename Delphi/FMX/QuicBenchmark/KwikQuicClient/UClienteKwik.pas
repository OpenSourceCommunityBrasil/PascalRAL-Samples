/// Cliente Android do benchmark QUIC do PascalRAL, sobre o engine Kwik.
///
/// E' o mesmo programa do MsQuicClient - as mesmas quatro funcoes, o mesmo
/// servidor, o mesmo frame no fio - trocando duas coisas: o engine e' o
/// ENGINEKWIK e a tela e' FMX. O servidor nao sabe a diferenca: o Kwik poe na
/// stream QUIC exatamente o frame que o TRALMsQuicServer le, porque os dois
/// clientes montam esse frame pela mesma unit (RALQuicFrame).
///
/// POR QUE O KWIK NO ANDROID. O engine MsQuic precisa de uma libmsquic.so
/// compilada com o NDK, plataforma que o proprio projeto do MsQuic nao
/// sustenta e para a qual ninguem publica binario. O Kwik e' QUIC em Java
/// puro: quatro jars, 646 KB, o mesmo arquivo para qualquer ABI. Nenhuma pilha
/// oficial do Android serve aqui - OkHttp, Cronet e HttpEngine sao clientes
/// HTTP e nao expoem stream crua, que e' o que este frame precisa.
///
/// O QUE MUDA NA TELA. O VCL tem a configuracao numa barra em cima e as tres
/// abas embaixo; num telefone nao cabe, entao a configuracao virou a primeira
/// aba. As duas grades do banco, que no VCL ficam lado a lado, viraram duas
/// abas internas pelo mesmo motivo.
///
/// O QUE O PROJETO PRECISA CARREGAR. Cinco jars declarados como JavaReference
/// no .dproj: kwik, agent15, hkdf, io.whitfin.siphash e o ralkwik da ponte.
/// Sem eles o engine responde emKwikBridgeMissing na primeira requisicao, e a
/// aba de testes mostra essa mensagem.
unit UClienteKwik;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Diagnostics,
  System.DateUtils, System.Rtti, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Edit, FMX.Memo,
  FMX.TabControl, FMX.Layouts, FMX.ListBox, FMX.Grid, FMX.Grid.Style,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo.Types,
  Data.DB,
  { FireDAC.Phys e FireDAC.DApt sao obrigatorios mesmo sem banco local: o
    TRALFDQuery e' um TFDQuery e, ao carregar o resultado, cria um TFDConnection
    que pede a fabrica do gerenciador fisico. FMXUI.Wait no lugar do VCLUI do
    cliente Windows - e' a mesma unit de espera, na outra biblioteca visual. }
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FireDAC.Phys, FireDAC.DApt, FireDAC.UI.Intf,
  FireDAC.FMXUI.Wait, FireDAC.Comp.UI,

  RALTypes, RALConsts, RALMIMETypes, RALClient, RALRequest, RALResponse,
  RALParams, RALCompress, RALCompressZLib, RALCripto, RALCriptoAES,
  RALKwikClient,
  RALStorage, RALStorageBIN, RALDBConnection, RALDBFiredacMemTable,
  RALDBFiredacDAO;

type
  /// O que a aba de conexao define, copiado para quem for usar.
  TConfigCliente = record
    Host: string;
    Porta: Integer;
    Timeout: Integer;
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
    SomaTicks: Int64;
    MinTicks: Int64;
    MaxTicks: Int64;
    /// A mensagem da PRIMEIRA falha desta thread. Sem ela o benchmark conta
    /// erros e nao diz por que - que foi exatamente o que atrasou o primeiro
    /// teste no aparelho: 200 de 200 falhando e nenhuma pista na tela.
    UltimoErro: string;
    constructor Create(AMaquina: TMaquina; ARajadas: Integer; const ARota: string);
  end;

  /// Um "cliente" do benchmark: um TRALClient proprio, como se fosse outro
  /// aparelho, e M trabalhadores batendo nele ao mesmo tempo.
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

  TfClienteKwik = class(TForm)
    tbTopo: TToolBar;
    lbTitulo: TLabel;
    tcAbas: TTabControl;
    tiConexao: TTabItem;
    sbConexao: TVertScrollBox;
    loHost: TLayout;
    lbHost: TLabel;
    edHost: TEdit;
    loPorta: TLayout;
    lbPorta: TLabel;
    edPorta: TEdit;
    loTimeout: TLayout;
    lbTimeout: TLabel;
    edTimeout: TEdit;
    loValidar: TLayout;
    lbValidar: TLabel;
    swValidar: TSwitch;
    loPin: TLayout;
    lbPin: TLabel;
    edPin: TEdit;
    loCompress: TLayout;
    lbCompress: TLabel;
    cbCompress: TComboBox;
    loCripto: TLayout;
    lbCripto: TLabel;
    cbCripto: TComboBox;
    loChave: TLayout;
    lbChave: TLabel;
    edChave: TEdit;
    loConexao: TLayout;
    lbConexao: TLabel;
    cbConexao: TComboBox;
    tiBench: TTabItem;
    loBenchTopo: TLayout;
    loClientes: TLayout;
    lbClientes: TLabel;
    edClientes: TEdit;
    loSimultaneas: TLayout;
    lbSimultaneas: TLabel;
    edSimultaneas: TEdit;
    loRajadas: TLayout;
    lbRajadas: TLabel;
    edRajadas: TEdit;
    loRota: TLayout;
    lbRota: TLabel;
    cbRota: TComboBox;
    loBotoesBench: TLayout;
    btIniciar: TButton;
    btParar: TButton;
    pbProgresso: TProgressBar;
    lbEnviadas: TLabel;
    lbErros: TLabel;
    lbVazao: TLabel;
    lbTempos: TLabel;
    lbDecorrido: TLabel;
    mmBench: TMemo;
    tiTestes: TTabItem;
    loBotoesTestes: TLayout;
    btPing: TButton;
    btParams: TButton;
    btMultipart: TButton;
    btEco: TButton;
    btLimpar: TButton;
    mmTestes: TMemo;
    tiBanco: TTabItem;
    loSQL: TLayout;
    lbSQL: TLabel;
    edSQL: TEdit;
    tcBanco: TTabControl;
    tiDAO: TTabItem;
    loBotoesDAO: TLayout;
    btAbrirDAO: TButton;
    btGravarDAO: TButton;
    lbDAO: TLabel;
    gridDAO: TGrid;
    tiDBW: TTabItem;
    loBotoesDBW: TLayout;
    btAbrirDBW: TButton;
    btGravarDBW: TButton;
    lbDBW: TLabel;
    gridDBW: TGrid;
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
    procedure gridGetValue(Sender: TObject; const ACol, ARow: Integer;
      var Value: TValue);
    procedure gridSetValue(Sender: TObject; const ACol, ARow: Integer;
      const Value: TValue);
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
    /// Qual dataset esta' por tras de cada grade - o TGrid aqui e' virtual,
    /// entao quem responde celula por celula e' o dataset, posicionado por
    /// RecNo. Sem LiveBindings: menos peca na tela e nada para configurar.
    function DatasetDaGrade(AGrid: TObject): TDataSet;
    procedure MontarColunas(AGrid: TGrid; ADataset: TDataSet);
  public
  end;

/// Um TRALClient sobre o engine Kwik, com tudo que a aba de conexao pede.
function NovoCliente(const AConfig: TConfigCliente): TRALClient;

var
  fClienteKwik: TfClienteKwik;

implementation

{$R *.fmx}

var
  gFeitas: Integer;
  gErros: Integer;
  gConcluidos: Integer;
  gParar: Boolean;

function NovoCliente(const AConfig: TConfigCliente): TRALClient;
begin
  Result := TRALClient.Create(nil);
  Result.EngineType := ENGINEKWIK;
  Result.BaseURL.Text := Format('https://%s:%d', [AConfig.Host, AConfig.Porta]);
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
  vOk: Boolean;
  vRelogio: TStopwatch;
  vTicks: Int64;
begin
  for vInt := 1 to FRajadas do
  begin
    if gParar then
      Break;

    vRelogio := TStopwatch.StartNew;
    vResp := nil;
    try
      { a sobrecarga com "var AResponse" e' sincrona e levanta excecao quando o
        transporte falha; um status diferente de 200 volta normalmente }
      FMaquina.Client.Get(StringRAL(FRota), vResp);
      vOk := (vResp <> nil) and (vResp.StatusCode = HTTP_OK);
      if (not vOk) and (UltimoErro = '') then
      begin
        if vResp = nil then
          UltimoErro := 'sem resposta'
        else
          UltimoErro := Format('HTTP %d %s', [vResp.StatusCode,
            string(vResp.ResponseText)]);
      end;
    except
      on e: Exception do
      begin
        vOk := False;
        if UltimoErro = '' then
          UltimoErro := e.Message;
      end;
    end;
    vResp.Free;
    vTicks := vRelogio.ElapsedTicks;

    Inc(Enviadas);
    if not vOk then
      Inc(Erros);
    SomaTicks := SomaTicks + vTicks;
    if vTicks < MinTicks then
      MinTicks := vTicks;
    if vTicks > MaxTicks then
      MaxTicks := vTicks;

    TInterlocked.Increment(gFeitas);
    if not vOk then
      TInterlocked.Increment(gErros);
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
  { COM ShareConnection LIGADO o RAL junta na mesma conexao QUIC todo cliente
    que julgue o certificado do mesmo jeito - e todas as maquinas deste
    processo julgariam igual, entao virariam UMA conexao. O evento e' o que
    distingue: cada maquina julga com um metodo seu, a politica passa a ser
    dela, e ela ganha uma conexao propria, multiplexada pelas suas M threads. }
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

procedure TfClienteKwik.FormCreate(Sender: TObject);
begin
  cbCompress.ItemIndex := 0;
  cbCripto.ItemIndex := 0;
  cbConexao.ItemIndex := 0;
  cbRota.ItemIndex := 0;
  tcAbas.ActiveTab := tiConexao;
  tcBanco.ActiveTab := tiDAO;
  btParar.Enabled := False;
end;

procedure TfClienteKwik.FormDestroy(Sender: TObject);
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

function TfClienteKwik.LerConfig: TConfigCliente;
begin
  Result.Host := Trim(edHost.Text);
  Result.Porta := StrToIntDef(edPorta.Text, 8443);
  Result.Timeout := StrToIntDef(edTimeout.Text, 15000);
  Result.Validar := swValidar.IsChecked;
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
  Result.Chave := edChave.Text;
  Result.Compartilhar := cbConexao.ItemIndex = 1;
  if (Result.Cripto <> crNone) and (Result.Chave = '') then
    raise Exception.Create('Informe a chave da criptografia - a mesma do servidor.');
end;

procedure TfClienteKwik.LogBench(const ATexto: string);
begin
  mmBench.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + ATexto);
  mmBench.GoToTextEnd;
end;

procedure TfClienteKwik.LogTeste(const ATexto: string);
begin
  mmTestes.Lines.Add(ATexto);
  mmTestes.GoToTextEnd;
end;

{ ----------------------------------------------------------------- benchmark }

procedure TfClienteKwik.LiberarMaquinas;
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

procedure TfClienteKwik.btIniciarClick(Sender: TObject);
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
  gConcluidos := 0;
  gParar := False;
  FTotal := vClientes * vSimultaneas * vRajadas;
  pbProgresso.Max := FTotal;
  pbProgresso.Value := 0;

  LogBench(Format('%d clientes x %d simultaneas x %d rajadas = %d requisicoes em /%s, ' +
    'compressao %s, cripto %s, %s',
    [vClientes, vSimultaneas, vRajadas, FTotal, cbRota.Selected.Text,
     cbCompress.Selected.Text, cbCripto.Selected.Text, cbConexao.Selected.Text]));

  SetLength(FMaquinas, vClientes);
  for vInt := 0 to vClientes - 1 do
    FMaquinas[vInt] := TMaquina.Create(vCfg, vSimultaneas, vRajadas,
      cbRota.Selected.Text);

  btIniciar.Enabled := False;
  btParar.Enabled := True;
  FInicio := TStopwatch.StartNew;
  for vInt := 0 to vClientes - 1 do
    for vTrab := 0 to High(FMaquinas[vInt].Trabalhadores) do
      FMaquinas[vInt].Trabalhadores[vTrab].Start;
  tmBench.Enabled := True;
end;

procedure TfClienteKwik.btPararClick(Sender: TObject);
begin
  gParar := True;
  btParar.Enabled := False;
end;

procedure TfClienteKwik.tmBenchTimer(Sender: TObject);
var
  vFeitas, vErros, vTotalTrab, vInt: Integer;
  vMs: Int64;
begin
  vFeitas := gFeitas;
  vErros := gErros;
  vMs := FInicio.ElapsedMilliseconds;
  pbProgresso.Value := vFeitas;
  lbEnviadas.Text := Format('Enviadas: %d de %d', [vFeitas, FTotal]);
  lbErros.Text := Format('Erros: %d', [vErros]);
  if vMs > 0 then
    lbVazao.Text := Format('Vazao: %.0f req/s', [(vFeitas - vErros) / (vMs / 1000)]);
  lbDecorrido.Text := Format('Decorrido: %.1f s', [vMs / 1000]);

  vTotalTrab := 0;
  for vInt := 0 to High(FMaquinas) do
    vTotalTrab := vTotalTrab + Length(FMaquinas[vInt].Trabalhadores);
  if gConcluidos >= vTotalTrab then
    FinalizarBench;
end;

procedure TfClienteKwik.FinalizarBench;
var
  vInt, vTrab, vEnviadas, vErros: Integer;
  vSoma, vMin, vMax: Int64;
  vMs, vMedia, vMinMs, vMaxMs, vVazao, vTaxa: Double;
  vT: TTrabalhador;
  vErro: string;
begin
  tmBench.Enabled := False;
  vMs := FInicio.ElapsedMilliseconds;
  vErro := '';

  vEnviadas := 0;
  vErros := 0;
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
      vSoma := vSoma + vT.SomaTicks;
      if vT.MinTicks < vMin then
        vMin := vT.MinTicks;
      if vT.MaxTicks > vMax then
        vMax := vT.MaxTicks;
      if (vErro = '') and (vT.UltimoErro <> '') then
        vErro := vT.UltimoErro;
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

  lbEnviadas.Text := Format('Enviadas: %d de %d', [vEnviadas, FTotal]);
  lbErros.Text := Format('Erros: %d (%.2f%%)', [vErros, vTaxa]);
  lbVazao.Text := Format('Vazao: %.0f req/s', [vVazao]);
  lbTempos.Text := Format('Tempo de resposta: media %.2f ms, min %.2f, max %.2f',
    [vMedia, vMinMs, vMaxMs]);
  lbDecorrido.Text := Format('Decorrido: %.2f s', [vMs / 1000]);
  pbProgresso.Value := vEnviadas;

  LogBench(Format('RESULTADO: %d requisicoes, %d erros (%.2f%%), %.0f req/s, ' +
    'media %.2f ms, min %.2f, max %.2f, em %.2f s',
    [vEnviadas, vErros, vTaxa, vVazao, vMedia, vMinMs, vMaxMs, vMs / 1000]));
  if vErro <> '' then
    LogBench('1o ERRO: ' + vErro);

  btIniciar.Enabled := True;
  btParar.Enabled := False;
end;

{ -------------------------------------------------------------------- testes }

function TfClienteKwik.ClienteDeTestes: TRALClient;
begin
  { um cliente novo a cada teste, para a configuracao da aba valer na hora }
  FreeAndNil(FCliTestes);
  FCliTestes := NovoCliente(LerConfig);
  Result := FCliTestes;
end;

procedure TfClienteKwik.btLimparClick(Sender: TObject);
begin
  mmTestes.Lines.Clear;
end;

procedure TfClienteKwik.btPingClick(Sender: TObject);
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
    LogTeste(Format('ping: HTTP %d "%s" em %d ms (compressao da resposta: %d, cripto: %d)',
      [vResp.StatusCode, string(vResp.ResponseText), vRelogio.ElapsedMilliseconds,
       Ord(vResp.ContentCompress), Ord(vResp.ContentCripto)]));
  except
    on e: Exception do
      LogTeste('ping: FALHOU - ' + e.Message);
  end;
  vResp.Free;
end;

procedure TfClienteKwik.btParamsClick(Sender: TObject);
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

procedure TfClienteKwik.btMultipartClick(Sender: TObject);
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

procedure TfClienteKwik.btEcoClick(Sender: TObject);
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
      LogTeste(Format('eco: HTTP %d, %d caracteres voltaram iguais em %d ms',
        [vResp.StatusCode, Length(vCorpo), vRelogio.ElapsedMilliseconds]))
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

function TfClienteKwik.DatasetDaGrade(AGrid: TObject): TDataSet;
begin
  if AGrid = gridDAO then
    Result := FQryDAO
  else
    Result := FTabDBW;
end;

{ Uma coluna por campo do dataset. As colunas velhas saem antes: um SQL novo
  traz outros campos, e uma coluna sobrando pediria um campo que nao existe. }
procedure TfClienteKwik.MontarColunas(AGrid: TGrid; ADataset: TDataSet);
var
  vInt: Integer;
  vCol: TStringColumn;
begin
  AGrid.BeginUpdate;
  try
    while AGrid.ColumnCount > 0 do
      AGrid.Columns[0].Free;
    AGrid.RowCount := 0;
    if (ADataset = nil) or (not ADataset.Active) then
      Exit;
    for vInt := 0 to ADataset.FieldCount - 1 do
    begin
      vCol := TStringColumn.Create(AGrid);
      vCol.Header := ADataset.Fields[vInt].DisplayName;
      vCol.Width := 120;
      vCol.ReadOnly := ADataset.Fields[vInt].ReadOnly;
      AGrid.AddObject(vCol);
    end;
    AGrid.RowCount := ADataset.RecordCount;
  finally
    AGrid.EndUpdate;
  end;
end;

{ O TGrid e' virtual: ele nao guarda valor nenhum, pergunta por celula. Quem
  responde e' o dataset, posicionado na linha pedida. RecNo e' 1-based e a
  grade e' 0-based. }
procedure TfClienteKwik.gridGetValue(Sender: TObject; const ACol, ARow: Integer;
  var Value: TValue);
var
  vDataset: TDataSet;
begin
  Value := TValue.Empty;
  vDataset := DatasetDaGrade(Sender);
  if (vDataset = nil) or (not vDataset.Active) then
    Exit;
  if (ARow < 0) or (ARow >= vDataset.RecordCount) then
    Exit;
  if (ACol < 0) or (ACol >= vDataset.FieldCount) then
    Exit;
  if vDataset.RecNo <> ARow + 1 then
    vDataset.RecNo := ARow + 1;
  Value := TValue.From<string>(vDataset.Fields[ACol].AsString);
end;

procedure TfClienteKwik.gridSetValue(Sender: TObject; const ACol, ARow: Integer;
  const Value: TValue);
var
  vDataset: TDataSet;
begin
  vDataset := DatasetDaGrade(Sender);
  if (vDataset = nil) or (not vDataset.Active) then
    Exit;
  if (ARow < 0) or (ARow >= vDataset.RecordCount) then
    Exit;
  if (ACol < 0) or (ACol >= vDataset.FieldCount) then
    Exit;
  if vDataset.Fields[ACol].ReadOnly then
    Exit;
  if vDataset.RecNo <> ARow + 1 then
    vDataset.RecNo := ARow + 1;
  vDataset.Edit;
  vDataset.Fields[ACol].AsString := Value.ToString;
  vDataset.Post;
end;

{ DAO: o TRALFDQuery e' um TFDQuery comum apontado para um TRALClient; o
  servidor publica a rota com o nome do seu TRALFDConnection. }
procedure TfClienteKwik.btAbrirDAOClick(Sender: TObject);
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
  end;

  vRelogio := TStopwatch.StartNew;
  try
    FQryDAO.Close;
    FQryDAO.SQL.Text := edSQL.Text;
    FQryDAO.OpenRemote;
    MontarColunas(gridDAO, FQryDAO);
    lbDAO.Text := Format('%d registros em %d ms', [FQryDAO.RecordCount,
      vRelogio.ElapsedMilliseconds]);
  except
    on e: Exception do
    begin
      MontarColunas(gridDAO, nil);
      lbDAO.Text := 'erro: ' + e.Message;
    end;
  end;
end;

procedure TfClienteKwik.btGravarDAOClick(Sender: TObject);
var
  vRelogio: TStopwatch;
begin
  if (FQryDAO = nil) or (not FQryDAO.Active) then
  begin
    lbDAO.Text := 'abra a consulta primeiro';
    Exit;
  end;
  if FQryDAO.State in dsEditModes then
    FQryDAO.Post;

  vRelogio := TStopwatch.StartNew;
  try
    { o caminho de volta do DAO: as linhas alteradas vao ao servidor, que as
      aplica no Firebird com o FireDAC dele }
    FQryDAO.ApplyUpdatesRemote;
    lbDAO.Text := Format('gravado em %d ms - reabrindo', [vRelogio.ElapsedMilliseconds]);
    btAbrirDAOClick(Sender);
  except
    on e: Exception do
      lbDAO.Text := 'erro ao gravar: ' + e.Message;
  end;
end;

procedure TfClienteKwik.OnErroDBW(Sender: TObject; AError: StringRAL);
begin
  lbDBW.Text := 'erro: ' + string(AError);
end;

{ DBWare: o TRALDBModule no servidor, TRALDBConnection + TRALDBFDMemTable
  aqui. O memtable e' local; Open pede o SQL ao servidor e carrega o
  resultado, e ApplyUpdates manda de volta o SQL de cada linha alterada. }
procedure TfClienteKwik.btAbrirDBWClick(Sender: TObject);
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
  end;

  vRelogio := TStopwatch.StartNew;
  try
    FTabDBW.Close;
    FTabDBW.SQL.Text := edSQL.Text;
    lbDBW.Text := '';
    FTabDBW.Open;
    if not FTabDBW.Active then
    begin
      MontarColunas(gridDBW, nil);
      if lbDBW.Text = '' then
        lbDBW.Text := 'nao abriu - veja o servidor';
      Exit;
    end;

    { para gravar de volta o memtable precisa saber a tabela e a chave; com
      as duas o RAL monta o UPDATE ... WHERE ID = :OLD_ID sozinho }
    FTabDBW.UpdateTable := 'BENCH';
    FTabDBW.UpdateMode := upWhereKeyOnly;
    if FTabDBW.FindField('ID') <> nil then
      FTabDBW.FieldByName('ID').ProviderFlags := [pfInKey];

    MontarColunas(gridDBW, FTabDBW);
    lbDBW.Text := Format('%d registros em %d ms', [FTabDBW.RecordCount,
      vRelogio.ElapsedMilliseconds]);
  except
    on e: Exception do
    begin
      MontarColunas(gridDBW, nil);
      lbDBW.Text := 'erro: ' + e.Message;
    end;
  end;
end;

procedure TfClienteKwik.btGravarDBWClick(Sender: TObject);
var
  vRelogio: TStopwatch;
begin
  if (FTabDBW = nil) or (not FTabDBW.Active) then
  begin
    lbDBW.Text := 'abra a consulta primeiro';
    Exit;
  end;
  if FTabDBW.State in dsEditModes then
    FTabDBW.Post;

  vRelogio := TStopwatch.StartNew;
  try
    FTabDBW.ApplyUpdates;
    lbDBW.Text := Format('gravado em %d ms - reabrindo', [vRelogio.ElapsedMilliseconds]);
    { reabrir e' o que prova que foi: o memtable e' local e continuaria
      mostrando o valor editado mesmo se o servidor tivesse recusado }
    btAbrirDBWClick(Sender);
  except
    on e: Exception do
      lbDBW.Text := 'erro ao gravar: ' + e.Message;
  end;
end;

end.
