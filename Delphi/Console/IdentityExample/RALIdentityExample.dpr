program RALIdentityExample;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  RALServer, RALIndyServer, RALIndyClient,
  Identidade.Exemplo in 'Identidade.Exemplo.pas';

var
  vServer: TRALServer;
  vExemplo: TIdentidadeExemplo;
begin
  vServer := TRALIndyServer.Create(nil);
  vExemplo := TIdentidadeExemplo.Create;
  try
    vServer.Port := 8000;
    vExemplo.Montar(vServer);
    vServer.Start;
    WriteLn('Segundo fator da ana (leia como QR code no aplicativo autenticador):');
    WriteLn('  ', string(vExemplo.URIDaAna));
    WriteLn('  codigo agora: ', string(vExemplo.CodigoDaAna));
    WriteLn;
    WriteLn('curl -d "usuario=bia&senha=senha-da-bia" http://localhost:8000/gettoken');
    WriteLn('curl -d "usuario=ana&senha=senha-da-ana&codigo=<codigo>" http://localhost:8000/gettoken');
    WriteLn('curl -H "Authorization: Bearer <token>" http://localhost:8000/perfil');
    WriteLn('   /admin (so'' admin), /vendas (politica), POST /sair (revoga o token)');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Stop;
  finally
    vExemplo.Free;
    vServer.Free;
  end;
end.
