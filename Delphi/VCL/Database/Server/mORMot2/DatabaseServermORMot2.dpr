// by PascalRAL - StandAlone App: 10/09/2024 19:41:40
program DatabaseServermORMot2;

uses
  Forms,
  Unit1 in 'Unit1.pas' {RALForm1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TRALForm1, RALForm1);
  Application.Run;
end.
