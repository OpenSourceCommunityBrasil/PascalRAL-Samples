unit UnitPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,

  RALServer;

type
  TFrmPrincipal = class(TForm)
    Image1: TImage;
    Label1: TLabel;
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
{
  Escolha o uses do motor que for usar
}
  RALSynopseServer,
//  RALIndyServer,
//  RALSaguiServer,
  Controllers.Usuario, Controllers.Pedido, Controllers.Categoria,
  Controllers.Produto, Controllers.Config;


procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
{
  Faça o construtor de acordo com o motor que for usar
}
//  FServer := TRALIndyServer.Create(nil);
  FServer := TRALSynopseServer.Create(nil);
//  FServer := TRALSaguiServer.Create(nil);
end;

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
{
  É uma boa prática sempre parar o servidor antes de destruir pra garantir que
  as threads fechem corretamente
}
  FServer.Stop;
  FreeAndNil(FServer);
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
{
  Configuração de servidor feita aqui no FormShow pra manter compatibilidade com
  o exemplo original, poderia normalmente realizar a configuração e início no
  FormCreate sem problema.
}

  Controllers.Usuario.RegistrarRotas(FServer);
  Controllers.Pedido.RegistrarRotas(FServer);
  Controllers.Categoria.RegistrarRotas(FServer);
  Controllers.Produto.RegistrarRotas(FServer);
  Controllers.Config.RegistrarRotas(FServer);

  FServer.Port := 3003;
  FServer.start;
end;

end.
