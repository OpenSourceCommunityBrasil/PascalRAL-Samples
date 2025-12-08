unit uMercadoPago;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient,
  System.JSON, System.Generics.Collections, System.NetEncoding;

type
  TMercadoPago = class
  private
    FAccessToken: string;
    FPublicKey: string;
    FBaseURL: string;
    FHttp: THTTPClient;
    FResponseContent: string;
    FStatusCode: integer;
    FClienteId: string;
    FErrorMessage: string;
    FTokenCartaoId: string;
    FCartaoId: string;
    FPaymentMethodId: string;
    FTokenCartaoCompra: string;
    FWebhookURL: string;
    FLinhaDigitavel: string;
    FURLPagamento: string;
    FPaymentId: string;
    FExternalReference: string;
    FPaymentStatus: string;
    FQRCodeBase64: string;
    FQRCode: string;

    function CreateRequest(AMethod, AUrl, AJsonBody: string;
                           Headers: TArray<TNameValuePair> = nil): integer;
    function AuthHeaders(const Extra: TArray<TNameValuePair> = nil): TArray<TNameValuePair>;
    function Url(const Path: string): string;
    procedure ProcessarRetornoCliente(json: string);
    procedure ProcessarRetornoErro(json: string);
    procedure ProcessarRetornoTokenCartao(json: string);
    procedure ProcessarRetornoCartaoId(json: string);
    procedure ProcessarRetornoTokenCompra(json: string);
    function NewIdempotencyKey: string;
    procedure ProcessarRetornoPayment(json: string);
    procedure ProcessarRetornoConsultaPagto(json: string);
    procedure ProcessarRetornoPix(json: string);

  public
    constructor Create;
    destructor Destroy; override;

    property ClienteId: string read FClienteId write FClienteId;
    property TokenCartaoId: string read FTokenCartaoId write FTokenCartaoId;
    property CartaoId: string read FCartaoId write FCartaoId;
    property PaymentMethodId: string read FPaymentMethodId write FPaymentMethodId;
    property TokenCartaoCompra: string read FTokenCartaoCompra write FTokenCartaoCompra;
    property PaymentId: string read FPaymentId write FPaymentId;
    property LinhaDigitavel: string read FLinhaDigitavel write FLinhaDigitavel;
    property URLPagamento: string read FURLPagamento write FURLPagamento;
    property PaymentStatus: string read FPaymentStatus write FPaymentStatus;
    property ExternalReference: string read FExternalReference write FExternalReference;
    property QRCode: string read FQRCode write FQRCode;
    property QRCodeBase64: string read FQRCodeBase64 write FQRCodeBase64;


    property ResponseContent: string read FResponseContent write FResponseContent;
    property StatusCode: integer read FStatusCode write FStatusCode;
    property ErrorMessage: string read FErrorMessage write FErrorMessage;

    function ListPaymentMethods: boolean;
    function CreateCustomer(Email, FirstName, LastName, DocType,
                            DocNumber: string): boolean;
    function CreateCardToken(const CardNumber: string; ExpMonth,
                              ExpYear: Integer; const CVV, HolderName, DocType,
                              DocNumber: string): boolean;
    function SaveCardToCustomer(const CustomerId, CardToken: string): boolean;
    function CreateTokenFromSavedCard(const CardId, CVV: string): boolean;
    function PayWithCard(const Value: Double; const CardToken,
                          Description: string; Installments: Integer; const PaymentMethodId,
                          IdempotencyKey, CustomerId, PayerEmail,
                          ExternalReference: string): boolean;
    function GetPayment(const PaymentId: string): boolean;
    function PayWithBoleto(const Value: Double; const Description,
                          IdempotencyKey, PaymentMethodId, CustomerId, FirstName, LastName, DocType,
                          DocNumber, ZipCode, StreetName, StreetNumber, Neighborhood, City, StateUF,
                          ExternalReference: string): boolean;
    function PayWithPix(const Amount: Double; const Description, CustomerId,
                      IdempotencyKey, ExternalReference: string): boolean;
  end;

implementation

