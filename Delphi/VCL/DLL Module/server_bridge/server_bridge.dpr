program server_bridge;

uses
  Vcl.Forms,
  uprincipal in 'fontes\uprincipal.pas' {fprincipal};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(Tfprincipal, fprincipal);
  Application.Run;
end.
