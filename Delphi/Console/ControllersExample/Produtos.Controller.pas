/// Um controller por atributos (Delphi 2010+): as rotas saem dos metodos.
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/controllers
unit Produtos.Controller;

interface

uses
  Classes, SysUtils, Generics.Collections,
  RALTypes, RALConsts, RALResponse, RALObjectJSON, RALObjectRTTI, RALControllers;

type
  /// Um produto, validado por atributos.
  TProduto = class(TRALObject)
  private
    FId: Integer;
    FNome: string;
    FPreco: Double;
  published
    property Id: Integer read FId write FId;
    [Required, MaxLength(40)]
    property Nome: string read FNome write FNome;
    [Range(0, 100000)]
    property Preco: Double read FPreco write FPreco;
  end;

  /// O produto que nao existe: o ExceptionMap do servidor responde 404.
  ENaoEncontrado = class(Exception);

  /// O CRUD de produtos.
  [Path('/produtos')]
  TProdutoController = class(TRALObject)
  public
    [GET]
    function Listar([FromQuery('nome')] AFiltro: string): TObjectList<TProduto>;
    [GET('/{id}')]
    function Obter(id: Integer): TProduto;
    [POST]
    function Criar(AProduto: TProduto; AResponse: TRALResponse): TProduto;
    [DELETE('/{id}')]
    procedure Apagar(id: Integer);
  end;

implementation

var
  gBanco: TObjectList<TProduto>;

function Copia(AProduto: TProduto): TProduto;
begin
  Result := TProduto.Create;
  Result.Id := AProduto.Id;
  Result.Nome := AProduto.Nome;
  Result.Preco := AProduto.Preco;
end;

function TProdutoController.Listar(AFiltro: string): TObjectList<TProduto>;
var
  vProduto: TProduto;
begin
  Result := TObjectList<TProduto>.Create(True);
  for vProduto in gBanco do
    if (AFiltro = '') or (Pos(LowerCase(AFiltro), LowerCase(vProduto.Nome)) > 0) then
      Result.Add(Copia(vProduto));
end;

function TProdutoController.Obter(id: Integer): TProduto;
var
  vProduto: TProduto;
begin
  for vProduto in gBanco do
    if vProduto.Id = id then
      Exit(Copia(vProduto));
  raise ENaoEncontrado.CreateFmt('produto %d', [id]);
end;

function TProdutoController.Criar(AProduto: TProduto; AResponse: TRALResponse): TProduto;
begin
  AProduto.Id := gBanco.Count + 1;
  gBanco.Add(Copia(AProduto));
  AResponse.StatusCode := HTTP_Created;
  Result := Copia(AProduto);
end;

procedure TProdutoController.Apagar(id: Integer);
var
  vInt: Integer;
begin
  for vInt := gBanco.Count - 1 downto 0 do
    if gBanco[vInt].Id = id then
      gBanco.Delete(vInt);
end;

initialization
  gBanco := TObjectList<TProduto>.Create(True);

finalization
  gBanco.Free;

end.
