program RALOperationsExample;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  RALServer, RALIndyServer, RALIndyClient,
  Operacao.Exemplo in 'Operacao.Exemplo.pas';

var
  vServer: TRALServer;
  vOperacao: TOperacaoExemplo;
begin
  vServer := TRALIndyServer.Create(nil);
  vOperacao := TOperacaoExemplo.Create;
  try
    vServer.Port := 8000;
    vOperacao.Montar(vServer, 8000);
    vServer.Start;
    WriteLn('http://localhost:8000/produtos       (de novo em 15 s: X-Cache: HIT)');
    WriteLn('http://localhost:8000/validar        (422 em problem+json)');
    WriteLn('http://localhost:8000/nada           (404 em problem+json)');
    WriteLn('http://localhost:8000/chamar         (o cliente repete o /instavel)');
    WriteLn('http://localhost:8000/health/ready   e  /metrics');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Stop;
  finally
    vOperacao.Free;
    vServer.Free;
  end;
end.
