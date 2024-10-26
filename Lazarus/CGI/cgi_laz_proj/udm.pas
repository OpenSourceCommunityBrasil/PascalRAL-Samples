unit udm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  RALCGIServer, RALRequest, RALResponse;

type

  { Tdm }

  Tdm = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
  private
    FCGI : TRALCGIServer;

    procedure teste(ARequest : TRALRequest; AResponse : TRALResponse);
  public

  end;

var
  dm: Tdm;

implementation

{$R *.lfm}

{ Tdm }

procedure Tdm.DataModuleCreate(Sender: TObject);
begin
  FCGI := TRALCGIServer.Create(nil);
  FCGI.CreateRoute('teste', @teste);
  FCGI.Start
end;

procedure Tdm.teste(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'RAL CGI Tester Lazarus');
end;

end.

