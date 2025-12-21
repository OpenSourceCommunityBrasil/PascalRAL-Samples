unit DataModule.Global;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.FMXUI.Wait,
  FireDAC.Phys.FBDef, FireDAC.Phys.IBBase, FireDAC.Phys.FB, Data.DB,
  FireDAC.Comp.Client, DataSet.Serialize, DataSet.Serialize.Config,
  FireDAC.DApt, System.JSON;

type
  TDm = class(TDataModule)
    Conn: TFDConnection;
    FDPhysFBDriverLink: TFDPhysFBDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure PopularFilaCorrida(id_corrida: integer);
    procedure AceitarCorrida(id_fila, id_motorista, id_corrida: integer);
    procedure CancelarCorrida(id_motorista, id_corrida: integer);
    procedure EncerrarCorrida(id_fila, id_motorista, id_corrida: integer);
    procedure ExpirarCorrida(id_fila, id_motorista, id_corrida: integer);
    procedure IniciarCorrida(id_fila, id_motorista, id_corrida: integer);
    procedure EnviarMensagemWhatsApp(id_corrida: integer; status: string);


  public
    // Motorista --------
    function LoginMotorista(email, senha: string): TJsonObject;
    function InserirMotorista(nome, email, senha, placa: string): TJsonObject;
    function StatusMotorista(id_motorista: integer; status: string; lat,
                             long: double): TJsonObject;

    // Usuario --------
    function InserirUsuario(nome, whatsapp: string): TJsonObject;
    function ListarUsuario(whatsapp: string): TJsonObject;

    // Corridas --------
    function ListarCorridas(id_motorista: integer): TJsonArray;
    function InserirCorrida(nome, whatsapp, origem, destino: string;
                            vl_corrida: double): TJsonObject;
    function StatusCorrida(id_fila, id_motorista, id_corrida: integer;
                           status: string): TJsonObject;
    function AvaliarCorrida(id_motorista, id_corrida,
                            avaliacao: integer): TJsonObject;
    function ListarOfertas(id_motorista: integer): TJsonObject;
  end;

var
  Dm: TDm;

Const
  QTD_MOTORISTA_POR_FILA = 5;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDm.DataModuleCreate(Sender: TObject);
begin
  TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
  TDataSetSerializeConfig.GetInstance.Import.DecimalSeparator := '.';

  if FileExists('E:\Mototaxi\BANCO.FDB') then
    Conn.Params.Add('Database=E:\Mototaxi\BANCO.FDB')
  else
    Conn.Params.Add('Database=D:\Mototaxi\Database\BANCO.FDB');

  FDPhysFBDriverLink.VendorLib := 'C:\Program Files (x86)\Firebird\Firebird_3_0\fbclient.dll';
end;

// WhatsApp --------
procedure TDm.EnviarMensagemWhatsApp(id_corrida: integer; status: string);
var
  qry: TFDQuery;
  destinatario, msg: string;
  delay: integer;
  link_Preview: boolean;
begin
  qry := TFDQuery.Create(nil);
  try
    qry.Connection := Conn;

    qry.SQL.Add('select m.nome, u.whatsapp, m.placa');
    qry.SQL.Add('from corrida c ');
    qry.SQL.Add('join usuario u on (u.id_usuario = c.id_usuario)');
    qry.SQL.Add('join motorista m on (m.id_motorista = c.id_motorista)');
    qry.SQL.Add('where c.id_corrida = :id_corrida');
    qry.ParamByName('id_corrida').Value := id_corrida;
    qry.Active := true;

    destinatario := qry.FieldByName('whatsapp').AsString;
    delay := 0;
    link_Preview := false;


    // Monta texto da mensagem...
    if status = 'aceita' then
      msg := 'Sua corrida foi aceita pelo motorista ' + qry.FieldByName('nome').AsString +
             ' (placa da moto: ' + qry.FieldByName('placa').AsString + '). Aguarde no local combinado'

    else if status = 'encerrada' then
      msg := 'A corrida foi encerrada pelo motorista ' + qry.FieldByName('nome').AsString +
             '. Agradecemos por usar o app Mototaxi'

    else if status = 'cancelada' then
      msg := 'Lamento informar mas a corrida foi cancelada pelo motorista. Por favor, solicite uma nova corrida.';


    Conn.ExecSQL('insert into whatsapp(destinatario, mensagem, delay, link_preview, status) ' +
                 'values(:destinatario, :mensagem, :delay, :link_preview, :status) ',
                  [destinatario, msg, delay, link_preview, 'pendente']);
  finally
    FreeAndNil(qry);
  end;
