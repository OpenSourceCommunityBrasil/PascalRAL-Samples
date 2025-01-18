library module_sample;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  System.SysUtils,
  System.Classes,
  RALServer,
  RALRequest,
  RALResponse,
  RALConsts;

{$R *.res}

type
  TModuleTeste = class(TRALModuleRoutes)
  private
    constructor Create(AOwner: TComponent); override;
  protected
    procedure ping(ARequest : TRALRequest; AResponse : TRALResponse);
  end;

var
  ral_module : TModuleTeste;

function start_module(server : TRALServer): Boolean; stdcall; export;
begin
  if ral_module = nil then
    ral_module := TModuleTeste.Create(nil);

  ral_module.Server := server;
end;

exports
  start_module index 1;

{ TModuleTeste }

constructor TModuleTeste.Create(AOwner: TComponent);
begin
  inherited;
  CreateRoute('/ping', ping);
end;

procedure TModuleTeste.ping(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong', 'text/plain');
  AResponse.ContentDispositionInline := True;
end;

begin
  ral_module := nil;
end.
