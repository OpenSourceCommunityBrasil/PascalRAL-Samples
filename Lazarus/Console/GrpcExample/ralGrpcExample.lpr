program ralGrpcExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  // Choose here the engine of the server and of the client
  {$IFDEF FPC}RALfpHTTPServer, RALfpHTTPClient,{$ELSE}RALIndyServer, RALIndyClient,{$ENDIF}
  RALTypes, RALServer, RALClient,
  RALProtobuf, RALGrpc, RALGrpcModule, RALGrpcClient,
  // written by ralprotoc from greeter.proto
  Greeter;

// gRPC-Web with PascalRAL: a TRALGrpcModule serving the Greeter service on
// one engine, and the generated TGreeterClient calling it through a TRALClient.
//
// Greeter.pas is generated; to regenerate it after editing greeter.proto:
//   ralprotoc greeter.proto
// (ralprotoc is tools/ralprotoc/ralprotoc.dpr in the RAL checkout, run from
// this folder). Compile the unit with RALModuleProtobufPackage and
// RALModuleGrpcPackage.

type
  // The service: a subclass of the generated base, one method per rpc.
  TGreeter = class(TGreeterServiceBase)
  protected
    function SayHello(ARequest: THelloRequest; ACall: TRALGrpcServerCall): THelloReply; override;
    procedure SayHellos(ARequest: THelloRequest; ACall: TRALGrpcServerCall); override;
  end;

  TPrinter = class
  public
    // called on the client side for each reply of the stream
    procedure Reply(ASender: TObject; AMessage: TRALProtoMessage; var ACancel: Boolean);
  end;

function TGreeter.SayHello(ARequest: THelloRequest; ACall: TRALGrpcServerCall): THelloReply;
begin
  Result := THelloReply.Create;
  Result.Message := 'Hello ' + ARequest.Name;
  Result.Index := 1;
end;

procedure TGreeter.SayHellos(ARequest: THelloRequest; ACall: TRALGrpcServerCall);
var
  vInt: Integer;
  vReply: THelloReply;
begin
  for vInt := 1 to ARequest.Times do
  begin
    vReply := THelloReply.Create;
    try
      vReply.Message := 'Hello ' + ARequest.Name;
      vReply.Index := vInt;
      // Send returns False when the client went away
      if not ACall.Send(vReply) then
        Exit;
    finally
      vReply.Free;
    end;
  end;
end;

procedure TPrinter.Reply(ASender: TObject; AMessage: TRALProtoMessage; var ACancel: Boolean);
begin
  WriteLn('  stream reply #', THelloReply(AMessage).Index, ': ', string(THelloReply(AMessage).Message));
end;

var
  FServer: TRALServer;
  FModule: TRALGrpcModule;
  FHttp: TRALClient;
  FClient: TGreeterClient;
  FPrinter: TPrinter;
  FRequest: THelloRequest;
  FReply: THelloReply;
begin
  {$IFDEF FPC}
  FServer := TRALfpHttpServer.Create(nil);
  {$ELSE}
  FServer := TRALIndyServer.Create(nil);
  {$ENDIF}
  FModule := TRALGrpcModule.Create(nil);
  FHttp := TRALClient.Create(nil);
  FClient := TGreeterClient.Create(nil);
  FPrinter := TPrinter.Create;
  FRequest := THelloRequest.Create;
  try
    FModule.AddService(TGreeter.Create);
    FModule.Server := FServer;
    FServer.Port := 8000;
    FServer.Start;
    WriteLn('RALServer running on Port ', FServer.Port, ', gRPC service demo.greet.Greeter');

    {$IFDEF FPC}
    FHttp.EngineType := 'fpHTTP';
    {$ELSE}
    FHttp.EngineType := 'Indy';
    {$ENDIF}
    FHttp.BaseURL.Text := 'http://127.0.0.1:8000';
    FClient.Client := FHttp;
    FClient.Protocol := gpWeb;

    FRequest.Name := 'Ana';
    FRequest.Times := 3;

    WriteLn('SayHello (unary):');
    FReply := FClient.SayHello(FRequest);
    try
      WriteLn('  ', string(FReply.Message));
    finally
      FReply.Free;
    end;

    WriteLn('SayHellos (server streaming, 3 replies):');
    FClient.SayHellos(FRequest, FPrinter.Reply);
  finally
    FServer.Stop;
    FRequest.Free;
    FPrinter.Free;
    FClient.Free;
    FHttp.Free;
    FModule.Free;
    FServer.Free;
  end;
end.
