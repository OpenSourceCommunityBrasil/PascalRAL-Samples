program ralMailExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  RALTypes, RALTools, RALBase64, RALEd25519, RALMailMIME, RALSMTPClient, RALSMTPServer,
  RALMailQueue, RALDKIM;

// E-mail with PascalRAL (package RALModuleMailPackage). In one program:
//  - a TRALSMTPServer on port 2525 that prints each message it receives and
//    checks its DKIM signature with a TRALDKIMVerifier;
//  - a TRALSMTPClient that sends a message with an attachment, signed by a
//    TRALDKIMSigner (Ed25519, a key made here);
//  - a TRALMailQueue that sends three more in the background.
// No TLS, so it runs without OpenSSL; to use it, see the comments.

var
  GLock: TCriticalSection;

// the events run on the server's and the queue's threads: one line at a time
procedure Log(const AText: string);
begin
  GLock.Acquire;
  try
    WriteLn(AText);
    Flush(Output);
  finally
    GLock.Release;
  end;
end;

type
  TDemo = class
  public
    Done: TEvent;
    Received: IntegerRAL;
    Signer: TRALDKIMSigner;
    Verifier: TRALDKIMVerifier;
    // server side
    procedure Rcpt(Sender: TObject; ASession: TRALSMTPSession; const AAddress: StringRAL;
      var ACode: IntegerRAL; var AReply: StringRAL);
    procedure Message(Sender: TObject; ASession: TRALSMTPSession; AEnvelope: TRALSMTPEnvelope;
      AData: TStream; var ACode: IntegerRAL; var AReply: StringRAL);
    procedure KeyLookup(Sender: TObject; const ASelector, ADomain: StringRAL;
      var ARecord: StringRAL; var ATemporary: Boolean);
    // queue side
    procedure Delivered(Sender: TObject; const AId: StringRAL; ARecipients: TStrings);
    procedure Bounced(Sender: TObject; const AId, ARecipient: StringRAL;
      ACode: IntegerRAL; const AReply: StringRAL);
  end;

procedure TDemo.Rcpt(Sender: TObject; ASession: TRALSMTPSession; const AAddress: StringRAL;
  var ACode: IntegerRAL; var AReply: StringRAL);
begin
  // only our own domain: a server on port 25 that accepts any address is an open relay
  if Pos('@example.com', LowerCase(string(AAddress))) = 0 then
  begin
    ACode := 550;
    AReply := '5.7.1 relay not permitted';
  end;
end;

procedure TDemo.Message(Sender: TObject; ASession: TRALSMTPSession; AEnvelope: TRALSMTPEnvelope;
  AData: TStream; var ACode: IntegerRAL; var AReply: StringRAL);
var
  vMsg: TRALMailMessage;
  vResults: TList;
  vInt: Integer;
  vDKIM: string;
begin
  // runs on the server's connection thread
  vResults := TList.Create;
  vMsg := TRALMailMessage.Create;
  try
    vDKIM := 'no signature';
    if Verifier.Verify(AData, vResults) then
      vDKIM := 'DKIM pass';
    for vInt := 0 to vResults.Count - 1 do
      TRALDKIMResult(vResults[vInt]).Free;
    AData.Position := 0;
    vMsg.LoadFromStream(AData);
    Log(Format('server: from <%s> to %s, "%s", %d attachment(s), %s',
      [string(AEnvelope.From), AEnvelope.Recipients.CommaText, string(vMsg.Subject),
       vMsg.Attachments.Count, vDKIM]));
  finally
    vMsg.Free;
    vResults.Free;
  end;
  if RALAtomicInc(Received) = 4 then
    Done.SetEvent;
end;

procedure TDemo.KeyLookup(Sender: TObject; const ASelector, ADomain: StringRAL;
  var ARecord: StringRAL; var ATemporary: Boolean);
begin
  // a real verifier asks DNS for <selector>._domainkey.<domain>; here it is our own key
  if (ASelector = Signer.Selector) and (ADomain = Signer.Domain) then
    ARecord := Signer.KeyRecord;
end;

procedure TDemo.Delivered(Sender: TObject; const AId: StringRAL; ARecipients: TStrings);
begin
  Log('queue: delivered to ' + ARecipients.CommaText);
end;

procedure TDemo.Bounced(Sender: TObject; const AId, ARecipient: StringRAL;
  ACode: IntegerRAL; const AReply: StringRAL);
begin
  Log(Format('queue: %s refused (%d %s)', [string(ARecipient), ACode, string(AReply)]));
