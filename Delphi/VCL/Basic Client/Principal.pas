unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RALClient, Vcl.StdCtrls,
  RALTypes, RALIndyClient, RALAuthentication, RALCustomObjects;

type
  TfPrincipal = class(TForm)
    cliente: TRALIndyClient;
    Button1: TButton;
    basic: TRALClientBasicAuth;
    Button2: TButton;
    Button3: TButton;
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
  cliente.BaseURL := BASEURL + '\clientes';
  cliente.AddHeader('nome', 'fernando_teste');
  if cliente.Get = 200 then
    ShowMessage(cliente.ResponseText)
  else
    ShowMessage(IntToStr(cliente.ResponseCode) + ' ' + cliente.ResponseText);
end;

procedure TfPrincipal.Button2Click(Sender: TObject);
begin
  cliente.BaseURL := BASEURL + '\ping';
  if cliente.Get = 200 then
    ShowMessage(cliente.ResponseText)
  else
    ShowMessage(IntToStr(cliente.ResponseCode) + ' ' + cliente.ResponseText);
end;

procedure TfPrincipal.Button3Click(Sender: TObject);
var
  vAuth : TRALAuthClient;
begin
  vAuth := cliente.Authentication;
  cliente.Authentication := nil;
  cliente.BaseURL := BASEURL + '\test';
  if cliente.Get = 200 then
    ShowMessage(cliente.ResponseText)
  else
    ShowMessage(IntToStr(cliente.ResponseCode) + ' ' + cliente.ResponseText);

  cliente.Authentication := vAuth;
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  BASEURL := cliente.BaseURL;
end;

end.
