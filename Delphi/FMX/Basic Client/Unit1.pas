unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  RALRequest, RALResponse, RALCustomObjects, RALClient, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, RALSynopseClient,
  RALIndyClient;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Button1: TButton;
    Memo1: TMemo;
    RALClient1: TRALClient;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
var
  AResp: TRALResponse;
begin
  Memo1.Lines.Clear;
  RALClient1.Get(Edit1.Text, AResp);

  Memo1.Lines.Append('StatusCode: ' + AResp.StatusCode.ToString);
  Memo1.Lines.Append(AResp.ResponseText);
  AResp.Free;
end;

end.
