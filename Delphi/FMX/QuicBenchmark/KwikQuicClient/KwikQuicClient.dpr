program KwikQuicClient;

uses
  System.StartUpCopy,
  FMX.Forms,
  UClienteKwik in 'UClienteKwik.pas' {fClienteKwik};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfClienteKwik, fClienteKwik);
  Application.Run;
end.