end;

var
  FDemo: TDemo;
  FServer: TRALSMTPServer;
  FClient: TRALSMTPClient;
  FQueue: TRALMailQueue;
  FMsg: TRALMailMessage;
  FSeed, FPublic: TBytes;
  FInt: Integer;
begin
  GLock := TCriticalSection.Create;
  FDemo := TDemo.Create;
  FDemo.Done := TEvent.Create(nil, True, False, '');
  FServer := TRALSMTPServer.Create(nil);
  FClient := TRALSMTPClient.Create(nil);
  FQueue := TRALMailQueue.Create(nil);
  FDemo.Signer := TRALDKIMSigner.Create(nil);
  FDemo.Verifier := TRALDKIMVerifier.Create(nil);
  FMsg := TRALMailMessage.Create;
  try
    // the server: only the plain port, no TLS
    FServer.Port := 2525;
    FServer.SubmissionPort := 0;
    FServer.TLSPort := 0;
    FServer.HostName := 'mx.example.com';
    // with a certificate, port 587 (STARTTLS) and 465 (TLS) open too, and they require login:
    //   FServer.SSL.CertFile := 'cert.pem'; FServer.SSL.KeyFile := 'key.pem';
    //   FServer.SSL.Enabled := True; FServer.Users.Add('user=secret');
    FServer.OnRcptTo := FDemo.Rcpt;
    FServer.OnMessage := FDemo.Message;
    FDemo.Verifier.OnKeyLookup := FDemo.KeyLookup;
    FServer.Active := True;
    Log('SMTP server running on port ' + IntToStr(FServer.Port));

    // DKIM: an Ed25519 key made now; publish KeyRecord as TXT at q1._domainkey.example.com
    RALEd25519GenerateKeyPair(FSeed, FPublic);
    FDemo.Signer.Algorithm := dkaEd25519SHA256;
    FDemo.Signer.Domain := 'example.com';
    FDemo.Signer.Selector := 'q1';
    FDemo.Signer.PrivateKey.Text := string(TRALBase64.Encode(FSeed));
    Log('DKIM record: ' + string(FDemo.Signer.KeyRecord));

    // the client: plain SMTP to our server; with a real provider set Security,
    // UserName and Password (see the comments in the README)
    FClient.Host := '127.0.0.1';
    FClient.Port := 2525;
    FClient.Security := msNone;
    FClient.DKIM := FDemo.Signer;

    FMsg.From.Add('ana@example.com', 'Ana');
    FMsg.Recipients.Add('bob@example.com', 'Bob');
    FMsg.Recipients.Add('someone@elsewhere.org');
    FMsg.Subject := 'Report for Bob';
    FMsg.Text := 'Hi Bob,' + sLineBreak + 'the report is attached.';
    FMsg.HTML := '<p>Hi <b>Bob</b>,</p><p>the report is attached.</p>';
    with TRALMailAttachment(FMsg.Attachments.Add) do
    begin
      LoadFromText('day;sales' + sLineBreak + 'mon;10' + sLineBreak);
      FileName := 'report.csv';
      ContentType := 'text/csv';
    end;
    FClient.Send(FMsg);
    for FInt := 0 to FClient.ResultCount - 1 do
      Log(Format('client: %s -> %d %s', [string(FClient.Results[FInt].Address),
        FClient.Results[FInt].Code, string(FClient.Results[FInt].Reply)]));

    // the queue: three more, sent in the background (a Folder keeps them across restarts)
    FQueue.Client := FClient;
    FQueue.OnDelivered := FDemo.Delivered;
    FQueue.OnBounced := FDemo.Bounced;
    FQueue.Active := True;
    FMsg.Recipients.Clear;
    FMsg.Recipients.Add('bob@example.com');
    FMsg.Attachments.Clear;
    for FInt := 1 to 3 do
    begin
      FMsg.Subject := StringRAL('Queued ' + IntToStr(FInt));
      FMsg.MessageID := '';
      FQueue.Enqueue(FMsg);
    end;

    if FDemo.Done.WaitFor(10000) = wrSignaled then
      Log('all four messages arrived')
    else
      Log('timeout: ' + IntToStr(FDemo.Received) + ' message(s) arrived');
    FQueue.Active := False;
  finally
    FMsg.Free;
    FQueue.Free;
    FClient.Free;
    FServer.Free;
    FDemo.Signer.Free;
    FDemo.Verifier.Free;
    FDemo.Done.Free;
    FDemo.Free;
    GLock.Free;
  end;
end.
