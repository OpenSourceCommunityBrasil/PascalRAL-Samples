program LiveBindingsFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  Principal in 'Principal.pas' {fPrincipal};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfPrincipal, fPrincipal);
  Application.Run;
end.
