program Project1;

{$MODE Delphi}

uses
  Forms, pascalral, Interfaces,
  Unit1 in 'Unit1.pas' {Form1};

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
