unit Controllers.Servico;

interface

uses
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts, RALTypes,
  System.SysUtils, System.JSON, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarServicos(Req: TRALRequest; Res: TRALResponse);
procedure ListarPrestadores(Req: TRALRequest; Res: TRALResponse);
procedure ListarHorarios(Req: TRALRequest; Res: TRALResponse);
procedure ListarReservas(Req: TRALRequest; Res: TRALResponse);
procedure InserirReserva(Req: TRALRequest; Res: TRALResponse);
procedure ExcluirReserva(Req: TRALRequest; Res: TRALResponse);
procedure ListarAssinantes(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
{
  Por padrão, o RAL permite todos os verbos na rota, para limitar a rota a responder
  apenas um ou alguns deles, utiliza-se a forma abaixo ou captura a rota antes e altera
  os AllowedMethods dela, por exemplo:
  var Rota: TRALRoute := AServer.CreateRoute(endpoint, método_resposta);
  Rota.AllowedMethods := [amGET, amPOST, amPUT...];

  O caminho da rota ou endpoint não precisa começar com '/', mas se criar rotas
  começando com '/', internamente o RAL corrige pro formato correto.
}
  AServer.CreateRoute('servicos', ListarServicos).AllowedMethods := [amGET];
  AServer.CreateRoute('servicos/:id_servico/prestadores', ListarPrestadores).AllowedMethods := [amGET];
  AServer.CreateRoute('horarios', ListarHorarios).AllowedMethods := [amGET];
  AServer.CreateRoute('reservas', ListarReservas).AllowedMethods := [amGET];
  AServer.CreateRoute('reservas', InserirReserva).AllowedMethods := [amPOST];
  AServer.CreateRoute('reservas/:id_reserva', ExcluirReserva).AllowedMethods := [amDELETE];
  AServer.CreateRoute('assinantes', ListarAssinantes).AllowedMethods := [amGET];
  //  AServer.CreateRoute('assinantes', InserirAssinantes).AllowedMethods := [amPOST];
  // ^-- Assinante cria conta demo no site...
end;

procedure ListarServicos(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  id_assinante: integer;
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
    {
      Se o parâmetro não existir, o RAL devolve o valor padrão(default) do tipo,
      no caso do integer, o padrão é 0.
    }
      id_assinante := Req.ParamByName('id_assinante').AsInteger;

      // Content-Type padrão do RAL é 'application/json', ele pode ser omitido
      Res.Answer(HTTP_OK, Dm.ListarServicos(id_assinante).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarPrestadores(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  id_servico: integer;
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
      id_servico := Req.ParamByName('id_servico').AsInteger;
      Res.Answer(HTTP_OK, Dm.ListarPrestadores(id_servico).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarHorarios(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  id_servico, id_prestador: integer;
  dt: string; // yyyy-mm-dd
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
      // /horarios?id_servico=1&id_prestador=1&dt=2025-01-31
      id_servico := Req.ParamByName('id_servico').AsInteger;
      id_prestador := Req.ParamByName('id_prestador').AsInteger;
      dt := Req.ParamByName('dt').AsString;

      Res.Answer(HTTP_OK, Dm.ListarHorarios(id_servico, id_prestador, dt).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarReservas(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  id_usuario: integer;
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
      // /reservas?id_usuario=123
      id_usuario := Req.ParamByName('id_usuario').AsInteger;

      Res.Answer(HTTP_OK, Dm.ListarReservas(id_usuario).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;

procedure InserirReserva(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  body: TJSONObject;
  id_usuario, id_servico, id_prestador, id_assinante: integer;
  dt, hora: string;
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;

      id_usuario := body.GetValue<integer>('id_usuario', 0);
      id_servico := body.GetValue<integer>('id_servico', 0);
      id_prestador := body.GetValue<integer>('id_prestador', 0);
      id_assinante := body.GetValue<integer>('id_assinante', 0);
      dt := body.GetValue<string>('dt_reserva', '');
      hora := body.GetValue<string>('hora_reserva', '');

      Res.Answer(HTTP_Created, Dm.InserirReserva(id_assinante, id_usuario, id_servico,
          id_prestador, dt, hora).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;

procedure ExcluirReserva(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  id_reserva: integer;
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
      id_reserva := Req.ParamByName('id_reserva').AsInteger;

      Res.Answer(HTTP_OK, Dm.ExcluirReserva(id_reserva).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarAssinantes(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  cidade: string;
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
      cidade := Req.ParamByName('cidade').AsString;

      Res.Answer(HTTP_OK, Dm.ListarAssinantes(cidade).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;

end.