end;

// Usuarios -------------
function TDm.ListarUsuario(whatsapp: string): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select id_usuario, nome, whatsapp');
    qry.SQL.Add('from usuario ');
    qry.SQL.Add('where whatsapp = :whatsapp');

    qry.ParamByName('whatsapp').Value := whatsapp;

    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.InserirUsuario(nome, whatsapp: string): TJsonObject;
var
  qry: TFDQuery;
  json: TJsonObject;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    // Verifica se usuario ja existe
    json := ListarUsuario(whatsapp);

    if json.Size > 0 then
      Result := json
    else
    begin
      qry.SQL.Add('insert into usuario(nome, whatsapp)');
      qry.SQL.Add('values(:nome, :whatsapp)');
      qry.SQL.Add('returning id_usuario, nome, whatsapp');

      qry.ParamByName('nome').Value := nome;
      qry.ParamByName('whatsapp').Value := whatsapp;

      qry.Active := true;

      Result := qry.ToJSONObject;
      FreeAndNil(json);
    end;

  finally
    FreeAndNil(qry);
  end;
end;

// Motoristas -------------
function TDm.LoginMotorista(email, senha: string): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select m.id_motorista, m.nome, m.email, m.status, m.placa,');
    qry.SQL.Add('  coalesce(f.id_fila, 0) id_fila, coalesce(f.id_corrida, 0) id_corrida, ');
    qry.SQL.Add('  c.origem, c.destino, coalesce(c.vl_corrida, 0) vl_corrida, ');
    qry.SQL.Add('  u.nome as nome_usuario, u.whatsapp, c.status as status_corrida, ');
    qry.SQL.Add('  coalesce(c.avaliacao, 0) avaliacao');
    qry.SQL.Add('from motorista m');
    qry.SQL.Add('left join corrida c on (c.id_corrida = m.id_corrida)');
    qry.SQL.Add('left join corrida_fila f on (f.id_corrida = c.id_corrida and f.id_motorista = m.id_motorista)');
    qry.SQL.Add('left join usuario u on (u.id_usuario = c.id_usuario)');
    qry.SQL.Add('where m.email = :email and m.senha = :senha');

    qry.ParamByName('email').Value := email;
    qry.ParamByName('senha').Value := senha;

    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.InserirMotorista(nome, email, senha, placa: string): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('insert into motorista(nome, email, senha, dt_cadastro, status, placa)');
    qry.SQL.Add('values(:nome, :email, :senha, current_timestamp, :status, :placa)');
    qry.ParamByName('nome').Value := nome;
    qry.ParamByName('email').Value := email;
    qry.ParamByName('senha').Value := senha;
    qry.ParamByName('status').Value := 'offline';
    qry.ParamByName('placa').Value := placa;
    qry.ExecSQL;

    Result := LoginMotorista(email, senha);

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.StatusMotorista(id_motorista: integer; status: string;
                                   lat, long: double): TJsonObject;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;
    Conn.StartTransaction;

    try
      //LimparDadosMotorista(id_motorista);

      // Muda status do motorista...
      qry.SQL.Add('update motorista set status = :status, latitude=:latitude,');
      qry.SQL.Add('longitude=:longitude, dt_atualizacao=current_timestamp');
      qry.SQL.Add('where id_motorista = :id_motorista');
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('status').Value := status;
      qry.ParamByName('latitude').Value := lat;
      qry.ParamByName('longitude').Value := long;
      qry.ExecSQL;

      Result := TJsonObject.Create(
                        TJsonPair.Create('sucesso', true)
                        );

      Conn.Commit;

    except on ex:exception do
      begin
        Conn.Rollback;
        raise Exception.Create(ex.Message);
      end;
    end;

  finally
    FreeAndNil(qry);
  end;
end;

