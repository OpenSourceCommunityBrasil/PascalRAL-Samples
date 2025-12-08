program ServidorRAL;

uses
  Vcl.Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  Controllers.Usuario in 'Controllers\Controllers.Usuario.pas',
  DataModule.Global in 'DataModules\DataModule.Global.pas' {Dm: TDataModule},
  uMD5 in 'Utils\uMD5.pas',
  Controllers.Produto in 'Controllers\Controllers.Produto.pas',
  Controllers.FormaPagto in 'Controllers\Controllers.FormaPagto.pas',
  Controllers.Pedido in 'Controllers\Controllers.Pedido.pas',
  uMercadoPago in 'Utils\uMercadoPago.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
