unit DataModule.Global;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait, Data.DB,
  FireDAC.Comp.Client, System.JSON,
  DataSet.Serialize.Config,
  DataSet.Serialize,
  FireDAC.DApt;

type
  TDmGlobal = class(TDataModule)
    conn: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    procedure DataModuleCreate(Sender: TObject);
    procedure connBeforeConnect(Sender: TObject);
  private
    procedure CarregarConfigDB(Connection: TFDConnection);

  public
    function Login(email, senha: string): TJsonObject;
    function InserirUsuario(nome, email, senha: string): TJsonObject;
    function ListarPedidos(dt_de, dt_ate, status: string): TJsonArray;
    function ListarPedidoById(id_pedido: integer): TJsonObject;
    function EditarStatusPedido(id_pedido: integer;
                                status: string): TJsonObject;
    function ListarCategorias: TJsonArray;
    function ListarCategoriaById(id_categoria: integer): TJsonObject;
    function EditarCategoria(id_categoria: integer;
                                   categoria: string): TJsonObject;
    function InserirCategoria(categoria: string): TJsonObject;
    function ExcluirCategoria(id_categoria: integer): TJsonObject;
    function OrdemCategoriaUp(id_categoria: integer): TJsonObject;
    function OrdemCategoriaDown(id_categoria: integer): TJsonObject;
    function ListarProdutos(id_categoria: integer): TJsonArray;
    function ListarProdutoById(id_produto: integer): TJsonObject;
    function InserirProduto(nome, descricao: string; preco: double;
                            id_categoria: integer): TJsonObject;

    function EditarProduto(id_produto: integer; nome, descricao: string;
                           preco: double; id_categoria: integer): TJsonObject;
    function ExcluirProduto(id_produto: integer): TJsonObject;
    procedure EditarFoto(id_produto: integer; arq_foto: string);
    function OrdemProdutoDown(id_produto: integer): TJsonObject;
    function OrdemProdutoUp(id_produto: integer): TJsonObject;
    function EditarConfig(vl_entrega: double): TJsonObject;
    function ListarConfig: TJsonObject;
  end;

var
  DmGlobal: TDmGlobal;

Const
  //URL_SERVER = 'http://localhost:3003/';
  URL_SERVER = 'http://192.168.0.103:3003/';

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDmGlobal.CarregarConfigDB(Connection: TFDConnection);
begin
    Connection.DriverName := 'SQLite';

    with Connection.Params do
    begin
        Clear;
        Add('DriverID=SQLite');

        // Mudar para sua pasta!!!!!!!!
        Add('Database=D:\99Coders\CursoFood\banco.db');

        Add('User_Name=');
        Add('Password=');
        Add('Port=');
        Add('Server=');
        Add('Protocol=');
        Add('LockingMode=Normal');
    end;
end;

procedure TDmGlobal.connBeforeConnect(Sender: TObject);
begin
    CarregarConfigDB(Conn);
end;

procedure TDmGlobal.DataModuleCreate(Sender: TObject);
begin
    TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
    TDataSetSerializeConfig.GetInstance.Import.DecimalSeparator := '.';

    conn.Connected := true;
end;

function TDmGlobal.Login(email, senha: string): TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('select id_usuario, nome, email from usuario_admin');
        qry.SQL.Add('where email=:email and senha=:senha');
        qry.ParamByName('email').Value := email;
        qry.ParamByName('senha').Value := senha;
        qry.Active := true;

        Result := qry.ToJSONObject;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.InserirUsuario(nome, email, senha: string): TJsonObject;
var
    qry: TFDQuery;
