unit UnitPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  RALServer, RALSwaggerModule;

type
  TFrmPrincipal = class(TForm)
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FServer: TRALServer; // Objeto genérico para poder utilizar qualquer motor
    {
      O exemplo inicial do Héber não tem Swagger, foi adicionado aqui pra mostrar
      como é simples aplicar swagger no projeto
     }
    FSwagger: TRALSwaggerModule;
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.dfm}

uses
  // Lembre-se de modificar o uses se for trocar de motor do servidor
  RALIndyServer,
//  RALSynopseServer,
//  RALSaguiServer,
  Controllers.Usuario,
  Controllers.Produto,
  Controllers.FormaPagto,
  Controllers.Pedido;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
  // Escolha o motor do servidor aqui, o restante do código permanece o mesmo

  FServer := TRALIndyServer.Create(self);
//  FServer := TRALSynopseServer.Create(self);
//  FServer := TRALSaguiServer.Create(self);

  // para adicionar o básico do swagger em seu servidor, basta usar essas 2 linhas abaixo
  FSwagger := TRALSwaggerModule.Create(self);
  FSwagger.Server := FServer;

  // para aparecer o nome do servidor no swagger
  FServer.Name := 'ECommerce';
end;

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
{
  É uma boa prática parar o servidor antes de matá-lo para garantir que as threads
  sejam encerradas corretamente.
}
  FServer.Stop;
  FreeAndNil(FSwagger);
  FreeAndNil(FServer);
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
{
  Diferente do cavalim, o servidor RAL não é Singleton então é preciso informar
  qual objeto vai receber as rotas a serem criadas. O evento aqui tá sendo mantido
  para ficar semelhante com o exemplo inicial o Héber que fazia tudo no FormShow.
  Mas poderia fazer essa inicialização diretamente no FormCreate sem prejuízo.
}
  Controllers.Usuario.RegistrarRotas(FServer);
  Controllers.Produto.RegistrarRotas(FServer);
  Controllers.FormaPagto.RegistrarRotas(FServer);
  Controllers.Pedido.RegistrarRotas(FServer);
{
  A porta do servidor pode ser alterada a qualquer momento antes da inicialização,
  o .Start. Após inicializado não pode modificar a porta com o servidor ativo.
  Também está configurado aqui para manter semelhança com o código inicial, poderia
  ser feito no FormCreate sem prejuízo nenhum.
}
  FServer.Port := 9000;
  FServer.Start;
end;

end.
