unit Controllers.Stripe;

interface

uses
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts, RALTypes, RALRoutes,
  System.SysUtils, System.JSON,
  Controllers.JWT, uStripe, Services.Stripe;

procedure RegistrarRotas(AServer: TRALServer);
procedure CriarCheckoutSession(Req: TRALRequest; Res: TRALResponse);
procedure WebhookStripe(Req: TRALRequest; Res: TRALResponse);
procedure CancelarAssinatura(Req: TRALRequest; Res: TRALResponse);

Const
  SecretKeyStripe = '???????????????';

implementation

uses UnitPrincipal;

procedure RegistrarRotas(AServer: TRALServer);
begin
{
  No exemplo original somente a última rota não tem autenticação, para manter o
  exemplo mais próximo do original, fizemos a autenticação JWT manual na rota também

  Porém, diferente do cavalim, o RAL possui autenticação JWT integrada diretamente
  no objeto do Servidor e a validação do JWT seria feita no OnValidate da autenticação
  em uma execução comum do RAL. Considerando esse cenário, nas rotas que não possuem
  autenticação, deveria ser informado o SkipAuthMethods na rota para evitar erro 401
  pela ausência de autenticação.
}
  // Rotas com autenticação
  AServer.CreateRoute('assinaturas/url', CriarCheckoutSession).AllowedMethods := [amPOST];
  AServer.CreateRoute('assinaturas/cancelamento', CancelarAssinatura)
    .AllowedMethods := [amPOST];
  // Rotas sem autenticação
  AServer.CreateRoute('webhook/stripe', WebhookStripe).AllowedMethods := [amPOST];
end;

procedure CriarCheckoutSession(Req: TRALRequest; Res: TRALResponse);
var
  secret_key, price_id, success_uRL, cancel_url, url, customer: string;
  id_usuario: integer;
  body: TJsonObject;
begin

  price_id := 'price_1RnpkaGIxmEKMVIq9OWO80wL';
  success_url := 'https://meusistema.com.br/sucesso';
  cancel_url := 'https://meusistema.com.br/erro';

  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    customer := body.GetValue<string>('customer', '');
    id_usuario := Get_Usuario_Request(Req);

    url := TStripe.CreateCheckoutSession(SecretKeyStripe, price_id, success_url,
                                         cancel_url, customer, id_usuario);
{
  Format é mais rápido e otimizado para formular strings do que concatenar com +,
  é a forma mais simples de concatenar strings de forma otimizada. A alternativa
  mais complexa e mais moderna seria usar TStringBuilder.

  No exemplo original, as strings estavam sendo concatenadas com +.

  O content-Type não tá sendo informado aqui, porque por padrão o RAL responde
  'application/json', então se o seu content-type de resposta for esse, pode ser
  omitido.
}
    Res.Answer(HTTP_OK, Format('{"url": "%s"}', [url]));
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure CancelarAssinatura(Req: TRALRequest; Res: TRALResponse);
var
  id_usuario: integer;
  stripe_assinatura_id: string;
  body: TJSONObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;

    stripe_assinatura_id := body.GetValue<string>('stripe_assinatura_id', '');
    id_usuario := Get_Usuario_Request(Req);


    TStripe.CancelarAssinaturaFinalPeriodo(SecretKeyStripe, stripe_assinatura_id);

    Services.Stripe.CancelarAssinatura(id_usuario);

    Res.Answer(HTTP_OK, 'Assinatura cancelada com sucesso', rctTEXTPLAIN);

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;

end;

procedure WebhookAssinaturaCriada(json: TJSONObject);
var
  DataObj, ObjectObj, PlanObj, MetadataObj : TJSONObject;
  StripeCustomerID, StripeAssinaturaID: string;
  VlAssinatura: double;
  id_usuario: integer;
begin
   // Campo             Caminho no JSON
  //----------------------------------------------------
  // id. cliente       data -> object -> customer
  // id. assinatura    data -> object -> id
  // valor do plano    data -> object -> plan -> amount
  // id. usuario       data -> object -> metadata -> id_usuario

  DataObj := json.GetValue<TJSONObject>('data');
  ObjectObj := DataObj.GetValue<TJSONObject>('object');
  PlanObj := ObjectObj.GetValue<TJSONObject>('plan');
  MetadataObj := ObjectObj.GetValue<TJSONObject>('metadata');

  StripeCustomerID := ObjectObj.GetValue<string>('customer', '');
  StripeAssinaturaID := ObjectObj.GetValue<string>('id', '');
  VlAssinatura := PlanObj.GetValue<double>('amount', 0) / 100;
  id_usuario := MetadataObj.GetValue<integer>('id_usuario', 0);

  Services.Stripe.WebhookAssinaturaCriada(id_usuario,
                                          StripeCustomerID,
                                          StripeAssinaturaID,
                                          VlAssinatura);

end;

procedure WebhookNovoPagamento(json: TJSONObject);
var
  ObjectObj: TJSONObject;
  StripeCustomerID: string;
begin
  // Campo             Caminho no JSON
  //----------------------------------------------------
  // id. cliente       data.object.customer

  ObjectObj  := json.GetValue<TJSONObject>('data')
                    .GetValue<TJSONObject>('object');

  StripeCustomerID := ObjectObj.GetValue<string>('customer', '');

  Services.Stripe.WebhookNovoPagamento(StripeCustomerID);

end;

procedure WebhookAssinaturaCancelada(json: TJSONObject);
var
  DataObj, ObjectObj : TJSONObject;
  StripeCustomerID, StripeAssinaturaID: string;
begin
  // Campo             Caminho no JSON
  //----------------------------------------------------
  // id. cliente       data -> object -> customer
  // id. assinatura    data -> object -> id

  //"cancel_at_period_end": true

  DataObj := json.GetValue<TJSONObject>('data');
  ObjectObj := DataObj.GetValue<TJSONObject>('object');

  StripeCustomerID := ObjectObj.GetValue<string>('customer', '');
  StripeAssinaturaID := ObjectObj.GetValue<string>('id', '');

  FrmPrincipal.Memo1.Lines.Add('****************************');
  FrmPrincipal.Memo1.Lines.Add(StripeCustomerID + ' - ' + StripeAssinaturaID);
  FrmPrincipal.Memo1.Lines.Add('****************************');

  //Services.Stripe.WebhookAssinaturaCancelada(StripeCustomerID, StripeAssinaturaID);
end;

procedure WebhookStripe(Req: TRALRequest; Res: TRALResponse);
var
  json_body: TJSONObject;
  event_type: string;
begin
  // Salvar log -> Req.body
  FrmPrincipal.Memo1.Lines.Add(Req.body.AsString);


  try
    json_body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    try
      event_type := json_body.GetValue<string>('type', '');

      // Criacao de nova assinatura
      if event_type = 'customer.subscription.created' then
        WebhookAssinaturaCriada(json_body)

      // Novo pagamento
      else if event_type = 'invoice.paid' then
        WebhookNovoPagamento(json_body);

      // Novo pagamento
      //else if event_type = 'customer.subscription.deleted' then
      //  WebhookAssinaturaCancelada(json_body);

      Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);
    finally
      FreeAndNil(json_body);
    end;

  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;


end;

end.

