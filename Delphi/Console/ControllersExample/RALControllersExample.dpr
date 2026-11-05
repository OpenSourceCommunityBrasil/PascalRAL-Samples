program RALControllersExample;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  RALServer, RALIndyServer, RALControllers,
  Produtos.Controller in 'Produtos.Controller.pas';

var
  vServer: TRALServer;
  vModulo: TRALControllerModule;
begin
  vServer := TRALIndyServer.Create(nil);
  try
    vServer.Port := 8000;
    vServer.ExceptionMap.AddMapping('ENaoEncontrado', 404);
    vModulo := TRALControllerModule.Create(vServer);
    vModulo.RegisterController(TProdutoController);
    vModulo.Server := vServer;
    vServer.Start;
    WriteLn('curl -d ''{"Nome":"Cafe","Preco":12.5}'' -H "Content-Type: application/json" http://localhost:8000/produtos');
    WriteLn('curl http://localhost:8000/produtos?nome=caf');
    WriteLn('curl http://localhost:8000/produtos/1');
    WriteLn('curl -X DELETE http://localhost:8000/produtos/1');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Stop;
  finally
    vServer.Free;
  end;
end.
