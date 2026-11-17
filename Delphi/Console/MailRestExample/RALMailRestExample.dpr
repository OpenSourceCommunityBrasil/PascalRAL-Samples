program RALMailRestExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF FPC}{$IFDEF UNIX}cthreads,{$ENDIF}Interfaces,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  RALTypes, RALConsts, RALServer, RALRoutes, RALRequest, RALResponse, RALParams,
  {$IFDEF FPC}RALfpHTTPServer,{$ELSE}RALIndyServer,{$ENDIF}
  RALMailMIME, RALSMTPClient, RALSMTPServer, RALMailRestModule, RALMailActions;

// E-mail over HTTP with PascalRAL (package RALModuleMailPackage). In one program:
//  - a TRALSMTPServer on port 2525 that prints each message it receives;
//  - a TRALSMTPClient pointed at it (no TLS, so it needs no OpenSSL);
//  - an HTTP server on port 8000 with a TRALMailRestModule: POST /mail/send
//    takes a JSON object or a form and sends it through the client;
//  - a route POST /contact that uses a TRALSendMail from code: the action holds
//    the template of the message and Send sends a copy of it.

var
  GLock: TCriticalSection;

// the events run on the threads of the servers: one line at a time
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
    Action: TRALSendMail;
    ActionLock: TCriticalSection;
    // SMTP server side
    procedure Message(Sender: TObject; ASession: TRALSMTPSession; AEnvelope: TRALSMTPEnvelope;
      AData: TStream; var ACode: IntegerRAL; var AReply: StringRAL);
    // module side
    procedure BeforeSend(Sender: TObject; ARequest: TRALRequest; AMessage: TRALMailMessage;
      var AStatus: IntegerRAL; var AError: StringRAL);
    // action side
    procedure Prepare(Sender: TObject; AMessage: TRALMailMessage);
    procedure Failed(Sender: TObject; AError: Exception);
    // the route /contact
    procedure Contact(ARequest: TRALRequest; AResponse: TRALResponse);
  end;

procedure TDemo.Message(Sender: TObject; ASession: TRALSMTPSession; AEnvelope: TRALSMTPEnvelope;
  AData: TStream; var ACode: IntegerRAL; var AReply: StringRAL);
var
  vMsg: TRALMailMessage;
begin
  // runs on the connection thread of the SMTP server
  vMsg := TRALMailMessage.Create;
  try
    AData.Position := 0;
    vMsg.LoadFromStream(AData);
    Log(Format('smtp: from <%s> to %s, "%s", %d attachment(s)',
      [string(AEnvelope.From), AEnvelope.Recipients.CommaText, string(vMsg.Subject),
       vMsg.Attachments.Count]));
  finally
    vMsg.Free;
  end;
end;

procedure TDemo.BeforeSend(Sender: TObject; ARequest: TRALRequest; AMessage: TRALMailMessage;
  var AStatus: IntegerRAL; var AError: StringRAL);
begin
  // the message the request built, before it is sent: it may be changed or refused
  if Pos('spam', LowerCase(string(AMessage.Subject))) > 0 then
  begin
    AStatus := 422;
    AError := 'subject refused';
  end
  else
    AMessage.Subject := '[site] ' + AMessage.Subject;
end;

procedure TDemo.Prepare(Sender: TObject; AMessage: TRALMailMessage);
begin
  // AMessage is a copy of Message made for this send: the template stays as it is
  AMessage.Headers.Values['X-Origin'] := 'contact form';
end;

procedure TDemo.Failed(Sender: TObject; AError: Exception);
begin
  Log('action: ' + AError.Message);
end;

