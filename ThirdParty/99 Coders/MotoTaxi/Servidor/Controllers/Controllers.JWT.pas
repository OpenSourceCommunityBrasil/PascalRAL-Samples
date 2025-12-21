unit Controllers.JWT;

interface

uses
  RALRequest, RALToken, System.SysUtils, DateUtils;

const
  SECRET = 'Mototaxi!2025#';

function Criar_Token(id_motorista: integer; validade_minutos: integer = 0): string;
function Get_Usuario_Request(Req: TRALRequest): integer;

implementation

function Criar_Token(id_motorista: integer; validade_minutos: integer = 0): string;
var
  jwt: TRALJWT;
begin
  jwt := TRALJWT.Create;
  try
    try
      jwt.Payload.AddClaim('id', id_motorista.ToString);

      // data de expiracao...
      if validade_minutos > 0 then
        jwt.Payload.Expiration := IncMinute(now, validade_minutos);

      jwt.SignSecretKey := SECRET;
      Result := jwt.Token;
    except
      Result := '';
    end;
  finally
    FreeAndNil(jwt);
  end;
end;

function Get_Usuario_Request(Req: TRALRequest): integer;
begin
  Result := StrToIntDef(Req.Authorization.AsAuthBearer.Payload.GetClaim('id'), 0);
end;

end.
