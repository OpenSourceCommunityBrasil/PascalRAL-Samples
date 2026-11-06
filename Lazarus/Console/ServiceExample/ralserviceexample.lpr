program ralserviceexample;

{ A server that runs as a Windows service or a systemd daemon, or in a console.
    ralserviceexample install      installs the service (Windows, as administrator) or writes
                       the systemd unit (Linux: UnitDir, /etc/systemd/system)
    ralserviceexample console      runs here until Ctrl+C
    ralserviceexample uninstall    removes it
  Configuration: servico.json next to the program, RAL_SERVER__PORT, or
  --Server.Port=8080 on the command line. }

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALServer, RALfpHTTPServer, RALServiceHost, RALSystemLog, RALConfig, RALScheduler,
  Servico.App in 'Servico.App.pas';

var
  vServer: TRALServer;
  vHost: TRALServiceHost;
  vLog: TRALSystemLog;
  vConfig: TRALConfig;
  vScheduler: TRALScheduler;
  vApp: TServicoApp;
begin
  vServer := TRALfpHttpServer.Create(nil);
  vHost := TRALServiceHost.Create(nil);
  vLog := TRALSystemLog.Create(nil);
  vConfig := TRALConfig.Create(nil);
  vScheduler := TRALScheduler.Create(nil);
  vApp := TServicoApp.Create;
  try
    vServer.Port := 8000;
    vConfig.FileName := ExtractFilePath(ParamStr(0)) + 'servico.json';
    vConfig.Load;
    vConfig.Bind(vServer, 'Server');
    vApp.Montar(vServer, vScheduler);

    vLog.Ident := 'ralservico';
    vHost.ServiceName := 'RALServico';
    vHost.DisplayName := 'RAL - exemplo de servico';
    vHost.Description := 'PascalRAL 2.0: servidor como servico';
    vHost.Server := vServer;
    vHost.OnLog := vLog.WriteText;
    vHost.StartArgs := 'run';
    vHost.Run;
  finally
    vApp.Free;
    vScheduler.Free;
    vConfig.Free;
    vLog.Free;
    vHost.Free;
    vServer.Free;
  end;
end.
