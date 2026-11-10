program RALJSONRPCExample;

{$APPTYPE CONSOLE}

{$I PascalRAL.inc}

uses
  System.Classes, System.SysUtils,

  // Choose here the engine of the server and of the client
  RALIndyServer, RALIndyClient,
  //RALSynopseServer,

  RALServer, RALClient, RALTypes, RALJson,
  RALJSONRPC, RALJSONRPCModule, RALJSONRPCClient
  {$IFDEF RALHasExtRTTI}, RALJSONRPCObjects{$ENDIF};

type
  TMetodos = class
  public
    // the methods run on the threads of the server: do not write to the console from them
    Notificacoes: Integer;
    procedure Agora(Sender: TObject; ARequest: TRALJSONRPCRequest; AResult: TRALJSONRPCResult);
    procedure Falha(Sender: TObject; ARequest: TRALJSONRPCRequest; AResult: TRALJSONRPCResult);
    procedure Saudacao(Sender: TObject; ARequest: TRALJSONRPCRequest; AResult: TRALJSONRPCResult);
    procedure Soma(Sender: TObject; ARequest: TRALJSONRPCRequest; AResult: TRALJSONRPCResult);
  end;

procedure TMetodos.Agora(Sender: TObject; ARequest: TRALJSONRPCRequest; AResult: TRALJSONRPCResult);
begin
  AResult.SetString(StringRAL(FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now)));
end;

procedure TMetodos.Falha(Sender: TObject; ARequest: TRALJSONRPCRequest; AResult: TRALJSONRPCResult);
begin
  // the code, the message and (optional) data as JSON text
  raise ERALJSONRPCError.CreateRPC(-1, 'Saldo insuficiente', '{"saldo": 10}');
end;

procedure TMetodos.Saudacao(Sender: TObject; ARequest: TRALJSONRPCRequest; AResult: TRALJSONRPCResult);
begin
  if ARequest.IsNotification then
    Inc(Notificacoes) // a notification: nobody waits for an answer
  else
    AResult.SetString('Ola, ' + ARequest.Param('nome').AsString + '!');
end;

procedure TMetodos.Soma(Sender: TObject; ARequest: TRALJSONRPCRequest; AResult: TRALJSONRPCResult);
begin
  // by name ({"a":2,"b":3}) or by position ([2,3]), the declared Param finds both
  AResult.SetInteger(ARequest.Param('a').AsInt64 + ARequest.Param('b').AsInt64);
end;

{$IFDEF RALHasExtRTTI}
type
  // the public methods become JSON-RPC methods: calc.Somar, calc.Dividir
  TCalculadora = class
  public
    function Dividir(A, B: Double): Double;
    function Somar(A, B: Integer): Integer;
  end;

function TCalculadora.Dividir(A, B: Double): Double;
begin
  if B = 0 then
    raise ERALJSONRPCError.CreateRPC(-2, 'Divisao por zero');
  Result := A / B;
end;

function TCalculadora.Somar(A, B: Integer): Integer;
begin
  Result := A + B;
end;
{$ENDIF}

procedure ChamarTudo(ARPC: TRALJSONRPCClient; AMetodos: TMetodos);
var
  vParams, vResultado: TRALJSON;
  vLote: TRALJSONRPCBatch;
  vSoma, vSaudacao, vFalha: IntegerRAL;
