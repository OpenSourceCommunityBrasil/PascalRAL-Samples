unit UnitPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  // Servidor genérico e autenticação
  RALServer, RALAuthentication;

type
  TFrmPrincipal = class(TForm)
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FServer: TRALServer; // Classe genérica para poder atribuir qualquer motor
    FBasicAuth: TRALServerBasicAuth; // Autenticação do servidor do tipo "Basic"
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.dfm}

uses
  // Lembre-se de trocar o Uses para o motor do servidor que for usar
//  RALIndyServer,
  RALSynopseServer,
//  RALSaguiServer,
  Controllers.Usuario,
  Controllers.Servico;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
{
   Troque o motor aqui e lembre-se de ajustar o Uses, o restante do código é o
   mesmo, não precisa mudar. :)
}
//  FServer := TRALIndyServer.Create(self);
  FServer := TRALSynopseServer.Create(self);
//  FServer := TRALSaguiServer.Create(self);

{
  Atribuição de autenticação ao servidor, como se trata de BasicAuthentication,
  você pode atribuir usuário e senha diretamente no método construtor. Esses valores
  podem vir de um arquivo .ini, ou um banco SQLite, ou uma unit de constantes, se
  preferir.
}
  FBasicAuth := TRALServerBasicAuth.Create(self, '99coders', '12345');
  FServer.Authentication := FBasicAuth;
end;

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
  // Boa prática sempre encerrar o servidor na finalização para garantir o fechamento
  // correto das threads que possam estar em execução
  FServer.Stop;
  FreeAndNil(FBasicAuth);
  FreeAndNil(FServer);
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
{
  Mantido no FormShow para semelhança com o código original do Héber, essas funções
  poderiam ser executadas no FormCreate sem prejuizo nenhum de funcionalidade
}
  Controllers.Usuario.RegistrarRotas(FServer);
  Controllers.Servico.RegistrarRotas(FServer);
  FServer.Port := 3001; // mantida a mesma porta do exemplo original
  FServer.Start;
end;

end.
