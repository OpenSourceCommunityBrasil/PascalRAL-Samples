unit Dm.Global;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.FMXUI.Wait, FireDAC.Phys.IBBase, Data.DB,
  FireDAC.Comp.Client, System.JSON, DataSet.Serialize,
  FireDAC.DApt, System.DateUtils;

type
  TDmGlobal = class(TDataModule)
    Conn: TFDConnection;
    FDPhysFBDriverLink: TFDPhysFBDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    // Usuarios --------
    function Login(email, senha: string): TJsonObject;
    function InserirUsuario(nome, email, senha: string): TJsonObject;
    procedure EditarSenha(id_usuario: integer; senha: string);
    procedure EditarUsuario(id_usuario: integer; nome, email: string);
    function ListarUsuarioId(id_usuario: integer): TJsonObject;
    function ListarUsuarioByEmail(email: string): TJsonObject;

    // Categorias --------
    function ListarCategorias(id_usuario: integer): TJsonArray;
    function ListarCategoriaId(id_usuario, id_categoria: integer): TJsonObject;
    function InserirCategoria(id_usuario: integer;
                              descricao: string): TJsonObject;
    procedure EditarCategoria(id_usuario, id_categoria: integer;
                              descricao: string);
    procedure ExcluirCategoria(id_usuario, id_categoria: integer);

    // Lancamentos --------
    function ListarLancamentos(id_usuario, id_categoria: integer;
                               dt_de, dt_ate: string): TJsonArray;
    procedure EditarLancamento(id_usuario, id_lancamento, id_categoria: integer;
                               descricao, tipo, dt_lancamento: string; valor: double);
    procedure ExcluirLancamento(id_usuario, id_lancamento: integer);
    function InserirLancamento(id_usuario, id_categoria: integer; descricao,
                               tipo, dt_lancamento: string; valor: double): TJsonObject;
    function ListarLancamentoId(id_usuario,
                                id_lancamento: integer): TJsonObject;

    // Webhooks ---------
    procedure WebhookAssinaturaCriada(id_usuario: integer; StripeCustomerID,
                                      StripeAssinaturaID: string; VlAssinatura: double);
    procedure WebhookNovoPagamento(StripeCustomerID: string);
    procedure CancelarAssinatura(id_usuario: integer);

    // Automacao (n8n) ---------
    function ListarUsuarioFone(whatsapp: string): TJsonObject;
  end;

var
  DmGlobal: TDmGlobal;

Const
  NUM_DIAS_DEMONSTRACAO = 7;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDmGlobal.DataModuleCreate(Sender: TObject);
begin
  if FileExists('E:\Poupei\BANCO.FDB') then
    Conn.Params.Add('Database=E:\Poupei\BANCO.FDB')
  else
    Conn.Params.Add('Database=D:\Poupei\Database\BANCO.FDB');

  FDPhysFBDriverLink.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_3_0\fbclient.dll';
end;

// CATEGORIAS ------

function TDmGlobal.ListarCategorias(id_usuario: integer): TJsonArray;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select * from categoria ');
    qry.SQL.Add('where id_usuario = :id_usuario');
    qry.SQL.Add('order by descricao');

    qry.ParamByName('id_usuario').Value := id_usuario;

    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;