begin
  // Call: params as TRALJSON (an object or an array), the result is yours to free
  vParams := TRALJSON.ParseJSON('{"a": 2, "b": 3}');
  try
    vResultado := ARPC.Call('soma', vParams);
    try
      WriteLn('soma(2, 3)         = ', vResultado.AsInt64);
    finally
      vResultado.Free;
    end;
  finally
    vParams.Free;
  end;

  // CallText: params and result as JSON text; by position this time
  WriteLn('soma([10, 20])     = ', ARPC.CallText('soma', '[10, 20]'));
  WriteLn('saudacao           = ', ARPC.CallText('saudacao', '{"nome": "Maria"}'));
  WriteLn('agora              = ', ARPC.CallText('agora'));

  // an ERALJSONRPCError of the server comes back as the same exception
  try
    ARPC.Call('falha');
  except
    on E: ERALJSONRPCError do
      WriteLn('falha              = erro ', E.Code, ' "', E.Message, '" data ', E.Data);
  end;

  // a call with wrong params is answered by the dispatcher: Invalid params
  try
    ARPC.CallText('soma', '["x", 1]');
  except
    on E: ERALJSONRPCError do
      WriteLn('soma("x", 1)       = erro ', E.Code, ' "', E.Message, '"');
  end;

  // a notification gets no answer
  vParams := TRALJSON.ParseJSON('{"nome": "Joao"}');
  try
    ARPC.Notify('saudacao', vParams);
  finally
    vParams.Free;
  end;
  WriteLn('notificacao        = enviada, o servidor contou ', AMetodos.Notificacoes);

  // a batch: one POST, the answers by the position Call returned
  vLote := ARPC.NewBatch;
  try
    vParams := TRALJSON.ParseJSON('[7, 8]');
    try
      vSoma := vLote.Call('soma', vParams);
    finally
      vParams.Free;
    end;
    vLote.Notify('agora');
    vSaudacao := vLote.Call('saudacao', nil);   // without params: Invalid params
    vFalha := vLote.Call('falha');
    vLote.Send;

    WriteLn('lote soma          = ', vLote.Value(vSoma).AsInt64);
    WriteLn('lote saudacao      = erro ', vLote.ErrorCode(vSaudacao), ' ', vLote.ErrorMessage(vSaudacao));
    WriteLn('lote falha         = erro ', vLote.ErrorCode(vFalha), ' ', vLote.ErrorMessage(vFalha));
  finally
    vLote.Free;
  end;
end;

var
  FServer: TRALServer;
  FModule: TRALJSONRPCModule;
  FClient: TRALClient;
  FRPC: TRALJSONRPCClient;
  FMetodos: TMetodos;
  vMethod: TRALJSONRPCMethod;
  {$IFDEF RALHasExtRTTI}
  FCalculadora: TCalculadora;
  {$ENDIF}
begin
  FMetodos := TMetodos.Create;
  FServer := TRALIndyServer.Create(nil);
  FModule := TRALJSONRPCModule.Create(nil);
  FClient := TRALClient.Create(nil);
  FRPC := TRALJSONRPCClient.Create(nil);
  {$IFDEF RALHasExtRTTI}
  FCalculadora := TCalculadora.Create;
  {$ENDIF}
  try
    // server: the module answers POST /rpc
    FModule.Server := FServer;
    vMethod := FModule.Methods.AddMethod('soma', FMetodos.Soma, 'soma dois inteiros');
    vMethod.Params.AddParam('a', jptInteger);
    vMethod.Params.AddParam('b', jptInteger);
    vMethod := FModule.Methods.AddMethod('saudacao', FMetodos.Saudacao);
    vMethod.Params.AddParam('nome', jptString);
    FModule.Methods.AddMethod('agora', FMetodos.Agora);
    FModule.Methods.AddMethod('falha', FMetodos.Falha);
    {$IFDEF RALHasExtRTTI}
    RALJSONRPCRegisterObject(FModule.Dispatcher, FCalculadora, 'calc');
    {$ENDIF}
    FServer.Port := 8000;
    FServer.Start;
    WriteLn('RALServer running on Port ' + IntToStr(FServer.Port) + ', JSON-RPC at ' + string(FModule.Path));

    // client in the same process
    FClient.EngineType := 'Indy';
    FClient.BaseURL.Text := 'http://127.0.0.1:8000';
    FRPC.Client := FClient;
    ChamarTudo(FRPC, FMetodos);

    {$IFDEF RALHasExtRTTI}
    WriteLn('calc.Somar([4, 5])   = ', FRPC.CallText('calc.Somar', '[4, 5]'));
    WriteLn('calc.Dividir([1, 4]) = ', FRPC.CallText('calc.Dividir', '[1, 4]'));
    try
      FRPC.CallText('calc.Dividir', '[1, 0]');
    except
      on E: ERALJSONRPCError do
        WriteLn('calc.Dividir([1, 0]) = erro ', E.Code, ' "', E.Message, '"');
    end;
    {$ENDIF}

    if ParamStr(1) = '--serve' then
    begin
      WriteLn('Press ENTER to finish');
      ReadLn;
    end;
  finally
    FServer.Stop;
    {$IFDEF RALHasExtRTTI}
    RALJSONRPCUnregisterObject(FModule.Dispatcher, FCalculadora);
    FreeAndNil(FCalculadora);
    {$ENDIF}
    FreeAndNil(FRPC);
    FreeAndNil(FClient);
    FreeAndNil(FModule);
    FreeAndNil(FServer);
    FreeAndNil(FMetodos);
  end;
end.