// Corridas --------
function TDm.ListarOfertas(id_motorista: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select f.id_fila, f.id_corrida, c.origem, c.destino, c.vl_corrida, u.nome, u.whatsapp');
    qry.SQL.Add('from corrida_fila f ');
    qry.SQL.Add('join corrida c on (c.id_corrida = f.id_corrida) ');
    qry.SQL.Add('join usuario u on (u.id_usuario = c.id_usuario)');
    qry.SQL.Add('where f.id_motorista = :id_motorista');
    qry.SQL.Add('and f.status = ''pendente'' ');

    qry.ParamByName('id_motorista').Value := id_motorista;

    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.PopularFilaCorrida(id_corrida: integer);
var
  qry: TFDQuery;
  posicao: Integer;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    // Lista top X motorista disponiveis...
    qry.SQL.Add('select id_motorista from motorista where status=:status');
    qry.SQL.Add('order by dt_atualizacao desc rows :qtd_motorista_por_fila');
    qry.ParamByName('status').Value := 'online';
    qry.ParamByName('qtd_motorista_por_fila').Value := QTD_MOTORISTA_POR_FILA;
    qry.Open;


    posicao := 1;
    while not qry.Eof do
    begin
      Conn.ExecSQL('insert into corrida_fila(id_corrida, id_motorista, posicao, status, dt_cadastro) ' +
                   'values (:id_corrida, :id_motorista, :posicao, :status, current_timestamp)',
        [id_corrida,
         qry.FieldByName('id_motorista').AsInteger,
         posicao, 'fila']);

      Inc(posicao);
      qry.Next;
    end;

  finally
    qry.Free;
  end;
end;

function TDm.InserirCorrida(nome, whatsapp, origem, destino: string; vl_corrida: double): TJsonObject;
var
  qry: TFDQuery;
  usuario: TJsonObject;
  id_corrida: integer;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      Conn.TxOptions.Isolation := xiReadCommitted;
      Conn.StartTransaction;

      // Descobre usuario (cadastra caso nao existir)...
      usuario := InserirUsuario(nome, whatsapp);

      if usuario.Size = 0 then
        raise Exception.Create('Usuário não encontrado com whatsapp: ' + whatsapp);


      // Grava corrida...
      qry.SQL.Add('insert into corrida(id_usuario, origem, destino, vl_corrida, status, dt_cadastro)');
      qry.SQL.Add('values(:id_usuario, :origem, :destino, :vl_corrida, :status, current_timestamp)');
      qry.SQL.Add('returning id_corrida');

      qry.ParamByName('id_usuario').Value := usuario.GetValue<integer>('id_usuario', 0);
      qry.ParamByName('origem').Value := origem;
      qry.ParamByName('destino').Value := destino;
      qry.ParamByName('vl_corrida').Value := vl_corrida;
      qry.ParamByName('status').Value := 'criando';
      qry.Active := true;

      id_corrida := qry.FieldByName('id_corrida').AsInteger;
      Result := qry.ToJSONObject;


      // Monta fila da corrida...
      PopularFilaCorrida(id_corrida);

      // Libera corrida para worker processar...
      Conn.ExecSQL('update corrida set status=:status where id_corrida=:id_corrida', ['pesquisando', id_corrida]);

      Conn.Commit;
    except on ex:exception do
      begin
        Conn.Rollback;
        raise Exception.Create(ex.Message);
      end;
    end;

  finally
    FreeAndNil(usuario);
    FreeAndNil(qry);
  end;
end;

function TDm.StatusCorrida(id_fila, id_motorista, id_corrida: integer;
                                 status: string): TJsonObject;
begin
  if status = 'aceita' then
    AceitarCorrida(id_fila, id_motorista, id_corrida)

  else if status = 'ignorada' then
    ExpirarCorrida(id_fila, id_motorista, id_corrida)

  else if status = 'iniciada' then
    IniciarCorrida(id_fila, id_motorista, id_corrida)

  else if status = 'encerrada' then
    EncerrarCorrida(id_fila, id_motorista, id_corrida)

  else if status = 'cancelada' then
    CancelarCorrida(id_motorista, id_corrida);
end;

procedure TDm.AceitarCorrida(id_fila, id_motorista, id_corrida: integer);
var
  qry: TFDQuery;
  rows: integer;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      Conn.StartTransaction;

      // tenta marcar "aceita" se ainda "pendente" e não expirou
      qry.SQL.Add('update corrida_fila set status = :status');
      qry.SQL.Add('where id_fila = :id_fila and id_corrida = :id_corrida');
      qry.SQL.Add('and id_motorista = :id_motorista');
      qry.SQL.Add('and status = ''pendente'' and dt_expiracao > current_timestamp');
      qry.SQL.Add('returning id_fila, id_motorista');
      qry.ParamByName('id_fila').Value := id_fila;
      qry.ParamByName('id_corrida').Value := id_corrida;
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('status').Value := 'aceita';
      qry.Active := true;

      // já expirou/foi respondida
      if qry.Eof then
      begin
        Conn.Rollback;
        raise Exception.Create('Corrida expirou');
      end;


      rows := Conn.ExecSQL('update corrida set status = :status, id_motorista = :id_motorista, dt_aceite = current_timestamp ' +
              'where id_corrida = :id_corrida and id_motorista is null ',
              ['aceita', id_motorista, id_corrida]);


      // consegui pegar a corrida...
      if rows = 1 then
      begin
        qry.SQL.Clear;
        qry.SQL.Add('update motorista set status = :status, id_corrida = :id_corrida');
        qry.SQL.Add('where id_motorista = :id_motorista');
        qry.ParamByName('id_motorista').Value := id_motorista;
        qry.ParamByName('status').Value := 'corrida';
        qry.ParamByName('id_corrida').Value := id_corrida;
        qry.ExecSQL;

        EnviarMensagemWhatsApp(id_corrida, 'aceita');

        Conn.Commit;
      end
      else
      begin
        // alguém já aceitou antes; volto esta oferta para ignorada por mim e libero trava
        Conn.ExecSQL('update corrida_fila set status=''ignorada'' where id_fila=:id_fila', [id_fila]);
        Conn.ExecSQL('delete from motorista_lock where id_motorista=:id_motorista', [id_motorista]);
        Conn.Commit;
      end;

    except on ex:exception do
      begin
        Conn.Rollback;
        raise Exception.Create(ex.Message);
      end;
    end;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.ExpirarCorrida(id_fila, id_motorista, id_corrida: integer);
var
  qry: TFDQuery;
  rows: integer;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      Conn.StartTransaction;

      // marca fila como "ignorada"
      qry.SQL.Clear;
      qry.SQL.Add('update corrida_fila set status = :status');
      qry.SQL.Add('where id_fila = :id_fila and id_corrida = :id_corrida');
      qry.SQL.Add('and id_motorista = :id_motorista');
      qry.SQL.Add('and status = ''pendente'' ');
      qry.ParamByName('id_fila').Value := id_fila;
      qry.ParamByName('id_corrida').Value := id_corrida;
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('status').Value := 'ignorada';
      qry.ExecSQL;

      // Remove trava do motorista
      qry.SQL.Clear;
      qry.SQL.Add('delete from motorista_lock');
      qry.SQL.Add('where id_motorista = :id_motorista');
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ExecSQL;


      Conn.Commit;

    except on ex:exception do
      begin
        Conn.Rollback;
        raise Exception.Create(ex.Message);
      end;
    end;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.IniciarCorrida(id_fila, id_motorista, id_corrida: integer);
var
  qry: TFDQuery;
  rows: integer;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      Conn.StartTransaction;

      // atualiza status da corrida
      qry.SQL.Clear;
      qry.SQL.Add('update corrida set status = :status, dt_inicio = current_timestamp');
      qry.SQL.Add('where id_corrida = :id_corrida');
      qry.SQL.Add('and id_motorista = :id_motorista');
      qry.ParamByName('id_corrida').Value := id_corrida;
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('status').Value := 'iniciada';
      qry.ExecSQL;

      Conn.Commit;

    except on ex:exception do
      begin
        Conn.Rollback;
        raise Exception.Create(ex.Message);
      end;
    end;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.EncerrarCorrida(id_fila, id_motorista, id_corrida: integer);
var
  qry: TFDQuery;
  rows: integer;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      Conn.StartTransaction;

      // marcar corrida como encerrada
      qry.SQL.Add('update corrida set status = :status, dt_termino = current_timestamp');
      qry.SQL.Add('where id_corrida = :id_corrida');
      qry.SQL.Add('and id_motorista = :id_motorista');
      qry.ParamByName('id_corrida').Value := id_corrida;
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('status').Value := 'encerrada';
      qry.ExecSQL;

      // Limpa fila
      qry.SQL.Clear;
      qry.SQL.Add('update corrida_fila set status = :status');
      qry.SQL.Add('where id_corrida = :id_corrida');
      qry.ParamByName('id_corrida').Value := id_corrida;
      qry.ParamByName('status').Value := 'encerrada';
      qry.ExecSQL;

      EnviarMensagemWhatsApp(id_corrida, 'encerrada');

      Conn.Commit;

    except on ex:exception do
      begin
        Conn.Rollback;
        raise Exception.Create(ex.Message);
      end;
    end;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.AvaliarCorrida(id_motorista, id_corrida, avaliacao: integer): TJsonObject;
var
  qry: TFDQuery;
  rows: integer;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      Conn.StartTransaction;

      // gravo a avaliacao na corrida
      qry.SQL.Add('update corrida set avaliacao = :avaliacao');
      qry.SQL.Add('where id_corrida = :id_corrida');
      qry.SQL.Add('and id_motorista = :id_motorista');
      qry.ParamByName('id_corrida').Value := id_corrida;
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('avaliacao').Value := avaliacao;
      qry.ExecSQL;

      // Libera motorista para outras corridas
      qry.SQL.Clear;
      qry.SQL.Add('update motorista set status = :status, id_corrida = null');
      qry.SQL.Add('where id_motorista = :id_motorista');
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('status').Value := 'online';
      qry.ExecSQL;

      qry.SQL.Clear;
      qry.SQL.Add('delete from motorista_lock');
      qry.SQL.Add('where id_motorista = :id_motorista');
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ExecSQL;


      Result := TJsonObject.Create(
                        TJsonPair.Create('sucesso', true)
                        );

      Conn.Commit;

    except on ex:exception do
      begin
        Conn.Rollback;
        raise Exception.Create(ex.Message);
      end;
    end;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.CancelarCorrida(id_motorista, id_corrida: integer);
var
  qry: TFDQuery;
  rows: integer;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    try
      Conn.StartTransaction;

      // marcar corrida como cancelada
      qry.SQL.Add('update corrida set status = :status, dt_termino = current_timestamp, avaliacao=0');
      qry.SQL.Add('where id_corrida = :id_corrida');
      qry.SQL.Add('and id_motorista = :id_motorista');
      qry.ParamByName('id_corrida').Value := id_corrida;
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('status').Value := 'cancelada';
      qry.ExecSQL;

      // Encerra a fila da corrida
      qry.SQL.Clear;
      qry.SQL.Add('update corrida_fila set status = :status');
      qry.SQL.Add('where id_corrida = :id_corrida');
      qry.ParamByName('id_corrida').Value := id_corrida;
      qry.ParamByName('status').Value := 'encerrada';
      qry.ExecSQL;


      // Libera motorista para outras corridas
      qry.SQL.Clear;
      qry.SQL.Add('update motorista set status = :status, id_corrida = null');
      qry.SQL.Add('where id_motorista = :id_motorista');
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ParamByName('status').Value := 'online';
      qry.ExecSQL;

      qry.SQL.Clear;
      qry.SQL.Add('delete from motorista_lock');
      qry.SQL.Add('where id_motorista = :id_motorista');
      qry.ParamByName('id_motorista').Value := id_motorista;
      qry.ExecSQL;

      EnviarMensagemWhatsApp(id_corrida, 'cancelada');

      Conn.Commit;

    except on ex:exception do
      begin
        Conn.Rollback;
        raise Exception.Create(ex.Message);
      end;
    end;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarCorridas(id_motorista: integer): TJsonArray;
var
  qry: TFDQuery;
begin
  try
    qry := TFDQuery.Create(nil);
    qry.Connection := Conn;

    qry.SQL.Add('select c.id_corrida, c.dt_cadastro, c.origem, c.destino, c.vl_corrida, u.nome, c.status, c.vl_corrida');
    qry.SQL.Add('from corrida c');
    qry.SQL.Add('join usuario u on (u.id_usuario = c.id_usuario)');
    qry.SQL.Add('where c.id_motorista = :id_motorista');
    qry.SQL.Add('and c.status in (''cancelada'', ''encerrada'') ');
    qry.SQL.Add('order by c.id_corrida desc');

    qry.ParamByName('id_motorista').Value := id_motorista;

    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;


end.
