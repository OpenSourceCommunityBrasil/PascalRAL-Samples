unit Controllers.Lancamento;

interface

uses
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts, RALTypes, RALRoutes,
  System.SysUtils, System.JSON, Services.Lancamento, Controllers.JWT;

procedure RegistrarRotas(AServer: TRALServer);
procedure Listar(Req: TRALRequest; Res: TRALResponse);
procedure ListarId(Req: TRALRequest; Res: TRALResponse);
procedure Inserir(Req: TRALRequest; Res: TRALResponse);
procedure Editar(Req: TRALRequest; Res: TRALResponse);
procedure Excluir(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
{
  Nesta classe, todas as rotas são protegidas por autenticação, então aqui não
  teria nenhum SkipAuthRoutes
}
  AServer.CreateRoute('lancamentos', Listar).AllowedMethods := [amGET];
  AServer.CreateRoute('lancamentos', Inserir).AllowedMethods := [amPOST];
  AServer.CreateRoute('lancamentos/:id_lancamento', ListarId).AllowedMethods := [amGET];
  AServer.CreateRoute('lancamentos/:id_lancamento', Editar).AllowedMethods := [amPUT];
  AServer.CreateRoute('lancamentos/:id_lancamento', Excluir).AllowedMethods := [amDELETE];
end;

procedure Listar(Req: TRALRequest; Res: TRALResponse);
var
  id_usuario, id_categoria: integer;
  dt_de, dt_ate: string;
begin
  try
    id_usuario := Get_Usuario_Request(Req);
{
  No RAL não é necessário fazer try .. except para buscar o parâmetro, pois se caso
  ele não existir, é retornado o valor default para o tipo escolhido, no caso do
  integer, se o parâmetro não existir, vai retornar 0.

  Para fazer uma validação mais precisa, utilize o método IsNilOrEmpty, que irá
  retornar true se caso o parâmetro não existir ou for vazio.
}
  //Req.ParamByName('id').IsNilOrEmpty = true se não existir ou for vazio
    id_categoria := Req.ParamByName('id_categoria').AsInteger;

    dt_de := Req.ParamByName('dt_de').AsString;
    dt_ate := Req.ParamByName('dt_ate').AsString;

    Res.Answer(HTTP_OK, Services.Lancamento.Listar(id_usuario, id_categoria, dt_de, dt_ate).ToJSON);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure Inserir(Req: TRALRequest; Res: TRALResponse);
var
  descricao, tipo, dt_lancamento: string;
  valor: double;
  id_usuario, id_categoria: integer;
  body: TJsonObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    descricao := body.GetValue<string>('descricao', '');
    tipo := body.GetValue<string>('tipo', '');
    dt_lancamento := body.GetValue<string>('dt_lancamento', '');
    valor := body.GetValue<double>('valor', 0);
    id_categoria := body.GetValue<integer>('id_categoria', 0);

    id_usuario := Get_Usuario_Request(Req);

    Res.Answer(HTTP_Created, Services.Lancamento.Inserir(id_usuario, id_categoria,
         descricao, tipo, dt_lancamento, valor).ToJSON);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure Editar(Req: TRALRequest; Res: TRALResponse);
var
  descricao, tipo, dt_lancamento: string;
  valor: double;
  id_usuario, id_categoria, id_lancamento: integer;
  body: TJsonObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    descricao := body.GetValue<string>('descricao', '');
    tipo := body.GetValue<string>('tipo', '');
    dt_lancamento := body.GetValue<string>('dt_lancamento', '');
    valor := body.GetValue<double>('valor', 0);
    id_categoria := body.GetValue<integer>('id_categoria', 0);

    id_lancamento := Req.ParamByName('id_lancamento').AsInteger;
    id_usuario := Get_Usuario_Request(Req);

    Services.Lancamento.Editar(id_usuario, id_lancamento, id_categoria,
                               descricao, tipo, dt_lancamento, valor);
    Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure ListarId(Req: TRALRequest; Res: TRALResponse);
var
  id_usuario, id_lancamento: integer;
begin
  try
    id_usuario := Get_Usuario_Request(Req);
    id_lancamento := Req.ParamByName('id_lancamento').AsInteger;

    Res.Answer(HTTP_OK, Services.Lancamento.ListarId(id_usuario, id_lancamento).ToJSON);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure Excluir(Req: TRALRequest; Res: TRALResponse);
var
  id_usuario, id_lancamento: integer;
begin
  try

    id_usuario := Get_Usuario_Request(Req);
    id_lancamento := Req.ParamByName('id_lancamento').AsInteger;

    Services.Lancamento.Excluir(id_usuario, id_lancamento);
    Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;


end.