constructor TMercadoPago.Create;
begin
  FAccessToken := 'TEST-??????????????????????????????????????????????????????';
  FPublicKey := 'TEST-????????????????????????????';
  FBaseURL := 'https://api.mercadopago.com';
  FWebhookURL := 'http://23.22.2.201:9000/webhook';
  FHttp := THTTPClient.Create;
  FHttp.ConnectionTimeout := 15000; // ms
  FHttp.ResponseTimeout := 30000;   // ms
end;

destructor TMercadoPago.Destroy;
begin
  FHttp.Free;
  inherited;
end;

function TMercadoPago.Url(const Path: string): string;
begin
  Result := FBaseURL + Path;
end;

function TMercadoPago.AuthHeaders(const Extra: TArray<TNameValuePair>):
                                  TArray<TNameValuePair>;
var
  Base: TArray<TNameValuePair>;
  I, N: Integer;
begin
  SetLength(Base, 2);
  Base[0] := TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken);
  Base[1] := TNameValuePair.Create('Content-Type', 'application/json');

  if (Extra = nil) or (Length(Extra) = 0) then
    Exit(Base);

  N := Length(Base);
  SetLength(Base, N + Length(Extra));

  for I := 0 to High(Extra) do
    Base[N + I] := Extra[I];

  Result := Base;
end;

function TMercadoPago.CreateRequest(AMethod, AUrl, AJsonBody: string;
                                    Headers: TArray<TNameValuePair> = nil): integer;
var
  Resp: IHTTPResponse;
  Body: TStringStream;
  Hdrs: TArray<TNameValuePair>;
begin

  if Headers = nil then
    Hdrs := AuthHeaders
  else
    Hdrs := AuthHeaders(Headers);

  Body := TStringStream.Create(AJsonBody, TEncoding.UTF8);
  //ContentBody := AJsonBody;
  try
    if AMethod = 'GET' then
      Resp := FHttp.Get(AUrl, nil, Hdrs)
    else if AMethod = 'POST' then
      Resp := FHttp.Post(AUrl, Body, nil, Hdrs)
    else if AMethod = 'PUT' then
      Resp := FHttp.Put(AUrl, Body, nil, Hdrs)
    else
      raise Exception.Create('Método HTTP não suportado: ' + AMethod);

    ResponseContent := Resp.ContentAsString;
    StatusCode := Resp.StatusCode;
    Result := Resp.StatusCode;
  finally
      Body.Free;
  end;
end;

function TMercadoPago.ListPaymentMethods: boolean;
begin
  Result := CreateRequest('GET', Url('/v1/payment_methods'), '') = 200;
end;

procedure TMercadoPago.ProcessarRetornoCliente(json: string);
var
    jsonObj: TJSONObject;
begin
    try
        jsonObj := TJSONObject.ParseJSONValue(json) as TJSONObject;

        Self.ClienteId := jsonObj.GetValue<string>('id', '');
    finally
        FreeAndNil(jsonObj);
    end;
end;

procedure TMercadoPago.ProcessarRetornoErro(json: string);
var
    jsonObj: TJSONObject;
    jsonArray: TJSONArray;
    erros: string;
    i: integer;
begin
    try
        erros := '';
        jsonObj := TJSONObject.ParseJSONValue(json) as TJSONObject;

        erros := jsonObj.getvalue<string>('message', '');

        jsonArray := jsonObj.GetValue<TJSONArray>('cause');

        for i := 0 to jsonArray.Size - 1 do
        begin
          if TJSONObject(jsonArray[i]).GetValue<string>('description', '') <> '' then
          begin
            if erros <> '' then
                erros := erros + ', ';

              erros := erros + TJSONObject(jsonArray[i]).GetValue<string>('description', '');
          end;
        end;

        Self.ErrorMessage := erros;

    finally
        FreeAndNil(jsonObj);
    end;
end;

procedure TMercadoPago.ProcessarRetornoTokenCartao(json: string);
var
    jsonObj: TJSONObject;
begin
    try
        jsonObj := TJSONObject.ParseJSONValue(json) as TJSONObject;

        Self.TokenCartaoId := jsonObj.GetValue<string>('id', '');
    finally
        FreeAndNil(jsonObj);
    end;
