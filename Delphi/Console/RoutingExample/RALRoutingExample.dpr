program RALRoutingExample;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  RALServer, RALIndyServer,
  Rotas.Exemplo in 'Rotas.Exemplo.pas';

var
  vServer: TRALServer;
  vRotas: TRotasExemplo;
begin
  vServer := TRALIndyServer.Create(nil);
  vRotas := TRotasExemplo.Create;
  try
    vServer.Port := 8000;
    vRotas.Montar(vServer);
    vServer.Start;
    WriteLn('http://localhost:8000/produtos/7');
    WriteLn('http://localhost:8000/pedidos  e  /pedidos/abertos');
    WriteLn('http://localhost:8000/arquivos/docs/manual.txt');
    WriteLn('http://localhost:8000/v2/clientes');
    WriteLn('http://localhost:8000/admin/relatorio  (cabecalho X-Chave: segredo)');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Stop;
  finally
    vRotas.Free;
    vServer.Free;
  end;
end.
