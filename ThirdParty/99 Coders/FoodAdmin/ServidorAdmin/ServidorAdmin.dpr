program ServidorAdmin;

uses
  System.StartUpCopy,
  FMX.Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  Controllers.Usuario in 'Controllers\Controllers.Usuario.pas',
  DataModule.Global in 'DataModules\DataModule.Global.pas' {DmGlobal: TDataModule},
  Controllers.Pedido in 'Controllers\Controllers.Pedido.pas',
  Controllers.Categoria in 'Controllers\Controllers.Categoria.pas',
  Controllers.Produto in 'Controllers\Controllers.Produto.pas',
  Controllers.Config in 'Controllers\Controllers.Config.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
