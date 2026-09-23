program Http2Client;

uses
  Vcl.Forms,
  UCliente in 'UCliente.pas' {fCliente};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfCliente, fCliente);
  Application.Run;
end.
