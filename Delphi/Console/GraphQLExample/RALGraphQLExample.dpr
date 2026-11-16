program RALGraphQLExample;

// A GraphQL endpoint on RAL: http://localhost:8096/graphql. Open it in a browser
// for GraphiQL (explore the schema in Docs, run queries); clients POST JSON.

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  Classes, SysUtils,
  {$IFDEF FPC}RALfpHTTPServer,{$ELSE}RALIndyServer,{$ENDIF}
  RALTypes, RALServer, RALJson, RALGraphQLExecutor, RALGraphQLModule;

const
  SDL =
    '"""A book of the catalog"""'#10 +
    'type Book { id: ID! title: String! year: Int author: Author }'#10 +
    'type Author { name: String! books: [Book!]! }'#10 +
    'input NewBook { title: String! year: Int author: String! }'#10 +
    'type Query {'#10 +
    '  """All the books, or those of one author"""'#10 +
    '  books(author: String): [Book!]!'#10 +
    '  book(id: ID!): Book'#10 +
    '}'#10 +
    'type Mutation { addBook(book: NewBook!): Book! }'#10;

type
  TApp = class
  public
    Books: TRALJSONArray;
    constructor Create;
    destructor Destroy; override;
    procedure ListBooks(AInfo: TRALGraphQLResolve);
    procedure OneBook(AInfo: TRALGraphQLResolve);
    procedure BookAuthor(AInfo: TRALGraphQLResolve);
    procedure AuthorBooks(AInfo: TRALGraphQLResolve);
    procedure AddBook(AInfo: TRALGraphQLResolve);
  end;

constructor TApp.Create;
begin
  Books := TRALJSONArray(TRALJSON.ParseJSON(
    '[{"id":"1","title":"Dom Casmurro","year":1899,"author":"Machado de Assis"},' +
    '{"id":"2","title":"Memorias Postumas de Bras Cubas","year":1881,"author":"Machado de Assis"},' +
    '{"id":"3","title":"Grande Sertao: Veredas","year":1956,"author":"Guimaraes Rosa"}]'));
end;

destructor TApp.Destroy;
begin
  Books.Free;
  inherited;
end;

{ the resolvers answer JSON; the fields below read it unless they have a resolver }
procedure TApp.ListBooks(AInfo: TRALGraphQLResolve);
var
  vList: TRALJSONArray;
  vInt: Integer;
  vBook: TRALJSONObject;
begin
  vList := TRALJSONArray.Create;
  for vInt := 0 to Books.Count - 1 do
  begin
    vBook := TRALJSONObject(Books.Get(vInt));
    if (AInfo.ArgAsString('author') = '') or (vBook.Find('author').AsString = AInfo.ArgAsString('author')) then
      vList.Add(TRALJSON.ParseJSON(vBook.ToJSON));
  end;
  AInfo.ReturnValue(vList);
end;

procedure TApp.OneBook(AInfo: TRALGraphQLResolve);
var
  vInt: Integer;
begin
  for vInt := 0 to Books.Count - 1 do
    if TRALJSONObject(Books.Get(vInt)).Find('id').AsString = AInfo.ArgAsString('id') then
      AInfo.ReturnJSON(Books.Get(vInt).ToJSON);
end;

{ Book.author: the stored text becomes an Author object }
procedure TApp.BookAuthor(AInfo: TRALGraphQLResolve);
begin
  AInfo.ReturnJSON('{"name":' + TRALJSONObject(AInfo.Parent).Find('author').ToJSON + '}');
end;

procedure TApp.AuthorBooks(AInfo: TRALGraphQLResolve);
var
  vList: TRALJSONArray;
  vInt: Integer;
  vName: StringRAL;
begin
  vName := TRALJSONObject(AInfo.Parent).Find('name').AsString;
  vList := TRALJSONArray.Create;
  for vInt := 0 to Books.Count - 1 do
    if TRALJSONObject(Books.Get(vInt)).Find('author').AsString = vName then
      vList.Add(TRALJSON.ParseJSON(Books.Get(vInt).ToJSON));
  AInfo.ReturnValue(vList);
end;

procedure TApp.AddBook(AInfo: TRALGraphQLResolve);
var
  vBook: TRALJSONObject;
begin
  // resolvers run on the server's threads: guard shared data in a real application
  vBook := TRALJSONObject(TRALJSON.ParseJSON(AInfo.Arg('book').ToJSON));
  vBook.Add('id', StringRAL(IntToStr(Books.Count + 1)));
  Books.Add(vBook);
  AInfo.ReturnJSON(vBook.ToJSON);
end;

var
  vApp: TApp;
  vServer: TRALServer;
  vGraphQL: TRALGraphQLModule;
begin
  vApp := TApp.Create;
  vServer := {$IFDEF FPC}TRALfpHttpServer{$ELSE}TRALIndyServer{$ENDIF}.Create(nil);
  vGraphQL := TRALGraphQLModule.Create(nil);
  try
    vGraphQL.Schema.Text := SDL;
    vGraphQL.Resolvers.AddResolver('Query', 'books', vApp.ListBooks);
    vGraphQL.Resolvers.AddResolver('Query', 'book', vApp.OneBook);
    vGraphQL.Resolvers.AddResolver('Book', 'author', vApp.BookAuthor);
    vGraphQL.Resolvers.AddResolver('Author', 'books', vApp.AuthorBooks);
    vGraphQL.Resolvers.AddResolver('Mutation', 'addBook', vApp.AddBook);
    vGraphQL.MaxDepth := 8;
    vGraphQL.Server := vServer;
    vServer.Port := 8096;
    vServer.Active := True;
    WriteLn('GraphQL at http://localhost:8096/graphql (GraphiQL in a browser)');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Active := False;
  finally
    vGraphQL.Free;
    vServer.Free;
    vApp.Free;
  end;
end.
