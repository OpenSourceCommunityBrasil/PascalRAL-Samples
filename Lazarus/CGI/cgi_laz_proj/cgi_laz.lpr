program cgi_laz;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, pascalral, cgiral, udm
  { you can add units after this };

var
  vDM : Tdm;

begin
  vDM := Tdm.Create(nil);
  vDM.Free;
end.

