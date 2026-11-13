/// Uma conversa em etapas no Telegram (RAL 2.0, RALModuleChatPackage e
/// RALModuleChatTelegramPackage): o robo, o canal e o fluxo de tres etapas estao
/// no formulario, montados so no Object Inspector (veja o Steps do Flow1); o codigo
/// so liga, desliga e mostra o pedido que chegou ao fim.
/// O token vem da variavel de ambiente TELEGRAM_TOKEN (peca um ao @BotFather).
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/chatbot-fluxo
unit Principal;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, SysUtils, SyncObjs, Forms, Controls, StdCtrls, ExtCtrls,
  RALfpHTTPClient,
  {$ELSE}
  System.Classes, System.SysUtils, System.SyncObjs, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  RALnetHTTPClient,
  {$ENDIF}
  RALTypes, RALChatMessage, RALChatChannel, RALChatBot, RALChatFlow, RALChatTelegram;

type
  { TfPrincipal }
  TfPrincipal = class(TForm)
    Bot1: TRALChatBot;
    Telegram1: TRALChatTelegram;
    Flow1: TRALChatFlow;
    pnlTopo: TPanel;
    btnIniciar: TButton;
    btnParar: TButton;
    mLog: TMemo;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure btnPararClick(Sender: TObject);
    procedure Flow1Cancel(Sender: TObject; AContext: TRALChatFlowContext;
      AReason: TRALChatFlowStop);
    procedure Flow1Finish(Sender: TObject; AContext: TRALChatFlowContext);
    procedure Bot1Error(Sender: TObject; AChannel: TRALChatChannel; const AText: string);
  private
    FFila: TStringList;
    FTrava: TCriticalSection;
    /// Guarda uma linha para o memo: os eventos do robo chegam em outra thread.
    procedure Log(const AText: string);
  end;

var
  fPrincipal: TfPrincipal;

implementation

{$IFDEF FPC}
{$R *.lfm}
{$ELSE}
{$R *.dfm}
{$ENDIF}

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  FFila := TStringList.Create;
  FTrava := TCriticalSection.Create;
end;

procedure TfPrincipal.FormDestroy(Sender: TObject);
begin
  Telegram1.Active := False;
  Bot1.Stop;
  FTrava.Free;
  FFila.Free;
end;

procedure TfPrincipal.Log(const AText: string);
begin
  FTrava.Enter;
  try
    FFila.Add(AText);
  finally
    FTrava.Leave;
  end;
end;

procedure TfPrincipal.Timer1Timer(Sender: TObject);
begin
  FTrava.Enter;
  try
    if FFila.Count > 0 then
    begin
      mLog.Lines.AddStrings(FFila);
      FFila.Clear;
    end;
  finally
    FTrava.Leave;
  end;
end;

procedure TfPrincipal.btnIniciarClick(Sender: TObject);
var
  vReport: StringRAL;
begin
  if GetEnvironmentVariable('TELEGRAM_TOKEN') = '' then
  begin
    mLog.Lines.Add('Defina a variavel de ambiente TELEGRAM_TOKEN com o token do @BotFather.');
    Exit;
  end;
  if not Telegram1.TestToken(vReport) then
  begin
    mLog.Lines.Add('O Telegram recusou o token: ' + string(vReport));
    Exit;
  end;
  mLog.Lines.Add(string(vReport));
  Telegram1.Active := True;
  mLog.Lines.Add('Mande /pedido para o robo no Telegram.');
end;

procedure TfPrincipal.btnPararClick(Sender: TObject);
begin
  Telegram1.Active := False;
  mLog.Lines.Add('Parado.');
end;

procedure TfPrincipal.Flow1Finish(Sender: TObject; AContext: TRALChatFlowContext);
begin
  // as respostas ficam na sessao da conversa, com o nome de cada etapa
  Log(Format('Pedido de %s: %s pizza(s) de %s', [string(AContext.GetValue('nome')),
    string(AContext.GetValue('quantidade')), string(AContext.GetValue('sabor'))]));
end;

procedure TfPrincipal.Flow1Cancel(Sender: TObject; AContext: TRALChatFlowContext;
  AReason: TRALChatFlowStop);
begin
  Log('Conversa ' + string(AContext.ChatId) + ' encerrada antes do fim.');
end;

procedure TfPrincipal.Bot1Error(Sender: TObject; AChannel: TRALChatChannel;
  const AText: string);
begin
  Log('erro: ' + AText);
end;

end.
