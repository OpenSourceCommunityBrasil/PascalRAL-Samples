/// Relay TCP que fica entre o cliente e o servidor do demo, para MEDIR e para
/// simular a internet.
///
/// Duas coisas que o demo precisa e que nao da' para obter de outro jeito:
///
///   1. Quantas conexoes TCP o cliente realmente abriu. Contar por fora
///      (netstat) engana: conexao ociosa fecha sozinha e TIME_WAIT continua
///      aparecendo depois. Aqui quem conta e' quem aceita, e o numero e' exato.
///
///   2. Latencia. Em loopback um handshake custa microssegundos, entao HTTP/1.1
///      e HTTP/2 empatam e o demo nao mostraria diferenca nenhuma. Com um
///      atraso por trecho encaminhado o custo de ABRIR conexao volta a pesar,
///      que e' o que acontece de verdade contra um servidor na internet.
///
/// Nao inspeciona nem altera um byte: encaminha. Por isso funciona igual com
/// TLS, e o ALPN - que e' quem escolhe o HTTP/2 - acontece fim a fim entre o
/// cliente e o servidor, sem o relay participar.
unit UDemoRelay;

interface

uses
  Winapi.Windows, Classes, SysUtils, SyncObjs, Winapi.Winsock2;

type
  { TDemoRelay }

  TDemoRelay = class
  private
    FEscuta: TSocket;
    FAceitador: TThread;
    FPortaDestino: Word;
    FAtrasoMs: Integer;
    FOciosoMs: Integer;
    FConexoes: Integer;
    { quantas estao abertas AGORA, e o maior numero que ja' estiveram ao
      mesmo tempo. Sao coisas diferentes do total: 53 conexoes abertas com
      pico 2 e' um cliente que abre e fecha uma de cada vez; 2 conexoes com
      pico 2 e' o mesmo trabalho sem pagar handshake. So' o par diz qual }
    FAbertas: Integer;
    FPico: Integer;
    { QUAL ESCUTA cada conexao pertence. Sem isto o contador de abertas
      derrapava: ao trocar de porta entre uma medicao e outra, os pares da
      escuta anterior ainda estao morrendo e cada um decrementava o contador
      da escuta NOVA - dando pico maior que o total de conexoes, que e'
      impossivel. Quem fecha so' desconta se for da geracao corrente. }
    FGeracao: Integer;
    FBytes: Int64;
    FTrava: TCriticalSection;
    FAtivo: boolean;
    function GetConexoes: Integer;
    function GetPico: Integer;
    function GetBytes: Int64;
  public
    constructor Create;
    destructor Destroy; override;

    /// Abre a escuta. APortaDestino e' para onde tudo e' encaminhado, e
    /// ACustoConexaoMs e' o que custa ABRIR uma conexao nova - o lugar
    /// certo para o atraso, ver o comentario de TDemoRelayPar.Execute.
    procedure Ligar(APortaLocal, APortaDestino: Word; ACustoConexaoMs: Integer);
    procedure Desligar;
    /// Zera os contadores sem derrubar a escuta: e' o que separa uma medicao
    /// da seguinte.
    procedure Zerar;

    procedure Conta(ABytes: Integer);
    function ContaConexao: Integer;
    procedure FechaConexao(AGeracao: Integer);

    property Ativo: boolean read FAtivo;
    property CustoConexaoMs: Integer read FAtrasoMs write FAtrasoMs;
    /// Depois de quanto tempo SEM TRAFEGO a conexao e' derrubada. E' o
    /// que todo servidor e todo proxy fazem com keep-alive ocioso, e sem
    /// isso a medicao mente a favor do HTTP/1.1: as conexoes dele ficam
    /// quentes do inicio ao fim e o handshake so' e' pago uma vez na vida.
    /// 0 desliga (as conexoes so' morrem quando o cliente as larga).
    property TempoOciosoMs: Integer read FOciosoMs write FOciosoMs;
    property PortaDestino: Word read FPortaDestino;
    /// Quantas conexoes TCP foram aceitas desde o ultimo Zerar
    property Conexoes: Integer read GetConexoes;
    /// Quantas estiveram abertas AO MESMO TEMPO, no auge
    property Pico: Integer read GetPico;
    property Bytes: Int64 read GetBytes;
  end;

implementation

const
  { Nao existem no Winapi.Winsock2 do Delphi 12, entao ficam declarados aqui.

    Isto importa mais do que parece: no Windows "localhost" resolve para ::1
    ANTES de 127.0.0.1. Um relay que escutasse so' em IPv4 seria procurado no
    endereco errado, e a medicao estaria medindo conexao que falha em vez de
    conexao que acontece. Com IPV6_V6ONLY desligado, um socket IPv6 aceita os
    dois. }
  AF_INET6_     = 23;
  IPPROTO_IPV6_ = 41;
  IPV6_V6ONLY_  = 27;

type
  TSockAddrIn6 = record
    sin6_family: u_short;
    sin6_port: u_short;
    sin6_flowinfo: u_long;
    sin6_addr: array [0 .. 15] of Byte; // in6addr_any = tudo zero
    sin6_scope_id: u_long;
  end;

type
  TDemoRelayPar = class;

  { A volta (servidor -> cliente) tem de correr ao mesmo tempo que a ida,
    senao o relay encaminharia meia conversa e travaria no primeiro
    handshake. }
  TDemoRelayVolta = class(TThread)
  private
    FPar: TDemoRelayPar;
  protected
    procedure Execute; override;
  public
    constructor Create(APar: TDemoRelayPar);
  end;

  { Uma thread por conexao aceita. Capturar a variavel do accept numa thread
    anonima daria corrida, porque o closure prende a VARIAVEL e nao o valor. }
  TDemoRelayPar = class(TThread)
  private
    FDono: TDemoRelay;
    FCliente: TSocket;
    FServidor: TSocket;
    FGeracao: Integer;
    FVolta: TDemoRelayVolta;
    { um recv que nao espera para sempre: e' assim que a conexao ociosa
      cai, e o timeout do soquete e' o jeito mais curto de conseguir isso
      sem reescrever o bombeamento em modo nao-bloqueante }
    procedure DefineTempoOcioso;
    procedure Bombeia(AOrigem, ADestino: TSocket);
  protected
    procedure Execute; override;
  public
    constructor Create(ADono: TDemoRelay; ACliente: TSocket; AGeracao: Integer);
  end;

  TDemoRelayAceitador = class(TThread)
  private
    FDono: TDemoRelay;
    FSocketEscuta: TSocket;
  protected
    procedure Execute; override;
  public
    constructor Create(ADono: TDemoRelay; AEscuta: TSocket);
  end;

{ TDemoRelayVolta }

constructor TDemoRelayVolta.Create(APar: TDemoRelayPar);
begin
  FPar := APar;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TDemoRelayVolta.Execute;
begin
  FPar.Bombeia(FPar.FServidor, FPar.FCliente);
end;

{ TDemoRelayPar }

constructor TDemoRelayPar.Create(ADono: TDemoRelay; ACliente: TSocket;
  AGeracao: Integer);
begin
  FDono := ADono;
  FCliente := ACliente;
  FGeracao := AGeracao;
  FServidor := INVALID_SOCKET;
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TDemoRelayPar.DefineTempoOcioso;
var
  vMs: DWORD;
begin
  if FDono.TempoOciosoMs <= 0 then
    Exit;
  vMs := FDono.TempoOciosoMs;
  setsockopt(FCliente, SOL_SOCKET, SO_RCVTIMEO, PAnsiChar(@vMs), SizeOf(vMs));
  setsockopt(FServidor, SOL_SOCKET, SO_RCVTIMEO, PAnsiChar(@vMs), SizeOf(vMs));
end;

{ recv devolvendo <= 0 aqui quer dizer tres coisas - o outro lado fechou,
  deu erro, ou ficou ocioso alem do TempoOciosoMs - e as tres terminam do
  mesmo jeito: esta conexao acabou. Nao vale distinguir. }
procedure TDemoRelayPar.Bombeia(AOrigem, ADestino: TSocket);
var
  vBuf: array [0 .. 32767] of Byte;
  vLido, vEnviado, vAgora: Integer;
begin
  repeat
    vLido := recv(AOrigem, vBuf[0], SizeOf(vBuf), 0);
    if vLido <= 0 then
      Break;
    FDono.Conta(vLido);
    vEnviado := 0;
    while vEnviado < vLido do
    begin
      vAgora := send(ADestino, vBuf[vEnviado], vLido - vEnviado, 0);
      if vAgora <= 0 then
        Break;
      Inc(vEnviado, vAgora);
    end;
  until False;
  { meio fechamento: avisa o outro lado que acabou, sem derrubar o sentido
    contrario, que ainda pode ter resposta a entregar }
  shutdown(ADestino, SD_SEND);
end;

{ O ATRASO MORA AQUI, e nao no encaminhamento de cada pedaco - foi preciso
  mover para ca'.

  Atrasando cada trecho, uma conexao unica com varios pedidos multiplexados
  paga o atraso UMA VEZ POR PEDACO, em fila, enquanto quatro conexoes pagam
  quatro atrasos em paralelo. O medidor punia exatamente o que ele existe
  para mostrar: o HTTP/2 aparecia mais lento por causa do medidor.

  Aqui o custo e' o de ABRIR conexao - que e' o custo real que separa as
  quatro celulas da matriz: TCP mais TLS sao dois a tres round-trips, e e'
  isso que o ShareConnection economiza. Encaminhar depois nao custa nada,
  que e' o certo: o relay nao esta' simulando banda, so' distancia. }
procedure TDemoRelayPar.Execute;
var
  vEnd: TSockAddrIn;
begin
  if FDono.CustoConexaoMs > 0 then
    Sleep(FDono.CustoConexaoMs);

  FServidor := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  DefineTempoOcioso;
  FillChar(vEnd, SizeOf(vEnd), 0);
  vEnd.sin_family := AF_INET;
  vEnd.sin_port := htons(FDono.PortaDestino);
  vEnd.sin_addr.S_addr := inet_addr('127.0.0.1');

  if Winapi.Winsock2.connect(FServidor, TSockAddr(vEnd), SizeOf(vEnd)) <> 0 then
  begin
    closesocket(FCliente);
    closesocket(FServidor);
    FDono.FechaConexao(FGeracao);
    Exit;
  end;

  FVolta := TDemoRelayVolta.Create(Self);
  try
    Bombeia(FCliente, FServidor);
    FVolta.WaitFor;
  finally
    FVolta.Free;
  end;

  closesocket(FCliente);
  closesocket(FServidor);
  FDono.FechaConexao(FGeracao);
end;

{ TDemoRelayAceitador }

constructor TDemoRelayAceitador.Create(ADono: TDemoRelay; AEscuta: TSocket);
begin
  FDono := ADono;
  FSocketEscuta := AEscuta;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TDemoRelayAceitador.Execute;
var
  vCliente: TSocket;
begin
  while not Terminated do
  begin
    vCliente := accept(FSocketEscuta, nil, nil);
    if vCliente = INVALID_SOCKET then
      Break; // a escuta foi fechada: e' assim que esta thread termina
    TDemoRelayPar.Create(FDono, vCliente, FDono.ContaConexao);
  end;
end;

{ TDemoRelay }

constructor TDemoRelay.Create;
begin
  inherited Create;
  FTrava := TCriticalSection.Create;
  FEscuta := INVALID_SOCKET;
end;

destructor TDemoRelay.Destroy;
begin
  Desligar;
  FTrava.Free;
  inherited;
end;

procedure TDemoRelay.Conta(ABytes: Integer);
begin
  FTrava.Enter;
  try
    Inc(FBytes, ABytes);
  finally
    FTrava.Leave;
  end;
end;

function TDemoRelay.ContaConexao: Integer;
begin
  FTrava.Enter;
  try
    Inc(FConexoes);
    Inc(FAbertas);
    if FAbertas > FPico then
      FPico := FAbertas;
    Result := FGeracao;
  finally
    FTrava.Leave;
  end;
end;

{ Chamado UMA vez por conexao aceita, no fim do par - inclusive quando o
  connect para o servidor falha, senao o contador de abertas so' subiria. }
procedure TDemoRelay.FechaConexao(AGeracao: Integer);
begin
  FTrava.Enter;
  try
    if AGeracao = FGeracao then
      Dec(FAbertas);
  finally
    FTrava.Leave;
  end;
end;

function TDemoRelay.GetPico: Integer;
begin
  FTrava.Enter;
  try
    Result := FPico;
  finally
    FTrava.Leave;
  end;
end;

function TDemoRelay.GetConexoes: Integer;
begin
  FTrava.Enter;
  try
    Result := FConexoes;
  finally
    FTrava.Leave;
  end;
end;

function TDemoRelay.GetBytes: Int64;
begin
  FTrava.Enter;
  try
    Result := FBytes;
  finally
    FTrava.Leave;
  end;
end;

procedure TDemoRelay.Zerar;
begin
  FTrava.Enter;
  try
    FConexoes := 0;
    FBytes := 0;
    { o pico nao volta a zero, volta ao que esta' aberto neste instante:
      uma conexao que sobreviveu a' medicao anterior JA' esta' ocupando o
      servidor quando a proxima comeca. Com a contagem por geracao,
      FAbertas so' conta conexoes desta escuta, entao isto e' exato. }
    FPico := FAbertas;
  finally
    FTrava.Leave;
  end;
end;

procedure TDemoRelay.Ligar(APortaLocal, APortaDestino: Word; ACustoConexaoMs: Integer);
var
  vEnd6: TSockAddrIn6;
  vUm, vZero: Integer;
begin
  Desligar;

  FPortaDestino := APortaDestino;
  FAtrasoMs := ACustoConexaoMs;
  { geracao nova: o que ainda esta' morrendo da escuta anterior nao mexe
    mais nestes contadores }
  Inc(FGeracao);
  FAbertas := 0;
  FPico := 0;
  Zerar;

  FEscuta := socket(AF_INET6_, SOCK_STREAM, IPPROTO_TCP);
  if FEscuta = INVALID_SOCKET then
    raise Exception.Create('relay: nao consegui criar o socket');

  vUm := 1;
  setsockopt(FEscuta, SOL_SOCKET, SO_REUSEADDR, @vUm, SizeOf(vUm));
  { dual-stack: aceita tanto ::1 quanto 127.0.0.1 - ver a nota das constantes }
  vZero := 0;
  setsockopt(FEscuta, IPPROTO_IPV6_, IPV6_V6ONLY_, @vZero, SizeOf(vZero));

  FillChar(vEnd6, SizeOf(vEnd6), 0);
  vEnd6.sin6_family := AF_INET6_;
  vEnd6.sin6_port := htons(APortaLocal);
  { sin6_addr fica em zero, que e' in6addr_any. O demo e' local, e quem decide
    de onde se pode chegar aqui e' o firewall do Windows. }

  if bind(FEscuta, PSockAddr(@vEnd6)^, SizeOf(vEnd6)) <> 0 then
  begin
    closesocket(FEscuta);
    FEscuta := INVALID_SOCKET;
    raise Exception.CreateFmt('relay: porta %d ocupada', [APortaLocal]);
  end;

  listen(FEscuta, 128);
  FAceitador := TDemoRelayAceitador.Create(Self, FEscuta);
  FAtivo := True;
end;

procedure TDemoRelay.Desligar;
begin
  if not FAtivo then
    Exit;
  FAtivo := False;

  { fechar a escuta e' o que acorda o accept bloqueado - nao ha' outro jeito
    de tirar uma thread de la' }
  if FEscuta <> INVALID_SOCKET then
  begin
    closesocket(FEscuta);
    FEscuta := INVALID_SOCKET;
  end;

  if FAceitador <> nil then
  begin
    FAceitador.Terminate;
    FAceitador.WaitFor;
    FreeAndNil(FAceitador);
  end;
end;

var
  vWSA: TWSAData;

initialization
  WSAStartup($0202, vWSA);

finalization
  WSACleanup;

end.
