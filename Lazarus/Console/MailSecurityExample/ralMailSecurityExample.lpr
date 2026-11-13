program ralMailSecurityExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALTypes, RALRSA, RALX509, RALMailMIME, RALSMIME, RALOpenPGP;

// Signed and encrypted e-mail with PascalRAL (package RALModuleMailPackage):
//  - S/MIME with TRALSMIME: a key and a certificate made here (in real use, the
//    PFX of a certificate authority), a message signed and encrypted, then opened;
//  - OpenPGP with TRALOpenPGP: an Ed25519 key made here (in real use, the key
//    exported from GnuPG), a message signed and encrypted (PGP/MIME), then opened.
// Each result is written to a .eml file that a mail program can open.
// No OpenSSL and no GnuPG needed: the cryptography is RAL's own.

function NewMessage(const ASubject: StringRAL): TRALMailMessage;
begin
  Result := TRALMailMessage.Create;
  Result.From.Add('ana@example.com', 'Ana');
  Result.Recipients.Add('ana@example.com', 'Ana');
  Result.Subject := ASubject;
  Result.Text := 'The contract is attached in the next message.';
end;

procedure SMIME;
var
  vKey: TRALRSAKey;
  vCert: TRALX509Certificate;
  vSMIME: TRALSMIME;
  vMsg, vBack: TRALMailMessage;
  vOut: TMemoryStream;
  vInfo: TRALSMIMEInfo;
begin
  WriteLn('S/MIME: making a 2048-bit RSA key and a certificate (a few seconds)...');
  vKey := TRALRSAKey.Generate(2048);
  vCert := TRALX509Certificate.Create(RALCreateCertificate(vKey, 'Ana', nil,
    Now - 1, Now + 365));
  vSMIME := TRALSMIME.Create(nil);
  vMsg := NewMessage('S/MIME test');
  vBack := TRALMailMessage.Create;
  vOut := TMemoryStream.Create;
  try
    vSMIME.Certificate.Text := string(vCert.ToPEM);
    vSMIME.PrivateKey.Text := string(vKey.PrivateKeyPEM);
    // to Ana (her own certificate here), and to self
    vSMIME.SignAndEncrypt(vMsg, [vCert], vOut);
    vOut.SaveToFile('smime.eml');
    WriteLn('S/MIME: signed and encrypted, ', vOut.Size, ' bytes in smime.eml');
    vOut.Position := 0;
    vSMIME.TrustedCertificates.Text := string(vCert.ToPEM);
    vSMIME.Open(vOut, vBack, vInfo);
    WriteLn('S/MIME: opened "', string(vBack.Subject), '": encrypted=', vInfo.Encrypted,
      ' signed=', vInfo.Signed, ' signature valid=', vInfo.SignatureValid,
      ' trusted=', vInfo.ChainTrusted, ' cipher=', string(vInfo.ContentCipher));
  finally
    vOut.Free;
    vBack.Free;
    vMsg.Free;
    vSMIME.Free;
    vCert.Free;
    vKey.Free;
  end;
end;

procedure OpenPGP;
var
  vPGP: TRALOpenPGP;
  vMsg, vBack: TRALMailMessage;
  vOut: TMemoryStream;
  vInfo: TRALPGPInfo;
begin
  vPGP := TRALOpenPGP.Create(nil);
  vMsg := NewMessage('OpenPGP test');
  vBack := TRALMailMessage.Create;
  vOut := TMemoryStream.Create;
  try
    // a new Ed25519 key (with a Curve25519 subkey for encryption) in the keyring
    vPGP.KeyRing.GenerateEd25519('Ana <ana@example.com>');
    vPGP.SignerKey := 'ana@example.com';
    // the recipients come from To/Cc/Bcc, looked up in the keyring by e-mail
    vPGP.SignAndEncrypt(vMsg, vOut);
    vOut.SaveToFile('openpgp.eml');
    WriteLn('OpenPGP: signed and encrypted, ', vOut.Size, ' bytes in openpgp.eml');
    vOut.Position := 0;
    vPGP.Open(vOut, vBack, vInfo);
    WriteLn('OpenPGP: opened "', string(vBack.Subject), '": encrypted=', vInfo.Encrypted,
      ' signed=', vInfo.Signed, ' signature valid=', vInfo.SignatureValid,
      ' signer=', string(vInfo.SignerEmail));
  finally
    vOut.Free;
    vBack.Free;
    vMsg.Free;
    vPGP.Free;
  end;
end;

begin
  try
    SMIME;
    OpenPGP;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
end.
