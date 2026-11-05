/// RALProxy como servico do Windows. A configuracao e' o ralproxy.conf ao lado
/// do executavel; salvar o arquivo recarrega sem cortar conexoes.
///
///   RALProxyService.exe /install     (como administrador)
///   sc start RALProxy
///   sc stop RALProxy
///   RALProxyService.exe /uninstall
program RALProxyService;

uses
  Windows, SysUtils, Classes, Vcl.SvcMgr,
  RALProxy.App in 'RALProxy.App.pas';

type
  /// O servico: o mesmo TRALProxyApp do console, com o ciclo do Windows.
  TRALProxyService = class(TService)
  private
    FApp: TRALProxyApp;
    procedure Comecou(Sender: TService; var Started: Boolean);
    procedure Rodando(Sender: TService);
    procedure Parou(Sender: TService; var Stopped: Boolean);
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    function GetServiceController: TServiceController; override;
  end;

var
  GServico: TRALProxyService;

procedure ControleDoServico(CtrlCode: DWord); stdcall;
begin
  GServico.Controller(CtrlCode);
end;

constructor TRALProxyService.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited CreateNew(AOwner, Dummy);
  Name := 'RALProxy';
  DisplayName := 'RALProxy (PascalRAL)';
  OnStart := Comecou;
  OnExecute := Rodando;
  OnStop := Parou;
end;

function TRALProxyService.GetServiceController: TServiceController;
begin
  Result := ControleDoServico;
end;

procedure TRALProxyService.Comecou(Sender: TService; var Started: Boolean);
begin
  FApp := TRALProxyApp.Create(ExtractFilePath(ParamStr(0)) + 'ralproxy.conf');
  try
    FApp.Inicia;
    Started := True;
  except
    on E: Exception do
    begin
      LogMessage('RALProxy: ' + E.Message, EVENTLOG_ERROR_TYPE);
      FreeAndNil(FApp);
      Started := False;
    end;
  end;
end;

procedure TRALProxyService.Rodando(Sender: TService);
var
  vErro: string;
  vVolta: Integer;
begin
  vVolta := 0;
  while not Terminated do
  begin
    ServiceThread.ProcessRequests(False);
    Sleep(200);
    Inc(vVolta);
    if (vVolta mod 10 = 0) and FApp.ArquivoMudou then
      if not FApp.Recarrega(vErro) then
        FApp.Erro('recarga recusada, a configuracao anterior continua: ' + vErro);
  end;
end;

procedure TRALProxyService.Parou(Sender: TService; var Stopped: Boolean);
begin
  FreeAndNil(FApp);
  Stopped := True;
end;

begin
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  GServico := TRALProxyService.CreateNew(Application, 0);
  Application.Run;
end.
