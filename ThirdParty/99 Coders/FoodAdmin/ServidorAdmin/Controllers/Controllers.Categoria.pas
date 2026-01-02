unit Controllers.Categoria;

interface

uses
  RALRequest, RALResponse, RALServer, RALTypes, RALConsts, RALMIMETypes,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarCategorias(Req: TRALRequest; Res: TRALResponse);
procedure ListarCategoriaById(Req: TRALRequest; Res: TRALResponse);
procedure InserirCategoria(Req: TRALRequest; Res: TRALResponse);
procedure EditarCategoria(Req: TRALRequest; Res: TRALResponse);
procedure ExcluirCategoria(Req: TRALRequest; Res: TRALResponse);

procedure EditarOrdemUp(Req: TRALRequest; Res: TRALResponse);
procedure EditarOrdemDown(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('admin/categorias', ListarCategorias).AllowedMethods := [amGET];
  AServer.CreateRoute('admin/categorias/:id_categoria', ListarCategoriaById)
    .AllowedMethods := [amGET];
  AServer.CreateRoute('admin/categorias', InserirCategoria).AllowedMethods := [amPOST];
  AServer.CreateRoute('admin/categorias/:id_categoria', EditarCategoria)
    .AllowedMethods := [amPUT];
  AServer.CreateRoute('admin/categorias/:id_categoria', ExcluirCategoria)
    .AllowedMethods := [amDELETE];

  AServer.CreateRoute('admin/categorias/:id_categoria/up', EditarOrdemUp)
    .AllowedMethods := [amPUT];
  AServer.CreateRoute('admin/categorias/:id_categoria/down', EditarOrdemDown)
    .AllowedMethods := [amPUT];
end;

procedure ListarCategorias(Req: TRALRequest; Res: TRALResponse);
var
  DmGlobal: TDmGlobal;
begin
  try
    try
      // http://localhost:3000/admin/categorias

      DmGlobal := TDmGlobal.Create(nil);

      Res.Answer(HTTP_OK, DmGlobal.ListarCategorias.ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure ListarCategoriaById(Req: TRALRequest; Res: TRALResponse);
var
  id_categoria: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/categorias/5

      DmGlobal := TDmGlobal.Create(nil);

      id_categoria := Req.ParamByName('id_categoria').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.ListarCategoriaById(id_categoria).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure InserirCategoria(Req: TRALRequest; Res: TRALResponse);
var
  DmGlobal: TDmGlobal;
  body: TJSONObject;
  descricao: string;
begin
  try
    try
      // http://localhost:3000/admin/categorias
      // Body = {"descricao": "Sobremesa"}

      DmGlobal := TDmGlobal.Create(nil);

      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      descricao := body.GetValue<string>('descricao', '');

      Res.Answer(HTTP_Created, DmGlobal.InserirCategoria(descricao).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarCategoria(Req: TRALRequest; Res: TRALResponse);
var
  id_categoria: integer;
  DmGlobal: TDmGlobal;
  body: TJSONObject;
  descricao: string;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/categorias/5
      // Body = {"descricao": "Sobremesa"}

      DmGlobal := TDmGlobal.Create(nil);
      id_categoria := Req.ParamByName('id_categoria').AsInteger;

      // Ler dados do corpo da requisicao...
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      descricao := body.GetValue<string>('descricao', '');

      Res.Answer(HTTP_OK, DmGlobal.EditarCategoria(id_categoria, descricao).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure ExcluirCategoria(Req: TRALRequest; Res: TRALResponse);
var
  id_categoria: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/categorias/5

      DmGlobal := TDmGlobal.Create(nil);
      id_categoria := Req.ParamByName('id_categoria').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.ExcluirCategoria(id_categoria).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarOrdemUp(Req: TRALRequest; Res: TRALResponse);
var
  id_categoria: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/categorias/5/up

      DmGlobal := TDmGlobal.Create(nil);
      id_categoria := Req.ParamByName('id_categoria').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.OrdemCategoriaUp(id_categoria).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarOrdemDown(Req: TRALRequest; Res: TRALResponse);
var
  id_categoria: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/categorias/5/down

      DmGlobal := TDmGlobal.Create(nil);
      id_categoria := Req.ParamByName('id_categoria').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.OrdemCategoriaDown(id_categoria).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

end.
