unit DataModule.Global;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.VCLUI.Wait, Data.DB,
  FireDAC.Comp.Client, DataSet.Serialize.Config, DataSet.Serialize,
  System.JSON, FireDAC.DApt;

type
  TDmGlobal = class(TDataModule)
    Conn: TFDConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure CarregarConfigDBSQLite(Connection: TFDConnection);
  public
    function Login(email, senha: string): TJsonObject;
    function InserirUsuario(nome, email, senha, cidade: string): TJsonObject;
    function ListarServicos(id_assinante: integer): TJsonArray;
    function ListarPrestadores(id_servico: integer): TJsonArray;
    function ListarHorarios(id_servico, id_prestador: integer;
      dt: string): TJsonArray;
    function ListarReservas(id_usuario: integer): TJsonArray;
    function InserirReserva(id_assinante, id_usuario, id_servico,
      id_prestador: integer; dt, hora: string): TJsonObject;
    function ExcluirReserva(id_reserva: integer): TJsonObject;
    function ListarAssinantes(cidade: string): TJsonArray;
  end;

var
  DmGlobal: TDmGlobal;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDmGlobal.CarregarConfigDBSQLite(Connection: TFDConnection);
begin
    Connection.DriverName := 'SQLite';

    with Connection.Params do
    begin
        Clear;
        Add('DriverID=SQLite');

        // Mudar para sua pasta!!!!!!!!
        if FileExists('E:\BarberPro\Database\banco.db') then
            Add('Database=E:\BarberPro\Database\banco.db')
        else
            Add('Database=D:\BarberPro\Fontes\Servidor\Database\banco.db');
        //-----------------------------

        Add('User_Name=');
        Add('Password=');
        Add('Port=');
        Add('Server=');
        Add('Protocol=');
        Add('LockingMode=Normal');
    end;
end;

procedure TDmGlobal.DataModuleCreate(Sender: TObject);
begin
    TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
    TDataSetSerializeConfig.GetInstance.Import.DecimalSeparator := '.';

    CarregarConfigDBSQLite(Conn);

    Conn.Connected := true;
end;

