unit UnitPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,

  RALServer
  ;

type
  TFrmPrincipal = class(TForm)
    Memo1: TMemo;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FServer: TRALServer;
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.fmx}

uses
//  RALIndyServer,
  RALSynopseServer,
//  RALSaguiServer,
     Controllers.Usuario,
     Controllers.Categoria,
     Controllers.Lancamento,
     Controllers.Stripe;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
//  FServer := TRALIndyServer.Create(nil);
  FServer := TRALSynopseServer.Create(nil);
//  FServer := TRALSaguiServer.Create(nil);
end;

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
  FServer.Stop;
  FServer.Free;
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
  Controllers.Usuario.RegistrarRotas(FServer);
  Controllers.Categoria.RegistrarRotas(FServer);
  Controllers.Lancamento.RegistrarRotas(FServer);
  Controllers.Stripe.RegistrarRotas(FServer);

  FServer.Port := 3001;
  FServer.Start;
end;

end.
