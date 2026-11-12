program RALJobQueueExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, SyncObjs,
  RALJobStore, RALJobQueue;

// Fila de jobs persistente (TRALJobQueue). Cada job vira um arquivo na pasta
// "jobs"; se o processo cair ou for encerrado, basta criar a fila de novo sobre
// a mesma pasta e os jobs pendentes (e as tentativas ja feitas) continuam la.

type
  TExemplo = class
  private
    FFila: TRALJobQueue;
    FLock: TCriticalSection;
    // Os eventos rodam nas threads de trabalho: toda saida passa por aqui.
    procedure Log(const ATexto: string);
    procedure Email(Sender: TObject; AJob: TRALJob);
    procedure Instavel(Sender: TObject; AJob: TRALJob);
    procedure Limite(Sender: TObject; AJob: TRALJob);
    procedure Permanente(Sender: TObject; AJob: TRALJob);
    procedure Feito(Sender: TObject; AJob: TRALJob);
    procedure Falhou(Sender: TObject; AJob: TRALJob; AWillRetry: Boolean);
    procedure Morto(Sender: TObject; AJob: TRALJob);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Executar;
  end;

constructor TExemplo.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FFila := TRALJobQueue.Create(nil);
  FFila.Folder := ExtractFilePath(ParamStr(0)) + 'jobs';
  FFila.Workers := 2;
  FFila.MaxAttempts := 4;
  FFila.RetryDelay := 500;
  FFila.PollInterval := 200;
  FFila.Handlers.AddHandler('email', Email);
  FFila.Handlers.AddHandler('instavel', Instavel);
  FFila.Handlers.AddHandler('limite', Limite);
  FFila.Handlers.AddHandler('permanente', Permanente);
  FFila.OnJobDone := Feito;
  FFila.OnJobFailed := Falhou;
  FFila.OnJobDead := Morto;
end;

destructor TExemplo.Destroy;
begin
  FFila.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TExemplo.Log(const ATexto: string);
begin
  FLock.Enter;
  try
    WriteLn(ATexto);
    Flush(Output);
  finally
    FLock.Leave;
  end;
end;

procedure TExemplo.Email(Sender: TObject; AJob: TRALJob);
begin
  Log('[email] enviando para ' + string(AJob.Payload));
end;

procedure TExemplo.Instavel(Sender: TObject; AJob: TRALJob);
begin
  // Falha nas tentativas 1 e 2 (a excecao agenda a nova tentativa) e passa na 3.
  Log('[instavel] tentativa ' + IntToStr(AJob.Attempts));
  if AJob.Attempts < 3 then
    raise Exception.Create('servidor indisponivel');
end;

procedure TExemplo.Limite(Sender: TObject; AJob: TRALJob);
begin
  // O destino pediu para esperar: reagenda em 1 s sem tratar como erro comum.
  Log('[limite] tentativa ' + IntToStr(AJob.Attempts));
  if AJob.Attempts = 1 then
    AJob.RetryAfter(1000, '429');
end;

procedure TExemplo.Permanente(Sender: TObject; AJob: TRALJob);
begin
  // Erro sem conserto: vai direto para os jobs mortos, sem novas tentativas.
  Log('[permanente] tentativa ' + IntToStr(AJob.Attempts));
  AJob.GiveUp('550 caixa inexistente');
end;

procedure TExemplo.Feito(Sender: TObject; AJob: TRALJob);
begin
  Log('  -> concluido: ' + string(AJob.Name) + ' ' + string(AJob.Id) +
    ' (tentativas: ' + IntToStr(AJob.Attempts) + ')');
end;

procedure TExemplo.Falhou(Sender: TObject; AJob: TRALJob; AWillRetry: Boolean);
var
  vTexto: string;
begin
  if AWillRetry then
    vTexto := 'vai repetir'
  else
    vTexto := 'nao vai repetir';
  Log('  -> falhou: ' + string(AJob.Name) + ' (' + vTexto + '), erro "' +
    string(AJob.LastError) + '", proxima em ' +
    IntToStr(AJob.Due - FFila.JobStore.Current) + ' ms');
end;

procedure TExemplo.Morto(Sender: TObject; AJob: TRALJob);
begin
  Log('  -> morto: ' + string(AJob.Name) + ' ' + string(AJob.Id));
end;

procedure TExemplo.Executar;
var
  vIds: TStringList;
  vJob: TRALJob;
  vI, vEsperado: Integer;
begin
  // Enfileirar funciona com a fila parada: os jobs ficam esperando.
  FFila.Enqueue('email', 'ana@exemplo.com');
  FFila.Enqueue('email', 'bia@exemplo.com');
  FFila.Enqueue('email', 'caio@exemplo.com');
  FFila.Enqueue('instavel', '');
  FFila.Enqueue('limite', '');
  FFila.Enqueue('permanente', '');
  FFila.Enqueue('email', 'atrasado-2s@exemplo.com', 2000);
  FFila.EnqueueAt('email', 'agendado-3s@exemplo.com', Now + 3 / 86400);

  Log('Iniciando a fila com 2 trabalhadores...');
  FFila.Active := True;

  // Espera esvaziar (prontos + em execucao) por no maximo 20 s.
  vEsperado := 0;
  while vEsperado < 200 do
  begin
    if (FFila.Count(jsReady) + FFila.Count(jsLeased) = 0) and
       (FFila.RunningCount = 0) then
      Break;
    Sleep(100);
    Inc(vEsperado);
  end;

  FLock.Enter;
  try
    WriteLn('Fila vazia. Jobs mortos: ', FFila.Count(jsDead));
    vIds := TStringList.Create;
    vJob := TRALJob.Create;
    try
      FFila.List(jsDead, vIds);
      for vI := 0 to vIds.Count - 1 do
        if FFila.ReadJob(vIds[vI], vJob) then
          WriteLn('  ', string(vJob.Name), ' ', vIds[vI], ': "',
            string(vJob.LastError), '" apos ', vJob.Attempts, ' tentativa(s)');
    finally
      vJob.Free;
      vIds.Free;
    end;
  finally
    FLock.Leave;
  end;

  // Para reprocessar um morto seria Requeue(Id) / RequeueAll; aqui so limpamos.
  FFila.PurgeDead;
  FFila.Active := False;
end;

var
  Exemplo: TExemplo;
begin
  Exemplo := TExemplo.Create;
  try
    Exemplo.Executar;
  finally
    Exemplo.Free;
  end;
end.
