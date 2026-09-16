program ralwebexample;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,

  // Choose here the engine of the server
  RALSynopseServer,
  //RALIndyServer,
  //RALSaguiServer,

  RALServer, RALWebModule, Web.Routes
  { you can add units after this };

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
    Defining the root path where the webfiles should be stored.

    IncludeTrailingPathDelimiter, and not the TPath.Combine that the Delphi
    version of this example uses: System.IOUtils is a Delphi unit and FPC has no
    such thing, so this project did not compile at all. The plain SysUtils call
    exists on both compilers and uses the separator of whichever platform is
    running, which is the whole point of not writing the slash by hand.
    }
    FWebModule.DocumentRoot :=
      IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0))) + 'web';

    // adding routes to the server from unit Web.Routes;
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

