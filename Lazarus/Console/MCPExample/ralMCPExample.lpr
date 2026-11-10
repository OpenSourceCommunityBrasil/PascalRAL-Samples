program ralMCPExample;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  RALfpHTTPServer, RALfpHTTPClient, RALServer, RALClient, RALTypes, RALJson, RALJSONRPC,
  RALMCPServer, RALMCPStdio, RALMCPModule, RALMCPClient;

type
  TFerramentas = class
  public
    // os manipuladores rodam nas threads do servidor: não escreva no console de dentro deles
    procedure Somar(Sender: TObject; ACall: TRALMCPCall; AResult: TRALMCPToolResult);
    procedure Hora(Sender: TObject; ACall: TRALMCPCall; AResult: TRALMCPToolResult);
    procedure Saudar(Sender: TObject; ACall: TRALMCPCall; AResult: TRALMCPToolResult);
    procedure LerConfig(Sender: TObject; ACall: TRALMCPCall; AContents: TRALMCPResourceContents);
    procedure Revisar(Sender: TObject; ACall: TRALMCPCall; AResult: TRALMCPPromptResult);
    // do cliente embutido
    procedure ResponderEntrada(Sender: TObject; const AKey: StringRAL; ARequest: TRALJSON;
      var AResponse: TRALJSON);
    procedure Notificacao(Sender: TObject; AMessage: TRALJSONObject);
  end;

procedure TFerramentas.Somar(Sender: TObject; ACall: TRALMCPCall; AResult: TRALMCPToolResult);
begin
  AResult.AddText(StringRAL(IntToStr(ACall.Argument('a').AsInt64 + ACall.Argument('b').AsInt64)));
end;

procedure TFerramentas.Hora(Sender: TObject; ACall: TRALMCPCall; AResult: TRALMCPToolResult);
begin
  // só vira notificação se o cliente pediu progresso (token) e o transporte transmite
  ACall.Progress(1, 2, 'lendo o relógio');
  AResult.AddText(StringRAL(FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now)));
  ACall.Progress(2, 2);
end;

procedure TFerramentas.Saudar(Sender: TObject; ACall: TRALMCPCall; AResult: TRALMCPToolResult);
var
  vResposta: TRALJSON;
  vNome: string;
begin
  if ACall.Argument('nome') <> nil then
    vNome := string(ACall.Argument('nome').AsString)
  else
  begin
    // MRTR: sem o nome, a chamada termina pedindo a entrada; o cliente responde e chama de novo
    vResposta := ACall.InputResponse('nome');
    if vResposta = nil then
    begin
      ACall.Elicit('nome', 'Qual é o seu nome?',
        TRALJSONObject(TRALJSON.ParseJSON(
          '{"type":"object","properties":{"nome":{"type":"string"}},"required":["nome"]}')));
      Exit;
    end;
    vNome := string(vResposta.AsObject.Get('content').AsObject.Get('nome').AsString);
  end;
  AResult.AddText(StringRAL('Olá, ' + vNome + '!'));
end;

procedure TFerramentas.LerConfig(Sender: TObject; ACall: TRALMCPCall;
  AContents: TRALMCPResourceContents);
begin
  AContents.AddText('{"modo": "exemplo", "versao": 1}', 'application/json');
end;

procedure TFerramentas.Revisar(Sender: TObject; ACall: TRALMCPCall; AResult: TRALMCPPromptResult);
begin
  AResult.Description := 'Revisão de código';
  AResult.AddText('user', 'Revise o código abaixo e aponte erros e melhorias:' + #10 +
    ACall.Argument('codigo').AsString);
end;

procedure TFerramentas.ResponderEntrada(Sender: TObject; const AKey: StringRAL; ARequest: TRALJSON;
  var AResponse: TRALJSON);
begin
  // o servidor pediu a entrada "nome": aceita e responde
  AResponse := TRALJSON.ParseJSON('{"action":"accept","content":{"nome":"Maria"}}');
end;

procedure TFerramentas.Notificacao(Sender: TObject; AMessage: TRALJSONObject);
begin
  WriteLn('  (notificação do servidor: ', AMessage.Get('method').AsString, ')');
end;

function TextoDe(AResultado: TRALJSONObject): string;
begin
  Result := string(AResultado.Find('content').AsArray.Items[0].AsObject.Get('text').AsString);
end;

procedure ChamarFerramenta(AMCP: TRALMCPClient; const ANome, AArgumentos: string);
var
  vArgs: TRALJSON;
  vResultado: TRALJSONObject;
begin
  vArgs := TRALJSON.ParseJSON(StringRAL(AArgumentos));
  try
    vResultado := AMCP.CallTool(StringRAL(ANome), vArgs);
    try
      WriteLn(ANome, '(', AArgumentos, ') = ', TextoDe(vResultado));
    finally
      vResultado.Free;
    end;
  finally
    vArgs.Free;
  end;
end;

