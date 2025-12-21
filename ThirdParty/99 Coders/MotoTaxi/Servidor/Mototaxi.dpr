program Mototaxi;

uses
  System.StartUpCopy,
  FMX.Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  Controllers.UsuarioMotorista in 'Controllers\Controllers.UsuarioMotorista.pas',
  Controllers.JWT in 'Controllers\Controllers.JWT.pas',
  DataModule.Global in 'DataModules\DataModule.Global.pas' {Dm: TDataModule},
  Controllers.Corrida in 'Controllers\Controllers.Corrida.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
