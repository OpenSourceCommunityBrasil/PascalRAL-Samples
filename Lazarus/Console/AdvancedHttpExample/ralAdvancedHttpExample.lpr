program ralAdvancedHttpExample;

{$APPTYPE CONSOLE}
{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALTypes, RALConsts, RALServer, RALClient, RALRequest, RALResponse,
  // the engines register themselves: the server here, the client by EngineType
  RALAdvancedHTTPServer, RALfpHTTPClient;

// EXPERIMENTAL. The AdvancedHTTP engine (package AdvancedHTTPRAL, on the
// AdvancedHTTPServer library) needs FPC 3.3.1 or newer: with any other compiler
// RALAdvancedHTTPServer compiles empty and this program does not build. The
// library has known defects on Windows (keep-alive stalls, TLS answers without a
// body, chunked request bodies crash it), so the example keeps to two short
// calls and does not use TLS. Only one TRALAdvancedHTTPServer can be active in a
// process.
//
// The server answers /hello and a streamed /stream; the client, in the same
// program, calls both over HTTP/1.1 with the fpHTTP engine.

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
  AResponse.Answer(HTTP_OK, 'Hello from AdvancedHTTP', 'text/plain');
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
  FServer: TRALAdvancedHTTPServer;
  FClient: TRALClient;
  FHandlers: THandlers;
  FResponse: TRALResponse;
begin
  FServer := TRALAdvancedHTTPServer.Create(nil);
  FClient := TRALClient.Create(nil);
  FHandlers := THandlers.Create;
  try
    FServer.Port := 8000;
    FServer.CreateRoute('hello', FHandlers.Hello);
    FServer.CreateRoute('stream', FHandlers.Stream);
    FServer.Active := True;
    WriteLn('RALServer (AdvancedHTTP) running on Port ', FServer.Port);

    FClient.EngineType := 'fpHTTP';
    FClient.BaseURL.Text := 'http://127.0.0.1:8000';

    FResponse := nil;
    FClient.Get('/hello', FResponse);
    try
      WriteLn('GET /hello -> ', FResponse.StatusCode, ' "', string(FResponse.ResponseText), '"');
    finally
      FreeAndNil(FResponse);
    end;

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
