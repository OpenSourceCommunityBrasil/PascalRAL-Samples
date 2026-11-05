program ralmoduleexample;

{$mode delphi}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils,
  RALServer, RALfpHTTPServer,
  Saudacao.Module;

var
  vServer: TRALServer;
  vModule: TSaudacaoModule;
begin
  vServer := TRALfpHTTPServer.Create(nil);
  vModule := TSaudacaoModule.Create(nil);
  try
    vServer.Port := 8000;
    vModule.Domain := '/saudacao';
    vModule.Server := vServer;
    vServer.Start;
    WriteLn('http://localhost:8000/saudacao/ola/ana');
    WriteLn('http://localhost:8000/saudacao/ping');
    WriteLn('http://localhost:8000/saudacao/falha');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Stop;
  finally
    vModule.Free;
    vServer.Free;
  end;
end.
