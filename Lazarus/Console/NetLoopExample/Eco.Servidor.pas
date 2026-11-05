/// Um servidor de eco sobre a rede propria do RAL 2.0 (RALNetPackage): o
/// TRALSocketLoop aceita e cuida das threads; o protocolo (devolver cada linha
/// em maiusculas, "sair" encerra) fica numa descendente de
/// TRALSocketLoopConnection. E' o mesmo molde do broker MQTT do RAL.
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/internos-utils
unit Eco.Servidor;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils,
  RALTypes, RALSocket, RALSocketLoop;

type
  /// Uma conexao do eco: so' a thread dona dela chama estes metodos.
  TEcoConexao = class(TRALSocketLoopConnection)
  private
    FEntrada: AnsiString;
    FSaida: AnsiString;
  public
    constructor Create(ASocket: TRALSocket);
    destructor Destroy; override;

    function FlushOutput: boolean; override;
    function HasOutput: boolean; override;
    procedure Serve(ANow: Int64RAL); override;
    procedure Stopping; override;
  end;

  /// O servidor: um socket escutando e o laco de eventos.
  TEcoServidor = class
  private
    FEscuta: TRALSocket;
    FLoop: TRALSocketLoop;

    procedure Aceitou(ASocket: TRALSocket; ATag: IntegerRAL);
    procedure Relogio(Sender: TObject);
  public
    destructor Destroy; override;

    /// Escuta em APorta com duas threads de poll.
    procedure Iniciar(APorta: Integer);
    procedure Parar;
  end;

implementation

{ TEcoConexao }

constructor TEcoConexao.Create(ASocket: TRALSocket);
begin
  inherited Create;
  FSocket := ASocket;
  FChannel := TRALSocketChannel.Create(ASocket); // o canal e' dono do socket
end;

destructor TEcoConexao.Destroy;
begin
  FreeAndNil(FChannel);
  inherited Destroy;
end;

function TEcoConexao.HasOutput: boolean;
begin
  Result := FSaida <> '';
end;

function TEcoConexao.FlushOutput: boolean;
var
  vEnviados: IntegerRAL;
begin
  Result := True;
  try
    while FSaida <> '' do
    begin
      vEnviados := FChannel.Write(Pointer(FSaida)^, Length(FSaida));
      if vEnviados <= 0 then
        Break; // o socket encheu: o resto vai na proxima passada
      Delete(FSaida, 1, vEnviados);
    end;
  except
    Result := False; // a conexao caiu: o laco a fecha
  end;
end;

procedure TEcoConexao.Serve(ANow: Int64RAL);
var
  vBuffer: array[0..4095] of AnsiChar;
  vLidos, vFim: IntegerRAL;
  vLinha, vPedaco: AnsiString;
begin
  // le o que chegou, sem esperar
  repeat
    vLidos := FChannel.Read(vBuffer, SizeOf(vBuffer));
    if vLidos = 0 then
    begin
      Close; // o cliente fechou
      Exit;
    end;
    if vLidos > 0 then
    begin
      SetString(vPedaco, PAnsiChar(@vBuffer[0]), vLidos);
      FEntrada := FEntrada + vPedaco;
    end;
  until vLidos <= 0;
  // responde cada linha inteira
  vFim := Pos(AnsiString(#10), FEntrada);
  while vFim > 0 do
  begin
    vLinha := AnsiString(Trim(string(Copy(FEntrada, 1, vFim - 1))));
    Delete(FEntrada, 1, vFim);
    if vLinha = 'sair' then
    begin
      FSaida := FSaida + 'tchau'#10;
      CloseAfterFlush := True; // fecha depois que o tchau sair
      Exit;
    end;
    FSaida := FSaida + AnsiString(UpperCase(string(vLinha))) + #10;
    vFim := Pos(AnsiString(#10), FEntrada);
  end;
end;

procedure TEcoConexao.Stopping;
begin
  // o servidor vai parar: a ultima palavra
  FSaida := FSaida + 'servidor parando'#10;
  FlushOutput;
end;

{ TEcoServidor }

destructor TEcoServidor.Destroy;
begin
  Parar;
  inherited Destroy;
end;

procedure TEcoServidor.Iniciar(APorta: Integer);
begin
  FEscuta := TRALSocket.Create;
  FEscuta.Listen('', APorta, mifIPv4);
  FLoop := TRALSocketLoop.Create;
  FLoop.OnAccept := Aceitou;
  FLoop.OnTimer := Relogio;
  FLoop.TimerInterval := 5000;
  FLoop.AddListener(FEscuta, 0);
  FLoop.Start(2);
end;

procedure TEcoServidor.Parar;
begin
  if FLoop <> nil then
  begin
    FLoop.Stop;
    FreeAndNil(FLoop);
  end;
  FreeAndNil(FEscuta);
end;

procedure TEcoServidor.Aceitou(ASocket: TRALSocket; ATag: IntegerRAL);
begin
  // a thread com menos conexoes fica com esta
  FLoop.Adopt(TEcoConexao.Create(ASocket));
end;

procedure TEcoServidor.Relogio(Sender: TObject);
begin
  WriteLn('conexoes abertas: ', FLoop.ConnectionCount);
end;

end.
