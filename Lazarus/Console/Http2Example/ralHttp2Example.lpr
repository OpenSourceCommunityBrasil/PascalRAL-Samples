program ralHttp2Example;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALTypes, RALConsts, RALServer, RALClient, RALRequest, RALResponse,
  // the engines register themselves: the server here, the client by EngineType
  RALNgHttp2Server, RALNgHttp2Client;

// HTTP/2 with PascalRAL on the nghttp2 engine (package NgHttp2RAL; the nghttp2
// library - libnghttp2.so.14 / nghttp2.dll - must be found at run time).
// The server answers /hello and a streamed /stream; the client, in the same
// program, calls both over cleartext HTTP/2 (h2c, prior knowledge).
//
// To serve HTTP/2 over TLS instead (h2), before Active := True:
//   FServer.SSL.CertFile := 'cert.pem';
//   FServer.SSL.KeyFile := 'key.pem';
//   FServer.SSL.Enabled := True;
// and call https://localhost:<port> from the client.

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
  AResponse.Answer(HTTP_OK, 'Hello over HTTP/' + ARequest.Protocol, 'text/plain');
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

function VersionName(AVersion: TRALHTTPVersion): string;
begin
  if AVersion = rhv2 then
    Result := 'HTTP/2'
  else
    Result := 'other (not HTTP/2)';
end;

var
  FServer: TRALNgHttp2Server;
  FClient: TRALClient;
  FHandlers: THandlers;
  FResponse: TRALResponse;
begin
  FServer := TRALNgHttp2Server.Create(nil);
  FClient := TRALClient.Create(nil);
  FHandlers := THandlers.Create;
  try
    FServer.Port := 8000;
    FServer.CreateRoute('hello', FHandlers.Hello);
    FServer.CreateRoute('stream', FHandlers.Stream);
    FServer.Active := True;
    WriteLn('RALServer (nghttp2) running on Port ', FServer.Port);

    FClient.EngineType := 'NgHttp2';
    FClient.BaseURL.Text := 'http://127.0.0.1:8000';

    FResponse := nil;
    FClient.Get('/hello', FResponse);
    try
      WriteLn('GET /hello -> ', FResponse.StatusCode, ' "', string(FResponse.ResponseText),
        '" via ', VersionName(FResponse.ProtocolVersion));
    finally
      FreeAndNil(FResponse);
    end;

    WriteLn('GET /stream (pieces arrive as the server sends them):');
    FClient.Get('/stream', FHandlers.Piece, FResponse);
    try
      WriteLn('  status ', FResponse.StatusCode, ' via ', VersionName(FResponse.ProtocolVersion));
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
