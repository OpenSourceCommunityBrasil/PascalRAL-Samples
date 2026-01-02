unit UnitPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,

  RALServer;

type
  TFrmPrincipal = class(TForm)
    Image1: TImage;
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
  RALSynopseServer,
//  RALIndyServer,
//  RALSaguiServer,
 Controllers.Cardapio, Controllers.Pedido, Controllers.Config, Controllers.Usuario;


procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
//  FServer := TRALIndyServer.Create(nil);
  FServer := TRALSynopseServer.Create(nil);
//  FServer := TRALSaguiServer.Create(nil);
end;

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FServer);
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
  Controllers.Cardapio.RegistrarRotas(FServer);
  Controllers.Pedido.RegistrarRotas(FServer);
  Controllers.Config.RegistrarRotas(FServer);
  Controllers.Usuario.RegistrarRotas(FServer);

  FServer.Port := 3002;
  FServer.Start;
end;

end.
