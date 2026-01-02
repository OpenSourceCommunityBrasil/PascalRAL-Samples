unit DataModule.Global;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.FMXUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  DataSet.Serialize.Config, DataSet.Serialize, System.JSON,
  FireDAC.DApt, uFunctions;

type
  TDm = class(TDataModule)
    Conn: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
    procedure ConnBeforeConnect(Sender: TObject);
  private
    procedure CarregarConfigDB(Connection: TFDConnection);
    function InserirUsuario(fone: string): TJsonObject;

    { Private declarations }
  public
    function ListarConfig: TJsonObject;
    function ListarCardapios: TJsonArray;
    function ListarPedidos(id_usuario: integer): TJsonArray;
    function InserirPedido(id_usuario: integer;
                           endereco, fone: string;
                           vl_subtotal, vl_entrega, vl_total: double;
                           itens: TJSONArray): TJsonObject;
    function Login(fone: string): TJsonObject;
  end;

var
  Dm: TDm;



implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDm.CarregarConfigDB(Connection: TFDConnection);
begin
    Connection.DriverName := 'SQLite';

    with Connection.Params do
    begin
        Clear;
        Add('DriverID=SQLite');

        // Mudar para sua pasta!!!!!!!!
        Add('Database=D:\99Coders\CursoFood\banco.db');
        //Add('Database=E:\Food\DB\banco.db');

        Add('User_Name=');
        Add('Password=');
        Add('Port=');
        Add('Server=');
        Add('Protocol=');
        Add('LockingMode=Normal');
    end;
end;

procedure TDm.ConnBeforeConnect(Sender: TObject);
begin
    CarregarConfigDB(Conn);
end;

procedure TDm.DataModuleCreate(Sender: TObject);
begin
    TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
    TDataSetSerializeConfig.GetInstance.Import.DecimalSeparator := '.';

    Conn.Connected := true;
end;

function TDm.ListarConfig: TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := Conn;

        qry.SQL.Add('select * from config');
        qry.Active := true;

        Result := qry.ToJSONObject; //  {"vl_entrega": 3}

    finally
        FreeAndNil(qry);
    end;
end;

