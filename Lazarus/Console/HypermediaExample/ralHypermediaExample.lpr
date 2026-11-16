program ralHypermediaExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALTypes, RALMIMETypes, RALRequest, RALResponse, RALClient, RALInProc, RALHypermedia;

// Hypermedia with PascalRAL (package RALModuleHypermediaPackage), on the InProc engine
// (no port opened): the route /clientes/:id answers plain JSON, and
// TRALHypermediaPlugin turns the same answer into HAL, JSON:API or an HTML page by
// the Accept header the client sends, with the links listed for the resource.

type
  TDemo = class
  public
    procedure Customer(ARequest: TRALRequest; AResponse: TRALResponse);
  end;

procedure TDemo.Customer(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, StringRAL('{"id":' + string(ARequest.ParamByName('id').AsString) +
    ',"nome":"Ana","cidade":"Recife"}'), rctAPPLICATIONJSON);
end;

var
  FDemo: TDemo;
  FServer: TRALInProcServer;
  FPlugin: TRALHypermediaPlugin;
  FResource: TRALHypermediaResource;
  FClient: TRALClient;
  FResp: TRALResponse;
  FAccept: string;
begin
  FDemo := TDemo.Create;
  FServer := TRALInProcServer.Create(nil);
  FPlugin := TRALHypermediaPlugin.Create(nil);
  FClient := TRALClient.Create(nil);
  try
    FServer.ServerName := 'loja';
    FServer.CreateRoute('clientes/:id', FDemo.Customer, 'one customer');
    FResource := FPlugin.Resources.Add;
    FResource.Path := 'clientes/:id';
    FResource.ResourceType := 'clientes';
    FResource.Title := 'Cliente';
    FResource.Links.Add('pedidos=/clientes/{id}/pedidos');
    FPlugin.Server := FServer;
    FServer.Active := True;
    FClient.EngineType := 'InProc';
    FClient.BaseURL.Text := 'inproc://loja';
    for FAccept in ['application/json', 'application/hal+json', 'application/vnd.api+json',
      'text/html'] do
    begin
      FClient.Request.Clear;
      FClient.Request.AddHeader('Accept', StringRAL(FAccept));
      FClient.Get('clientes/7', FResp);
      try
        WriteLn('Accept: ', FAccept);
        WriteLn('  ', string(FResp.ContentType));
        WriteLn('  ', StringReplace(string(FResp.ResponseText), #10, #10'  ', [rfReplaceAll]));
      finally
        FResp.Free;
      end;
    end;
    FServer.Active := False;
  finally
    FClient.Free;
    FPlugin.Free;
    FServer.Free;
    FDemo.Free;
  end;
end.
