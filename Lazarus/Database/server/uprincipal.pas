unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, RALIndyServer,
  RALDBModule, RALDBStorageBIN, RALDBBufDataset, RALSwaggerModule, BufDataset,
  DB, RALDBZeos, RALParams;

type

  { TForm1 }

  TForm1 = class(TForm)
    dbmodule: TRALDBModule;
    dbzeos: TRALDBZeosLink;
    swagger: TRALSwaggerModule;
    storage_bin: TRALDBStorageBINLink;
    server: TRALIndyServer;
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
  server.Start;
end;

end.

