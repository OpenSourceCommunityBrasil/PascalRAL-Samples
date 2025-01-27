unit udm_rest;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  Data.DB, FireDAC.Comp.Client, RALRequest, RALResponse, RALToken;

type
  Tdm_rest = class(TDataModule)
    conexao: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
    function userCodigo(AUser, APass : string) : integer;
    function userExiste(ACodigo : integer) : boolean;
  public
    { Public declarations }
    procedure getJWTToken(ARequest: TRALRequest; AResponse: TRALResponse;
                          AParams: TRALJWTParams; var AResult: Boolean);
    procedure validBasicAuth(ARequest : TRALRequest; AResponse: TRALResponse;
                             var AResult: Boolean);
    procedure validJWToken(ARequest: TRALRequest; AResponse: TRALResponse;
                          AParams: TRALJWTParams; var AResult: Boolean);
  end;

var
  dm_rest: Tdm_rest;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  uglobal_vars;

procedure Tdm_rest.DataModuleCreate(Sender: TObject);
begin
  with conexao do begin
    Close;
    Params.Clear;
    Params.Add('DriverID=SQLite');
    Params.Add('Database='+gb_database);
    Params.Add('Server='+gb_hostname);
    Params.Add('LockingMode=Normal');
    Open;
  end;
end;

procedure Tdm_rest.getJWTToken(ARequest: TRALRequest; AResponse: TRALResponse;
                               AParams: TRALJWTParams; var AResult: Boolean);
var
  vUser : string;
  vPass : string;
  vCodigo : integer;
begin
  AResult := False;
  vUser := ARequest.ParamByName('user').AsString;
  vPass := ARequest.ParamByName('pass').AsString;
  vCodigo := userCodigo(vUser, vPass);
  if vCodigo > 0 then begin
    AResult := True;
    AParams.AddClaim('cod', IntToStr(vCodigo));
  end;
end;

function Tdm_rest.userCodigo(AUser, APass: string): integer;
var
  q1 : TFDQuery;
begin
  Result := -1;
  q1 := TFDQuery.Create(nil);
  try
    q1.Connection := conexao;
    q1.Close;
    q1.SQL.Clear;
    q1.SQL.Add('select codigo from usuarios');
    q1.SQL.Add('where usuario = :usuario and senha = :senha and');
    q1.SQL.Add('      ativo = ''S''');
    q1.ParamByName('usuario').AsString := AUser;
    q1.ParamByName('senha').AsString := APass;
    q1.Open;

    Result := q1.Fields[0].AsInteger;
  finally
    FreeAndNil(q1);
  end;
end;

function Tdm_rest.userExiste(ACodigo: integer): boolean;
var
  q1 : TFDQuery;
begin
  Result := False;
  q1 := TFDQuery.Create(nil);
  try
    q1.Connection := conexao;
    q1.Close;
    q1.SQL.Clear;
    q1.SQL.Add('select count(*) from usuarios');
    q1.SQL.Add('where codigo = :codigo and');
    q1.SQL.Add('      ativo = ''S''');
    q1.ParamByName('codigo').AsInteger := ACodigo;
    q1.Open;

    Result := q1.Fields[0].AsInteger > 0;
  finally
    FreeAndNil(q1);
  end;
end;

procedure Tdm_rest.validBasicAuth(ARequest: TRALRequest;
  AResponse: TRALResponse; var AResult: Boolean);
var
  basic : TRALAuthBasic;
  vCodigo : integer;
begin
  AResult := False;
  basic := ARequest.Authorization.AsAuthBasic;
  if basic = nil then
    Exit;

  vCodigo := userCodigo(basic.UserName, basic.Password);
  AResult := vCodigo > 0;
end;

procedure Tdm_rest.validJWToken(ARequest: TRALRequest; AResponse: TRALResponse;
  AParams: TRALJWTParams; var AResult: Boolean);
var
  vCodigo : integer;
begin
  if AResult then begin
    vCodigo := StrToIntDef(AParams.GetClaim('cod'), -1);
    AResult := userExiste(vCodigo);
  end;
end;

end.
