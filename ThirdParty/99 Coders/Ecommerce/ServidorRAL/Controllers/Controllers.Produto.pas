unit Controllers.Produto;

interface

uses
  RALServer, RALTypes, RALRequest, RALResponse, RALConsts, RALMIMETypes,
  System.SysUtils, System.JSON, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarCategorias(Req: TRALRequest; Res: TRALResponse);
procedure ListarProdutos(Req: TRALRequest; Res: TRALResponse);
procedure ListarProdutoId(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('categorias', ListarCategorias).AllowedMethods := [amGET];
  AServer.CreateRoute('produtos', ListarProdutos).AllowedMethods := [amGET];
  AServer.CreateRoute('produtos/:id_produto', ListarProdutoId).AllowedMethods := [amGET];
end;

procedure ListarCategorias(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
begin
  Dm := TDm.Create(nil);

  try
    try
      Res.Answer(Dm.ListarCategorias.ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarProdutos(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_categoria: integer;
  busca: string;
begin
  Dm := TDm.Create(nil);

  // Get -> /produtos?id_categoria=2&busca=fone
  try
    {
      não precisa try .. except aqui porque internamente já é tratado o parâmetro
      e se for nil, retorna vazio para string ou 0 para inteiro, ou o IDE Default para
      o tipo primitivo do .AsTipo
    }
    try
      id_categoria := Req.ParamByName('id_categoria').AsInteger;
      busca := Req.ParamByName('busca').AsString;

      Res.Answer(HTTP_OK, Dm.ListarProdutos(id_categoria, busca).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarProdutoId(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_produto, id_usuario: integer;
begin
  Dm := TDm.Create(nil);

  // Get -> /produtos/12345
  try
    try
      id_produto := Req.ParamByName('id_produto').AsInteger;
      id_usuario := Req.ParamByName('id_usuario').AsInteger;

      Res.Answer(HTTP_OK, Dm.ListarProdutoId(id_produto, id_usuario).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;


end.
