unit Controllers.Corrida;

interface

uses
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts, RALTypes, RALRoutes,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarOfertas(Req: TRALRequest; Res: TRALResponse);
procedure InserirCorrida(Req: TRALRequest; Res: TRALResponse);
procedure StatusCorrida(Req: TRALRequest; Res: TRALResponse);
procedure AvaliarCorrida(Req: TRALRequest; Res: TRALResponse);
procedure ListarCorridas(Req: TRALRequest; Res: TRALResponse);

implementation

uses
  Controllers.JWT;

procedure RegistrarRotas(AServer: TRALServer);
var
  Rota: TRALRoute;
begin
{
  No código original, o JWT foi atribuído manualmente às rotas, sem atribuir uma
  autenticação ao objeto do servidor. Preservamos a ideia do exemplo original,
  por isso não estamos utilizando o SkipAuthMethods nas rotas que deveriam ignorar
  autenticação. Porém o código ficou comentado para estudos.

  Repare também que as rotas não precisam iniciar por '/', não é proibido adicionar
  porque internamente o RAL corrige, mas também não é obrigatório iniciar por '/'.
}

  // Essa rota /corridas deveria ignorar autenticação, de acordo com o exemplo original
  Rota := AServer.CreateRoute('corridas', InserirCorrida);
  Rota.AllowedMethods := [amPOST];
//  Rota.SkipAuthMethods := [amPOST];

  // As rotas abaixo seriam protegidas por autenticação, de acordo com o exemplo original
  AServer.CreateRoute('corridas/ofertas', ListarOfertas).AllowedMethods := [amGET];
  AServer.CreateRoute('corridas/:id_corrida/status', StatusCorrida)
    .AllowedMethods := [amPUT];
  AServer.CreateRoute('corridas/:id_corrida/avaliacao', AvaliarCorrida)
    .AllowedMethods := [amPUT];
  AServer.CreateRoute('corridas', ListarCorridas).AllowedMethods := [amGET];
end;

procedure ListarOfertas(Req: TRALRequest; Res: TRALResponse);
var
  id_motorista: integer;
  dm: TDm;
begin
  dm := TDm.Create(nil);
  try
    try
      id_motorista := Get_Usuario_Request(Req);

      Res.Answer(HTTP_OK, dm.ListarOfertas(id_motorista).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

procedure InserirCorrida(Req: TRALRequest; Res: TRALResponse);
var
  nome, whatsapp, origem, destino: string;
  vl_corrida: double;
  body, json_retorno: TJsonObject;
  dm: TDm;
begin
  dm := TDm.Create(nil);
  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      nome := body.GetValue<string>('nome', '');
      whatsapp := body.GetValue<string>('whatsapp', '');
      origem := body.GetValue<string>('origem', '');
      destino := body.GetValue<string>('destino', '');
      vl_corrida := body.GetValue<double>('vl_corrida', 0);

      Res.Answer(HTTP_Created, dm.InserirCorrida(nome, whatsapp, origem,
                                                 destino, vl_corrida).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

procedure StatusCorrida(Req: TRALRequest; Res: TRALResponse);
var
  status: string;
  id_motorista, id_corrida, id_fila: integer;
  dm: TDm;
  body: TJSONObject;
begin
  dm := TDm.Create(nil);
  try
    try
      id_motorista := Get_Usuario_Request(Req);
      id_corrida := Req.ParamByName('id_corrida').AsInteger;

      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      id_fila := body.getvalue<integer>('id_fila', 0);
      status := body.getvalue<string>('status', '');

      Res.Answer(HTTP_OK, dm.StatusCorrida(id_fila, id_motorista,
                                           id_corrida, status).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

procedure AvaliarCorrida(Req: TRALRequest; Res: TRALResponse);
var
  avaliacao: integer;
  id_motorista, id_corrida: integer;
  dm: TDm;
  body: TJSONObject;
begin
  dm := TDm.Create(nil);
  try
    try
      id_motorista := Get_Usuario_Request(Req);
      id_corrida := Req.ParamByName('id_corrida').AsInteger;

      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      avaliacao := body.getvalue<integer>('avaliacao', 0);

      Res.Answer(HTTP_OK, dm.AvaliarCorrida(id_motorista,
                                            id_corrida, avaliacao).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

procedure ListarCorridas(Req: TRALRequest; Res: TRALResponse);
var
  id_motorista: integer;
  dm: TDm;
begin
  dm := TDm.Create(nil);
  try
    try
      id_motorista := Get_Usuario_Request(Req);
      Res.Answer(HTTP_OK, dm.ListarCorridas(id_motorista).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;


end.
