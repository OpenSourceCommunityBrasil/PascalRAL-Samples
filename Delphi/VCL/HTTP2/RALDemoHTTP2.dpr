program RALDemoHTTP2;

uses
  Vcl.Forms,
  Principal in 'Principal.pas' {fPrincipal},
  UDemoRelay in 'UDemoRelay.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfPrincipal, fPrincipal);
  Application.Run;
end.
