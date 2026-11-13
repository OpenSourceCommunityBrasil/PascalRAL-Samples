program RALXSocketExample;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils,
  RALTypes, RALConsts, RALServer, RALClient, RALRequest, RALResponse,
  // the engines register themselves: the server here, the clients by EngineType
  RALXSocketServer, RALXSocketClient, RALIndyClient;

// The XSocket engine (package XSocketRAL, on Delphi-Cross-Socket; Delphi 11 or
// newer). The server answers /hello and a streamed /stream; the client, in the
// same program, calls both over HTTP/1.1.
//
// The XSocket client hands the body over whole (it does not stream the answer),
// so /stream is read with the Indy client, which delivers the pieces as they
// arrive.
//
// To serve HTTPS instead, before Active := True:
//   FServer.SSL.CertFile := 'cert.pem';
//   FServer.SSL.KeyFile := 'key.pem';      // PEM, without a password
//   FServer.SSL.Enabled := True;
// and call https://localhost:<port> (OpenSSL 3 must be found at run time).

type
  THandlers = class
  public
    procedure Hello(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Stream(ARequest: TRALRequest; AResponse: TRALResponse);
    // client side: called for each piece of the streamed answer
    procedure Piece(ASender: TObject; AResponse: TRALResponse; const ABuffer;
      ASize: IntegerRAL; var ACancel: Boolean);
  end;

procedure THandlers.Hello(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'Hello from XSocket', 'text/plain');
end;

procedure THandlers.Stream(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vInt: Integer;
begin
  AResponse.BeginStream(HTTP_OK, 'text/plain');
  for vInt := 1 to 3 do
  begin
    // Send returns False when the client went away
    if not AResponse.Send(StringRAL('piece ' + IntToStr(vInt) + #10)) then
      Exit;
    Sleep(100);
  end;
end;

procedure THandlers.Piece(ASender: TObject; AResponse: TRALResponse; const ABuffer;
  ASize: IntegerRAL; var ACancel: Boolean);
var
  vText: AnsiString;
begin
  SetString(vText, PAnsiChar(@ABuffer), ASize);
  Write('  got: ', Trim(string(vText)), ' ');
  WriteLn('(', FormatDateTime('ss.zzz', Now), ')');
end;

var
  FServer: TRALXSocketServer;
  FClient: TRALClient;
  FHandlers: THandlers;
  FResponse: TRALResponse;
begin
  FServer := TRALXSocketServer.Create(nil);
  FClient := TRALClient.Create(nil);
  FHandlers := THandlers.Create;
  try
    FServer.Port := 8000;
    FServer.CreateRoute('hello', FHandlers.Hello);
    FServer.CreateRoute('stream', FHandlers.Stream);
    FServer.Active := True;
    WriteLn('RALServer (XSocket) running on Port ', FServer.Port);

    FClient.EngineType := 'XSocket';
    FClient.BaseURL.Text := 'http://127.0.0.1:8000';

    FResponse := nil;
    FClient.Get('/hello', FResponse);
    try
      WriteLn('GET /hello -> ', FResponse.StatusCode, ' "', string(FResponse.ResponseText), '"');
    finally
      FreeAndNil(FResponse);
    end;

    // the Indy client delivers the pieces as the server sends them
    FClient.EngineType := 'Indy';
    WriteLn('GET /stream (pieces arrive as the server sends them):');
    FClient.Get('/stream', FHandlers.Piece, FResponse);
    try
      WriteLn('  status ', FResponse.StatusCode);
    finally
      FreeAndNil(FResponse);
    end;
  finally
    FServer.Active := False;
    FHandlers.Free;
    FClient.Free;
    FServer.Free;
  end;
end.
