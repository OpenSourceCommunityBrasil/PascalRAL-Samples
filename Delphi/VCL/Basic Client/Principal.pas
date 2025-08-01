unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RALClient, Vcl.StdCtrls,
  RALTypes, RALIndyClient, RALAuthentication, RALCustomObjects, RALRequest,
  RALResponse;

type
  TfPrincipal = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    cliente: TRALClient;
    basic: TRALClientBasicAuth;
    Button4: TButton;
    lInfo: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
    BASEURL: string;
  public
    { Public declarations }
  end;

var
  fPrincipal: TfPrincipal;

implementation

{$R *.dfm}

procedure TfPrincipal.Button1Click(Sender: TObject);
var
  Response: TRALResponse;
  // this is needed by the client to provide the answer object
begin
  cliente.BASEURL.Text := BASEURL;
  cliente.Request.AddHeader('nome', 'fernando_teste');
  cliente.Get('/clientes', Response);
  try
    if Response.StatusCode = 200 then
      ShowMessage(Response.ResponseText)
    else
      ShowMessage(IntToStr(Response.StatusCode) + ' ' + Response.ResponseText);
  finally
    // RALClient will create an instance of RALResponse, but won't hook into it,
    // so we need to dispose it ourselves.
    Response.Free;
  end;
end;

procedure TfPrincipal.Button2Click(Sender: TObject);
var
  Response: TRALResponse;
begin
  cliente.BASEURL.Text := BASEURL;
  cliente.Get('/ping', Response);
  try
    if Response.StatusCode = 200 then
      ShowMessage(Response.ResponseText)
    else
      ShowMessage(IntToStr(Response.StatusCode) + ' ' + Response.ResponseText);
  finally
    Response.Free;
  end;
end;

procedure TfPrincipal.Button3Click(Sender: TObject);
var
  Response: TRALResponse;
begin
  cliente.BASEURL.Text := BASEURL;
  cliente.Get('/test', Response);
  try
    if Response.StatusCode = 200 then
      ShowMessage(Response.ResponseText)
    else
      ShowMessage(IntToStr(Response.StatusCode) + ' ' + Response.ResponseText);
  finally
    Response.Free;
  end;
end;

procedure TfPrincipal.Button4Click(Sender: TObject);
var
  Response: TRALResponse;
begin
  // we'll force an error here
  cliente.BASEURL.Text := BASEURL + '/test';

  // this would translate into: http://localhost:8000/test/test which doesn't exist
  // in the server, therefore it should answer a 404 error page
  cliente.Get('/test', Response);
  try
    if Response.StatusCode = 200 then
      ShowMessage(Response.ResponseText)
    else
      ShowMessage(IntToStr(Response.StatusCode) + ' ' + Response.ResponseText);
  finally
    Response.Free;
  end;
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  BASEURL := 'http://localhost:8000';
  lInfo.Visible := false;
end;

end.
