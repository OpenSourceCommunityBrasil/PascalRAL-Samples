unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RALSynopseServer, RALfpHTTPServer, RALAuthentication,
  Forms, Controls, Graphics, Dialogs, StdCtrls, RALRoutes, RALResponse,
  RALRequest;

type

  { TForm1 }

  TForm1 = class(TForm)
    RALfpHttpServer1: TRALfpHttpServer;
    RALServerBasicAuth1: TRALServerBasicAuth;
    ToggleBox1: TToggleBox;
    procedure RALfpHttpServer1_fileReply(ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure RALfpHttpServer1_pingReply(ARequest: TRALRequest;
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

procedure TForm1.RALfpHttpServer1_pingReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'pong');
end;

procedure TForm1.ToggleBox1Change(Sender: TObject);
begin
  RALfpHttpServer1.Active := ToggleBox1.Checked;
end;

procedure TForm1.RALfpHttpServer1_fileReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(ExtractFilePath(ParamStr(0)) + '\Banner.png');
end;

end.

