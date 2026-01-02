program ServidorPoupei;

uses
  System.StartUpCopy,
  FMX.Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  Controllers.Usuario in 'Controllers\Controllers.Usuario.pas',
  Controllers.Categoria in 'Controllers\Controllers.Categoria.pas',
  Services.Categoria in 'Services\Services.Categoria.pas',
  Dm.Global in 'Repositories\Dm.Global.pas' {DmGlobal: TDataModule},
  Controllers.JWT in 'Controllers\Controllers.JWT.pas',
  Services.Usuario in 'Services\Services.Usuario.pas',
  uMD5 in 'Utils\uMD5.pas',
  Controllers.Lancamento in 'Controllers\Controllers.Lancamento.pas',
  Services.Lancamento in 'Services\Services.Lancamento.pas',
  Controllers.Stripe in 'Controllers\Controllers.Stripe.pas',
  uStripe in 'Utils\uStripe.pas',
  Services.Stripe in 'Services\Services.Stripe.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