function TDmGlobal.Login(email, senha: string): TJsonObject;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('select id_usuario, nome, email, cidade');
      qry.SQL.Add('from usuario');
      qry.SQL.Add('where email=:email and senha=:senha');
      qry.ParamByName('email').Value := email;
      qry.ParamByName('senha').Value := senha;
      qry.Active := true;

      Result := qry.ToJSONObject;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.InserirUsuario(nome, email, senha, cidade: string): TJsonObject;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('select * from usuario where email = :email');
      qry.ParamByName('email').Value := email;
      qry.Active := true;

      if qry.RecordCount > 0 then
        raise Exception.Create('Já existe uma conta criada com esse e-mail. Tente usar outro e-mail.');


      qry.Active := false;
      qry.SQL.Clear;
      qry.SQL.Add('insert into usuario(nome, email, senha, cidade)');
      qry.SQL.Add('values(:nome, :email, :senha, :cidade);');
      qry.SQL.Add('select last_insert_rowid() as id_usuario'); // SQLite
      //qry.SQL.Add('returning id_usuario'); // Firebird
      qry.ParamByName('nome').Value := nome;
      qry.ParamByName('email').Value := email;
      qry.ParamByName('senha').Value := senha;
      qry.ParamByName('cidade').Value := cidade;
      qry.Active := true;

      Result := qry.ToJSONObject;
      Result.AddPair('email', email);
      Result.AddPair('nome', nome);
      Result.AddPair('cidade', cidade);

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarServicos(id_assinante: integer): TJsonArray;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('select * from servico');
      qry.SQL.Add('where id_assinante = :id_assinante');
      qry.SQL.Add('order by descricao');
      qry.ParamByName('id_assinante').Value := id_assinante;
      qry.Active := true;

      Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarPrestadores(id_servico: integer): TJsonArray;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('select s.*, p.nome from servico_prestador s');
      qry.SQL.Add('join prestador p on (p.id_prestador = s.id_prestador)');
      qry.SQL.Add('where s.id_servico = :id_servico');
      qry.ParamByName('id_servico').Value := id_servico;
      qry.SQL.Add('order by s.id_serv_prestador');
      qry.Active := true;

      Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarHorarios(id_servico, id_prestador: integer;
                                  dt: string): TJsonArray;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('select h.*');
      qry.SQL.Add('from horario h');
      qry.SQL.Add('where h.id_prestador = :id_prestador');
      qry.SQL.Add('and h.id_servico = :id_servico');
      qry.SQL.Add('and h.horario not in (select r.hora_reserva');
      qry.SQL.Add('                    from reserva r');
      qry.SQL.Add('                    where r.id_prestador = h.id_prestador');
      qry.SQL.Add('                    and    r.id_servico = h.id_servico');
      qry.SQL.Add('                    and    r.dt_reserva = :dt');
      qry.SQL.Add('                    )');
      qry.SQL.Add('order by h.horario');

      qry.ParamByName('id_prestador').Value := id_prestador;
      qry.ParamByName('id_servico').Value := id_servico;
      qry.ParamByName('dt').Value := dt; // yyyy-mm-dd

      qry.Active := true;

      Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarReservas(id_usuario: integer): TJsonArray;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('select r.*, s.descricao, p.nome, a.empresa');
      qry.SQL.Add('from reserva r');
      qry.SQL.Add('join assinante a on (a.id_assinante = r.id_assinante)');
      qry.SQL.Add('join servico s on (s.id_servico = r.id_servico)');
      qry.SQL.Add('join prestador p on (p.id_prestador = r.id_prestador)');
      qry.SQL.Add('where r.id_usuario = :id_usuario');
      qry.SQL.Add('order by r.dt_reserva desc');

      qry.ParamByName('id_usuario').Value := id_usuario;

      qry.Active := true;

      Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.InserirReserva(id_assinante, id_usuario, id_servico, id_prestador: integer;
                                  dt, hora: string): TJsonObject;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('insert into reserva(id_assinante, id_usuario, id_servico, id_prestador, dt_reserva, hora_reserva)');
      qry.SQL.Add('values(:id_assinante, :id_usuario, :id_servico, :id_prestador, :dt_reserva, :hora_reserva);');
      qry.SQL.Add('select last_insert_rowid() as id_reserva'); // SQLite
      //qry.SQL.Add('returning id_reserva'); // Firebird

      qry.ParamByName('id_assinante').Value := id_assinante;
      qry.ParamByName('id_usuario').Value := id_usuario;
      qry.ParamByName('id_servico').Value := id_servico;
      qry.ParamByName('id_prestador').Value := id_prestador;
      qry.ParamByName('dt_reserva').Value := dt;
      qry.ParamByName('hora_reserva').Value := hora;
      qry.Active := true;

      Result := qry.ToJSONObject;

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ExcluirReserva(id_reserva: integer): TJsonObject;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('delete from reserva where id_reserva = :id_reserva;');
      qry.ParamByName('id_reserva').Value := id_reserva;
      qry.ExecSQL;

      // {"id_reserva": 123}
      Result := TJSONObject.Create(TJsonPair.Create('id_reserva', id_reserva));

    finally
        FreeAndNil(qry);
    end;
end;

function TDmGlobal.ListarAssinantes(cidade: string): TJsonArray;
var
  qry: TFDQuery;
begin
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      qry.SQL.Add('select a.* from assinante a');
      qry.SQL.Add('where a.cidade = :cidade');
      qry.SQL.Add('order by a.empresa');

      qry.ParamByName('cidade').Value := cidade;
      qry.Active := true;

      Result := qry.ToJSONArray;

    finally
        FreeAndNil(qry);
    end;
end;


end.