end;

procedure TMercadoPago.ProcessarRetornoCartaoId(json: string);
var
    jsonObj: TJSONObject;
begin
    try
        jsonObj := TJSONObject.ParseJSONValue(json) as TJSONObject;

        Self.CartaoId := jsonObj.GetValue<string>('id', '');
        Self.PaymentMethodId := jsonObj.GetValue<TJsonObject>('payment_method')
                                       .GetValue<string>('id', '');
    finally
        FreeAndNil(jsonObj);
    end;
end;

procedure TMercadoPago.ProcessarRetornoTokenCompra(json: string);
var
    jsonObj: TJSONObject;
begin
    try
        jsonObj := TJSONObject.ParseJSONValue(json) as TJSONObject;

        Self.TokenCartaoCompra := jsonObj.GetValue<string>('id', '');
    finally
        FreeAndNil(jsonObj);
    end;
end;

procedure TMercadoPago.ProcessarRetornoPayment(json: string);
var
    jsonObj: TJSONObject;
begin
    try
        jsonObj := TJSONObject.ParseJSONValue(json) as TJSONObject;

        Self.PaymentId := jsonObj.GetValue<string>('id', '');

        if jsonObj.GetValue<TJsonObject>('transaction_details') <> nil then
          Self.LinhaDigitavel := jsonObj.GetValue<TJsonObject>('transaction_details')
                                        .GetValue<string>('digitable_line', '');

        if jsonObj.GetValue<TJsonObject>('transaction_details') <> nil then
          Self.URLPagamento := jsonObj.GetValue<TJsonObject>('transaction_details')
                                      .GetValue<string>('external_resource_url', '');

    finally
        FreeAndNil(jsonObj);
    end;
end;

procedure TMercadoPago.ProcessarRetornoConsultaPagto(json: string);
var
    jsonObj: TJSONObject;
begin
    try
        jsonObj := TJSONObject.ParseJSONValue(json) as TJSONObject;

        Self.ExternalReference := jsonObj.GetValue<string>('external_reference', '');
        Self.PaymentStatus := jsonObj.GetValue<string>('status', '');
    finally
        FreeAndNil(jsonObj);
    end;
end;

procedure TMercadoPago.ProcessarRetornoPix(json: string);
var
    jsonObj: TJSONObject;
begin
    try
        jsonObj := TJSONObject.ParseJSONValue(json) as TJSONObject;

        Self.PaymentId := jsonObj.GetValue<string>('id', '');

        if jsonObj.GetValue<TJsonObject>('point_of_interaction') <> nil then
        begin
          Self.URLPagamento := jsonObj.GetValue<TJsonObject>('point_of_interaction')
                                      .GetValue<TJsonObject>('transaction_data')
                                      .GetValue<string>('ticket_url', '');

          Self.QRCode := jsonObj.GetValue<TJsonObject>('point_of_interaction')
                                      .GetValue<TJsonObject>('transaction_data')
                                      .GetValue<string>('qr_code', '');


          Self.QRCodeBase64 := jsonObj.GetValue<TJsonObject>('point_of_interaction')
                                      .GetValue<TJsonObject>('transaction_data')
                                      .GetValue<string>('qr_code_base64', '');
        end;


    finally
        FreeAndNil(jsonObj);
    end;
end;

function TMercadoPago.NewIdempotencyKey: string;
begin
  Result := TGUID.NewGuid.ToString.Replace('{','').Replace('}','');
end;

function TMercadoPago.CreateCustomer(Email, FirstName, LastName,
                                     DocType, DocNumber: string): boolean;
var
  J: TJSONObject;
  Ident: TJSONObject;
begin
  J := TJSONObject.Create;
  try
    if Email <> '' then J.AddPair('email', Email);
    if FirstName <> '' then J.AddPair('first_name', FirstName);
    if LastName <> '' then J.AddPair('last_name', LastName);
    if (DocType <> '') and (DocNumber <> '') then
    begin
      Ident := TJSONObject.Create;
      Ident.AddPair('type', DocType);
      Ident.AddPair('number', DocNumber);
      J.AddPair('identification', Ident);
    end;

    Result := CreateRequest('POST', Url('/v1/customers'), J.ToJSON) = 201;

    if Result then
      ProcessarRetornoCliente(ResponseContent)
    else
      ProcessarRetornoErro(ResponseContent);

  finally
    J.Free;
  end;