procedure TDemo.Contact(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vParam: TRALParam;
  vText: string;
  vOk: Boolean;
begin
  vParam := ARequest.ParamByName('message');
  if vParam = nil then
  begin
    AResponse.Answer(400, '{"error":"field message is required"}');
    Exit;
  end;
  vText := string(vParam.AsString);
  // the route runs on a thread per request and Message is shared: one at a time
  ActionLock.Acquire;
  try
    Action.Message.Text := StringRAL(vText);
    vOk := Action.Send;
  finally
    ActionLock.Release;
  end;
  if vOk then
    AResponse.Answer(200, '{"sent":true}')
  else
    AResponse.Answer(502, '{"sent":false}');
end;

var
  FDemo: TDemo;
  FSMTP: TRALSMTPServer;
  FClient: TRALSMTPClient;
  FServer: TRALServer;
  FModule: TRALMailRestModule;
  FRoute: TRALRoute;
begin
  GLock := TCriticalSection.Create;
  FDemo := TDemo.Create;
  FDemo.ActionLock := TCriticalSection.Create;
  FSMTP := TRALSMTPServer.Create(nil);
  FClient := TRALSMTPClient.Create(nil);
  {$IFDEF FPC}
  FServer := TRALfpHTTPServer.Create(nil);
  {$ELSE}
  FServer := TRALIndyServer.Create(nil);
  {$ENDIF}
  FModule := TRALMailRestModule.Create(nil);
  FDemo.Action := TRALSendMail.Create(nil);
  try
    // the mail server: only the plain port, no TLS
    FSMTP.Port := 2525;
    FSMTP.SubmissionPort := 0;
    FSMTP.TLSPort := 0;
    FSMTP.HostName := 'mx.example.com';
    FSMTP.OnMessage := FDemo.Message;
    FSMTP.Active := True;
    Log('SMTP server running on port ' + IntToStr(FSMTP.Port));

    // the client: plain SMTP to our server; with a real provider set Host, Port,
    // Security, UserName and Password
    FClient.Host := '127.0.0.1';
    FClient.Port := 2525;
    FClient.Security := msNone;

    // the module: POST /mail/send; each request uses its own copy of Client
    FServer.Port := 8000;
    FModule.Domain := '/mail';
    FModule.Client := FClient;
    FModule.DefaultFrom := 'Site <site@example.com>';
    // only these authors may be sent in "from" (empty list: only DefaultFrom)
    FModule.AllowedFrom.Add('@example.com');
    FModule.OnBeforeSend := FDemo.BeforeSend;
    FModule.Server := FServer;

    // the action, made in code: Message is the template of every send
    FDemo.Action.Client := FClient;
    FDemo.Action.OnPrepare := FDemo.Prepare;
    FDemo.Action.OnFailed := FDemo.Failed;
    FDemo.Action.Message.From.Add('site@example.com', 'Site');
    FDemo.Action.Message.Recipients.Add('support@example.com', 'Support');
    FDemo.Action.Message.Subject := 'Contact form';
    FRoute := FServer.CreateRoute('contact', FDemo.Contact, 'Sends the field message by e-mail');
    FRoute.AllowedMethods := [amPOST];

    FServer.Active := True;
    Log('HTTP server running on port ' + IntToStr(FServer.Port));
    Log('');
    Log('Try:');
    Log('  curl -X POST http://127.0.0.1:8000/mail/send -H "Content-Type: application/json" ' +
      '-d "{\"to\":\"bob@example.com\",\"subject\":\"Hello\",\"text\":\"Hi Bob\"}"');
    Log('  curl -X POST http://127.0.0.1:8000/mail/send -F to=bob@example.com ' +
      '-F subject=Report -F text=attached -F file=@report.csv');
    Log('  curl -X POST http://127.0.0.1:8000/contact -d "message=Please call me"');
    Log('Enter to stop...');
    ReadLn;
    FServer.Active := False;
    FSMTP.Active := False;
  finally
    FDemo.Action.Free;
    FModule.Free;
    FServer.Free;
    FClient.Free;
    FSMTP.Free;
    FDemo.ActionLock.Free;
    FDemo.Free;
    GLock.Free;
  end;
end.
