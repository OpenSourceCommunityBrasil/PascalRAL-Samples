unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, RALSynopseServer, RALAuthentication, Forms, Controls,
  Graphics, Dialogs, StdCtrls, RALRoutes, RALResponse, RALRequest;

type

  { TForm1 }

  TForm1 = class(TForm)
    RALServerBasicAuth1: TRALServerBasicAuth;
    RALSynopseServer1: TRALSynopseServer;
    ToggleBox1: TToggleBox;
    procedure RALSynopseServer1_fileReply(ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure RALSynopseServer1_pingReply(ARequest: TRALRequest;
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

procedure TForm1.RALSynopseServer1_pingReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'pong');
end;

procedure TForm1.ToggleBox1Change(Sender: TObject);
begin
  RALSynopseServer1.Active := ToggleBox1.Checked;
end;

procedure TForm1.RALSynopseServer1_fileReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(ExtractFilePath(ParamStr(0)) + '\Banner.png');
end;

end.

