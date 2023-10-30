program ConsoleServer;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  RALServer,
  RALSynopseServer,
  Rotas in 'Rotas.pas';

var
  Server: TRALServer;

begin
  Server := TRALSynopseServer.Create(nil);
  Server.Port := 8000;
  Server.ShowServerStatus := true;
  Rota.CreateRoute(Server);

  Server.Active := true;
  Writeln('press any key to close the app...');
  Readln;
  Server.Active := false;
  FreeAndNil(Server);

end.
