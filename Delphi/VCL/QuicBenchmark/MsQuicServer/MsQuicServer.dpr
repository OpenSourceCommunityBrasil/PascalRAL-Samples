program MsQuicServer;

uses
  Vcl.Forms,
  UServidor in 'UServidor.pas' {fServidor};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfServidor, fServidor);
  Application.Run;
end.
