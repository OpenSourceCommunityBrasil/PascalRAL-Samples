/// RALProxy: um balanceador no modelo do NGINX feito com o RAL 2.0
/// (RALModuleProxyPackage: TRALBalancer, TRALUpstream, TRALProxyConfig).
/// Le um arquivo de configuracao no subconjunto da sintaxe do NGINX, abre as
/// portas, grava o log de acesso (combined ou json) e recarrega a
/// configuracao sem cortar as conexoes abertas.
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/ralproxy
unit RALProxy.App;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  {$IFDEF UNIX}BaseUnix,{$ENDIF}
  {$ENDIF}
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  RALTypes, RALBalancer, RALProxyConfig;

type
  /// O programa: a configuracao em vigor, os logs e a recarga.
  TRALProxyApp = class
  private
    FAccessFile: TFileStream;
    FAccessFormat: string;
    FAccessName: string;
    FArquivo: string;
    FData: TDateTime;
    FHost: TRALProxyHost;
    FLock: TCriticalSection;

    function DataDoArquivo: TDateTime;
    procedure Acesso(Sender: TObject; const AEntry: TRALBalancerAccess);
    procedure AbreLogs(AConfig: TRALProxyConfig);
    procedure GravaPid(AConfig: TRALProxyConfig);
  public
    constructor Create(const AArquivo: string);
    destructor Destroy; override;

    { Le e confere a configuracao, sem abrir portas (o "nginx -t"); False com
      o erro, que traz arquivo, linha e coluna }
    function Testa(out AErro: string): boolean;
    /// Abre as portas da configuracao.
    procedure Inicia;
    { Le a configuracao de novo e a poe no lugar da que roda; as conexoes
      abertas seguem. Com erro, a que roda continua e o erro volta aqui }
    function Recarrega(out AErro: string): boolean;
    /// A configuracao mudou no disco desde a ultima leitura (para o Windows).
    function ArquivoMudou: boolean;
    /// Fecha tudo.
    procedure Para;
    /// Escreve no log de erros (error_log) ou na saida de erro.
    procedure Erro(const ATexto: string);

    /// O que roda.
    property Host: TRALProxyHost read FHost;
  end;

var
  { Ligada pelo sinal: SIGHUP pede a recarga, SIGTERM e SIGINT a saida (no
    Windows, Ctrl+C) }
  GRecarregar: boolean = False;
  GSair: boolean = False;

/// Liga os sinais (Linux) ou o Ctrl+C (Windows) as variaveis acima.
procedure InstalaSinais;

implementation

{$IFDEF FPC}{$IFDEF UNIX}
procedure Sinal(ASinal: cint); cdecl;
begin
  if ASinal = SIGHUP then
    GRecarregar := True
  else
    GSair := True;
end;
{$ENDIF}{$ENDIF}

{$IFDEF MSWINDOWS}
function CtrlC(ATipo: DWORD): BOOL; stdcall;
begin
  GSair := True;
  Result := True;
end;
{$ENDIF}

procedure InstalaSinais;
begin
  {$IFDEF FPC}{$IFDEF UNIX}
  fpSignal(SIGHUP, SignalHandler(@Sinal));
  fpSignal(SIGTERM, SignalHandler(@Sinal));
  fpSignal(SIGINT, SignalHandler(@Sinal));
  {$ENDIF}{$ENDIF}
  {$IFDEF MSWINDOWS}
  SetConsoleCtrlHandler(@CtrlC, True);
  {$ENDIF}
end;

{ TRALProxyApp }

constructor TRALProxyApp.Create(const AArquivo: string);
begin
  inherited Create;
  FArquivo := ExpandFileName(AArquivo);
  FLock := TCriticalSection.Create;
  FHost := TRALProxyHost.Create;
  FHost.OnAccess := Acesso;
end;

destructor TRALProxyApp.Destroy;
begin
  Para;
  FHost.Free;
  FAccessFile.Free;
  FLock.Free;
  inherited Destroy;
end;

function TRALProxyApp.DataDoArquivo: TDateTime;
begin
  if not FileAge(FArquivo, Result) then
    Result := 0;
end;

function TRALProxyApp.ArquivoMudou: boolean;
begin
  Result := DataDoArquivo <> FData;
end;

procedure TRALProxyApp.Erro(const ATexto: string);
var
  vLinha: string;
  vArquivo: TextFile;
  vNome: string;
