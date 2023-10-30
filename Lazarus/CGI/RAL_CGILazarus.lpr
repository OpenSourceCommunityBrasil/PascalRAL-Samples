program RAL_CGILazarus;

{$mode objfpc}{$H+}

uses
  fpCGI, uCGIModule, pascalral, fphttpral, HTTPDefs, fphttp, RALCGIServer;

begin
  TRALCGI.SetModule(TCGIModule);
  TRALCGI.Initialize;
end.