function TDmGlobal.ListarCategoriaId(id_usuario, id_categoria: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select * from categoria ');
    qry.SQL.Add('where id_categoria = :id_categoria and id_usuario = :id_usuario');

    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_categoria').Value := id_categoria;

    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDmGlobal.InserirCategoria(id_usuario: integer; descricao: string): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('insert into categoria(descricao, id_usuario)');
    qry.SQL.Add('values(:descricao, :id_usuario)');
    qry.SQL.Add('returning id_categoria');

    qry.ParamByName('descricao').Value := descricao;
    qry.ParamByName('id_usuario').Value := id_usuario;

    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDmGlobal.EditarCategoria(id_usuario, id_categoria: integer; descricao: string);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('update categoria set descricao = :descricao');
    qry.SQL.Add('where id_categoria = :id_categoria and id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_categoria').Value := id_categoria;
    qry.ParamByName('descricao').Value := descricao;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDmGlobal.ExcluirCategoria(id_usuario, id_categoria: integer);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('delete from categoria ');
    qry.SQL.Add('where id_categoria = :id_categoria and id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_categoria').Value := id_categoria;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

// USUARIOS ------

function TDmGlobal.Login(email, senha: string): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select id_usuario, nome, email, dt_cadastro, status,');
    qry.SQL.Add('stripe_assinatura_id, stripe_cliente_id, vl_assinatura, ');
    qry.SQL.Add('dt_termino_acesso, current_date as dt_referencia');
    qry.SQL.Add('from usuario ');
    qry.SQL.Add('where email = :email and senha = :senha');

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
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('insert into usuario(nome, email, senha, dt_cadastro, status, dt_termino_acesso)');
    qry.SQL.Add('values(:nome, :email, :senha, current_timestamp, :status, :dt_termino_acesso)');
    qry.SQL.Add('returning id_usuario, nome, email, dt_cadastro, status,');
    qry.SQL.Add('stripe_assinatura_id, stripe_cliente_id, vl_assinatura,');
    qry.SQL.Add('dt_termino_acesso, current_date as dt_referencia');

    qry.ParamByName('nome').Value := nome;
    qry.ParamByName('email').Value := email;
    qry.ParamByName('senha').Value := senha;
    qry.ParamByName('status').Value := 'TESTE';
    qry.ParamByName('dt_termino_acesso').Value :=
              FormatDateTime('yyyy-mm-dd', date + NUM_DIAS_DEMONSTRACAO);


    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDmGlobal.EditarSenha(id_usuario: integer; senha: string);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('update usuario set senha = :senha where id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('senha').Value := senha;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

function TDmGlobal.ListarUsuarioId(id_usuario: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select id_usuario, nome, email, dt_cadastro, status,');
    qry.SQL.Add('stripe_assinatura_id, stripe_cliente_id, vl_assinatura,');
    qry.SQL.Add('dt_termino_acesso, current_date as dt_referencia');
    qry.SQL.Add('from usuario ');
    qry.SQL.Add('where id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDmGlobal.ListarUsuarioByEmail(email: string): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select id_usuario, nome, email, dt_cadastro, status from usuario ');
    qry.SQL.Add('where email = :email');
    qry.ParamByName('email').Value := email;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDmGlobal.EditarUsuario(id_usuario: integer; nome, email: string);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('update usuario set nome=:nome, email=:email ');
    qry.SQL.Add('where id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('nome').Value := nome;
    qry.ParamByName('email').Value := email;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

// LANCAMENTOS ------

function TDmGlobal.ListarLancamentos(id_usuario, id_categoria: integer;
                                     dt_de, dt_ate: string): TJsonArray;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select l.*, coalesce(c.descricao, ''Sem Categoria'') as categoria from lancamento l ');
    qry.SQL.Add('left join categoria c on (c.id_categoria = l.id_categoria and c.id_usuario = l.id_usuario)');
    qry.SQL.Add('where l.id_usuario = :id_usuario');

    if id_categoria > 0 then
    begin
      qry.SQL.Add('and l.id_categoria = :id_categoria');
      qry.ParamByName('id_categoria').Value := id_categoria;
    end;

    if dt_de <> '' then
    begin
      qry.SQL.Add('and l.dt_lancamento >= :dt_de');
      qry.ParamByName('dt_de').Value := dt_de;
    end;

    if dt_ate <> '' then
    begin
      qry.SQL.Add('and l.dt_lancamento <= :dt_ate');
      qry.ParamByName('dt_ate').Value := dt_ate;
    end;

    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;

function TDmGlobal.ListarLancamentoId(id_usuario, id_lancamento: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select l.*, coalesce(c.descricao, ''Sem Categoria'') as categoria from lancamento l ');
    qry.SQL.Add('left join categoria c on (c.id_categoria = l.id_categoria and c.id_usuario = l.id_usuario)');
    qry.SQL.Add('where l.id_lancamento = :id_lancamento and l.id_usuario = :id_usuario');

    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_lancamento').Value := id_lancamento;

    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDmGlobal.InserirLancamento(id_usuario, id_categoria: integer;
                                     descricao, tipo, dt_lancamento: string;
                                     valor: double): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('insert into lancamento(descricao, valor, tipo, id_categoria, dt_lancamento, id_usuario)');
    qry.SQL.Add('values(:descricao, :valor, :tipo, :id_categoria, :dt_lancamento, :id_usuario)');
    qry.SQL.Add('returning id_lancamento');

    qry.ParamByName('descricao').Value := descricao;
    qry.ParamByName('valor').Value := valor;
    qry.ParamByName('tipo').Value := tipo;

    if id_categoria > 0 then
      qry.ParamByName('id_categoria').Value := id_categoria
    else
      qry.ParamByName('id_categoria').Clear;

    qry.ParamByName('dt_lancamento').Value := dt_lancamento;
    qry.ParamByName('id_usuario').Value := id_usuario;

    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDmGlobal.EditarLancamento(id_usuario, id_lancamento, id_categoria: integer;
                                     descricao, tipo, dt_lancamento: string;
                                     valor: double);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('update lancamento set descricao = :descricao, valor = :valor, tipo = :tipo,');
    qry.SQL.Add('id_categoria = :id_categoria, dt_lancamento = :dt_lancamento');
    qry.SQL.Add('where id_lancamento = :id_lancamento and id_usuario = :id_usuario');
    qry.ParamByName('descricao').Value := descricao;
    qry.ParamByName('valor').Value := valor;
    qry.ParamByName('tipo').Value := tipo;
    qry.ParamByName('id_categoria').Value := id_categoria;
    qry.ParamByName('dt_lancamento').Value := dt_lancamento;
    qry.ParamByName('id_lancamento').Value := id_lancamento;
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDmGlobal.ExcluirLancamento(id_usuario, id_lancamento: integer);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('delete from lancamento ');
    qry.SQL.Add('where id_lancamento = :id_lancamento and id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_lancamento').Value := id_lancamento;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;


// WEBHOOK ------

procedure TDmGlobal.WebhookAssinaturaCriada(id_usuario: integer;
                                            StripeCustomerID, StripeAssinaturaID: string;
                                            VlAssinatura: double);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('update usuario set stripe_cliente_id = :stripe_cliente_id, ');
    qry.SQL.Add('stripe_assinatura_id = :stripe_assinatura_id, vl_assinatura = :vl_assinatura');
    qry.SQL.Add('where id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('stripe_cliente_id').Value := StripeCustomerID;
    qry.ParamByName('stripe_assinatura_id').Value := StripeAssinaturaID;
    qry.ParamByName('vl_assinatura').Value := VlAssinatura;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDmGlobal.WebhookNovoPagamento(StripeCustomerID: string);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('update usuario set dt_termino_acesso = :dt_termino_acesso, status = :status ');
    qry.SQL.Add('where stripe_cliente_id = :stripe_cliente_id');
    qry.ParamByName('stripe_cliente_id').Value := StripeCustomerID;
    qry.ParamByName('dt_termino_acesso').Value := FormatDateTime('yyyy-mm-dd', IncMonth(date));
    qry.ParamByName('status').Value := 'ATIVO';
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDmGlobal.CancelarAssinatura(id_usuario: integer);
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('update usuario set status = :status, stripe_assinatura_id = :stripe_assinatura_id ');
    qry.SQL.Add('where id_usuario = :id_usuario');

    qry.ParamByName('stripe_assinatura_id').Value := '';
    qry.ParamByName('status').Value := 'INATIVO';
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;


// Automacao (n8n) ---------

function TDmGlobal.ListarUsuarioFone(whatsapp: string): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select id_usuario, nome, email, dt_cadastro, status,');
    qry.SQL.Add('stripe_assinatura_id, stripe_cliente_id, vl_assinatura,');
    qry.SQL.Add('dt_termino_acesso, current_date as dt_referencia');
    qry.SQL.Add('from usuario ');
    qry.SQL.Add('where whatsapp = :whatsapp');
    qry.ParamByName('whatsapp').Value := whatsapp;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;


end.
