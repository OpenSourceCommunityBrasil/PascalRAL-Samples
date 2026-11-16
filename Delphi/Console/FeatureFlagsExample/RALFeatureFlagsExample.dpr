program RALFeatureFlagsExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALTypes, RALMIMETypes, RALRequest, RALResponse, RALClient, RALInProc, RALConfig,
  RALFeatureFlags;

// Feature flags with PascalRAL (package RALPluginFeatureFlagsPackage), on the InProc
// engine (no port opened):
//  - "checkout-novo" is on for 30% of the users (always the same ones) and for ana;
//  - "relatorio" comes from flags.json and guards the route /relatorio: off, it
//    answers 404; the program turns it on by rewriting the file, without a restart.

type
  TDemo = class
  public
    procedure Report(ARequest: TRALRequest; AResponse: TRALResponse);
  end;

procedure TDemo.Report(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'the new report', rctTEXTPLAIN);
end;

procedure SaveText(const AFile, AText: string);
var
  vList: TStringList;
begin
  vList := TStringList.Create;
  try
    vList.Text := AText;
    vList.SaveToFile(AFile);
  finally
    vList.Free;
  end;
end;

function Status(AClient: TRALClient): Integer;
var
  vResp: TRALResponse;
begin
  AClient.Get('relatorio', vResp);
  try
    Result := vResp.StatusCode;
  finally
    vResp.Free;
  end;
end;

var
  FDemo: TDemo;
  FConfig: TRALConfig;
  FFlags: TRALFeatureFlags;
  FFlag: TRALFeatureFlag;
  FServer: TRALInProcServer;
  FClient: TRALClient;
  FFile, FLine: string;
  FUser: Integer;
begin
  FFile := ExpandFileName('flags.json');
  SaveText(FFile, '{"Flags":{"relatorio":{"Enabled":false,"Paths":["/relatorio"]}}}');
  FDemo := TDemo.Create;
  FConfig := TRALConfig.Create(nil);
  FFlags := TRALFeatureFlags.Create(nil);
  FServer := TRALInProcServer.Create(nil);
  FClient := TRALClient.Create(nil);
  try
    FConfig.FileName := FFile;
    FConfig.Load;
    FFlags.Config := FConfig;
    FFlags.ReloadInterval := 100;
    FFlag := FFlags.Flags.Add;
    FFlag.Name := 'checkout-novo';
    FFlag.Percentage := 30;
    FFlag.Users.Add('ana');

    FLine := '';
    for FUser := 1 to 20 do
      if FFlags.IsEnabled('checkout-novo', 'cliente' + IntToStr(FUser)) then
        FLine := FLine + ' cliente' + IntToStr(FUser);
    WriteLn('checkout-novo (30%) is on for:', FLine);
    WriteLn('and for ana: ', FFlags.IsEnabled('checkout-novo', 'ana'));

    FServer.ServerName := 'flags';
    FServer.CreateRoute('relatorio', FDemo.Report, 'the new report');
    FFlags.Server := FServer;
    FServer.Active := True;
    FClient.EngineType := 'InProc';
    FClient.BaseURL.Text := 'inproc://flags';
    WriteLn('GET /relatorio with the flag off: ', Status(FClient));
    // the file time may have a resolution of a second
    Sleep(1100);
    SaveText(FFile, '{"Flags":{"relatorio":{"Enabled":true,"Paths":["/relatorio"]}}}');
    Sleep(200);
    WriteLn('GET /relatorio after the file changed: ', Status(FClient));
    FServer.Active := False;
  finally
    FClient.Free;
    FServer.Free;
    FFlags.Free;
    FConfig.Free;
    FDemo.Free;
    DeleteFile(FFile);
  end;
end.
