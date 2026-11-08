program RALWSSecurityExample;

{ A SOAP service that asks for the WS-Security UsernameToken, and the client that
  sends it as a digest. Both run in this process through the InProc engine, so
  the example needs no port; with a real engine nothing else changes. At the end
  the Body of the answer is written in canonical form (exclusive C14N), what an
  XML signature hashes. }

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  Classes, SysUtils,
  RALTypes, RALRequest, RALServer, RALClient, RALInProc, RALXML, RALXMLC14N,
  RALSOAPTypes, RALSOAPModule, RALSOAPClient, RALWSSecurity, RALWSSecurityAuth;

type
  TCalc = class
    procedure Somar(ARequest: TRALSOAPRequest; AResponse: TRALSOAPResponse);
    procedure SenhaDe(ARequest: TRALRequest; const AUserName: StringRAL;
      var APassword: StringRAL; var AFound: boolean);
  end;

procedure TCalc.Somar(ARequest: TRALSOAPRequest; AResponse: TRALSOAPResponse);
var
  vSoma: Integer;
begin
  vSoma := StrToInt(string(ARequest.ParamValue('a', '0'))) +
    StrToInt(string(ARequest.ParamValue('b', '0')));
  // who logged in: the authenticator filled the identity
  AResponse.AddResult('SomarResult').WithText(StringRAL(IntToStr(vSoma)));
  AResponse.AddResult('Usuario').WithText(ARequest.Core.Identity.Name);
end;

procedure TCalc.SenhaDe(ARequest: TRALRequest; const AUserName: StringRAL;
  var APassword: StringRAL; var AFound: boolean);
begin
  // a real service reads the user table here
  AFound := (AUserName = 'alice') or (AUserName = 'bob');
  if AUserName = 'alice' then
    APassword := 's3cret'
  else if AUserName = 'bob' then
    APassword := 'b0b-pass';
end;

procedure Chamar(const AUser, APassword: StringRAL; ATipo: TRALWSSPasswordType);
var
  vCliente: TRALSOAPClient;
  vOp: TRALSOAPClientOperation;
  vResposta: TRALXMLDocument;
begin
  vCliente := TRALSOAPClient.Create(nil);
  try
    vCliente.EngineType := 'InProc';
    vCliente.BaseURL.Text := 'inproc://calc';
    vCliente.ServicePath := '/calc';
    vCliente.Namespace := 'urn:calc';
    vCliente.Security.UserName := AUser;
    vCliente.Security.Password := APassword;
    vCliente.Security.PasswordType := ATipo;
    vOp := vCliente.Operations.Add as TRALSOAPClientOperation;
    vOp.Name := 'Somar';
    vOp.Params.AddParam('a', '2');
    vOp.Params.AddParam('b', '3');
    try
      vResposta := vCliente.Call('Somar');
      try
        WriteLn(AUser, ': ', vResposta.GetText('//SomarResult'), ' (logado como ',
          vResposta.GetText('//Usuario'), ')');
        WriteLn('  Body canonico: ', RALXMLCanonicalize(vResposta.GetNode('//Body'), xcmExclusive));
      finally
        vResposta.Free;
      end;
    except
      on E: ERALSOAPFault do
        WriteLn(AUser, ': recusado - ', E.Reason);
    end;
  finally
    vCliente.Free;
  end;
end;

var
  vCalc: TCalc;
  vServidor: TRALInProcServer;
  vModulo: TRALSOAPModule;
  vAuth: TRALServerWSSecurityAuth;
begin
  vCalc := TCalc.Create;
  vServidor := TRALInProcServer.Create(nil);
  vModulo := TRALSOAPModule.Create(nil);
  vAuth := TRALServerWSSecurityAuth.Create(nil);
  try
    vServidor.ServerName := 'calc';
    vModulo.Domain := '/calc';
    vModulo.Namespace := 'urn:calc';
    vModulo.AddOperation('Somar', vCalc.Somar, 'Soma dois inteiros');
    vModulo.Server := vServidor;

    vAuth.OnGetPassword := vCalc.SenhaDe;
    vAuth.PasswordTypes := [wptDigest];   // only the digest: the password never travels
    vServidor.Authentication := vAuth;
    vServidor.Active := True;

    Chamar('alice', 's3cret', wptDigest);
    Chamar('bob', 'b0b-pass', wptDigest);
    Chamar('alice', 'errada', wptDigest);
    Chamar('alice', 's3cret', wptText);     // refused: PasswordTypes allows the digest only

    vServidor.Active := False;
  finally
    vServidor.Authentication := nil;
    vAuth.Free;
    vModulo.Free;
    vServidor.Free;
    vCalc.Free;
  end;
end.
