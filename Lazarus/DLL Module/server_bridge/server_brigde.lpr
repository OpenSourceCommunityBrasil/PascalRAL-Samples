program server_brigde;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, zcomponent, pascalral, synopseral, uprincipal, uglobal_vars, udm, 
  udm_rest
  { you can add units after this };

{$R *.res}

begin
  {$ifopt D+}
  SetHeapTraceOutput('server_bridge.trc');
    {$if declared(UseHeapTrace)}
    GlobalSkipIfNoLeaks := True; // supported as of debugger version 3.2.0
    {$endIf}
  {$ENDIF}
  RequireDerivedFormResource:=True;
  Application.Title := 'Server Bridge';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(Tdm, dm);
  Application.CreateForm(Tfprincipal, fprincipal);
  Application.Run;
end.

