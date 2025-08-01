unit Unit1;

interface

uses
  Windows, SysUtils, Variants, Classes,
  Graphics,
  Controls, Forms, Dialogs, StdCtrls,

  RALHashes, ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Memo1: TMemo;
    FlowPanel1: TFlowPanel;
    Edit1: TEdit;
    Edit2: TEdit;
    FlowPanel2: TFlowPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    FlowPanel3: TFlowPanel;
    FlowPanel4: TFlowPanel;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    FlowPanel5: TFlowPanel;
    Button13: TButton;
    Button14: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.Button10Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.Decrypt(Edit1.Text, Edit2.text, ctAES128);
end;

procedure TForm1.Button11Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.Decrypt(Edit1.text, Edit2.text, ctAES192);
end;

procedure TForm1.Button12Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.Decrypt(Edit1.text, Edit2.text, ctAES256);
end;

procedure TForm1.Button13Click(Sender: TObject);
begin
  Memo1.Text := TRALHashes.toBase64(Edit1.Text);
end;

procedure TForm1.Button14Click(Sender: TObject);
begin
  Memo1.Text := TRALHashes.fromBase64(Edit1.Text);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Memo1.Lines.DefaultEncoding := TEncoding.UTF8;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.GetHash(Edit1.text, Edit2.text, htSHA224);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.GetHash(Edit1.text, Edit2.text, htSHA256);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.GetHash(Edit1.text, Edit2.text, htSHA384);
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.GetHash(Edit1.text, Edit2.text, htSHA512);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.GetHash(Edit1.text, Edit2.text, htSHA512_224);
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Memo1.text := TRALHashes.GetHash(Edit1.text, Edit2.text, htSHA512_256);
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  Memo1.Text := TRALHashes.Encrypt(Edit1.Text, Edit2.Text, ctAES128);;
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  Memo1.Text := TRALHashes.Encrypt(Edit1.Text, Edit2.Text, ctAES192);
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
  Memo1.Text := TRALHashes.Encrypt(Edit1.Text, Edit2.Text, ctAES256);
end;

end.
