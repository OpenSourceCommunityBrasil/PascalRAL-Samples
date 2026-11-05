program RALObjectsExample;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  RALServer, RALIndyServer,
  Objetos.Exemplo in 'Objetos.Exemplo.pas';

var
  vServer: TRALServer;
  vExemplo: TObjetosExemplo;
begin
  vServer := TRALIndyServer.Create(nil);
  vExemplo := TObjetosExemplo.Create;
  try
    vServer.Port := 8000;
    vExemplo.Montar(vServer);
    vServer.Start;
    WriteLn('curl -d ''{"cliente":"Ana","email":"ana@x.com","itens":[{"produto":"Cafe","qtd":2,"preco":12.5}]}'' -H "Content-Type: application/json" http://localhost:8000/pedidos');
    WriteLn('curl -d ''{"cliente":""}'' -H "Content-Type: application/json" http://localhost:8000/pedidos   (422)');
    WriteLn('curl -H "Accept: text/csv" http://localhost:8000/itens');
    WriteLn('curl -H "Accept: application/yaml" http://localhost:8000/itens');
    WriteLn('http://localhost:8000/swagger');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Stop;
  finally
    vExemplo.Free;
    vServer.Free;
  end;
end.
