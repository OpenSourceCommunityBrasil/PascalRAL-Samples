program RALServicesEventsExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  RALTypes, RALMIMETypes, RALRequest, RALResponse, RALClient, RALInProc,
  RALServiceContainer, RALEventBus;

// Services and events with PascalRAL (packages RALHostingContainerPackage and
// RALModuleEventBusPackage), on the InProc engine, so no port is opened:
//  - TRALServiceContainer makes a "numbering" service once for the program and an
//    "order desk" service once per request (freed when the request ends);
//  - the route /pedido asks the container for the order desk, which takes a number
//    and publishes the event pedido/criado on a TRALEventBus;
//  - an "invoice" part of the program subscribed to pedido/# and reacts on the
//    bus's thread, without the route knowing it exists.

type
  INumbering = interface
    ['{4B0C1E6A-2D3F-4A5B-8C7D-9E0F1A2B3C4D}']
    function Next: Integer;
  end;

  IOrderDesk = interface
    ['{4B0C1E6A-2D3F-4A5B-8C7D-9E0F1A2B3C4E}']
    function Place(const AItem: string): Integer;
  end;

  /// One for the whole program: hands out order numbers.
  TNumbering = class(TRALService, INumbering)
  private
    FLast: Integer;
    FLock: TCriticalSection;
  public
    constructor Create(AContainer: TRALServiceContainer; ARequest: TRALRequest); override;
    destructor Destroy; override;
    function Next: Integer;
  end;

  /// One per request: asks the container for the numbering it depends on.
  TOrderDesk = class(TRALService, IOrderDesk)
  private
    FNumbering: INumbering;
  public
    constructor Create(AContainer: TRALServiceContainer; ARequest: TRALRequest); override;
    destructor Destroy; override;
    function Place(const AItem: string): Integer;
  end;

  TDemo = class
  public
    Services: TRALServiceContainer;
    Events: TRALEventBus;
    procedure OrderRoute(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Invoice(Sender: TObject; AEvent: TRALEvent);
  end;

var
  GLock: TCriticalSection;
  GDemo: TDemo;

procedure Log(const AText: string);
begin
  GLock.Acquire;
  try
    WriteLn(AText);
    Flush(Output);
  finally
    GLock.Release;
  end;
end;

constructor TNumbering.Create(AContainer: TRALServiceContainer; ARequest: TRALRequest);
begin
  inherited Create(AContainer, ARequest);
  FLock := TCriticalSection.Create;
  FLast := 1000;
end;

destructor TNumbering.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

function TNumbering.Next: Integer;
begin
  FLock.Acquire;
  try
    Inc(FLast);
    Result := FLast;
  finally
    FLock.Release;
  end;
end;

constructor TOrderDesk.Create(AContainer: TRALServiceContainer; ARequest: TRALRequest);
begin
  inherited Create(AContainer, ARequest);
  AContainer.Resolve(INumbering, FNumbering, ARequest);
  Log('  order desk made for this request');
end;

destructor TOrderDesk.Destroy;
begin
  Log('  order desk freed with the request');
  inherited Destroy;
end;

function TOrderDesk.Place(const AItem: string): Integer;
begin
  Result := FNumbering.Next;
  GDemo.Events.Publish('pedido/criado', RawByteString(UTF8String(
    Format('{"numero":%d,"item":"%s"}', [Result, AItem]))));
end;

procedure TDemo.OrderRoute(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vDesk: IOrderDesk;
  vNumber: Integer;
begin
  Services.Resolve(IOrderDesk, vDesk, ARequest);
  vNumber := vDesk.Place(string(ARequest.ParamByName('item').AsString));
  AResponse.Answer(200, StringRAL(Format('pedido %d registrado', [vNumber])), rctTEXTPLAIN);
end;

procedure TDemo.Invoice(Sender: TObject; AEvent: TRALEvent);
begin
  // runs on the bus's thread: the route has already answered
  Log('  invoice for ' + string(AEvent.Topic) + ': ' + AEvent.Text);
end;

var
  FServer: TRALInProcServer;
  FClient: TRALClient;
  FResp: TRALResponse;
  FItem: string;
begin
  GLock := TCriticalSection.Create;
  GDemo := TDemo.Create;
  GDemo.Services := TRALServiceContainer.Create(nil);
  GDemo.Events := TRALEventBus.Create(nil);
  FServer := TRALInProcServer.Create(nil);
  FClient := TRALClient.Create(nil);
  try
    RALRegisterService(TNumbering);
    RALRegisterService(TOrderDesk);
    GDemo.Services.AddService('numbering', 'TNumbering', slSingleton,
      '{4B0C1E6A-2D3F-4A5B-8C7D-9E0F1A2B3C4D}');
    GDemo.Services.AddService('orders', 'TOrderDesk', slPerRequest,
      '{4B0C1E6A-2D3F-4A5B-8C7D-9E0F1A2B3C4E}');

    GDemo.Events.Delivery := edAsync;
    GDemo.Events.Subscribe('pedido/#', GDemo.Invoice);

    FServer.ServerName := 'loja';
    FServer.CreateRoute('pedido', GDemo.OrderRoute, 'places an order');
    FServer.Active := True;
    FClient.EngineType := 'InProc';
    FClient.BaseURL.Text := 'inproc://loja';

    for FItem in ['pizza', 'refrigerante'] do
    begin
      Log('GET /pedido?item=' + FItem);
      FClient.Request.Clear;
      FClient.Request.AddQuery('item', StringRAL(FItem));
      FClient.Get('pedido', FResp);
      try
        Log('  answer: ' + string(FResp.ResponseText));
      finally
        FResp.Free;
      end;
    end;
    GDemo.Events.WaitIdle;
    FServer.Active := False;
  finally
    FClient.Free;
    FServer.Free;
    GDemo.Events.Free;
    GDemo.Services.Free;
    GDemo.Free;
    GLock.Free;
  end;
end.
