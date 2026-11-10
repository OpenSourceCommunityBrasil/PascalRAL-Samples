program RALCryptoCurvesExample;

{$APPTYPE CONSOLE}

{$I PascalRAL.inc}

uses
  System.SysUtils,
  RALTypes, RALTools, RALCurve25519, RALEd25519, RALHKDF, RALAESGCM;

function ParaHex(const ABytes: TBytes): string;
var
  vI: Integer;
begin
  Result := '';
  for vI := 0 to High(ABytes) do
    Result := Result + LowerCase(IntToHex(ABytes[vI], 2));
end;

function ParaBytes(const ATexto: string): TBytes;
var
  vUTF8: UTF8String;
begin
  vUTF8 := UTF8Encode(ATexto);
  SetLength(Result, Length(vUTF8));
  if Length(vUTF8) > 0 then
    Move(vUTF8[1], Result[0], Length(vUTF8));
end;

function ParaTexto(const ABytes: TBytes): string;
var
  vUTF8: UTF8String;
begin
  SetLength(vUTF8, Length(ABytes));
  if Length(ABytes) > 0 then
    Move(ABytes[0], vUTF8[1], Length(ABytes));
  Result := UTF8ToString(vUTF8);
end;

function Igual(const A, B: TBytes): Boolean;
begin
  Result := (Length(A) = Length(B)) and
    ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function SimNao(AValor: Boolean): string;
begin
  if AValor then
    Result := 'sim'
  else
    Result := 'nao';
end;

procedure Assinatura;
var
  vSemente, vPublica, vMensagem, vAssinatura, vAlterada: TBytes;
begin
  WriteLn('--- Ed25519: assinar e verificar ---');
  RALEd25519GenerateKeyPair(vSemente, vPublica);
  WriteLn('semente (privada) = ', ParaHex(vSemente));
  WriteLn('chave pública     = ', ParaHex(vPublica));

  vMensagem := ParaBytes('Transferir 100 para a conta 42');
  vAssinatura := RALEd25519Sign(vMensagem, vSemente);
  WriteLn('assinatura        = ', ParaHex(vAssinatura));
  WriteLn('verifica          = ', SimNao(RALEd25519Verify(vMensagem, vAssinatura, vPublica)));

  vAlterada := ParaBytes('Transferir 900 para a conta 42');
  WriteLn('mensagem alterada = ', SimNao(RALEd25519Verify(vAlterada, vAssinatura, vPublica)),
    ' (deve ser "nao")');
end;

function Acordo: TBytes;
var
  vPrivAlice, vPubAlice, vPrivBob, vPubBob, vSegAlice, vSegBob: TBytes;
begin
  WriteLn;
  WriteLn('--- X25519: acordo de chave entre Alice e Bob ---');
  RALX25519GenerateKeyPair(vPrivAlice, vPubAlice);
  RALX25519GenerateKeyPair(vPrivBob, vPubBob);
  WriteLn('pública da Alice  = ', ParaHex(vPubAlice));
  WriteLn('pública do Bob    = ', ParaHex(vPubBob));

  // cada lado usa a sua chave privada e a pública do outro
  vSegAlice := RALX25519(vPrivAlice, vPubBob);
  vSegBob := RALX25519(vPrivBob, vPubAlice);
  WriteLn('segredo da Alice  = ', ParaHex(vSegAlice));
  WriteLn('segredo do Bob    = ', ParaHex(vSegBob));
  WriteLn('iguais            = ', SimNao(Igual(vSegAlice, vSegBob)));
  Result := vSegAlice;
end;

procedure Cifra(const ASegredo: TBytes);
var
  vChave, vIV, vAAD, vCifrado, vDecifrado: TBytes;
  vAdulterado: TBytes;
  vOk: Boolean;
begin
  WriteLn;
  WriteLn('--- HKDF-SHA256 e AES-256-GCM ---');
  // o segredo do acordo não serve direto como chave: o HKDF deriva 32 bytes dele
  vChave := RALHKDFDerive(rhkSHA256, ASegredo, ParaBytes('sal do exemplo'),
    ParaBytes('PascalRAL exemplo'), 32);
  WriteLn('chave AES-256     = ', ParaHex(vChave));

  // o IV (12 bytes) nunca pode se repetir com a mesma chave; aqui vem de bytes aleatórios
  vIV := RandomBytes(12);
  vAAD := ParaBytes('cabeçalho autenticado');
  vCifrado := RALAESGCMEncrypt(vChave, vIV, vAAD, ParaBytes('Texto secreto do exemplo'));
  WriteLn('IV                = ', ParaHex(vIV));
  WriteLn('cifrado + tag     = ', ParaHex(vCifrado));

  vOk := RALAESGCMDecrypt(vChave, vIV, vAAD, vCifrado, vDecifrado);
  WriteLn('decifra           = ', SimNao(vOk), ' -> "', ParaTexto(vDecifrado), '"');

  // um bit alterado no cifrado: a tag não confere e nada é devolvido
  vAdulterado := Copy(vCifrado, 0, Length(vCifrado));
  vAdulterado[0] := vAdulterado[0] xor 1;
  vOk := RALAESGCMDecrypt(vChave, vIV, vAAD, vAdulterado, vDecifrado);
  WriteLn('cifrado alterado  = ', SimNao(vOk), ' (deve ser "nao"; texto vazio: ',
    SimNao(Length(vDecifrado) = 0), ')');

  // o cabeçalho autenticado (AAD) alterado também é recusado
  vOk := RALAESGCMDecrypt(vChave, vIV, ParaBytes('outro cabeçalho'), vCifrado, vDecifrado);
  WriteLn('AAD alterado      = ', SimNao(vOk), ' (deve ser "nao")');
end;

begin
  Assinatura;
  Cifra(Acordo);
end.
