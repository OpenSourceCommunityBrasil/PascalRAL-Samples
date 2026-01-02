unit Services.Stripe;

interface

uses
 System.SysUtils, System.JSON, Dm.Global;


procedure WebhookAssinaturaCriada(id_usuario: integer;
                                  StripeCustomerID, StripeAssinaturaID: string;
                                  VlAssinatura: double);
procedure WebhookNovoPagamento(StripeCustomerID: string);
procedure CancelarAssinatura(id_usuario: integer);

implementation

procedure WebhookAssinaturaCriada(id_usuario: integer;
                                  StripeCustomerID, StripeAssinaturaID: string;
                                  VlAssinatura: double);
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    dm.WebhookAssinaturaCriada(id_usuario, StripeCustomerID,
                               StripeAssinaturaID, VlAssinatura);

  finally
    FreeAndNil(dm);
  end;
end;

procedure WebhookNovoPagamento(StripeCustomerID: string);
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    dm.WebhookNovoPagamento(StripeCustomerID);

  finally
    FreeAndNil(dm);
  end;
end;

procedure CancelarAssinatura(id_usuario: integer);
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    dm.CancelarAssinatura(id_usuario);

  finally
    FreeAndNil(dm);
  end;
end;

end.

