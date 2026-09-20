/// Servidor do benchmark MsQuic (QUIC) do PascalRAL.
///
/// Sobe um TRALMsQuicServer com as rotas que o cliente do benchmark usa
/// (ping, params, multipart, eco, lento), publica o banco Firebird pelos DOIS
/// stacks de banco do RAL - o DAO (TRALFDConnection, consumido por TRALFDQuery)
/// e o DBWare (TRALDBModule, consumido por TRALDBFDMemTable) - e cria o banco
/// de teste com 2000 registros quando ele nao existe.
///
/// QUIC nao tem modo sem TLS: o certificado e a chave PEM sao obrigatorios.
/// Um par autoassinado serve, veja o README ao lado.
unit UServidor;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.DateUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Phys,
  FireDAC.Phys.IBBase, FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Comp.Client, FireDAC.Comp.DataSet,

  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse,
  RALParams, RALCompress, RALCompressZLib, RALCripto, RALCriptoAES,
  RALMsQuicServer,
  { os storages so' existem no executavel que os liga - sem RALStorageBIN o
    DBWare responde "Storage 1 not declared in uses" a todo opensql }
  RALStorage, RALStorageBIN, RALStorageJSON,
  RALDBModule, RALDBBase, RALDBFireDAC, RALDBFiredacDAO;