procedure DemonstrarCliente(AMCP: TRALMCPClient);
var
  vLista: TRALJSONArray;
  vResultado: TRALJSONObject;
begin
  vLista := AMCP.ListTools;
  try
    WriteLn('ferramentas listadas: ', vLista.Count);
  finally
    vLista.Free;
  end;
  ChamarFerramenta(AMCP, 'somar', '{"a": 2, "b": 3}');
  ChamarFerramenta(AMCP, 'hora', '{}');
  ChamarFerramenta(AMCP, 'saudar', '{"nome": "João"}');
  // sem o nome: o servidor pede por elicitação e OnInputRequest responde
  ChamarFerramenta(AMCP, 'saudar', '{}');

  vResultado := AMCP.ReadResource('app://config');
  try
    WriteLn('app://config = ', string(vResultado.Find('contents').AsArray.Items[0].AsObject.Get('text').AsString));
  finally
    vResultado.Free;
  end;

  vResultado := AMCP.GetPrompt('revisar_codigo', TRALJSON.ParseJSON('{"codigo": "x := 1;"}'));
  try
    WriteLn('revisar_codigo = ', string(vResultado.Find('messages').AsArray.Items[0].AsObject.Get('content').AsObject.Get('text').AsString));
  finally
    vResultado.Free;
  end;
end;

procedure ConfigurarServidor(AMCPServer: TRALMCPServer; AF: TFerramentas);
var
  vTool: TRALMCPTool;
begin
  AMCPServer.ServerName := 'MCPExample';
  AMCPServer.ServerVersion := '1.0';

  vTool := AMCPServer.Tools.AddTool('somar', 'Soma dois inteiros', {$IFDEF FPC}@{$ENDIF}AF.Somar);
  vTool.Params.AddParam('a', mptInteger, 'primeiro número');
  vTool.Params.AddParam('b', mptInteger, 'segundo número');
  AMCPServer.Tools.AddTool('hora', 'Devolve a hora do servidor', {$IFDEF FPC}@{$ENDIF}AF.Hora);
  vTool := AMCPServer.Tools.AddTool('saudar', 'Saúda alguém; pergunta o nome se não vier',
    {$IFDEF FPC}@{$ENDIF}AF.Saudar);
  vTool.Params.AddParam('nome', mptString, 'nome a saudar', False);

  AMCPServer.Resources.AddResource('app://config', 'config',
    {$IFDEF FPC}@{$ENDIF}AF.LerConfig, 'application/json');
  AMCPServer.Prompts.AddPrompt('revisar_codigo', 'Pede a revisão de um trecho de código',
    {$IFDEF FPC}@{$ENDIF}AF.Revisar).Arguments.AddArgument('codigo', True, 'o código a revisar');
end;

var
  FF: TFerramentas;
  FMCPServer: TRALMCPServer;
  FStdio: TRALMCPStdio;
  FServer: TRALServer;
  FModule: TRALMCPModule;
  FClient: TRALClient;
  FMCP: TRALMCPClient;
begin
  FF := TFerramentas.Create;
  FMCPServer := TRALMCPServer.Create(nil);
  try
    ConfigurarServidor(FMCPServer, FF);

    if ParamStr(1) = '--stdio' then
    begin
      // o que um cliente de IA inicia: lê JSON-RPC do stdin, responde no stdout (nada mais vai ao stdout)
      FStdio := TRALMCPStdio.Create(nil);
      try
        FStdio.Server := FMCPServer;
        FStdio.Run;
      finally
        FreeAndNil(FStdio);
      end;
    end
    else
    begin
      FServer := TRALfpHttpServer.Create(nil);
      FModule := TRALMCPModule.Create(nil);
      FClient := TRALClient.Create(nil);
      FMCP := TRALMCPClient.Create(nil);
      try
        FModule.MCPServer := FMCPServer;
        FModule.Server := FServer;
        FServer.Port := StrToIntDef(ParamStr(1), 8000); // a porta pode vir como parâmetro
        FServer.Start;
        WriteLn('RALServer running on Port ', FServer.Port, ', MCP at ', string(FModule.Path));

        // cliente MCP no mesmo processo
        FClient.EngineType := 'fpHTTP';
        FClient.BaseURL.Text := 'http://127.0.0.1:' + IntToStr(FServer.Port);
        FMCP.Client := FClient;
        FMCP.Capabilities := '{"elicitation":{"form":{}}}';
        FMCP.OnInputRequest := {$IFDEF FPC}@{$ENDIF}FF.ResponderEntrada;
        FMCP.OnNotification := {$IFDEF FPC}@{$ENDIF}FF.Notificacao;
        DemonstrarCliente(FMCP);

        WriteLn('Press ENTER to finish');
        ReadLn;
      finally
        FServer.Stop;
        FreeAndNil(FMCP);
        FreeAndNil(FClient);
        FreeAndNil(FModule);
        FreeAndNil(FServer);
      end;
    end;
  finally
    FreeAndNil(FMCPServer);
    FreeAndNil(FF);
  end;
end.
