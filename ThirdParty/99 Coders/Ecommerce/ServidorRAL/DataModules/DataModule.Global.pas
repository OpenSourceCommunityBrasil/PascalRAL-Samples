unit DataModule.Global;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  FireDAC.Phys.FBDef, FireDAC.Phys.IBBase, FireDAC.Phys.FB, Data.DB,
  FireDAC.Comp.Client, SYstem.JSON, DataSet.Serialize.Config,
  DataSet.Serialize, FireDAC.DApt, uMD5, uMercadoPago;

type
  TDm = class(TDataModule)
    Conn: TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    function MP_InserirCliente(email, nome, sobrenome, tipo_doc,
                               doc: string): string;
    function MP_InserirCartao(cliente_id, cartao: string; mes, ano: integer; cvv, nome,
      tipo_doc, doc: string; var payment_id: string;
      var token_cartao_id: string): string;
    function CobrarPedido(id_usuario, id_pedido, id_forma_pagto, id_cartao,
      num_parcela: integer; cvv: string): TJsonObject;
    procedure StatusPedido(id_pedido: integer; status, payment_id: string);
    { Private declarations }
  public
    function Login(email, senha: string): TJsonObject;
    function Registro(nome, sobrenome, email, senha, cpf: string): TJsonObject;
    function ListarCategorias: TJsonArray;
    function ListarProdutos(id_categoria: integer; busca: string): TJsonArray;
    function ListarProdutoId(id_produto, id_usuario: integer): TJsonObject;
    function ExcluirFavorito(id_favorito: integer): string;
    function InserirFavorito(id_usuario, id_produto: integer): TJsonObject;
    function ListarCartoes(id_usuario: integer): TJsonArray;
    function ListarFormaPagto(valor: double): TJsonArray;
    function InserirPedido(id_usuario: integer; vl_frete, vl_subtotal,
                          vl_total: double; id_forma_pagto, id_cartao, num_parcela: integer;
                          cvv, endereco, numero, complemento, bairro,
                          cidade, uf, cep: string; itens: TJsonArray): TJsonObject;
    function CalcularFrete(qtd_itens: integer): TJsonObject;
    function ListarPedidos(id_usuario: integer): TJsonArray;
    function ListarPedidoId(id_usuario, id_pedido: integer): TJsonObject;
    function ListarUsuarioId(id_usuario: integer): TJsonObject;
    procedure EditarUsuario(id_usuario: integer; nome, email: string);
    function ListarFavoritos(id_usuario: integer): TJsonArray;
    procedure EditarSenha(id_usuario: integer; nova_senha: string);

    function ListarEnderecos(id_usuario: integer): TJsonArray;
    function InserirEndereco(id_usuario: integer; tipo, endereco, numero,
                             complemento, bairro, cidade, uf, cep: string): TJsonObject;
    procedure EditarEndereco(id_usuario, id_endereco: integer; tipo, endereco,
                             numero, complemento, bairro, cidade, uf, cep: string);
    procedure ExcluirEndereco(id_usuario, id_endereco: integer);
    function ListarEnderecoId(id_usuario, id_endereco: integer): TJsonObject;
    function InserirCartao(id_usuario: integer; numero, mes, ano, cod,
                           nome, cpf: string): TJsonObject;
    procedure ExcluirCartao(id_usuario, id_cartao: integer);
  end;

var
  Dm: TDm;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDm.DataModuleCreate(Sender: TObject);
begin
  TDataSetSerializeConfig.GetInstance.CaseNameDefinition := cndLower;
  TDataSetSerializeConfig.GetInstance.Import.DecimalSeparator := '.';
end;

function TDm.Login(email, senha: string): TJsonObject;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    qry.SQL.Add('select id_usuario, nome, email from usuario where email=:email and senha=:senha');
    qry.ParamByName('email').Value := email;
    qry.ParamByName('senha').Value := SaltPassword(senha);
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.MP_InserirCliente(email, nome, sobrenome, tipo_doc, doc: string): string;
var
  mp: TMercadoPago;
begin
  mp := TMercadoPago.Create;
  try
    if mp.CreateCustomer(email, nome, sobrenome, tipo_doc, doc) then
      Result := mp.ClienteId
    else
      raise Exception.Create(mp.ErrorMessage);

  finally
    FreeAndNil(mp);
  end;
end;