type
  TfServidor = class(TForm)
    pnTopo: TPanel;
    gbServidor: TGroupBox;
    lbPorta: TLabel;
    edPorta: TEdit;
    lbPool: TLabel;
    edPool: TEdit;
    lbCert: TLabel;
    edCert: TEdit;
    lbChave: TLabel;
    edChave: TEdit;
    lbCompress: TLabel;
    cbCompress: TComboBox;
    lbCripto: TLabel;
    cbCripto: TComboBox;
    lbChaveCripto: TLabel;
    edChaveCripto: TEdit;
    btLigar: TButton;
    lbStatus: TLabel;
    gbFirebird: TGroupBox;
    lbFBHost: TLabel;
    edFBHost: TEdit;
    lbFBPorta: TLabel;
    edFBPorta: TEdit;
    lbFBBanco: TLabel;
    edFBBanco: TEdit;
    lbFBUsuario: TLabel;
    edFBUsuario: TEdit;
    lbFBSenha: TLabel;
    edFBSenha: TEdit;
    btCriarBanco: TButton;
    lbBanco: TLabel;
    mmLog: TMemo;
    tmContadores: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btLigarClick(Sender: TObject);
    procedure btCriarBancoClick(Sender: TObject);
    procedure tmContadoresTimer(Sender: TObject);
  private
    FServer: TRALMsQuicServer;
    FConnDAO: TRALFDConnection;
    FModulo: TRALDBModule;
    procedure Log(const ATexto: string);
    function NovaConexaoFB(ACriar: Boolean): TFDConnection;
    procedure CriarBanco;
    procedure Ligar;
    procedure Desligar;
    procedure AplicarConfiguracao;
    // rotas
    procedure RotaPing(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaParams(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaMultipart(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaEco(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RotaLenta(ARequest: TRALRequest; AResponse: TRALResponse);
  public
  end;

var
  fServidor: TfServidor;

implementation

{$R *.dfm}

const
  PORTA_PADRAO = 8100;
  ROTA_LENTA_MS = 50;
  REGISTROS = 2000;

{ ---------------------------------------------------------------- formulario }

procedure TfServidor.FormCreate(Sender: TObject);
var
  vPasta: string;
begin
  vPasta := ExtractFilePath(ParamStr(0));
  edPorta.Text := IntToStr(PORTA_PADRAO);
  edPool.Text := '1';
  edCert.Text := vPasta + 'cert.pem';
  edChave.Text := vPasta + 'key.pem';
  edFBBanco.Text := vPasta + 'benchmark.fdb';
  cbCompress.ItemIndex := 0;
  cbCripto.ItemIndex := 0;
end;

procedure TfServidor.FormDestroy(Sender: TObject);
begin
  Desligar;
end;

procedure TfServidor.Log(const ATexto: string);
begin
  mmLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + '  ' + ATexto);
end;

{ --------------------------------------------------------------------- banco }

function TfServidor.NovaConexaoFB(ACriar: Boolean): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  Result.LoginPrompt := False;
  Result.Params.Clear;
  Result.Params.Add('DriverID=FB');
  Result.Params.Add('Server=' + edFBHost.Text);
  Result.Params.Add('Port=' + edFBPorta.Text);
  Result.Params.Add('Database=' + edFBBanco.Text);
  Result.Params.Add('User_Name=' + edFBUsuario.Text);
  Result.Params.Add('Password=' + edFBSenha.Text);
  Result.Params.Add('Protocol=TCPIP');
  Result.Params.Add('CharacterSet=UTF8');
  if ACriar then
    Result.Params.Add('CreateDatabase=Yes');
end;

{ Uma tabela com seis colunas de tipos diferentes - inteiro, texto, numerico
  com decimais, data e hora, booleano e texto longo - porque cada uma delas
  atravessa o fio de um jeito nos dois stacks de banco. }
procedure TfServidor.CriarBanco;
var
  vCon: TFDConnection;
  vQry: TFDQuery;
  vInt: Integer;
begin
  Log('criando ' + edFBBanco.Text + ' ...');
  vCon := NovaConexaoFB(not FileExists(edFBBanco.Text));
  try
    vCon.Connected := True;
    vQry := TFDQuery.Create(nil);
    try
      vQry.Connection := vCon;
      vQry.SQL.Text := 'select count(*) from RDB$RELATIONS where RDB$RELATION_NAME = ''BENCH''';
      vQry.Open;
      if vQry.Fields[0].AsInteger = 0 then
      begin
        vQry.Close;
        vQry.ExecSQL(
          'CREATE TABLE BENCH (' +
          '  ID INTEGER NOT NULL PRIMARY KEY,' +
          '  NOME VARCHAR(60),' +
          '  VALOR NUMERIC(15,2),' +
          '  DATA_CAD TIMESTAMP,' +
          '  ATIVO BOOLEAN,' +
          '  OBS VARCHAR(200))');
        vCon.Commit;
      end;

      vQry.Close;
      vQry.SQL.Text := 'select count(*) from BENCH';
      vQry.Open;
      if vQry.Fields[0].AsInteger >= REGISTROS then
      begin
        Log(Format('tabela BENCH ja' + ' tem %d registros', [vQry.Fields[0].AsInteger]));
        Exit;
      end;
      vQry.Close;

      { Array DML: um round trip para os 2000, em vez de 2000 }
      vQry.SQL.Text := 'insert into BENCH (ID, NOME, VALOR, DATA_CAD, ATIVO, OBS) ' +
                       'values (:ID, :NOME, :VALOR, :DATA_CAD, :ATIVO, :OBS)';
      vQry.Params.ArraySize := REGISTROS;
      for vInt := 0 to REGISTROS - 1 do
      begin
        vQry.Params[0].AsIntegers[vInt] := vInt + 1;
        vQry.Params[1].AsStrings[vInt] := Format('Cliente %.4d', [vInt + 1]);
        vQry.Params[2].AsCurrencys[vInt] := (vInt + 1) * 1.25;
        vQry.Params[3].AsDateTimes[vInt] := IncMinute(EncodeDate(2026, 1, 1), vInt * 7);
        vQry.Params[4].AsBooleans[vInt] := (vInt mod 3) <> 0;
        vQry.Params[5].AsStrings[vInt] := Format('Registro %d gerado pelo benchmark, com acentua'#231#227'o', [vInt + 1]);
      end;
      vCon.StartTransaction;
      vQry.Execute(REGISTROS, 0);
      vCon.Commit;
      Log(Format('tabela BENCH criada com %d registros', [REGISTROS]));
    finally
      vQry.Free;
    end;
  finally
    vCon.Free;
  end;
end;

procedure TfServidor.btCriarBancoClick(Sender: TObject);
begin
  try
    CriarBanco;
    lbBanco.Caption := 'banco pronto';
  except
    on e: Exception do
    begin
      Log('ERRO ao criar o banco: ' + e.Message);
      lbBanco.Caption := 'erro - veja o log';
    end;
  end;
end;

{ ------------------------------------------------------------------ servidor }

procedure TfServidor.AplicarConfiguracao;
begin
  FServer.Port := StrToIntDef(edPorta.Text, PORTA_PADRAO);
  FServer.PoolCount := StrToIntDef(edPool.Text, 1);
  FServer.SSL.CertificateFile := edCert.Text;
  FServer.SSL.PrivateKeyFile := edChave.Text;
  { O servidor decide a compressao da resposta quando CompressType nao e'
    ctNone; com ctNone quem decide e' o Accept-Encoding do cliente. }
  case cbCompress.ItemIndex of
    1: FServer.CompressType := ctGZip;
    2: FServer.CompressType := ctDeflate;
    3: FServer.CompressType := ctZLib;
  else
    FServer.CompressType := ctNone;
  end;
  case cbCripto.ItemIndex of
    1: FServer.CriptoOptions.CriptType := crAES128;
    2: FServer.CriptoOptions.CriptType := crAES192;
    3: FServer.CriptoOptions.CriptType := crAES256;
  else
    FServer.CriptoOptions.CriptType := crNone;
  end;
  FServer.CriptoOptions.Key := StringRAL(edChaveCripto.Text);
end;

procedure TfServidor.Ligar;
begin
  if (cbCripto.ItemIndex > 0) and (edChaveCripto.Text = '') then
    raise Exception.Create('Informe a chave da criptografia.');

  if FServer = nil then
  begin
    FServer := TRALMsQuicServer.Create(Self);
    FServer.CreateRoute('ping', RotaPing, 'responde pong');
    FServer.CreateRoute('params', RotaParams, 'devolve os parametros recebidos');
    FServer.CreateRoute('multipart', RotaMultipart, 'lista as partes recebidas');
    FServer.CreateRoute('eco', RotaEco, 'devolve o corpo recebido');
    FServer.CreateRoute('lento', RotaLenta, 'demora, para medir paralelismo');

    { --- stack 1: DAO. O TRALFDConnection publica sozinho a rota que o
          TRALFDQuery do cliente consome; o nome do componente e' a rota, e o
          cliente o informa em RALFDConnectionServer. --- }
    FConnDAO := TRALFDConnection.Create(Self);
    FConnDAO.Name := 'RALConnBench';
    FConnDAO.LoginPrompt := False;

    { --- stack 2: DBWare. O TRALDBModule publica opensql, execsql,
          applyupdates e companhia sob /db; o cliente usa TRALDBConnection +
          TRALDBFDMemTable. --- }
    FModulo := TRALDBModule.Create(Self);
    FModulo.Domain := '/db';
    FModulo.DatabaseLink := 'FireDAC';
    FModulo.DatabaseType := dtFirebird;
    { pool de conexoes de banco ligado: sem ele cada requisicao abre e fecha
      uma conexao com o Firebird, e e' isso que o benchmark mediria }
    FModulo.PoolOptions.Enabled := True;
  end;

  AplicarConfiguracao;

  FConnDAO.Connected := False;
  FConnDAO.Params.Clear;
  FConnDAO.Params.Add('DriverID=FB');
  FConnDAO.Params.Add('Server=' + edFBHost.Text);
  FConnDAO.Params.Add('Port=' + edFBPorta.Text);
  FConnDAO.Params.Add('Database=' + edFBBanco.Text);
  FConnDAO.Params.Add('User_Name=' + edFBUsuario.Text);
  FConnDAO.Params.Add('Password=' + edFBSenha.Text);
  FConnDAO.Params.Add('Protocol=TCPIP');
  FConnDAO.Params.Add('CharacterSet=UTF8');
  FConnDAO.Connected := True;
  FConnDAO.RALServer := FServer;

  FModulo.Hostname := StringRAL(edFBHost.Text);
  FModulo.Port := StrToIntDef(edFBPorta.Text, 3050);
  FModulo.Database := StringRAL(edFBBanco.Text);
  FModulo.Username := StringRAL(edFBUsuario.Text);
  FModulo.Password := StringRAL(edFBSenha.Text);
  FModulo.Server := FServer;

  FServer.Active := True;
  Log(Format('servidor QUIC no ar em udp/%d - msquic %s - PoolCount %d - compressao %s - cripto %s',
    [FServer.Port, FServer.Engine, FServer.PoolCount, cbCompress.Text, cbCripto.Text]));
  Log('rotas: /ping /params /multipart /eco /lento, DAO em /RALConnBench, DBWare em /db');
  btLigar.Caption := 'Desligar';
  lbStatus.Caption := 'no ar';
  tmContadores.Enabled := True;
end;

procedure TfServidor.Desligar;
begin
  tmContadores.Enabled := False;
  if (FServer <> nil) and FServer.Active then
  begin
    FServer.Active := False;
    Log('servidor desligado');
  end;
  if FConnDAO <> nil then
    FConnDAO.Connected := False;
  btLigar.Caption := 'Ligar';
  lbStatus.Caption := 'parado';
end;

procedure TfServidor.btLigarClick(Sender: TObject);
begin
  try
    if (FServer <> nil) and FServer.Active then
      Desligar
    else
      Ligar;
  except
    on e: Exception do
    begin
      Log('ERRO: ' + e.Message);
      lbStatus.Caption := 'erro - veja o log';
    end;
  end;
end;

procedure TfServidor.tmContadoresTimer(Sender: TObject);
begin
  if (FServer <> nil) and FServer.Active then
    lbStatus.Caption := Format('no ar - %d conexoes aceitas, %d requisicoes',
      [FServer.ConnectionCount, FServer.RequestCount]);
end;

{ --------------------------------------------------------------------- rotas }

procedure TfServidor.RotaPing(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
end;

{ Devolve, uma por linha, o que chegou: query, campos e corpo. E' o que prova
  que parametros atravessam compressao e criptografia sem se perder. }
procedure TfServidor.RotaParams(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vInt: Integer;
  vParam: TRALParam;
  vSaida: string;
begin
  vSaida := '';
  for vInt := 0 to ARequest.Params.Count - 1 do
  begin
    vParam := ARequest.Params.Index[vInt];
    case vParam.Kind of
      rpkQUERY: vSaida := vSaida + 'query ';
      rpkBODY: vSaida := vSaida + 'body ';
      rpkFIELD: vSaida := vSaida + 'field ';
      rpkCOOKIE: vSaida := vSaida + 'cookie ';
    else
      Continue;
    end;
    vSaida := vSaida + string(vParam.ParamName) + '=' + string(vParam.AsString) + sLineBreak;
  end;
  AResponse.Answer(HTTP_OK, StringRAL(vSaida), rctTEXTPLAIN);
end;

procedure TfServidor.RotaMultipart(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vInt: Integer;
  vParam: TRALParam;
  vSaida: string;
  vTotal: Int64;
begin
  vSaida := '';
  vTotal := 0;
  for vInt := 0 to ARequest.Params.Count - 1 do
  begin
    vParam := ARequest.Params.Index[vInt];
    if not (vParam.Kind in [rpkBODY, rpkFIELD]) then
      Continue;
    vSaida := vSaida + Format('parte %s: %d bytes, tipo %s, arquivo "%s"',
      [string(vParam.ParamName), vParam.Size, string(vParam.ContentType),
       string(vParam.FileName)]) + sLineBreak;
    vTotal := vTotal + vParam.Size;
  end;
  vSaida := vSaida + Format('total: %d bytes', [vTotal]);
  AResponse.Answer(HTTP_OK, StringRAL(vSaida), rctTEXTPLAIN);
end;

procedure TfServidor.RotaEco(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, ARequest.RequestText, rctTEXTPLAIN);
end;

{ Uma rota que espera. Com PoolCount = 1 duas destas ao mesmo tempo demoram o
  dobro - e' o que o campo PoolCount da tela deixa ver. }
procedure TfServidor.RotaLenta(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  Sleep(ROTA_LENTA_MS);
  AResponse.Answer(HTTP_OK, 'ok', rctTEXTPLAIN);
end;

end.