function TDm.ListarCardapios: TJsonArray;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := Conn;

        qry.SQL.Add('select p.id_produto, p.nome, p.descricao, p.preco, p.id_categoria, p.ordem, c.categoria,');
        qry.SQL.Add('''' + URL_SERVER_FOTO + ''' || p.foto as foto');
        qry.SQL.Add('from produto p');
        qry.SQL.Add('join produto_categoria c on (c.id_categoria = p.id_categoria)');
        qry.SQL.Add('order by c.ordem, p.ordem');
        qry.Active := true;

        Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;

function TDm.ListarPedidos(id_usuario: integer): TJsonArray;
var
    qry: TFDQuery;
    i: integer;
    ped: TJSONObject;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := Conn;

        qry.SQL.Add('select id_pedido, id_usuario, endereco, fone, vl_subtotal, vl_entrega,');
        qry.SQL.Add('vl_total, status, strftime(''%d/%m/%Y %H:%M'', dt_pedido) as dt_pedido');
        qry.SQL.Add('from pedido');
        qry.SQL.Add('where id_usuario = :id_usuario');
        qry.SQL.Add('order by id_pedido desc');
        qry.ParamByName('id_usuario').Value := id_usuario;
        qry.Active := true;

        Result := qry.ToJSONArray;

        // Acrescentar os itens...
        for i := 0 to Result.Size - 1 do
        begin
            ped := TJSONObject(Result[i]);

            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('select i.id_produto, i.qtd, i.vl_unitario, i.vl_total, i.obs,');
            qry.SQL.Add('       p.nome, p.descricao,');
            qry.SQL.Add('''' + URL_SERVER_FOTO + ''' || p.foto as foto');
            qry.SQL.Add('from pedido_item i');
            qry.SQL.Add('join produto p on (p.id_produto = i.id_produto)');
            qry.SQL.Add('where i.id_pedido = :id_pedido');
            qry.SQL.Add('order by i.id_item');
            qry.ParamByName('id_pedido').Value := ped.GetValue<integer>('id_pedido', 0);
            qry.Active := true;

            ped.AddPair('itens', qry.ToJSONArray);
        end;

    finally
        FreeAndNil(qry);
    end;
end;


function TDm.InserirPedido(id_usuario: integer;
                           endereco, fone: string;
                           vl_subtotal, vl_entrega, vl_total: double;
                           itens: TJSONArray): TJsonObject;
var
    qry: TFDQuery;
    i, id_pedido: integer;
    item: TJSONObject;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := Conn;

        qry.SQL.Add('insert into pedido(id_usuario, endereco, fone, vl_subtotal, ');
        qry.SQL.Add('vl_entrega, vl_total, dt_pedido, status)');
        qry.SQL.Add('values(:id_usuario, :endereco, :fone, :vl_subtotal, ');
        qry.SQL.Add(':vl_entrega, :vl_total, :dt_pedido, :status);');
        qry.SQL.Add('select last_insert_rowid() as id_pedido ');

        qry.ParamByName('id_usuario').Value := id_usuario;
        qry.ParamByName('endereco').Value := endereco;
        qry.ParamByName('fone').Value := fone;
        qry.ParamByName('vl_subtotal').Value := vl_subtotal;
        qry.ParamByName('vl_entrega').Value := vl_entrega;
        qry.ParamByName('vl_total').Value := vl_total;
        qry.ParamByName('dt_pedido').Value := FormatDateTime('yyyy-mm-dd HH:nn:ss', now);
        qry.ParamByName('status').Value :=  'A';
        qry.Active := true;
        Result := qry.ToJSONObject;

        // Tratamento dos itens...
        id_pedido := qry.FieldByName('id_pedido').AsInteger;

        for i := 0 to itens.Size - 1 do
        begin
            item := TJsonObject(itens[i]);

            qry.Active := false;
            qry.SQL.Clear;
            qry.SQL.Add('insert into pedido_item(id_pedido, id_produto, qtd, vl_unitario, vl_total, obs)');
            qry.SQL.Add('values(:id_pedido, :id_produto, :qtd, :vl_unitario, :vl_total, :obs)');

            qry.ParamByName('id_pedido').Value := id_pedido;
            qry.ParamByName('id_produto').Value := item.GetValue<integer>('id_produto', 0);
            qry.ParamByName('qtd').Value := item.GetValue<double>('qtd', 0);
            qry.ParamByName('vl_unitario').Value := item.GetValue<double>('vl_unitario', 0);
            qry.ParamByName('vl_total').Value := item.GetValue<double>('vl_total', 0);
            qry.ParamByName('obs').Value := item.GetValue<string>('obs', '');

            qry.ExecSQL;

        end;

        // Atualiza dados do usuario...
        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('update usuario set endereco=:endereco, fone=:fone');
        qry.SQL.Add('where id_usuario = :id_usuario');
        qry.ParamByName('endereco').Value := endereco;
        qry.ParamByName('fone').Value := fone;
        qry.ParamByName('id_usuario').Value := id_usuario;
        qry.ExecSQL;

    finally
        FreeAndNil(qry);
    end;
end;


function TDm.InserirUsuario(fone: string): TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := Conn;
        qry.SQL.Add('insert into usuario (fone) values(:fone);');
        qry.SQL.Add('select last_insert_rowid() as id_usuario ');
        qry.ParamByName('fone').Value := fone;
        qry.Active := true;

        Result := qry.ToJSONObject;
        Result.AddPair('fone', fone);
        Result.AddPair('endereco', '');

    finally
        FreeAndNil(qry);
    end;
end;

function TDm.Login(fone: string): TJsonObject;
var
    qry: TFDQuery;
begin
    try
        qry := TFDQuery.Create(nil);
        qry.Connection := Conn;
        qry.SQL.Add('select * from usuario where fone = :fone');
        qry.ParamByName('fone').Value := fone;
        qry.Active := true;

        if qry.RecordCount > 0 then
            Result := qry.ToJSONObject
        else
            Result := InserirUsuario(fone);

        //   {"id_usuario": 1, "fone": "1100000000", "endereco": "Av. Brasil"}

    finally
        FreeAndNil(qry);
    end;
end;

end.
