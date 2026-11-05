program RALProxyExample;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  RALServer, RALIndyServer, RALIndyClient,
  Proxy.Exemplo in 'Proxy.Exemplo.pas';

var
  vFrente: TRALServer;
  vTras1, vTras2: TServidorDeTras;
  vProxy: TProxyExemplo;
begin
  vTras1 := TServidorDeTras.Create(TRALIndyServer.Create(nil), 'A', 8101);
  vTras2 := TServidorDeTras.Create(TRALIndyServer.Create(nil), 'B', 8102);
  vFrente := TRALIndyServer.Create(nil);
  vProxy := TProxyExemplo.Create;
  try
    vFrente.Port := 8100;
    vProxy.Montar(vFrente, [8101, 8102]);
    vFrente.Active := True;
    WriteLn('http://localhost:8100/api/quem     (A e B se alternam)');
    WriteLn('http://localhost:8100/proxy/stats  (estatistica; ?format=prometheus)');
    WriteLn('Enter para derrubar o servidor B...');
    ReadLn;
    FreeAndNil(vTras2);
    WriteLn('B caiu: /api/quem continua respondendo, so'' pelo A');
    WriteLn('Enter para terminar...');
    ReadLn;
    vFrente.Active := False;
  finally
    vProxy.Free;
    vFrente.Free;
    vTras2.Free;
    vTras1.Free;
  end;
end.
