unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RALSynopseServer, RALAuthentication,
  Forms, Controls, Graphics, Dialogs, StdCtrls, RALResponse,
  RALRequest, RALConsts, RALTypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    RALServerBasicAuth1: TRALServerBasicAuth;
    server: TRALSynopseServer;
    ToggleBox1: TToggleBox;
    procedure FileReply(ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure FormCreate(Sender: TObject);
    procedure PingReply(ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure ToggleBox1Change(Sender: TObject);
    procedure Reply(ARequest: TRALRequest; AResponse: TRALResponse);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.PingReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'pong');
end;

procedure TForm1.ToggleBox1Change(Sender: TObject);
begin
  server.Active := ToggleBox1.Checked;
end;

procedure TForm1.Reply(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, ARequest.ParamByName('pdf').AsString);
end;

procedure TForm1.FileReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(ExtractFilePath(ParamStr(0)) + '\Banner.png');
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  server.CreateRoute('file', @FileReply);
  server.CreateRoute('ping', @PingReply);
  server.CreateRoute('reply', @Reply);
end;

end.