end;

function TMercadoPago.CreateCardToken(const CardNumber: string; ExpMonth, ExpYear: Integer;
                                      const CVV, HolderName, DocType,
                                      DocNumber: string): boolean;
var
  J, Holder, Ident: TJSONObject;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('card_number', CardNumber);
    J.AddPair('expiration_month', TJSONNumber.Create(ExpMonth));
    J.AddPair('expiration_year',  TJSONNumber.Create(ExpYear));
    J.AddPair('security_code', CVV);

    Holder := TJSONObject.Create;
    Holder.AddPair('name', HolderName);

    if (DocType <> '') and (DocNumber <> '') then
    begin
      Ident := TJSONObject.Create;
      Ident.AddPair('type', DocType);
      Ident.AddPair('number', DocNumber);
      Holder.AddPair('identification', Ident);
    end;

    J.AddPair('cardholder', Holder);

    Result := CreateRequest('POST', Url('/v1/card_tokens'), J.ToJSON) = 201;

    if Result then
      ProcessarRetornoTokenCartao(ResponseContent)
    else
      ProcessarRetornoErro(ResponseContent);

  finally
    J.Free;
  end;
end;

function TMercadoPago.SaveCardToCustomer(const CustomerId, CardToken: string): boolean;
var
  J: TJSONObject;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('token', CardToken);
    Result := CreateRequest('POST', Url('/v1/customers/' + CustomerId + '/cards'),
                J.ToJSON) = 201;

    if Result then
      ProcessarRetornoCartaoId(ResponseContent)
    else
      ProcessarRetornoErro(ResponseContent);
  finally
    J.Free;
  end;
end;

function TMercadoPago.CreateTokenFromSavedCard(const CardId, CVV: string): boolean;
var
  J: TJSONObject;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('card_id', CardId);
    J.AddPair('security_code', CVV);
    Result := CreateRequest('POST', Url('/v1/card_tokens'), J.ToJSON) = 201;

    if Result then
      ProcessarRetornoTokenCompra(ResponseContent)
    else
      ProcessarRetornoErro(ResponseContent);
  finally
    J.Free;
  end;
end;

function TMercadoPago.PayWithCard(const Value: Double; const CardToken, Description: string;
                                  Installments: Integer; const PaymentMethodId: string;
                                  const IdempotencyKey: string;
                                  const CustomerId: string; const PayerEmail: string;
                                  const ExternalReference: string): boolean;
var
  J, Payer: TJSONObject;
  Headers: TArray<TNameValuePair>;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('transaction_amount', TJSONNumber.Create(Value));
    J.AddPair('token', CardToken);
    J.AddPair('description', Description);
    J.AddPair('installments', TJSONNumber.Create(Installments));
    if PaymentMethodId <> '' then
      J.AddPair('payment_method_id', PaymentMethodId);

    Payer := TJSONObject.Create;
    if CustomerId <> '' then
    begin
      Payer.AddPair('type', 'customer');
      Payer.AddPair('id', CustomerId);
    end
    else if PayerEmail <> '' then
      Payer.AddPair('email', PayerEmail);
    J.AddPair('payer', Payer);

    if ExternalReference <> '' then
      J.AddPair('external_reference', ExternalReference);
    if FWebhookURL <> '' then
      J.AddPair('notification_url', FWebhookURL);

    SetLength(Headers, 1);

    If IdempotencyKey <> '' then
      Headers[0] := TNameValuePair.Create('X-Idempotency-Key', IdempotencyKey)
    else
      Headers[0] := TNameValuePair.Create('X-Idempotency-Key', NewIdempotencyKey);

    Result := CreateRequest('POST', Url('/v1/payments'), J.ToJSON, Headers) = 201;

    if Result then
      ProcessarRetornoPayment(ResponseContent)
    else
      ProcessarRetornoErro(ResponseContent);
  finally
    J.Free;
  end;