function TDm.MP_InserirCartao(cliente_id, cartao: string;
                              mes, ano: integer;
                              cvv, nome, tipo_doc, doc: string;
                              var payment_id: string;
                              var token_cartao_id: string): string;  // Retorno CartaoId
var
  mp: TMercadoPago;
begin
  if cliente_id = '' then
    raise Exception.Create('Id. do cliente não informado');

  mp := TMercadoPago.Create;
  try
    if NOT mp.CreateCardToken(cartao, mes, ano, cvv, nome, tipo_doc, doc) then
      raise Exception.Create('Erro CreateCardToken: ' + mp.ErrorMessage);

    if mp.SaveCardToCustomer(cliente_id, mp.TokenCartaoId) then
    begin
        payment_id := mp.PaymentMethodId;
        token_cartao_id := mp.TokenCartaoId;
        Result := mp.CartaoId;
    end
    else
      raise Exception.Create('Erro SaveCardToCustomer: ' + mp.ErrorMessage);


  finally
    FreeAndNil(mp);
  end;

end;

function TDm.Registro(nome, sobrenome, email, senha, cpf: string): TJsonObject;
var
  qry: TFDQuery;
  cliente_id: string;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    // Registrar cliente no Mercado Pago
    cliente_id := MP_InserirCliente(email, nome, sobrenome, 'CPF', cpf);

    qry.SQL.Add('insert into usuario(nome, email, senha, cliente_id) ');
    qry.SQL.Add('values(:nome, :email, :senha, :cliente_id)');
    qry.SQL.Add('returning id_usuario, nome, email, cliente_id');
    qry.ParamByName('nome').Value := nome + ' ' + sobrenome;
    qry.ParamByName('email').Value := email;
    qry.ParamByName('senha').Value := SaltPassword(senha);
    qry.ParamByName('cliente_id').Value := cliente_id;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarCategorias(): TJsonArray;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Add('select * from produto_categoria order by ordem');
    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarProdutos(id_categoria: integer; busca: string): TJsonArray;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Add('select * from produto where id_produto > 0');

    if id_categoria > 0 then
    begin
      qry.SQL.Add('and id_categoria=:id_categoria');
      qry.ParamByName('id_categoria').Value := id_categoria;
    end;

    if busca <> '' then
    begin
      qry.SQL.Add('and (nome like :nome or descricao like :descricao)');
      qry.ParamByName('nome').Value := '%' + busca + '%';
      qry.ParamByName('descricao').Value := '%' + busca + '%';
    end;

    qry.SQL.Add('order by nome');
    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarProdutoId(id_produto, id_usuario: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Add('select p.*, coalesce(f.id_favorito, 0) as id_favorito from produto p');
    qry.SQL.Add('left join usuario_favorito f on (f.id_produto = p.id_produto and f.id_usuario = :id_usuario)');
    qry.SQL.Add('where p.id_produto = :id_produto');
    qry.ParamByName('id_produto').Value := id_produto;
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.InserirFavorito(id_usuario, id_produto: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Add('delete from usuario_favorito');
    qry.SQL.Add('where id_usuario = :id_usuario and id_produto = :id_produto');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_produto').Value := id_produto;
    qry.ExecSQL;

    qry.SQL.Clear;
    qry.SQL.Add('insert into usuario_favorito(id_usuario, id_produto)');
    qry.SQL.Add('values(:id_usuario, :id_produto)');
    qry.SQL.Add('returning id_favorito');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_produto').Value := id_produto;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ExcluirFavorito(id_favorito: integer): string;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Add('delete from usuario_favorito');
    qry.SQL.Add('where id_favorito = :id_favorito');
    qry.ParamByName('id_favorito').Value := id_favorito;
    qry.ExecSQL;

    Result := 'OK';

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarEnderecos(id_usuario: integer): TJsonArray;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    qry.SQL.Add('select * from usuario_endereco where id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarCartoes(id_usuario: integer): TJsonArray;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    qry.SQL.Add('select * from usuario_cartao where id_usuario = :id_usuario');
    qry.SQL.Add('order by validade');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarFormaPagto(valor: double): TJsonArray;
var
  qry: TFDQuery;
  i, num_parcela: integer;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    qry.SQL.Add('select * from forma_pagto');
    qry.SQL.Add('order by descricao');
    qry.Active := true;

    Result := qry.ToJSONArray;

    for i := 0 to Result.Size - 1 do
    begin
      num_parcela := 1;

      if TJsonObject(Result[i]).GetValue<string>('tipo') = 'CARTAO' then
      begin
        if valor < 50 then
          num_parcela := 2
        else
          num_parcela := 6;
      end;

      TJsonObject(Result[i]).AddPair('num_parcela', num_parcela);
    end;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.StatusPedido(id_pedido: integer; status, payment_id: string);
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  try
    qry.Connection := Conn;

    qry.SQL.Add('update pedido set status = :status, payment_id = :payment_id where id_pedido = :id_pedido');
    qry.ParamByName('id_pedido').Value := id_pedido;
    qry.ParamByName('status').Value := status;
    qry.ParamByName('payment_id').Value := payment_id;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;

end;

// Cartao -> {"id_pedido": 123, "forma_pagto": "CARTAO", "sucesso": true, "retorno": "", "url": ""}
//           {"id_pedido": 123, "forma_pagto": "CARTAO", "sucesso": false, "retorno": "Erro ao cobrar cartão", "url": ""}
// Pix -> {"id_pedido": 123, "forma_pagto": "PIX", "sucesso": true, "retorno": "00g0erg0er0dg0s0rg0dsr0g0dg0", "url": "https://xxxx/qrcode.png"}
// Boleto -> {"id_pedido": 123, "forma_pagto": "BOLETO", "sucesso": true, "retorno": "00000000000000", "url": "https://xxxx/url_pagto"}
function TDm.CobrarPedido(id_usuario, id_pedido, id_forma_pagto, id_cartao, num_parcela: integer; cvv: string): TJsonObject;
var
  forma_pagto, token_cartao_compra, card_id, payment_id, cliente_id, email: string;
  nome, sobrenome, cpf, cep, numero, endereco, bairro, cidade, estado: string;
  vl_total: double;
  qry: TFDQuery;
  mp: TMercadoPago;
  json: TJSONObject;
begin
  qry := TFDQuery.Create(nil);
  mp := TMercadoPago.Create;
  json := TJSONObject.Create;


  try
    try
      qry.Connection := Conn;

      json.AddPair('id_pedido', id_pedido);


      // Descobrir a forma pagto (CARTAO, BOLETO ou PIX)
      qry.Active := false;
      qry.SQL.Add('select * from forma_pagto where id_forma_pagto = :id_forma_pagto');
      qry.ParamByName('id_forma_pagto').Value := id_forma_pagto;
      qry.Active := true;
      forma_pagto := qry.FieldByName('tipo').AsString;

      json.AddPair('forma_pagto', forma_pagto);


      // Dados para cobranca
      qry.Active := false;
      qry.SQL.Clear;
      qry.SQL.Add('select c.cartao_id, p.vl_total, c.payment_id, u.cliente_id, u.email, u.nome, ');
      qry.SQL.Add('p.cep, p.numero, p.endereco, p.bairro, p.cidade, p.uf');
      qry.SQL.Add('from pedido p');
      qry.SQL.Add('left join usuario_cartao c on (c.id_cartao = p.id_cartao and c.id_cartao = :id_cartao)');
      qry.SQL.Add('join usuario u on (u.id_usuario = p.id_usuario)');
      qry.SQL.Add('where p.id_usuario = :id_usuario');
      qry.SQL.Add('and p.id_pedido = :id_pedido');
      qry.ParamByName('id_cartao').Value := id_cartao;
      qry.ParamByName('id_usuario').Value := id_usuario;
      qry.ParamByName('id_pedido').Value := id_pedido;
      qry.Active := true;

      card_id := qry.FieldByName('cartao_id').AsString;
      vl_total := qry.FieldByName('vl_total').AsFloat;
      payment_id := qry.FieldByName('payment_id').AsString;
      cliente_id := qry.FieldByName('cliente_id').AsString;
      email := qry.FieldByName('email').AsString;
      nome := Copy(qry.FieldByName('nome').AsString, 1, Pos(' ', qry.FieldByName('nome').AsString) - 1);
      sobrenome := Copy(qry.FieldByName('nome').AsString, Pos(' ', qry.FieldByName('nome').AsString) + 1, 100);
      cpf := '19119119100';
      cep := qry.FieldByName('cep').AsString;
      numero := qry.FieldByName('numero').AsString;
      endereco := qry.FieldByName('endereco').AsString;
      bairro := qry.FieldByName('bairro').AsString;
      cidade := qry.FieldByName('cidade').AsString;
      estado := qry.FieldByName('uf').AsString;

      if forma_pagto = 'CARTAO' then
      begin
        if NOT mp.CreateTokenFromSavedCard(card_id, cvv) then
          raise Exception.Create(mp.ErrorMessage);

        token_cartao_compra := mp.TokenCartaoCompra;


        if NOT mp.PayWithCard(vl_total, token_cartao_compra, 'Compra Ecommerce Delphi',
                       num_parcela, payment_id, '', cliente_id, email, id_pedido.ToString) then
          raise Exception.Create('Erro ao cobrar cartão: ' + mp.ErrorMessage);

        StatusPedido(id_pedido, 'P', mp.PaymentId);

        json.AddPair('retorno', 'OK');
        json.AddPair('url', '');
        json.AddPair('sucesso', true);
      end

      else if forma_pagto = 'BOLETO' then
      begin
        if NOT mp.PayWithBoleto(vl_total, 'Compra Ecommerce Delphi', '', 'bolbradesco', cliente_id,
                      nome, sobrenome, 'CPF', cpf, cep, endereco,
                      numero, bairro, cidade, estado, id_pedido.ToString) then
          raise Exception.Create('Erro ao gerar boleto: ' + mp.ErrorMessage)
        else
        begin
          json.AddPair('retorno', mp.LinhaDigitavel);
          json.AddPair('url', mp.URLPagamento);
          json.AddPair('sucesso', true);
        end;
      end

      else
      begin
        if NOT mp.PayWithPix(vl_total, 'Compra Ecommerce Delphi', cliente_id, '', id_pedido.ToString) then
          raise Exception.Create('Erro ao gerar PIX: ' + mp.ErrorMessage)
        else
        begin
          json.AddPair('retorno', mp.QRCode);
          json.AddPair('url', mp.URLPagamento);
          json.AddPair('sucesso', true);
        end;
      end;


    except on ex:exception do
      begin
          json.AddPair('retorno', ex.Message);
          json.AddPair('url', '');
          json.AddPair('sucesso', false);
      end;
    end;

    Result := json;

  finally
    FreeAndNil(mp);
    FreeAndNil(qry);
  end;

end;

function TDm.InserirPedido(id_usuario: integer;
                           vl_frete, vl_subtotal, vl_total: double;
                           id_forma_pagto, id_cartao, num_parcela: integer;
                           cvv, endereco, numero, complemento, bairro,
                           cidade, uf, cep: string;
                           itens: TJsonArray): TJsonObject;
var
  qry: TFDQuery;
  id_pedido, i: integer;
begin
  qry := TFDQuery.Create(nil);

  try
    try
      qry.Connection := Conn;

      Conn.StartTransaction;

      qry.SQL.Add('insert into pedido(id_usuario, vl_frete, vl_subtotal, vl_total,');
      qry.SQL.Add('id_forma_pagto, id_cartao, num_parcela, endereco, numero, complemento, bairro,');
      qry.SQL.Add('cidade, uf, cep, status, dt_pedido) ');
      qry.SQL.Add('values(:id_usuario, :vl_frete, :vl_subtotal, :vl_total,');
      qry.SQL.Add(':id_forma_pagto, :id_cartao, :num_parcela, :endereco, :numero, :complemento, :bairro,');
      qry.SQL.Add(':cidade, :uf, :cep, :status, current_timestamp)');
      qry.SQL.Add('returning id_pedido');

      qry.ParamByName('id_usuario').Value := id_usuario;
      qry.ParamByName('vl_frete').Value := vl_frete;
      qry.ParamByName('vl_subtotal').Value := vl_subtotal;
      qry.ParamByName('vl_total').Value := vl_total;
      qry.ParamByName('id_forma_pagto').Value := id_forma_pagto;
      qry.ParamByName('id_cartao').Value := id_cartao;
      qry.ParamByName('num_parcela').Value := num_parcela;
      qry.ParamByName('endereco').Value := endereco;
      qry.ParamByName('numero').Value := numero;
      qry.ParamByName('complemento').Value := complemento;
      qry.ParamByName('bairro').Value := bairro;
      qry.ParamByName('cidade').Value := cidade;
      qry.ParamByName('uf').Value := uf;
      qry.ParamByName('cep').Value := cep;
      qry.ParamByName('status').Value := 'A';
      qry.Active := true;

      //Result := qry.ToJSONObject;

      // Itens...
      id_pedido := qry.FieldByName('id_pedido').AsInteger;

      for i := 0 to itens.Size - 1 do
      begin
        qry.Active := false;
        qry.SQL.Clear;
        qry.SQL.Add('insert into pedido_item(id_pedido, id_produto, nome, descricao, qtd, vl_unitario, vl_total)');
        qry.SQL.Add('values(:id_pedido, :id_produto, :nome, :descricao, :qtd, :vl_unitario, :vl_total)');
        qry.ParamByName('id_pedido').Value := id_pedido;
        qry.ParamByName('id_produto').Value := TJsonObject(itens[i]).GetValue<integer>('id_produto');
        qry.ParamByName('nome').Value := TJsonObject(itens[i]).GetValue<string>('nome');
        qry.ParamByName('descricao').Value := TJsonObject(itens[i]).GetValue<string>('descricao');
        qry.ParamByName('qtd').Value := TJsonObject(itens[i]).GetValue<integer>('qtd');
        qry.ParamByName('vl_unitario').Value := TJsonObject(itens[i]).GetValue<double>('vl_unitario');
        qry.ParamByName('vl_total').Value := TJsonObject(itens[i]).GetValue<double>('vl_total');
        qry.ExecSQL;
      end;

      Conn.Commit;

      Result := CobrarPedido(id_usuario, id_pedido, id_forma_pagto, id_cartao, num_parcela, cvv);

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


function TDm.CalcularFrete(qtd_itens: integer): TJsonObject;
var
  json: TJsonObject;
begin
  json := TJsonObject.Create;

  if qtd_itens > 5 then
    json.AddPair('vl_frete', 50)
  else
    json.AddPair('vl_frete', 10);

  Result := json;
end;

function TDm.ListarPedidos(id_usuario: integer): TJsonArray;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    qry.SQL.Add('select * from pedido where id_usuario = :id_usuario');
    qry.SQL.Add('order by id_pedido desc');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarPedidoId(id_usuario, id_pedido: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    // Pedido
    qry.SQL.Add('select p.*, f.descricao as descr_forma_pagto from pedido p');
    qry.SQL.Add('join forma_pagto f on (f.id_forma_pagto = p.id_forma_pagto)');
    qry.SQL.Add('where p.id_usuario = :id_usuario');
    qry.SQL.Add('and p.id_pedido = :id_pedido');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_pedido').Value := id_pedido;
    qry.Active := true;

    Result := qry.ToJSONObject;

    // Itens...
    qry.Active := false;
    qry.SQL.Clear;
    qry.SQL.Add('select i.*, p.foto from pedido_item i ');
    qry.SQL.Add('join produto p on (p.id_produto = i.id_produto)');
    qry.SQL.Add('where i.id_pedido = :id_pedido');
    qry.SQL.Add('order by i.id_item');
    qry.ParamByName('id_pedido').Value := id_pedido;
    qry.Active := true;

    Result.AddPair('itens', qry.ToJSONArray);

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarUsuarioId(id_usuario: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    qry.SQL.Add('select id_usuario, nome, email from usuario where id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.EditarUsuario(id_usuario: integer; nome, email: string);
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Add('select id_usuario from usuario');
    qry.SQL.Add('where email = :email and id_usuario <> :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('email').Value := email;
    qry.Active := true;

    if qry.RecordCount > 0 then
      raise Exception.Create('Já existe uma outra conta usando esse e-mail');

    qry.Active := false;
    qry.SQL.Clear;
    qry.SQL.Add('update usuario set nome=:nome, email=:email');
    qry.SQL.Add('where id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('nome').Value := nome;
    qry.ParamByName('email').Value := email;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarFavoritos(id_usuario: integer): TJsonArray;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    qry.SQL.Add('select f.id_favorito, f.id_produto, p.nome, p.descricao, p.foto, p.preco');
    qry.SQL.Add('from usuario_favorito f ');
    qry.SQL.Add('join produto p on (p.id_produto = f.id_produto)');
    qry.SQL.Add('where f.id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.Active := true;

    Result := qry.ToJSONArray;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.EditarSenha(id_usuario: integer; nova_senha: string);
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Add('update usuario set senha=:senha');
    qry.SQL.Add('where id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('senha').Value := SaltPassword(nova_senha);
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.InserirEndereco(id_usuario: integer; tipo, endereco, numero,
                             complemento, bairro, cidade, uf, cep: string ): TJsonObject;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Clear;
    qry.SQL.Add('insert into usuario_endereco(id_usuario, tipo, endereco, numero, complemento, bairro, cidade, uf, cep)');
    qry.SQL.Add('values(:id_usuario, :tipo, :endereco, :numero, :complemento, :bairro, :cidade, :uf, :cep)');
    qry.SQL.Add('returning id_endereco');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('tipo').Value := tipo;
    qry.ParamByName('endereco').Value := endereco;
    qry.ParamByName('numero').Value := numero;
    qry.ParamByName('complemento').Value := complemento;
    qry.ParamByName('bairro').Value := bairro;
    qry.ParamByName('cidade').Value := cidade;
    qry.ParamByName('uf').Value := uf;
    qry.ParamByName('cep').Value := cep;

    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.EditarEndereco(id_usuario, id_endereco: integer; tipo, endereco, numero,
                            complemento, bairro, cidade, uf, cep: string );
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Clear;
    qry.SQL.Add('update usuario_endereco set tipo=:tipo, endereco=:endereco, numero=:numero, ');
    qry.SQL.Add('complemento=:complemento, bairro=:bairro, cidade=:cidade, uf=:uf, cep=:cep');
    qry.SQL.Add('where id_endereco = :id_endereco and id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_endereco').Value := id_endereco;
    qry.ParamByName('tipo').Value := tipo;
    qry.ParamByName('endereco').Value := endereco;
    qry.ParamByName('numero').Value := numero;
    qry.ParamByName('complemento').Value := complemento;
    qry.ParamByName('bairro').Value := bairro;
    qry.ParamByName('cidade').Value := cidade;
    qry.ParamByName('uf').Value := uf;
    qry.ParamByName('cep').Value := cep;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.ExcluirEndereco(id_usuario, id_endereco: integer);
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Clear;
    qry.SQL.Add('delete from usuario_endereco');
    qry.SQL.Add('where id_endereco = :id_endereco and id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_endereco').Value := id_endereco;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.ListarEnderecoId(id_usuario, id_endereco: integer): TJsonObject;
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);

  try
    qry.Connection := Conn;

    qry.SQL.Add('select * from usuario_endereco');
    qry.SQL.Add('where id_usuario = :id_usuario and id_endereco = :id_endereco');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_endereco').Value := id_endereco;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

function TDm.InserirCartao(id_usuario: integer;
                           numero, mes, ano, cod, nome, cpf: string): TJsonObject;
var
  qry: TFDQuery;
  cliente_id, token_cartao_id, cartao_id, payment_id: string;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  qry.SQL.Clear;
  qry.SQL.Add('select cliente_id from usuario where id_usuario = :id_usuario');
  qry.ParamByName('id_usuario').Value := id_usuario;
  qry.Active := true;

  cliente_id := qry.FieldByName('cliente_id').AsString;


  // Registrar cartão na API do Gateway...
  cartao_id := MP_InserirCartao(cliente_id, numero, mes.ToInteger, ano.ToInteger, cod, nome, 'CPF',
                                cpf, payment_id, token_cartao_id);
  //---------------------------------------


  try
    qry.SQL.Clear;
    qry.SQL.Add('insert into usuario_cartao(id_usuario, descricao, validade, cartao_id, payment_id, token_cartao_id)');
    qry.SQL.Add('values(:id_usuario, :descricao, :validade, :cartao_id, :payment_id, :token_cartao_id)');
    qry.SQL.Add('returning id_cartao, cartao_id, payment_id, token_cartao_id');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('descricao').Value := 'Cartão final ' + Copy(numero, length(numero)-3, 4);
    qry.ParamByName('validade').Value := mes + '/' + ano;
    qry.ParamByName('cartao_id').Value := cartao_id;
    qry.ParamByName('payment_id').Value := payment_id;
    qry.ParamByName('token_cartao_id').Value := token_cartao_id;
    qry.Active := true;

    Result := qry.ToJSONObject;

  finally
    FreeAndNil(qry);
  end;
end;

procedure TDm.ExcluirCartao(id_usuario, id_cartao: integer);
var
  qry: TFDQuery;
begin
  qry := TFDQuery.Create(nil);
  qry.Connection := Conn;

  try
    qry.SQL.Clear;
    qry.SQL.Add('delete from usuario_cartao');
    qry.SQL.Add('where id_cartao = :id_cartao and id_usuario = :id_usuario');
    qry.ParamByName('id_usuario').Value := id_usuario;
    qry.ParamByName('id_cartao').Value := id_cartao;
    qry.ExecSQL;

  finally
    FreeAndNil(qry);
  end;
end;

end.
