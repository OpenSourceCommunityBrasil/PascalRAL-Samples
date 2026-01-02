program ServidorFood;

uses
  System.StartUpCopy,
  FMX.Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  Controllers.Cardapio in 'Controllers\Controllers.Cardapio.pas',
  Controllers.Pedido in 'Controllers\Controllers.Pedido.pas',
  Controllers.Config in 'Controllers\Controllers.Config.pas',
  DataModule.Global in 'DataModules\DataModule.Global.pas' {Dm: TDataModule},
  Controllers.Usuario in 'Controllers\Controllers.Usuario.pas',
  uFunctions in 'Units\uFunctions.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
