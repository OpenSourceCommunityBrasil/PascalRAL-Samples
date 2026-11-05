/// Operacao de um servidor RAL 2.0: log de acesso, erros em problem+json,
/// limite de pedidos, cache de resposta com ETag, saude, metricas, rastreio, e
/// no cliente o Retry.
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/operacao
unit Operacao.Exemplo;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils,
  RALServer, RALClient, RALRequest, RALResponse, RALTypes, RALConsts,
  RALMIMETypes, RALObservability, RALTraffic, RALResponseCache;

type
  /// Um erro de validacao: o ExceptionMap o responde 422, nao 500.
  EValidacao = class(Exception);

  /// Liga os plugins de operacao num servidor e cria as rotas do exemplo.
  TOperacaoExemplo = class
  private
    FCache: TRALResponseCachePlugin;
    FChamadas: Integer;
    FHealth: TRALHealthPlugin;
    FLimite: TRALRateLimitPlugin;
    FLog: TRALLogPlugin;
    FMetricas: TRALMetricsPlugin;
    FPorta: Integer;
    FRastreio: TRALTracePlugin;

    procedure Chamar(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure ChecarDisco(ACheck: TRALHealthCheck; var AHealthy: boolean;
      var AOutput: StringRAL);
    procedure Instavel(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Produtos(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Validar(ARequest: TRALRequest; AResponse: TRALResponse);
  public
    destructor Destroy; override;

    /// Liga os plugins em AServer (que escuta em APorta) e cria as rotas.
    procedure Montar(AServer: TRALServer; APorta: Integer);
  end;

implementation

destructor TOperacaoExemplo.Destroy;
begin
  // cada plugin se desliga do servidor ao ser liberado
  FCache.Free;
  FHealth.Free;
  FLimite.Free;
  FLog.Free;
  FMetricas.Free;
  FRastreio.Free;
  inherited Destroy;
end;

procedure TOperacaoExemplo.Montar(AServer: TRALServer; APorta: Integer);
begin
  FPorta := APorta;

  // erros do proprio RAL (404, 405, 429, 500...) no JSON da RFC 9457
  AServer.ErrorFormat := efProblemJSON;
  AServer.ExceptionMap.AddMapping('EValidacao', 422, '', 'Dados invalidos');

  // uma linha por pedido no console, no formato combined do Apache
  FLog := TRALLogPlugin.Create(nil);
  FLog.Format := lfCombined;
  FLog.Console := True;
  FLog.Server := AServer;

  // traceparent: o mesmo traceId no log, no erro e no proximo servico
  FRastreio := TRALTracePlugin.Create(nil);
  FRastreio.Server := AServer;

  // 30 pedidos por minuto por IP; /instavel so 5 a cada 10 segundos
  FLimite := TRALRateLimitPlugin.Create(nil);
  FLimite.Limit := 30;
  FLimite.Window := 60000;
  FLimite.Rules.AddRule('/instavel', 5, 10000);
  FLimite.Server := AServer;

  // /produtos fica 15 segundos no cache; toda resposta GET ganha ETag
  FCache := TRALResponseCachePlugin.Create(nil);
  FCache.CacheRoutes.AddRoute('/produtos', 15);
  FCache.Server := AServer;

  // /health/live e /health/ready
  FHealth := TRALHealthPlugin.Create(nil);
  FHealth.Checks.AddCheck('disco', ChecarDisco);
  FHealth.Server := AServer;

  // /metrics no formato do Prometheus
  FMetricas := TRALMetricsPlugin.Create(nil);
  FMetricas.Server := AServer;

  AServer.CreateRoute('produtos', Produtos).Allow([amGET]);
  AServer.CreateRoute('validar', Validar).Allow([amGET]);
  AServer.CreateRoute('instavel', Instavel).Allow([amGET]);
  AServer.CreateRoute('chamar', Chamar).Allow([amGET]);
end;

procedure TOperacaoExemplo.ChecarDisco(ACheck: TRALHealthCheck; var AHealthy: boolean;
  var AOutput: StringRAL);
begin
  // num servidor de verdade: espaco em disco, o banco, um servico externo
  AHealthy := DirectoryExists(ExtractFilePath(ParamStr(0)));
  if not AHealthy then
    AOutput := 'pasta do programa sumiu';
end;

procedure TOperacaoExemplo.Produtos(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  // a hora mostra quando a resposta veio do cache (X-Cache: HIT)
  AResponse.Answer(HTTP_OK, '{"produtos":["cafe","pao"],"gerado":"' +
    StringRAL(FormatDateTime('hh:nn:ss', Now)) + '"}', rctAPPLICATIONJSON);
end;

procedure TOperacaoExemplo.Validar(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  // o ExceptionMap responde 422 em problem+json
  raise EValidacao.Create('o campo nome e obrigatorio');
end;

procedure TOperacaoExemplo.Instavel(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  // falha duas vezes a cada tres: o Retry do cliente insiste
  Inc(FChamadas);
  if FChamadas mod 3 <> 0 then
    AResponse.AnswerError(HTTP_ServiceUnavailable, 'tente de novo')
  else
    AResponse.Answer(HTTP_OK, 'agora foi', rctTEXTPLAIN);
end;

procedure TOperacaoExemplo.Chamar(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vClient: TRALClient;
  vResp: TRALResponse;
begin
  // um cliente que repete ate 3 vezes; leva o traceparent deste pedido
  vClient := TRALClient.Create(nil);
  try
    vClient.EngineType := {$IFDEF FPC}'fpHTTP'{$ELSE}'Indy'{$ENDIF};
    vClient.BaseURL.Text := 'http://localhost:' + IntToStr(FPorta);
    vClient.Retry.MaxAttempts := 3;
    vClient.Retry.Delay := 100;
    vResp := nil;
    try
      vClient.Get('/instavel', vResp);
      AResponse.Answer(HTTP_OK, 'o /instavel respondeu ' +
        StringRAL(IntToStr(vResp.StatusCode)) + ': ' + vResp.ResponseText, rctTEXTPLAIN);
    finally
      vResp.Free;
    end;
  finally
    vClient.Free;
  end;
end;

end.
