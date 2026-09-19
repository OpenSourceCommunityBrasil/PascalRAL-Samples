unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, StdCtrls,
  RALfpHTTPServer, RALRequest, RALResponse, RALConsts, RALMIMETypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    server: TRALfpHttpServer;
    lblStatus: TLabel;
    ToggleBox1: TToggleBox;
    procedure FormCreate(Sender: TObject);
    procedure PingReply(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure ToggleBox1Change(Sender: TObject);
  private
    procedure UpdateStatus;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  server.CreateRoute('ping', @PingReply);
  UpdateStatus;
end;

procedure TForm1.PingReply(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  { rctTEXTPLAIN is not optional here: the two-argument Answer defaults the
    content type to rctAPPLICATIONJSON, so the body went out as 'pong' under
    Content-Type: application/json, which is not valid JSON. }
  AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
end;

procedure TForm1.ToggleBox1Change(Sender: TObject);
begin
  server.Active := ToggleBox1.Checked;
  UpdateStatus;
end;

procedure TForm1.UpdateStatus;
begin
  if server.Active then
  begin
    ToggleBox1.Caption := 'Desligar';
    lblStatus.Caption := 'ouvindo em http://localhost:' + IntToStr(server.Port) + '/ping';
  end
  else
  begin
    ToggleBox1.Caption := 'Ligar';
    lblStatus.Caption := 'parado';
  end;
end;

end.
