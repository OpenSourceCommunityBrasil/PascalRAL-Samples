unit uStripe;

interface

uses
  System.SysUtils, System.Net.HttpClient, System.JSON,
  System.Classes;

type
  TStripe = class
  public
    class function CreateCheckoutSession(ASecretKey, APriceID,
                                         ASuccessURL, ACancelURL, Customer: string;
                                         Id_usuario: integer): string;
    class procedure CancelarAssinaturaFinalPeriodo(ASecretKey, SubscriptionID: string);
  end;

implementation


class function TStripe.CreateCheckoutSession(ASecretKey, APriceID, ASuccessURL,
                                             ACancelURL, Customer: string;
                                             Id_usuario: integer): string;
var
  Client: THttpClient;
  Params: TStringList;
  Resp: IHTTPResponse;
  Json: TJSONObject;
begin
  Result := '';
  Client := THttpClient.Create;
  Params := TStringList.Create;
  try
    Client.CustomHeaders['Authorization'] := 'Bearer ' + ASecretKey;
    Client.CustomHeaders['Content-Type'] := 'application/x-www-form-urlencoded';

    Params.Add('mode=subscription');
    Params.Add('line_items[0][price]=' + APriceID);
    Params.Add('line_items[0][quantity]=1');
    Params.Add('success_url=' + ASuccessURL);
    Params.Add('cancel_url=' + ACancelURL);
    Params.Add('subscription_data[metadata][id_usuario]=' + Id_usuario.ToString);

    // Se passou um customer id, deve criar a fatura para ele...
    if Customer <> '' then
      Params.Add('customer=' + Customer);
    //-------------------------------------

    Resp := Client.Post('https://api.stripe.com/v1/checkout/sessions', Params);

    if Resp.StatusCode = 200 then
    begin
      Json := TJSONObject.ParseJSONValue(Resp.ContentAsString) as TJSONObject;
      try
        Result := Json.GetValue<string>('url');
      finally
        Json.Free;
      end;
    end
    else
      raise Exception.Create('Erro ao criar sessão: ' + Resp.ContentAsString);
  finally
    Params.Free;
    Client.Free;
  end;
end;

class procedure TStripe.CancelarAssinaturaFinalPeriodo(ASecretKey, SubscriptionID: string);
var
  Client: THttpClient;
  Params: TStringList;
  Resp: IHTTPResponse;
  Url: string;
begin
  Client := THttpClient.Create;
  Params := TStringList.Create;
  try
    Url := 'https://api.stripe.com/v1/subscriptions/' + SubscriptionID;

    Client.CustomHeaders['Authorization'] := 'Bearer ' + ASecretKey;
    Client.CustomHeaders['Content-Type'] := 'application/x-www-form-urlencoded';

    Params.Add('cancel_at_period_end=true');

    Resp := Client.Post(Url, Params);

    if Resp.StatusCode <> 200 then
      raise Exception.Create(Resp.ContentAsString());

  finally
    Params.Free;
    Client.Free;
  end;
end;

end.

