unit Servico.App;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

{ The application of the service example: two routes and a job. The host,
  the configuration and the system log are wired in the program. }

interface

uses
  Classes, SysUtils,
  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse,
  RALScheduler;

type
  TServicoApp = class
  private
    FTicks: Integer;
  public
    /// GET /ping: pong and how many times the job ran.
    procedure Ping(ARequest: TRALRequest; AResponse: TRALResponse);
    /// GET /lento: two seconds, to watch a stop wait for it.
    procedure Lento(ARequest: TRALRequest; AResponse: TRALResponse);
    /// The job of the scheduler.
    procedure Tarefa(AJob: TRALScheduledJob);
    procedure Montar(AServer: TRALServer; AScheduler: TRALScheduler);
  end;

implementation

procedure TServicoApp.Ping(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong ' + IntToStr(FTicks), rctTEXTPLAIN);
end;

procedure TServicoApp.Lento(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  Sleep(2000);
  AResponse.Answer(HTTP_OK, 'lento terminou', rctTEXTPLAIN);
end;

procedure TServicoApp.Tarefa(AJob: TRALScheduledJob);
begin
  Inc(FTicks);
end;

procedure TServicoApp.Montar(AServer: TRALServer; AScheduler: TRALScheduler);
begin
  AServer.CreateRoute('ping', Ping);
  AServer.CreateRoute('lento', Lento);
  { every 30 seconds; a cron would be Cron := '*/5 * * * *' }
  AScheduler.Jobs.AddInterval('contador', 30000, Tarefa).RunOnStart := True;
  AScheduler.Server := AServer;
end;

end.
