unit UnitPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,

  // servidor genérico
  RALServer
  ;

type
  TFrmPrincipal = class(TForm)
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FServer: TRALServer; // Objeto genérico para funcionar com qualquer motor
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.fmx}

uses
  // Lembre-se de modificar o uses para o motor que for usar no RAL
//  RALIndyServer,
  RALSynopseServer,
//  RALSaguiServer,
     Controllers.UsuarioMotorista,
     Controllers.Corrida;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
{
   Troque o motor aqui e lembre-se de ajustar o Uses, o restante do código é o
   mesmo, não precisa mudar. :)
}
//  FServer := TRALIndyServer.Create(self);
  FServer := TRALSynopseServer.Create(self);
//  FServer := TRALSaguiServer.Create(self);

end;

procedure TFrmPrincipal.FormDestroy(Sender: TObject);
begin
{
  Boa prática sempre encerrar (Stop) o servidor na finalização antes de matar a
  instância do objeto, para garantir o fechamento correto das threads que possam
  estar em execução
}
  FServer.Stop;
  FreeAndNil(FServer);
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
{
  Mantido no FormShow para semelhança com o código original do Héber, essas funções
  poderiam ser executadas no FormCreate sem prejuizo nenhum de funcionalidade
}
  Controllers.UsuarioMotorista.RegistrarRotas(FServer);
  Controllers.Corrida.RegistrarRotas(FServer);
  FServer.Port := 9000; // mantida a mesma porta do exemplo original
  FServer.Start;
end;

end.
