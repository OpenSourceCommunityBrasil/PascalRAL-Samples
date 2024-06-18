unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RALClient, Vcl.StdCtrls,
  RALTypes, RALIndyClient, RALAuthentication, RALCustomObjects;

type
  TfPrincipal = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    cliente: TRALIndyClient;
    basic: TRALClientBasicAuth;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
begin
  cliente.BaseURL.Text := BASEURL + '/clientes';
  cliente.Request.AddHeader('nome', 'fernando_teste');
  cliente.Get;
  if cliente.Response.StatusCode = 200 then
    ShowMessage(cliente.ResponseText)
  else
    ShowMessage(IntToStr(cliente.Response.StatusCode) + ' ' + cliente.ResponseText);
end;

procedure TfPrincipal.Button2Click(Sender: TObject);
begin
  cliente.BaseURL.Text := BASEURL + '/ping';
  cliente.Get;
  if cliente.Response.StatusCode = 200 then
    ShowMessage(cliente.ResponseText)
  else
    ShowMessage(IntToStr(cliente.Response.StatusCode) + ' ' + cliente.ResponseText);
end;

procedure TfPrincipal.Button3Click(Sender: TObject);
var
  vAuth : TRALAuthClient;
begin
  vAuth := cliente.Authentication;
  cliente.Authentication := nil;
  cliente.BaseURL.Text := BASEURL + '/test';
  cliente.Get;
  if cliente.Response.StatusCode = 200 then
    ShowMessage(cliente.ResponseText)
  else
    ShowMessage(IntToStr(cliente.Response.StatusCode) + ' ' + cliente.ResponseText);

  cliente.Authentication := vAuth;
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  BASEURL := 'http://localhost:8000';
end;

end.
