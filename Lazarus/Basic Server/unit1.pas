unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RALfpHTTPServer, RALAuthentication,
  Forms, Controls, Graphics, Dialogs, StdCtrls, RALResponse,
  RALRequest, RALRoutes;

type

  { TForm1 }

  TForm1 = class(TForm)
    RALServerBasicAuth1: TRALServerBasicAuth;
    server: TRALfpHttpServer;
    ToggleBox1: TToggleBox;
    procedure FileReply(ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure PingReply(ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure ToggleBox1Change(Sender: TObject);
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

procedure TForm1.FileReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(ExtractFilePath(ParamStr(0)) + '\Banner.png');
end;

end.

