program Console;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Classes,
  RALIndyServer,
  RALRequest,
  RALResponse;

type
  { TRALApplication }

  TRALApplication = class(TComponent)
  private
    FServer : TRALIndyServer;
  protected
    procedure teste(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
    procedure DoRun;
  public
    constructor Create(TheOwner : TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TRALApplication }

constructor TRALApplication.Create(TheOwner: TComponent);
begin
  inherited;
  FServer := TRALIndyServer.Create(nil);
end;

destructor TRALApplication.Destroy;
begin
  FServer.Free;
  inherited;
end;

procedure TRALApplication.DoRun;
begin
  inherited;
  FServer.CreateRoute('teste',teste);

  FServer.Active := True;

  Readln;
end;

procedure TRALApplication.teste(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.ResponseText := 'RALTeste';
end;

procedure TRALApplication.WriteHelp;
begin

end;

var
  Application : TRALApplication;
begin
  Application := TRALApplication.Create(nil);
  Application.DoRun;
  Application.Free;
end.
