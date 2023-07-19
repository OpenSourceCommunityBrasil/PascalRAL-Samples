unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RALClient, Vcl.StdCtrls,
  RALTypes, RALIndyClient;

type
  TfPrincipal = class(TForm)
    cliente: TRALIndyClient;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fPrincipal: TfPrincipal;

implementation

{$R *.dfm}

procedure TfPrincipal.Button1Click(Sender: TObject);
var
  head: TStringList;
begin
  head := TStringList.Create;
  head.Add('nome=fernando_teste');
  if cliente.Get('clientes', head) = 200 then
    ShowMessage(cliente.ResponseText)
  else
  begin
    ShowMessage(IntToStr(cliente.ResponseCode) + ' ' + cliente.ResponseText);
  end;
  head.Free;
end;

end.
