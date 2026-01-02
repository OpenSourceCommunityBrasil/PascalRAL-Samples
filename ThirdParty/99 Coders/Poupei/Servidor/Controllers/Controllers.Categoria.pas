unit Controllers.Categoria;

interface

uses
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts, RALTypes, RALRoutes,
  System.SysUtils, System.JSON, Services.Categoria, Controllers.JWT;

procedure RegistrarRotas(AServer: TRALServer);
procedure Listar(Req: TRALRequest; Res: TRALResponse);
procedure ListarId(Req: TRALRequest; Res: TRALResponse);
procedure Inserir(Req: TRALRequest; Res: TRALResponse);
procedure Editar(Req: TRALRequest; Res: TRALResponse);
procedure Excluir(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('categorias', Listar).AllowedMethods := [amGET];
  AServer.CreateRoute('categorias', Inserir).AllowedMethods := [amPOST];
  AServer.CreateRoute('categorias/:id_categoria', ListarId).AllowedMethods := [amGET];
  AServer.CreateRoute('categorias/:id_categoria', Editar).AllowedMethods := [amPUT];
  AServer.CreateRoute('categorias/:id_categoria', Excluir).AllowedMethods := [amDELETE];
end;

procedure Listar(Req: TRALRequest; Res: TRALResponse);
var
  id_usuario: integer;
begin
  try
    id_usuario := Get_Usuario_Request(Req);

    Res.Answer(HTTP_OK, Services.Categoria.Listar(id_usuario).ToJSON);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure Inserir(Req: TRALRequest; Res: TRALResponse);
var
  descricao: string;
  id_usuario: integer;
  body: TJsonObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    descricao := body.GetValue<string>('descricao', '');
    id_usuario := Get_Usuario_Request(Req);

    Res.Answer(HTTP_Created, Services.Categoria.Inserir(id_usuario, descricao).ToJSON);
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure Editar(Req: TRALRequest; Res: TRALResponse);
var
  descricao: string;
  id_usuario, id_categoria: integer;
  body: TJsonObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    descricao := body.GetValue<string>('descricao', '');
    id_categoria := Req.ParamByName('id_categoria').AsInteger;
    id_usuario := Get_Usuario_Request(Req);

    Services.Categoria.Editar(id_usuario, id_categoria, descricao);
    Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure ListarId(Req: TRALRequest; Res: TRALResponse);
var
  id_usuario, id_categoria: integer;
begin
  try
    id_usuario := Get_Usuario_Request(Req);
    id_categoria := Req.ParamByName('id_categoria').AsInteger;

    Res.Answer(HTTP_OK, Services.Categoria.ListarId(id_usuario, id_categoria).ToJSON);
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure Excluir(Req: TRALRequest; Res: TRALResponse);
var
  id_usuario, id_categoria: integer;
begin
  try
    id_usuario := Get_Usuario_Request(Req);
    id_categoria := Req.ParamByName('id_categoria').AsInteger;

    Services.Categoria.Excluir(id_usuario, id_categoria);
    Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;


end.

