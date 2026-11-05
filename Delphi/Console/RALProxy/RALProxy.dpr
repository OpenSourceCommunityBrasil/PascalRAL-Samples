/// RALProxy no console: um balanceador no modelo do NGINX feito com o RAL 2.0.
///
///   ralproxy [-c ralproxy.conf] [-t]
///
/// -c  o arquivo de configuracao (padrao: ralproxy.conf ao lado do programa)
/// -t  so' confere a configuracao e sai (como "nginx -t")
///
/// Recarga sem cortar conexoes: no Linux, kill -HUP <pid>; no Windows, salvar
/// o arquivo (ele e' olhado a cada 2 segundos). Ctrl+C (ou SIGTERM) termina.
program RALProxy;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF FPC}{$IFDEF UNIX}cthreads,{$ENDIF}{$ENDIF}
  SysUtils,
  RALProxy.App in 'RALProxy.App.pas';

var
  vApp: TRALProxyApp;
  vArquivo, vErro: string;
  vSoTestar: boolean;
  vI, vEspera: Integer;
begin
  vArquivo := ExtractFilePath(ParamStr(0)) + 'ralproxy.conf';
  vSoTestar := False;
  vI := 1;
  while vI <= ParamCount do
  begin
    if (ParamStr(vI) = '-c') and (vI < ParamCount) then
    begin
      Inc(vI);
      vArquivo := ParamStr(vI);
    end
    else if ParamStr(vI) = '-t' then
      vSoTestar := True
    else
    begin
      WriteLn('uso: ralproxy [-c arquivo.conf] [-t]');
      Halt(2);
    end;
    Inc(vI);
  end;

  vApp := TRALProxyApp.Create(vArquivo);
  try
    if vSoTestar then
    begin
      if vApp.Testa(vErro) then
      begin
        WriteLn('ralproxy: a configuracao ', vArquivo, ' esta'' certa');
        Halt(0);
      end;
      WriteLn('ralproxy: ', vErro);
      Halt(1);
    end;

    try
      vApp.Inicia;
    except
      on E: Exception do
      begin
        vApp.Erro(E.Message);
        Halt(1);
      end;
    end;
    WriteLn('ralproxy: rodando com ', vArquivo, ' (', vApp.Host.Balancers.Count, ' porta(s))');
    InstalaSinais;

    vEspera := 0;
    while not GSair do
    begin
      Sleep(200);
      Inc(vEspera);
      { SIGHUP no Linux; no Windows (e onde o sinal nao chega) o arquivo salvo
        de novo, olhado a cada 2 segundos }
      if (vEspera mod 10 = 0) and vApp.ArquivoMudou then
        GRecarregar := True;
      if GRecarregar then
      begin
        GRecarregar := False;
        if vApp.Recarrega(vErro) then
          WriteLn('ralproxy: configuracao recarregada (', vApp.Host.Balancers.Count, ' porta(s))')
        else
          vApp.Erro('recarga recusada, a configuracao anterior continua: ' + vErro);
      end;
    end;
    WriteLn('ralproxy: terminando');
    vApp.Para;
  finally
    vApp.Free;
  end;
end.
