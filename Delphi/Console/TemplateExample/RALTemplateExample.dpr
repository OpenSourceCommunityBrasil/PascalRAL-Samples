program RALTemplateExample;

{$APPTYPE CONSOLE}

uses
  System.Classes, System.SysUtils, Data.DB, Datasnap.DBClient, MidasLib,

  // Choose here the engine of the server
  RALIndyServer,
  //RALSynopseServer,

  RALServer, RALRequest, RALResponse, RALRoutes, RALTypes,
  RALTemplate, RALTemplateDB;

var
  FServer: TRALServer;

function CriarProdutos: TDataSet;
var
  vDS: TClientDataSet;
begin
  vDS := TClientDataSet.Create(nil);
  vDS.FieldDefs.Add('nome', ftString, 60);
  vDS.FieldDefs.Add('categoria', ftString, 30);
  vDS.FieldDefs.Add('preco', ftString, 15);
  vDS.CreateDataSet;
  Result := vDS;
end;

var
  FEngine: TRALMustacheEngine;

procedure AddProduto(ADS: TDataSet; const ANome, ACategoria, APreco: string);
begin
  ADS.Append;
  ADS.FieldByName('nome').AsString := ANome;
  ADS.FieldByName('categoria').AsString := ACategoria;
  ADS.FieldByName('preco').AsString := APreco;
  ADS.Post;
end;

procedure ProdutosReply(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vDados: TRALTemplateMap;
  vProdutos: TDataSet;
begin
  vProdutos := CriarProdutos;
  try
    AddProduto(vProdutos, 'Teclado', 'Periféricos', '129,90');
    AddProduto(vProdutos, 'Mouse <sem fio>', 'Periféricos', '59,90');
    AddProduto(vProdutos, 'Monitor', 'Vídeo', '899,00');
    vProdutos.First;

    vDados := TRALTemplateMap.Create;
    try
      // the dataset is walked by {{#produtos}}, one record at a time
      vDados.Add('produtos', vProdutos).Add('loja', 'Loja do Exemplo');
      FEngine.Render(AResponse, 'produtos', [vDados]);
    finally
      vDados.Free;
    end;
  finally
    vProdutos.Free;
  end;
end;

procedure OlaReply(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vDados: TRALTemplateMap;
begin
  vDados := TRALTemplateMap.Create;
  try
    vDados.Add('nome', ARequest.ParamByName('nome').AsString);
    AResponse.Answer(200, FEngine.RenderSource('Olá, {{nome}}!', [vDados]), 'text/html; charset=utf-8');
  finally
    vDados.Free;
  end;
end;

procedure CriarTemplates;
begin
  FEngine.AddTemplate('layout',
    '<!DOCTYPE html>' + sLineBreak +
    '<html><head><meta charset="utf-8"><title>{{$title}}Sem título{{/title}}</title></head>' + sLineBreak +
    '<body>{{$content}}{{/content}}</body></html>');
  FEngine.AddTemplate('linha',
    '<tr><td>{{nome}}</td><td>{{categoria}}</td><td>{{preco}}</td></tr>' + sLineBreak);
  // the page is the block "content" of the layout; its {{$title}} replaces the layout's
  FEngine.AddTemplate('produtos',
    '{{$title}}Produtos - {{loja}}{{/title}}' + sLineBreak +
    '<h1>{{loja}}</h1>' + sLineBreak +
    '<table border="1">' + sLineBreak +
    '{{#produtos}}{{>linha}}{{/produtos}}' +
    '{{^produtos}}<tr><td>nenhum</td></tr>{{/produtos}}' + sLineBreak +
    '</table>');
  FEngine.Layout := 'layout';
end;

begin
  FServer := TRALIndyServer.Create(nil);
  FEngine := TRALMustacheEngine.Create(nil);
  try
    CriarTemplates;
    FServer.CreateRoute('produtos', {$IFDEF FPC}@{$ENDIF}ProdutosReply).AllowedMethods := [amGET];
    FServer.CreateRoute('ola', {$IFDEF FPC}@{$ENDIF}OlaReply).AllowedMethods := [amGET];
    FServer.Port := 8000;
    FServer.Start;

    WriteLn('RALServer running on Port ' + IntToStr(FServer.Port));
    WriteLn('Try /produtos and /ola?nome=%3Cb%3E');
    WriteLn('Press ENTER to finish');
    ReadLn;
  finally
    FServer.Stop;
    FreeAndNil(FEngine);
    FreeAndNil(FServer);
  end;
end.
