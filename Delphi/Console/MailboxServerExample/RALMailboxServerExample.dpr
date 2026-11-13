program RALMailboxServerExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  RALTypes, RALMailMIME, RALSMTPClient, RALSMTPServer, RALMailStore, RALIMAPServer,
  RALIMAPClient;

// A small mail server with PascalRAL (package RALModuleMailPackage), in one program:
//  - TRALSMTPServer on port 2525 receives mail for @example.com and drops it into
//    the mailbox of the user before the @, kept by a TRALMailStore in a folder;
//  - TRALIMAPServer on port 1143 serves those mailboxes (user ana, password secret);
//  - TRALSMTPClient sends two messages and TRALIMAPClient lists and reads them.
// No TLS, so it runs without OpenSSL; for real use set SSL.CertFile/KeyFile and
// SSL.Enabled on both servers (ports 465/993 open too) and use TLS in the clients.

var
  GLock: TCriticalSection;
  GStore: TRALMailStore;

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
    procedure Rcpt(Sender: TObject; ASession: TRALSMTPSession; const AAddress: StringRAL;
      var ACode: IntegerRAL; var AReply: StringRAL);
    procedure Message(Sender: TObject; ASession: TRALSMTPSession; AEnvelope: TRALSMTPEnvelope;
      AData: TStream; var ACode: IntegerRAL; var AReply: StringRAL);
  end;

procedure TDemo.Rcpt(Sender: TObject; ASession: TRALSMTPSession; const AAddress: StringRAL;
  var ACode: IntegerRAL; var AReply: StringRAL);
begin
  if Pos('@example.com', LowerCase(string(AAddress))) = 0 then
  begin
    ACode := 550;
    AReply := '5.7.1 relay not permitted';
  end;
end;

procedure TDemo.Message(Sender: TObject; ASession: TRALSMTPSession; AEnvelope: TRALSMTPEnvelope;
  AData: TStream; var ACode: IntegerRAL; var AReply: StringRAL);
var
  vInt: Integer;
  vUser: string;
begin
  // runs on the SMTP server's thread: one copy into each recipient's INBOX
  for vInt := 0 to AEnvelope.Recipients.Count - 1 do
  begin
    vUser := LowerCase(Copy(AEnvelope.Recipients[vInt], 1, Pos('@', AEnvelope.Recipients[vInt]) - 1));
    AData.Position := 0;
    GStore.Deliver(StringRAL(vUser), AData);
    Log('smtp: stored a message for ' + vUser);
  end;
end;

var
  FDemo: TDemo;
  FSMTP: TRALSMTPServer;
  FIMAPServer: TRALIMAPServer;
  FSender: TRALSMTPClient;
  FReader: TRALIMAPClient;
  FMsg: TRALMailMessage;
  FUIDs: TStringList;
  FInt: Integer;
begin
  GLock := TCriticalSection.Create;
  FDemo := TDemo.Create;
  GStore := TRALMailStore.Create(nil);
  FSMTP := TRALSMTPServer.Create(nil);
  FIMAPServer := TRALIMAPServer.Create(nil);
  FSender := TRALSMTPClient.Create(nil);
  FReader := TRALIMAPClient.Create(nil);
  FMsg := TRALMailMessage.Create;
  FUIDs := TStringList.Create;
  try
    GStore.Folder := StringRAL(IncludeTrailingPathDelimiter(GetCurrentDir) + 'mailboxes');

    FSMTP.Port := 2525;
    FSMTP.SubmissionPort := 0;
    FSMTP.TLSPort := 0;
    FSMTP.HostName := 'mx.example.com';
    FSMTP.OnRcptTo := FDemo.Rcpt;
    FSMTP.OnMessage := FDemo.Message;
    FSMTP.Active := True;

    FIMAPServer.Port := 1143;
    FIMAPServer.TLSPort := 0;
    FIMAPServer.Store := GStore;
    FIMAPServer.Users.Add('ana=secret');
    // only for this demo without TLS: PLAIN/LOGIN in clear
    FIMAPServer.AllowPlainAuthWithoutTLS := True;
    FIMAPServer.Active := True;
    Log('SMTP on 2525, IMAP on 1143; mailboxes in ' + string(GStore.Folder));

    FSender.Host := '127.0.0.1';
    FSender.Port := 2525;
    FSender.Security := msNone;
    FMsg.From.Add('bob@elsewhere.org', 'Bob');
    FMsg.Recipients.Add('ana@example.com', 'Ana');
    for FInt := 1 to 2 do
    begin
      FMsg.Subject := StringRAL('Hello ' + IntToStr(FInt));
      FMsg.Text := StringRAL('Message number ' + IntToStr(FInt) + '.');
      FMsg.MessageID := '';
      FSender.Send(FMsg);
    end;

    // ana reads her mailbox
    FReader.Host := '127.0.0.1';
    FReader.Port := 1143;
    FReader.Security := msNone;
    FReader.UserName := 'ana';
    FReader.Password := 'secret';
    FReader.Select('INBOX');
    Log(Format('imap: INBOX has %d message(s)', [FReader.Exists]));
    FReader.Search('ALL', FUIDs);
    for FInt := 0 to FUIDs.Count - 1 do
    begin
      FMsg.Clear;
      FReader.FetchMessage(StrToInt(FUIDs[FInt]), FMsg);
      Log(Format('imap: UID %s "%s" from %s: %s', [FUIDs[FInt], string(FMsg.Subject),
        string(FMsg.From[0].Address), Trim(string(FMsg.Text))]));
    end;
    // mark the first one read and move the second to an Archive mailbox
    if FUIDs.Count >= 2 then
    begin
      FReader.SetFlags([StrToInt(FUIDs[0])], '\Seen');
      // the store keeps everything between runs: Archive exists from the second run on
      try
        FReader.CreateMailbox('Archive');
      except
        on E: ERALIMAPError do
          Log('imap: ' + E.Message);
      end;
      FReader.Move([StrToInt(FUIDs[1])], 'Archive');
      Log(Format('imap: moved UID %s to Archive; INBOX now has %d', [FUIDs[1], FReader.Exists]));
    end;
    FReader.Disconnect;
  finally
    FUIDs.Free;
    FMsg.Free;
    FReader.Free;
    FSender.Free;
    FIMAPServer.Free;
    FSMTP.Free;
    GStore.Free;
    FDemo.Free;
    GLock.Free;
  end;
end.
