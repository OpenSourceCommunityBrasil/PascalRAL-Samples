/// Um proxy reverso com o RAL 2.0 (RALModuleProxyPackage): um servidor na
/// frente reparte /api entre dois servidores RAL de tras, que veem o IP real do
/// cliente pelo TRALForwardedPlugin (RALPluginForwardedPackage).
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/balanceador
unit Proxy.Exemplo;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils,
  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse,
  RALForwarded, RALProxyCore, RALProxyModule;

type
  /// Um servidor de tras: responde quem ele e' e quem pediu.
  TServidorDeTras = class
  private
    FNome: string;
    FForwarded: TRALForwardedPlugin;
    FServidor: TRALServer;

    procedure Quem(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Saude(ARequest: TRALRequest; AResponse: TRALResponse);
  public
    constructor Create(AServidor: TRALServer; const ANome: string; APorta: Integer);
    destructor Destroy; override;
  end;

  /// O servidor da frente: o proxy para os de tras.
  TProxyExemplo = class
  private
    FGrupo: TRALUpstream;
    FProxy: TRALProxyModule;

    procedure Mudou(Sender: TObject; AServer: TRALUpstreamServer; AUp: boolean);
  public
    destructor Destroy; override;

    /// Liga em AServidor um proxy de /api para as portas de tras.
    procedure Montar(AServidor: TRALServer; const APortas: array of Integer);
  end;

implementation

{ TServidorDeTras }

constructor TServidorDeTras.Create(AServidor: TRALServer; const ANome: string; APorta: Integer);
begin
  inherited Create;
  FNome := ANome;
  FServidor := AServidor;
  FServidor.Port := APorta;
  FServidor.CreateRoute('quem', Quem).Allow([amGET]);
  FServidor.CreateRoute('health', Saude).Allow([amGET]);
  // o proxy da frente esta' na mesma maquina: o IP dos pedidos e' o dele
  FForwarded := TRALForwardedPlugin.Create(nil);
  FForwarded.TrustedProxies.Text := 'loopback';
  FForwarded.Server := FServidor;
  FServidor.Active := True;
end;

destructor TServidorDeTras.Destroy;
begin
  FServidor.Active := False;
  FForwarded.Free;
  FServidor.Free;
  inherited Destroy;
end;

procedure TServidorDeTras.Quem(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  // ClientInfo.IP e' o cliente, nao o proxy, gracas ao TRALForwardedPlugin
  AResponse.Answer(HTTP_OK, '{"servidor":"' + StringRAL(FNome) + '","cliente":"' +
    ARequest.ClientInfo.IP + '"}', rctAPPLICATIONJSON);
end;

procedure TServidorDeTras.Saude(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'ok', rctTEXTPLAIN);
end;

{ TProxyExemplo }

destructor TProxyExemplo.Destroy;
begin
  FProxy.Free;
  FGrupo.Free;
  inherited Destroy;
end;

procedure TProxyExemplo.Montar(AServidor: TRALServer; const APortas: array of Integer);
var
  vInt: Integer;
begin
  FGrupo := TRALUpstream.Create(nil);
  FGrupo.Name := 'api';
  FGrupo.EngineType := {$IFDEF FPC}'fpHTTP'{$ELSE}'Indy'{$ENDIF};
  for vInt := 0 to High(APortas) do
    FGrupo.Servers.AddServer(StringRAL('http://127.0.0.1:' + IntToStr(APortas[vInt])));
  FGrupo.Policy := lpRoundRobin;
  // verificacao ativa: um servidor que nao responde /health sai da roda
  FGrupo.HealthCheck.Enabled := True;
  FGrupo.HealthCheck.Path := '/health';
  FGrupo.HealthCheck.Interval := 2000;
  FGrupo.ConnectTimeout := 1000;
  FGrupo.OnServerChange := Mudou;

  FProxy := TRALProxyModule.Create(nil);
  FProxy.Rules.AddRule('/api', FGrupo).StripPrefix := True; // /api/quem -> /quem
  FProxy.StatsPath := '/proxy/stats';
  FProxy.Via := 'exemplo';
  FProxy.Server := AServidor;
end;

procedure TProxyExemplo.Mudou(Sender: TObject; AServer: TRALUpstreamServer; AUp: boolean);
begin
  if AUp then
    WriteLn('voltou: ', AServer.URL)
  else
    WriteLn('saiu da roda: ', AServer.URL);
end;

end.
