program RAL_CGIDelphi;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  RALCGIServer,
  uCGIModule in 'uCGIModule.pas' {CGIModule: TWebModule};

begin
  TRALCGI.SetModule(TCGIModule);
  TRALCGI.Initialize;

end.
