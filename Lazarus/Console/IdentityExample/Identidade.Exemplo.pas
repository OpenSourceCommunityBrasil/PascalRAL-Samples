/// Identidade num servidor RAL 2.0: senhas com Argon2id, login JWT com segundo
/// fator (TOTP), papeis e politicas por rota, revogacao de tokens, troca de chave
/// e, se configurado, login por um provedor OpenID Connect.
/// Guias: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/autorizacao
///        https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/senhas
///        https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/oidc
unit Identidade.Exemplo;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils,
  RALServer, RALRequest, RALResponse, RALTypes, RALConsts, RALMIMETypes, RALToken,
  RALKeyValueStore, RALAuthBase, RALAuthentication, RALAuthorization, RALOIDC,
  RALOTP, RALPassword;

type
  /// Liga a autenticacao, as politicas e as rotas do exemplo num servidor.
  TIdentidadeExemplo = class
  private
    FAuthz: TRALAuthorizationPlugin;
    FJWT: TRALServerJWTAuth;
    FOIDC: TRALOIDCLogin;
    FSenhas: TRALPasswordList;
    FSegredoAna: StringRAL;
    FStore: TRALMemoryStore;
    FTotp: TRALTOTP;

    procedure Admin(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Entrar(ARequest: TRALRequest; AResponse: TRALResponse;
      AParams: TRALJWTParams; var AResult: boolean);
    procedure Perfil(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Publico(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Sair(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure SairDeTodos(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Vendas(ARequest: TRALRequest; AResponse: TRALResponse);
  public
    destructor Destroy; override;

    /// Liga tudo em AServer; o OIDC so' com RAL_OIDC_ISSUER no ambiente.
    procedure Montar(AServer: TRALServer);

    /// O URI otpauth:// da ana (mostre como QR code no aplicativo autenticador).
    function URIDaAna: StringRAL;
    /// O codigo TOTP da ana agora (para testar sem o celular).
    function CodigoDaAna: StringRAL;
  end;

implementation

destructor TIdentidadeExemplo.Destroy;
begin
  // cada plugin se desliga do servidor ao ser liberado
  FOIDC.Free;
  FAuthz.Free;
  FJWT.Free;
  FSenhas.Free;
  FStore.Free;
  FTotp.Free;
  inherited Destroy;
end;

procedure TIdentidadeExemplo.Montar(AServer: TRALServer);
var
  vRegra: TRALAuthPolicy;
begin
  { senhas: so' o hash fica guardado (Argon2id, parametros da OWASP) }
  FSenhas := TRALPasswordList.Create(nil);
  FSenhas.SetPassword('ana', 'senha-da-ana');
  FSenhas.SetPassword('bia', 'senha-da-bia');

  { segundo fator da ana }
  FTotp := TRALTOTP.Create;
  FTotp.Issuer := 'Exemplo RAL';
  FStore := TRALMemoryStore.Create(nil);
  FTotp.Store := FStore;          // o mesmo codigo nao vale duas vezes
  FSegredoAna := FTotp.NewSecret;

  { JWT: duas chaves (a mais nova assina, a antiga ainda confere) e a
    revogacao no store }
  FJWT := TRALServerJWTAuth.Create(nil);
  FJWT.Keys.AddSecret('2026-10', 'chave-antiga-troque-me');
  FJWT.Keys.AddSecret('2026-11', 'chave-nova-troque-me');
  FJWT.RevocationStore := FStore;
  FJWT.ExpirationSecs := 900;
  FJWT.OnGetToken := Entrar;
  AServer.Authentication := FJWT;

  { politica: papel vendas ou admin, e de um departamento conhecido }
  FAuthz := TRALAuthorizationPlugin.Create(nil);
  vRegra := FAuthz.Policies.AddPolicy('vendas', 'vendas,admin');
  vRegra.Claims.Add('dept=comercial|ti');
  FAuthz.Server := AServer;

  AServer.CreateRoute('publico', Publico).SkipAuth([amALL]);
  AServer.CreateRoute('perfil', Perfil);
  AServer.CreateRoute('admin', Admin).RequireRoles('admin');
  AServer.CreateRoute('vendas', Vendas).Policy := 'vendas';
  AServer.CreateRoute('sair', Sair).Allow([amPOST]);
  AServer.CreateRoute('sair-de-todos', SairDeTodos).Allow([amPOST]).RequireRoles('admin');

  { login por um provedor (Keycloak, Google, Entra ID...), se configurado:
    RAL_OIDC_ISSUER, RAL_OIDC_CLIENT e RAL_OIDC_SECRET }
  if GetEnvironmentVariable('RAL_OIDC_ISSUER') <> '' then
  begin
    FJWT.UseCookie := True;
    FOIDC := TRALOIDCLogin.Create(nil);
    FOIDC.Issuer := StringRAL(GetEnvironmentVariable('RAL_OIDC_ISSUER'));
    FOIDC.ClientID := StringRAL(GetEnvironmentVariable('RAL_OIDC_CLIENT'));
    FOIDC.ClientSecret := StringRAL(GetEnvironmentVariable('RAL_OIDC_SECRET'));
    FOIDC.Session := FJWT;
    FOIDC.PostLoginRedirect := '/perfil';
    FOIDC.Server := AServer;
  end;
end;

function TIdentidadeExemplo.URIDaAna: StringRAL;
begin
  Result := FTotp.URI('ana', FSegredoAna);
end;

function TIdentidadeExemplo.CodigoDaAna: StringRAL;
begin
  Result := FTotp.Code(FSegredoAna);
end;

{ POST /gettoken com usuario, senha (e codigo, para a ana): o JWT sai com os
  papeis e o departamento }
procedure TIdentidadeExemplo.Entrar(ARequest: TRALRequest; AResponse: TRALResponse;
  AParams: TRALJWTParams; var AResult: boolean);
var
  vUsuario: StringRAL;
begin
  vUsuario := ARequest.ParamByName('usuario').AsString;
  AResult := FSenhas.Verify(vUsuario, ARequest.ParamByName('senha').AsString);
  if AResult and (vUsuario = 'ana') then
    AResult := FTotp.Verify(FSegredoAna, ARequest.ParamByName('codigo').AsString, 'ana');
  if not AResult then
    Exit;
  AParams.Subject := vUsuario;
  if vUsuario = 'ana' then
  begin
    AParams.AddClaim('roles', '["admin"]');
    AParams.AddClaim('dept', 'ti');
  end
  else
  begin
    AParams.AddClaim('roles', '["vendas"]');
    AParams.AddClaim('dept', 'comercial');
  end;
end;

procedure TIdentidadeExemplo.Publico(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'qualquer um entra aqui', rctTEXTPLAIN);
end;

procedure TIdentidadeExemplo.Perfil(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'usuario ' + ARequest.Identity.Name + ', papeis: ' +
    StringRAL(StringReplace(ARequest.Identity.Roles.Text, sLineBreak, ' ',
    [rfReplaceAll])), rctTEXTPLAIN);
end;

procedure TIdentidadeExemplo.Admin(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'area do admin', rctTEXTPLAIN);
end;

procedure TIdentidadeExemplo.Vendas(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'relatorio de vendas para ' + ARequest.Identity.Name +
    ' (' + ARequest.Identity.Claim('dept') + ')', rctTEXTPLAIN);
end;

procedure TIdentidadeExemplo.Sair(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  { este token deixa de valer ja', mesmo antes de expirar }
  FJWT.Revoke(ARequest.Authorization.AuthString);
  AResponse.Answer(HTTP_OK, 'token revogado', rctTEXTPLAIN);
end;

procedure TIdentidadeExemplo.SairDeTodos(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  { todos os tokens da bia emitidos ate' agora }
  FJWT.RevokeAllFor('bia');
  AResponse.Answer(HTTP_OK, 'a bia saiu de todos os aparelhos', rctTEXTPLAIN);
end;

end.
