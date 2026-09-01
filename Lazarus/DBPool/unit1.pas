unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  RALSynopseServer, RALDBModule, RALDBZeos;

type

  { TForm1 }

  TForm1 = class(TForm)
    Memo1: TMemo;
    RALDBModule1: TRALDBModule;
    RALSynopseServer1: TRALSynopseServer;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Memo1.Visible := False;
  // your database
  RALDBModule1.Database := 'mydatabase';
  // your dbserver
  RALDBModule1.Hostname := '192.168.0.1';
  // password of the db user
  RALDBModule1.Password := '123456';
  // port of the dbserver
  RALDBModule1.Port := 0;
  // username of the db user
  RALDBModule1.Username := 'user';
  { library location of the .dll to connect with the db server. This field
    accepts relative paths and it'll automatically adjust to the full path.
    If your libraries are already installed in the system path, leave it blank
   }
  RALDBModule1.LibLocation := '..\lib\libpq.dll';


  RALSynopseServer1.Start;
end;

end.

