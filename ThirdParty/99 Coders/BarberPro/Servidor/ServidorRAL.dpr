program ServidorRAL;

uses
  Vcl.Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  DataModule.Global in 'DataModule.Global.pas' {DmGlobal: TDataModule},
  Controllers.Usuario in 'Controllers\Controllers.Usuario.pas',
  Controllers.Servico in 'Controllers\Controllers.Servico.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