begin
    if (Length(senha) < 5) then
        raise Exception.Create('A senha deve conter pelo menos 5 caracteres');

    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('insert into usuario_admin(nome, email, senha)');
        qry.SQL.Add('values(:nome, :email, :senha);');
        qry.SQL.Add('select last_insert_rowid() as id_usuario'); // SQLite...
        //qry.SQL.Add('returning id_usuario'); // Firebird...
        qry.ParamByName('nome').Value := nome;
        qry.ParamByName('email').Value := email;
        qry.ParamByName('senha').Value := senha;
        qry.Active := true;

        Result := qry.ToJSONObject; //{"id_usuario": 123}

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarPedidos(dt_de, dt_ate, status: string): TJsonArray;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('select p.*, s.descricao as descr_status, s.cor as cor_status');
        qry.SQL.Add('from pedido p');
        qry.SQL.Add('join pedido_status s on (s.status = p.status)');

        qry.SQL.Add('where p.id_pedido > 0');

        if (dt_de <> '') then
        begin
            qry.SQL.Add('and p.dt_pedido >= :dt_de');
            qry.ParamByName('dt_de').Value := dt_de; // yyyy-mm-dd
        end;

        if (dt_ate <> '') then
        begin
            qry.SQL.Add('and p.dt_pedido < date(:dt_ate, ''+1 day'')');
            qry.ParamByName('dt_ate').Value := dt_ate; // yyyy-mm-dd
        end;

        if (status <> '') then
        begin
            qry.SQL.Add('and p.status = :status');
            qry.ParamByName('status').Value := status;
        end;

        qry.SQL.Add('order by p.id_pedido desc');
        qry.Active := true;

        Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarPedidoById(id_pedido: integer): TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('select p.*, s.descricao as descr_status, s.cor as cor_status ');
        qry.SQL.Add('from pedido p');
        qry.SQL.Add('join pedido_status s on (s.status = p.status)');
        qry.SQL.Add('where p.id_pedido = :id_pedido');
        qry.ParamByName('id_pedido').Value := id_pedido;
        qry.Active := true;

        Result := qry.ToJSONObject;

        // Busca itens do pedido...
        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('select i.id_item, i.id_produto, p.nome, i.qtd, i.vl_unitario, ');
        qry.SQL.Add('i.vl_total, i.obs, ');
        qry.SQL.Add('''' + URL_SERVER + ''' || p.foto as foto');
        qry.SQL.Add('from pedido_item i');
        qry.SQL.Add('join produto p on (p.id_produto = i.id_produto)');
        qry.SQL.Add('where i.id_pedido = :id_pedido');
        qry.ParamByName('id_pedido').Value := id_pedido;
        qry.Active := true;

        Result.AddPair('itens', qry.ToJSONArray);

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.EditarStatusPedido(id_pedido: integer;
                                      status: string): TJsonObject;
var
    qry: TFDQuery;
begin
    if (status = '') then
        raise Exception.Create('Informe o status');

    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('update pedido set status = :status');
        qry.SQL.Add('where id_pedido = :id_pedido;');
        qry.ParamByName('status').Value := status;
        qry.ParamByName('id_pedido').Value := id_pedido;
        qry.ExecSQL;

        {"id_pedido": 123}

        Result := TJsonObject.Create(TJSONPair.Create('id_pedido', id_pedido));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarCategorias(): TJsonArray;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('select *');
        qry.SQL.Add('from produto_categoria');
        qry.SQL.Add('order by ordem');
        qry.Active := true;

        Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarCategoriaById(id_categoria: integer): TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('select *');
        qry.SQL.Add('from produto_categoria');
        qry.SQL.Add('where id_categoria = :id_categoria');
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.Active := true;

        Result := qry.ToJSONObject;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.InserirCategoria(categoria: string): TJsonObject;
var
    qry: TFDQuery;
    ordem: integer;
begin
    if (categoria = '') then
        raise Exception.Create('Informe a descrição');

    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        // Calcular a ordem...
        qry.SQL.Add('select count(*) as cont from produto_categoria');
        qry.Active := true;
        ordem := qry.FieldByName('cont').AsInteger + 1;

        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('insert into produto_categoria(categoria, ordem)');
        qry.SQL.Add('values(:categoria, :ordem);');
        qry.SQL.Add('select last_insert_rowid() as id_categoria'); // SQLite...
        qry.ParamByName('categoria').Value := categoria;
        qry.ParamByName('ordem').Value := ordem;
        qry.Active := true;

        Result := qry.ToJSONObject;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.EditarCategoria(id_categoria: integer;
                                   categoria: string): TJsonObject;
var
    qry: TFDQuery;
begin
    if (categoria = '') then
        raise Exception.Create('Informe a descrição');

    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('update produto_categoria set categoria = :categoria');
        qry.SQL.Add('where id_categoria = :id_categoria;');
        qry.ParamByName('categoria').Value := categoria;
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.ExecSQL;

        Result := TJsonObject.Create(TJSONPair.Create('id_categoria', id_categoria));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ExcluirCategoria(id_categoria: integer): TJsonObject;
var
    qry: TFDQuery;
    ordem: integer;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        // Consiste se categoria possui produto...
        qry.SQL.Add('select * from produto');
        qry.SQL.Add('where id_categoria = :id_categoria;');
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.Active := true;

        if qry.RecordCount > 0 then
            raise Exception.Create('Categoria não pode ser excluída pois possui produtos cadastrados');


        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('select ordem from produto_categoria');
        qry.SQL.Add('where id_categoria = :id_categoria;');
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.Active := true;
        ordem := qry.FieldByName('ordem').AsInteger;

        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('delete from produto_categoria');
        qry.SQL.Add('where id_categoria = :id_categoria;');
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.ExecSQL;

        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('update produto_categoria set ordem = ordem - 1');
        qry.SQL.Add('where ordem > :ordem');
        qry.ParamByName('ordem').Value := ordem;
        qry.ExecSQL;

        Result := TJsonObject.Create(TJSONPair.Create('id_categoria', id_categoria));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.OrdemCategoriaUp(id_categoria: integer): TJsonObject;
var
    qry: TFDQuery;
    ordem: integer;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;


        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('select ordem from produto_categoria');
        qry.SQL.Add('where id_categoria = :id_categoria;');
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.Active := true;
        ordem := qry.FieldByName('ordem').AsInteger;

        if ordem > 1 then
        begin
            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('update produto_categoria set ordem = ordem + 1');
            qry.SQL.Add('where ordem = :ordem;');
            qry.ParamByName('ordem').Value := ordem - 1;
            qry.ExecSQL;

            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('update produto_categoria set ordem = ordem - 1');
            qry.SQL.Add('where id_categoria = :id_categoria;');
            qry.ParamByName('id_categoria').Value := id_categoria;
            qry.ExecSQL;
        end;

        Result := TJsonObject.Create(TJSONPair.Create('id_categoria', id_categoria));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.OrdemCategoriaDown(id_categoria: integer): TJsonObject;
var
    qry: TFDQuery;
    ordem, cont: integer;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('select count(*) as cont from produto_categoria');
        qry.Active := true;
        cont := qry.FieldByName('cont').AsInteger;


        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('select ordem from produto_categoria');
        qry.SQL.Add('where id_categoria = :id_categoria;');
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.Active := true;
        ordem := qry.FieldByName('ordem').AsInteger;


        if (ordem < cont) then
        begin
            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('update produto_categoria set ordem = ordem - 1');
            qry.SQL.Add('where ordem = :ordem;');
            qry.ParamByName('ordem').Value := ordem + 1;
            qry.ExecSQL;

            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('update produto_categoria set ordem = ordem + 1');
            qry.SQL.Add('where id_categoria = :id_categoria;');
            qry.ParamByName('id_categoria').Value := id_categoria;
            qry.ExecSQL;
        end;

        Result := TJsonObject.Create(TJSONPair.Create('id_categoria', id_categoria));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarProdutos(id_categoria: integer): TJsonArray;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('select id_produto, nome, descricao, preco, id_categoria, ordem,');
        qry.SQL.Add('''' + URL_SERVER + ''' || foto as foto');
        qry.SQL.Add('from produto');

        if id_categoria > 0 then
        begin
            qry.SQL.Add('where id_categoria = :id_categoria');
            qry.ParamByName('id_categoria').Value := id_categoria;
        end;

        qry.SQL.Add('order by ordem');
        qry.Active := true;

        Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarProdutoById(id_produto: integer): TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;
        qry.SQL.Add('select p.id_produto, p.nome, p.descricao, p.preco, p.id_categoria, p.ordem,');
        qry.SQL.Add('''' + URL_SERVER + ''' || p.foto as foto, c.categoria');
        qry.SQL.Add('from produto p');
        qry.SQL.Add('join produto_categoria c on (c.id_categoria = p.id_categoria)');
        qry.SQL.Add('where p.id_produto = :id_produto');
        qry.ParamByName('id_produto').Value := id_produto;
        qry.Active := true;

        Result := qry.ToJSONObject;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.InserirProduto(nome, descricao: string;
                                  preco: double;
                                  id_categoria: integer): TJsonObject;
var
    qry: TFDQuery;
    ordem: integer;
begin
    if (id_categoria < 1) then
        raise Exception.Create('Informe a categoria do produto');

    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;


        // Calcula a ordem...
        qry.SQL.Add('select * from produto where id_categoria=:id_categoria');
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.Active := true;
        ordem := qry.RecordCount + 1;


        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('insert into produto(nome, descricao, preco, id_categoria, ordem)');
        qry.SQL.Add('values(:nome, :descricao, :preco, :id_categoria, :ordem);');
        qry.SQL.Add('select last_insert_rowid() as id_produto'); // SQLite...
        //qry.SQL.Add('returning id_usuario'); // Firebird...
        qry.ParamByName('nome').Value := nome;
        qry.ParamByName('descricao').Value := descricao;
        qry.ParamByName('preco').Value := preco;
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.ParamByName('ordem').Value := ordem;
        qry.Active := true;

        Result := qry.ToJSONObject; //{"id_produto": 123}

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.EditarProduto(id_produto: integer;
                                 nome, descricao: string;
                                 preco: double;
                                 id_categoria: integer): TJsonObject;
var
    qry: TFDQuery;
begin
    if (id_produto < 1) then
        raise Exception.Create('Informe o código do produto');
    if (id_categoria < 1) then
        raise Exception.Create('Informe a categoria do produto');

    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;


        qry.SQL.Add('update produto set nome=:nome, descricao=:descricao,');
        qry.SQL.Add('preco=:preco, id_categoria=:id_categoria');
        qry.SQL.Add('where id_produto=:id_produto');

        qry.ParamByName('id_produto').Value := id_produto;
        qry.ParamByName('nome').Value := nome;
        qry.ParamByName('descricao').Value := descricao;
        qry.ParamByName('preco').Value := preco;
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.ExecSQL;

        Result := TJSONObject.Create(TJSONPair.Create('id_produto', id_produto));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ExcluirProduto(id_produto: integer): TJsonObject;
var
    qry: TFDQuery;
begin
    if (id_produto < 1) then
        raise Exception.Create('Informe o código do produto');

    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('select * from pedido_item where id_produto=:id_produto;');
        qry.ParamByName('id_produto').Value := id_produto;
        qry.Active := true;

        if qry.RecordCount > 0 then
            raise Exception.Create('O produto não pode ser removido porque está cadastrado em um pedido');


        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('delete from produto where id_produto=:id_produto;');
        qry.ParamByName('id_produto').Value := id_produto;
        qry.ExecSQL;

        Result := TJSONObject.Create(TJSONPair.Create('id_produto', id_produto));

    finally
        FreeAndNil(qry);
    end;
end;

procedure TDmGlobal.EditarFoto(id_produto: integer; arq_foto: string);
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('update produto set foto = :foto where id_produto = :id_produto');
        //qry.ParamByName('foto').Value := URL_SERVER + arq_foto;
        qry.ParamByName('foto').Value := arq_foto;
        qry.ParamByName('id_produto').Value := id_produto;
        qry.ExecSQL;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.OrdemProdutoUp(id_produto: integer): TJsonObject;
var
    qry: TFDQuery;
    ordem, id_categoria: integer;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;


        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('select ordem, id_categoria from produto');
        qry.SQL.Add('where id_produto = :id_produto;');
        qry.ParamByName('id_produto').Value := id_produto;
        qry.Active := true;
        ordem := qry.FieldByName('ordem').AsInteger;
        id_categoria := qry.FieldByName('id_categoria').AsInteger;

        if ordem > 1 then
        begin
            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('update produto set ordem = ordem + 1');
            qry.SQL.Add('where id_categoria = :id_categoria and ordem = :ordem;');
            qry.ParamByName('id_categoria').Value := id_categoria;
            qry.ParamByName('ordem').Value := ordem - 1;
            qry.ExecSQL;

            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('update produto set ordem = ordem - 1');
            qry.SQL.Add('where id_produto = :id_produto;');
            qry.ParamByName('id_produto').Value := id_produto;
            qry.ExecSQL;
        end;

        Result := TJsonObject.Create(TJSONPair.Create('id_produto', id_categoria));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.OrdemProdutoDown(id_produto: integer): TJsonObject;
var
    qry: TFDQuery;
    ordem, id_categoria, cont: integer;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('select ordem, id_categoria from produto');
        qry.SQL.Add('where id_produto = :id_produto;');
        qry.ParamByName('id_produto').Value := id_produto;
        qry.Active := true;
        ordem := qry.FieldByName('ordem').AsInteger;
        id_categoria := qry.FieldByName('id_categoria').AsInteger;

        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('select count(*) as cont from produto where id_categoria=:id_categoria');
        qry.ParamByName('id_categoria').Value := id_categoria;
        qry.Active := true;
        cont := qry.FieldByName('cont').AsInteger;



        if (ordem < cont) then
        begin
            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('update produto set ordem = ordem - 1');
            qry.SQL.Add('where id_categoria=:id_categoria and ordem = :ordem;');
            qry.ParamByName('id_categoria').Value := id_categoria;
            qry.ParamByName('ordem').Value := ordem + 1;
            qry.ExecSQL;

            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('update produto set ordem = ordem + 1');
            qry.SQL.Add('where id_produto = :id_produto;');
            qry.ParamByName('id_produto').Value := id_produto;
            qry.ExecSQL;
        end;

        Result := TJsonObject.Create(TJSONPair.Create('id_produto', id_categoria));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.EditarConfig(vl_entrega: double): TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('update config set vl_entrega=:vl_entrega');
        qry.ParamByName('vl_entrega').Value := vl_entrega;
        qry.ExecSQL;

        Result := TJSONObject.Create(TJsonPair.Create('vl_entrega', vl_entrega));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarConfig(): TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := conn;

        qry.SQL.Add('select * from config');
        qry.Active := true;

        Result := qry.ToJSONObject;

    finally
        FreeAndNil(qry);
    end;
end;


end.