end;

function TMercadoPago.PayWithPix(const Amount: Double; const Description, CustomerId,
  IdempotencyKey, ExternalReference: string): boolean;
var
  J, Payer: TJSONObject;
  Headers: TArray<TNameValuePair>;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('transaction_amount', TJSONNumber.Create(Amount));
    J.AddPair('description', Description);
    J.AddPair('payment_method_id', 'pix');

    Payer := TJSONObject.Create;
    Payer.AddPair('type', 'customer');
    Payer.AddPair('id', CustomerId);

    J.AddPair('payer', Payer);

    if ExternalReference <> '' then
      J.AddPair('external_reference', ExternalReference);
    if FWebhookURL <> '' then
      J.AddPair('notification_url', FWebhookURL);

    SetLength(Headers, 1);

    If IdempotencyKey <> '' then
      Headers[0] := TNameValuePair.Create('X-Idempotency-Key', IdempotencyKey)
    else
      Headers[0] := TNameValuePair.Create('X-Idempotency-Key', NewIdempotencyKey);

    Result := CreateRequest('POST', Url('/v1/payments'), J.ToJSON, Headers) = 201;

    if Result then
      ProcessarRetornoPix(ResponseContent)
    else
      ProcessarRetornoErro(ResponseContent);
  finally
    J.Free;
  end;
end;

function TMercadoPago.PayWithBoleto(const Value: Double; const Description, IdempotencyKey: string;
  const PaymentMethodId, CustomerId, FirstName, LastName, DocType, DocNumber: string;
  const ZipCode, StreetName, StreetNumber, Neighborhood, City, StateUF,
  ExternalReference: string): boolean;
var
  J, Payer, Ident, Addr: TJSONObject;
  Headers: TArray<TNameValuePair>;
begin
  J := TJSONObject.Create;
  try
    J.AddPair('transaction_amount', TJSONNumber.Create(Value));
    J.AddPair('description', Description);
    J.AddPair('payment_method_id', PaymentMethodId);

    Payer := TJSONObject.Create;
    Payer.AddPair('type', 'customer');
    Payer.AddPair('id', CustomerId);
    if FirstName <> '' then Payer.AddPair('first_name', FirstName);
    if LastName  <> '' then Payer.AddPair('last_name', LastName);

    if (DocType <> '') and (DocNumber <> '') then
    begin
      Ident := TJSONObject.Create;
      Ident.AddPair('type', DocType);
      Ident.AddPair('number', DocNumber);
      Payer.AddPair('identification', Ident);
    end;

    Addr := TJSONObject.Create;
    Addr.AddPair('zip_code', ZipCode);
    Addr.AddPair('street_name', StreetName);
    Addr.AddPair('street_number', StreetNumber);
    Addr.AddPair('neighborhood', Neighborhood);
    Addr.AddPair('city', City);
    Addr.AddPair('federal_unit', StateUF);
    Payer.AddPair('address', Addr);

    J.AddPair('payer', Payer);

    if ExternalReference <> '' then
      J.AddPair('external_reference', ExternalReference);
    if FWebhookURL <> '' then
      J.AddPair('notification_url', FWebhookURL);

    SetLength(Headers, 1);

    If IdempotencyKey <> '' then
      Headers[0] := TNameValuePair.Create('X-Idempotency-Key', IdempotencyKey)
    else
      Headers[0] := TNameValuePair.Create('X-Idempotency-Key', NewIdempotencyKey);

    Result := CreateRequest('POST', Url('/v1/payments'), J.ToJSON, Headers) = 201;

    if Result then
      ProcessarRetornoPayment(ResponseContent)
    else
      ProcessarRetornoErro(ResponseContent);
  finally
    J.Free;
  end;
end;

function TMercadoPago.GetPayment(const PaymentId: string): boolean;
begin
  Result := CreateRequest('GET', Url('/v1/payments/' + PaymentId), '') = 200;

  if Result then
      ProcessarRetornoConsultaPagto(ResponseContent)
    else
      ProcessarRetornoErro(ResponseContent);

end;

end.
