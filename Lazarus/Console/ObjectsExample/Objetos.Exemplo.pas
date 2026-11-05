/// Objetos no corpo num servidor RAL 2.0: a rota recebe um TPedido ja lido e
/// validado, responde no formato do Accept (JSON, YAML, CSV), e o Swagger mostra
/// o esquema da classe.
/// Guias: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/objetos
///        https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/validacao
unit Objetos.Exemplo;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils,
  RALServer, RALRoutes, RALRequest, RALResponse, RALTypes, RALConsts,
  RALSwaggerModule, RALObjectJSON, RALObjectBinding;

type
  /// Um item do pedido.
  TItem = class(TCollectionItem)
  private
    FPreco: Double;
    FProduto: StringRAL;
    FQtd: Integer;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  published
    property Produto: StringRAL read FProduto write FProduto;
    property Qtd: Integer read FQtd write FQtd;
    property Preco: Double read FPreco write FPreco;
  end;

  /// O pedido: TRALObject, para o RAL chamar o Create que cria os itens.
  TPedido = class(TRALObject)
  private
    FCliente: StringRAL;
    FEmail: StringRAL;
    FId: Integer;
    FItens: TCollection;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    property Id: Integer read FId write FId;
    property Cliente: StringRAL read FCliente write FCliente;
    property Email: StringRAL read FEmail write FEmail;
    property Itens: TCollection read FItens;
  end;

  /// As rotas do exemplo.
  TObjetosExemplo = class
  private
    FPedidos: TCollection;
    FSwagger: TRALSwaggerModule;
    procedure Criar(ARequest: TRALRequest; AResponse: TRALResponse; ABody: TObject);
    procedure Itens(ARequest: TRALRequest; AResponse: TRALResponse);
  public
    destructor Destroy; override;
    /// Cria as rotas em AServer.
    procedure Montar(AServer: TRALServer);
  end;

implementation

procedure TItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TItem then
  begin
    TItem(Dest).Produto := FProduto;
    TItem(Dest).Qtd := FQtd;
    TItem(Dest).Preco := FPreco;
  end
  else
    inherited AssignTo(Dest);
end;

constructor TPedido.Create;
begin
  inherited Create;
  FItens := TCollection.Create(TItem);
end;

destructor TPedido.Destroy;
begin
  FItens.Free;
  inherited;
end;

destructor TObjetosExemplo.Destroy;
begin
  FSwagger.Free;
  FPedidos.Free;
  inherited;
end;

procedure TObjetosExemplo.Montar(AServer: TRALServer);
var
  vRota: TRALRoute;
begin
  FPedidos := TCollection.Create(TItem);
  RALObjectSettings.JSON.Naming := onCamel;       // clienteNome, valorTotal...

  vRota := AServer.CreateObjectRoute('pedidos', 'TPedido', Criar, 'Cria um pedido');
  vRota.Allow([amPOST]);
  vRota.ResponseClass := 'TPedido';
  vRota.ValidationRules.AddRule('Cliente', vrRequired);
  vRota.ValidationRules.AddRule('Cliente', vrMaxLength, '40');
  vRota.ValidationRules.AddRule('Email', vrEmail);
  vRota.ValidationRules.AddRule('Itens', vrRequired, '', 'o pedido precisa de itens');

  AServer.CreateRoute('itens', Itens, 'Todos os itens pedidos (JSON, YAML ou CSV)')
    .Allow([amGET]);

  FSwagger := TRALSwaggerModule.Create(nil);
  FSwagger.Server := AServer;
end;

procedure TObjetosExemplo.Criar(ARequest: TRALRequest; AResponse: TRALResponse;
  ABody: TObject);
var
  vPedido: TPedido;
  vInt: Integer;
begin
  vPedido := TPedido(ABody);                  // lido e validado; o RAL libera
  vPedido.Id := FPedidos.Count + 1;
  for vInt := 0 to vPedido.Itens.Count - 1 do
    FPedidos.Add.Assign(vPedido.Itens.Items[vInt]);
  RALAnswerObject(ARequest, AResponse, HTTP_Created, vPedido);
end;

procedure TObjetosExemplo.Itens(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  RALAnswerObject(ARequest, AResponse, HTTP_OK, FPedidos);
end;

initialization
  RALRegisterObjectClass(TPedido);

end.