begin
  vLinha := FormatDateTime('yyyy/mm/dd hh:nn:ss', Now) + ' [erro] ' + ATexto;
  vNome := '';
  if FHost.Config <> nil then
    vNome := FHost.Config.ErrorLog;
  if vNome = '' then
  begin
    WriteLn(ErrOutput, vLinha);
    Exit;
  end;
  FLock.Acquire;
  try
    AssignFile(vArquivo, vNome);
    try
      if FileExists(vNome) then
        Append(vArquivo)
      else
        Rewrite(vArquivo);
      WriteLn(vArquivo, vLinha);
      CloseFile(vArquivo);
    except
      WriteLn(ErrOutput, vLinha);
    end;
  finally
    FLock.Release;
  end;
end;

{ uma linha por pedido, na thread do balanceador: so' o arquivo sob a trava }
procedure TRALProxyApp.Acesso(Sender: TObject; const AEntry: TRALBalancerAccess);
var
  vLinha: RawByteString;
begin
  if FAccessFile = nil then
    Exit;
  vLinha := RawByteString(RALBalancerAccessLine(AEntry, FAccessFormat)) + #10;
  FLock.Acquire;
  try
    if FAccessFile <> nil then
      FAccessFile.WriteBuffer(Pointer(vLinha)^, Length(vLinha));
  finally
    FLock.Release;
  end;
end;

procedure TRALProxyApp.AbreLogs(AConfig: TRALProxyConfig);
var
  vNome: string;
begin
  vNome := AConfig.AccessLog;
  if (vNome <> '') and not ((vNome[1] = '/') or (vNome[1] = '\') or
     ((Length(vNome) > 1) and (vNome[2] = ':'))) then
    vNome := ExtractFilePath(FArquivo) + vNome;
  FLock.Acquire;
  try
    FAccessFormat := AConfig.AccessLogFormat;
    if vNome = FAccessName then
      Exit;
    FreeAndNil(FAccessFile);
    FAccessName := vNome;
    if vNome = '' then
      Exit;
    ForceDirectories(ExtractFilePath(vNome));
    if FileExists(vNome) then
    begin
      FAccessFile := TFileStream.Create(vNome, fmOpenWrite or fmShareDenyNone);
      FAccessFile.Seek(0, soEnd);
    end
    else
      FAccessFile := TFileStream.Create(vNome, fmCreate or fmShareDenyNone);
  finally
    FLock.Release;
  end;
end;

procedure TRALProxyApp.GravaPid(AConfig: TRALProxyConfig);
var
  vLista: TStringList;
begin
  if AConfig.PidFile = '' then
    Exit;
  vLista := TStringList.Create;
  try
    {$IFDEF FPC}
    vLista.Text := IntToStr(GetProcessID);
    {$ELSE}
    vLista.Text := IntToStr(GetCurrentProcessId);
    {$ENDIF}
    vLista.SaveToFile(AConfig.PidFile);
  finally
    vLista.Free;
  end;
end;

function TRALProxyApp.Testa(out AErro: string): boolean;
var
  vConfig: TRALProxyConfig;
begin
  AErro := '';
  vConfig := TRALProxyConfig.Create;
  try
    try
      vConfig.LoadFromFile(FArquivo);
      Result := True;
    except
      on E: Exception do
      begin
        AErro := E.Message;
        Result := False;
      end;
    end;
  finally
    vConfig.Free;
  end;
end;

procedure TRALProxyApp.Inicia;
var
  vConfig: TRALProxyConfig;
begin
  FData := DataDoArquivo;
  vConfig := TRALProxyConfig.Create;
  try
    vConfig.LoadFromFile(FArquivo);
  except
    vConfig.Free;
    raise;
  end;
  AbreLogs(vConfig);
  GravaPid(vConfig);
  FHost.Start(vConfig); // o host fica com a configuracao
end;

function TRALProxyApp.Recarrega(out AErro: string): boolean;
var
  vConfig: TRALProxyConfig;
begin
  AErro := '';
  FData := DataDoArquivo;
  vConfig := TRALProxyConfig.Create;
  try
    vConfig.LoadFromFile(FArquivo);
  except
    on E: Exception do
    begin
      vConfig.Free;
      AErro := E.Message;
      Result := False;
      Exit;
    end;
  end;
  try
    FHost.Reload(vConfig);
    AbreLogs(vConfig);
    Result := True;
  except
    on E: Exception do
    begin
      // o Reload que falha ao abrir uma porta nova nao fica com a configuracao
      if FHost.Config <> vConfig then
        vConfig.Free;
      AErro := E.Message;
      Result := False;
    end;
  end;
end;

procedure TRALProxyApp.Para;
begin
  FHost.Stop;
end;

end.
