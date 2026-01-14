program RALWebExample;

uses
  System.Classes, System.SysUtils, System.IOUtils,

  // Choose here the engine of the server
  RALSynopseServer,
  //RALIndyServer,
  //RALSaguiServer,

  RALServer, RALWebModule,

  // routing unit
  Web.Routes in 'src/web.routes.pas';

var
  FServer: TRALServer;
  FWebModule: TRALWebModule;
begin
  // Change the engine of the server here:
  FServer := TRALSynopseServer.Create(nil);
  //FServer := TRALIndyServer.Create(nil);
  //FServer := TRALSaguiServer.Create(nil);

  FWebModule := TRALWebModule.Create(nil);
  try
    FWebModule.Server := FServer;
    {
    Defining the root path where the webfiles should be stored. We use TPath.Combine
    here for easy compatibility between Windows and Linux servers, since Windows
    uses '/' for folders and Linux uses '\'. It's easy to mix those so TPath solves
    that
    }
    FWebModule.DocumentRoot := TPath.Combine(ExtractFileDir(ParamStr(0)), 'web');

    // adding routes to the server from unit Web.Routes:
    RegisterWebRoutes(FWebModule);

    FServer.Port := 8000; // 8000 is the default port if none is assigned.
    FServer.Start;

    WriteLn('RALServer running on Port ' + FServer.Port.ToString);
    WriteLn('Press any key to finish');
    ReadLn;
  finally
    FServer.Stop;
    FreeAndNil(FWebModule);
    FreeAndNil(FServer);
  end;
end.
