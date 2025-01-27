program server_bridge;

uses
  Vcl.Forms,
  uprincipal in 'fontes\uprincipal.pas' {fprincipal},
  uglobal_vars in 'fontes\uglobal_vars.pas',
  udm in 'fontes\udm.pas' {dm: TDataModule},
  udm_rest in 'fontes\udm_rest.pas' {dm_rest: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.ShowMainForm := False;
  Application.Title := 'Server Bridge';
  Application.CreateForm(Tdm, dm);
  Application.CreateForm(Tfprincipal, fprincipal);
  Application.CreateForm(Tdm_rest, dm_rest);
  Application.Run;
end.
