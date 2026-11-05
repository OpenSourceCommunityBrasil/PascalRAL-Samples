unit Controllers.Produto;

interface

uses
  RALRequest, RALResponse, RALServer, RALTypes, RALConsts, RALMIMETypes,
  System.JSON, System.SysUtils, System.Classes, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarProdutos(Req: TRALRequest; Res: TRALResponse);
procedure ListarProdutoById(Req: TRALRequest; Res: TRALResponse);
procedure InserirProduto(Req: TRALRequest; Res: TRALResponse);
procedure EditarProduto(Req: TRALRequest; Res: TRALResponse);
procedure ExcluirProduto(Req: TRALRequest; Res: TRALResponse);
procedure EditarFoto(Req: TRALRequest; Res: TRALResponse);
procedure EditarOrdemUp(Req: TRALRequest; Res: TRALResponse);
procedure EditarOrdemDown(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('admin/produtos', ListarProdutos).AllowedMethods := [amGET];
  AServer.CreateRoute('admin/produtos', InserirProduto).AllowedMethods := [amPOST];
  AServer.CreateRoute('admin/produtos/:id_produto', ListarProdutoById)
    .AllowedMethods := [amGET];
  AServer.CreateRoute('admin/produtos/:id_produto', EditarProduto)
    .AllowedMethods := [amPUT];
  AServer.CreateRoute('admin/produtos/:id_produto', ExcluirProduto)
    .AllowedMethods := [amDELETE];
  AServer.CreateRoute('admin/produtos/:id_produto/foto', EditarFoto)
    .AllowedMethods := [amPUT];
  AServer.CreateRoute('admin/produtos/:id_produto/up', EditarOrdemUp)
    .AllowedMethods := [amPUT];
  AServer.CreateRoute('admin/produtos/:id_produto/down', EditarOrdemDown)
    .AllowedMethods := [amPUT];
end;

procedure ListarProdutos(Req: TRALRequest; Res: TRALResponse);
var
  DmGlobal: TDmGlobal;
  id_categoria: integer;
begin
  try
    try
      // http://localhost:3000/admin/produtos?id_categoria=1

      DmGlobal := TDmGlobal.Create(nil);
      id_categoria := Req.ParamByName('id_categoria').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.ListarProdutos(id_categoria).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure ListarProdutoById(Req: TRALRequest; Res: TRALResponse);
var
  id_produto: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/produtos/5

      DmGlobal := TDmGlobal.Create(nil);
      id_produto := Req.ParamByName('id_produto').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.ListarProdutoById(id_produto).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure InserirProduto(Req: TRALRequest; Res: TRALResponse);
var
  DmGlobal: TDmGlobal;
  body: TJSONObject;
  nome, descricao: string;
  preco: double;
  id_categoria: integer;
begin
  try
    try
      // http://localhost:3000/admin/produtos
      // Body = nome, descricao, preco, foto, id_categoria

      DmGlobal := TDmGlobal.Create(nil);

      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      nome := body.GetValue<string>('nome', '');
      descricao := body.GetValue<string>('descricao', '');
      preco := body.GetValue<double>('preco', 0);
      id_categoria := body.GetValue<integer>('id_categoria', 0);

      Res.Answer(HTTP_Created, DmGlobal.InserirProduto(nome, descricao, preco,
                                                       id_categoria).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarProduto(Req: TRALRequest; Res: TRALResponse);
var
  DmGlobal: TDmGlobal;
  body: TJSONObject;
  nome, descricao: string;
  preco: double;
  id_produto, id_categoria: integer;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/produtos/5
      // Body = nome, descricao, preco, foto, id_categoria

      DmGlobal := TDmGlobal.Create(nil);
      id_produto := Req.ParamByName('id_produto').AsInteger;

      // Ler dados do corpo da requisicao...
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      nome := body.GetValue<string>('nome', '');
      descricao := body.GetValue<string>('descricao', '');
      preco := body.GetValue<double>('preco', 0);
      id_categoria := body.GetValue<integer>('id_categoria', 0);

      res.Answer(HTTP_OK, DmGlobal.EditarProduto(id_produto, nome, descricao, preco,
                                                 id_categoria).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure ExcluirProduto(Req: TRALRequest; Res: TRALResponse);
var
  id_produto: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/produtos/5

      DmGlobal := TDmGlobal.Create(nil);
      id_produto := Req.ParamByName('id_produto').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.ExcluirProduto(id_produto).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarFoto(Req: TRALRequest; Res: TRALResponse);
var
  DmGlobal: TDmGlobal;
  id_produto: integer;
  arqfoto, arqparam: TFileStream;
begin
  id_produto := Req.ParamByName('id_produto').AsInteger;

  { No cliente, a requisição é feita dessa forma:
    TRequest.New.BaseURL(BASE_URL)
            .Resource('admin/produtos')
            .ResourceSuffix(id_produto.tostring + '/foto')
            .AddParam('files', arq_foto, pkFILE)
            .Put;
    Por isso, como o body possui somente 1 parâmetro que é o arquivo, no RAL a
    gente trata dessa forma abaixo:
  }

  arqparam := TFileStream(Req.ParamByName('files').AsStream);
  try
    arqfoto := TFileStream.Create(ExtractFilePath(ParamStr(0)) + 'Fotos/' + arqparam.FileName, fmOpenReadWrite);
    arqfoto.CopyFrom(arqparam, arqparam.Size);

    DmGlobal := TDmGlobal.Create(nil);
    try
      DmGlobal.EditarFoto(id_produto, arqfoto.FileName);
    finally
      DmGlobal.Free;
    end;
  finally
    arqfoto.Free;
  end;

  Res.Answer(HTTP_OK);
end;

procedure EditarOrdemUp(Req: TRALRequest; Res: TRALResponse);
var
  id_produto: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/produtos/5/up

      DmGlobal := TDmGlobal.Create(nil);
      id_produto := Req.ParamByName('id_produto').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.OrdemProdutoUp(id_produto).ToJSON);

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
  id_produto: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/produtos/5/down

      DmGlobal := TDmGlobal.Create(nil);
      id_produto := Req.ParamByName('id_produto').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.OrdemProdutoDown(id_produto).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

end.
