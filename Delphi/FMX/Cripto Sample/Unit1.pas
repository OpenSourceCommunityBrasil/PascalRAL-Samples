unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.StdCtrls, FMX.Layouts, FMX.Controls.Presentation,
  FMX.Edit,
  RALHashes;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    FlowLayout1: TFlowLayout;
    FlowLayoutBreak1: TFlowLayoutBreak;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Memo1: TMemo;
    Button6: TButton;
    FlowLayoutBreak2: TFlowLayoutBreak;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Label1: TLabel;
    FlowLayoutBreak3: TFlowLayoutBreak;
    FlowLayoutBreak4: TFlowLayoutBreak;
    Label2: TLabel;
    FlowLayoutBreak5: TFlowLayoutBreak;
    FlowLayoutBreak6: TFlowLayoutBreak;
    Button13: TButton;
    Label3: TLabel;
    FlowLayoutBreak7: TFlowLayoutBreak;
    Button14: TButton;
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
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

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
