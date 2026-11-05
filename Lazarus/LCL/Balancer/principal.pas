/// O TRALBalancer na tela (RAL 2.0, RALModuleProxyPackage): o balanceador e o
/// grupo de servidores (TRALUpstream) estao no formulario, configurados no
/// Object Inspector; dois servidores RAL de tras sobem junto, e o log de
/// acesso de cada pedido aparece na tela.
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/balanceador
unit Principal;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, SysUtils, SyncObjs, Forms, Controls, StdCtrls, ExtCtrls, Dialogs,
  RALfpHTTPServer,
  {$ELSE}
  System.Classes, System.SysUtils, System.SyncObjs, Vcl.Forms, Vcl.Controls,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs,
  RALIndyServer,
  {$ENDIF}
  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse,
  RALProxyCore, RALBalancer;

type
  { TfPrincipal }
  TfPrincipal = class(TForm)
    Balancer1: TRALBalancer;
    Upstream1: TRALUpstream;
    Timer1: TTimer;
    pnlTopo: TPanel;
    btnIniciar: TButton;
    btnParar: TButton;
    btnTestar: TButton;
    lInfo: TLabel;
    mLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure btnPararClick(Sender: TObject);
    procedure btnTestarClick(Sender: TObject);
    procedure Balancer1Access(Sender: TObject; const AEntry: TRALBalancerAccess);
    procedure Timer1Timer(Sender: TObject);
  private
    FTrasA: TRALServer;
    FTrasB: TRALServer;
    FFila: TStringList;
    FTrava: TCriticalSection;
    procedure QuemA(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure QuemB(ARequest: TRALRequest; AResponse: TRALResponse);
    function NovoServidor(APorta: Integer): TRALServer;
  end;

var
  fPrincipal: TfPrincipal;

implementation

{$IFDEF FPC}
{$R *.lfm}
{$ELSE}
{$R *.dfm}
{$ENDIF}

function TfPrincipal.NovoServidor(APorta: Integer): TRALServer;
begin
  Result := {$IFDEF FPC}TRALfpHttpServer{$ELSE}TRALIndyServer{$ENDIF}.Create(Self);
  Result.Port := APorta;
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  FFila := TStringList.Create;
  FTrava := TCriticalSection.Create;
  // os dois servidores que o Upstream1 lista (8101 e 8102)
  FTrasA := NovoServidor(8101);
  FTrasA.CreateRoute('quem', QuemA);
  FTrasB := NovoServidor(8102);
  FTrasB.CreateRoute('quem', QuemB);
  FTrasA.Active := True;
  FTrasB.Active := True;
  lInfo.Caption := 'http://localhost:' + IntToStr(Balancer1.Port) + '/quem   (A e B se alternam)' +
    '   http://localhost:' + IntToStr(Balancer1.Port) + string(Balancer1.StatsPath);
end;

procedure TfPrincipal.FormDestroy(Sender: TObject);
begin
  Balancer1.Active := False;
  FTrasA.Active := False;
  FTrasB.Active := False;
  FFila.Free;
  FTrava.Free;
end;

procedure TfPrincipal.QuemA(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'servidor A, para ' + ARequest.GetHeader('X-Forwarded-For'), rctTEXTPLAIN);
end;

procedure TfPrincipal.QuemB(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'servidor B, para ' + ARequest.GetHeader('X-Forwarded-For'), rctTEXTPLAIN);
end;

procedure TfPrincipal.btnIniciarClick(Sender: TObject);
begin
  Balancer1.Active := True;
  mLog.Lines.Add('balanceador na porta ' + IntToStr(Balancer1.Port));
end;

procedure TfPrincipal.btnPararClick(Sender: TObject);
begin
  Balancer1.Active := False;
  mLog.Lines.Add('balanceador parado');
end;

procedure TfPrincipal.btnTestarClick(Sender: TObject);
var
  vRelatorio: StringRAL;
begin
  // o mesmo que o verbo "Testar servidores" do Upstream1 na IDE
  Upstream1.TestServers(vRelatorio);
  ShowMessage(string(vRelatorio));
end;

{ numa thread do balanceador: a linha so' entra na fila; o timer a leva a tela }
procedure TfPrincipal.Balancer1Access(Sender: TObject; const AEntry: TRALBalancerAccess);
begin
  FTrava.Acquire;
  try
    FFila.Add(string(RALBalancerAccessLine(AEntry)) + '  -> ' + string(AEntry.Server));
  finally
    FTrava.Release;
  end;
end;

procedure TfPrincipal.Timer1Timer(Sender: TObject);
begin
  FTrava.Acquire;
  try
    if FFila.Count = 0 then
      Exit;
    mLog.Lines.AddStrings(FFila);
    FFila.Clear;
  finally
    FTrava.Release;
  end;
end;

end.
