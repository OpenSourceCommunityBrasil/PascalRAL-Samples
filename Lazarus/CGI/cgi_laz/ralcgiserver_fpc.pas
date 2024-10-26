unit ralcgiserver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  custcgi, custweb, fpweb, httpDefs,
  RALServer, RALRequest, RALResponse, RALTools;

type

  { TRALCGIServerHandler }

  TRALCGIServerHandler = Class(TCgiHandler)
  public
    procedure HandleRequest(ARequest : Trequest; AResponse : TResponse); override;
  end;

  { TRALCGIServerApp }

  TRALCGIServerApp = Class(TCustomCGIApplication)
  protected
   function InitializeWebHandler: TWebHandler; override;
  end;

  { TRALCGIServer }

  TRALCGIServer = class(TRALServer)
  private
    FCGIApp : TRALCGIServerApp;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;

    procedure Start;
  end;


implementation

{ TRALCGIServerHandler }
{
procedure TRALCGIServerHandler.HandleRequest(ARequest: Trequest;
  AResponse: TResponse);
  procedure AddNV(Const N,V : String);
  begin
    AResponse.Contents.Add('<TR><TD>'+N+'</TD><TD>'+V+'</TD></TR>');
  end;
var
  I,P : Integer;
  N,V : String;
begin
  With AResponse.Contents do
  begin
    BeginUpdate;
    Try
      Add('<HTML><TITLE>FPC CGI Test page</TITLE><BODY>');
//      DumpRequest(ARequest, AResponse.Contents);
      Add('<H1>CGI environment:</H1>');
      Add('<TABLE BORDER="1">');
      Add('<TR><TD>Name</TD><TD>Value</TD></TR>');

      for I:=1 to GetEnvironmentVariableCount do
      begin
        V:=GetEnvironmentString(i);
        P:=Pos('=',V);
        N:=Copy(V,1,P-1);
        System.Delete(V,1,P);
        AddNV(N,V);
      end;
      Add('</TABLE>');
      Add('</BODY></HTML>');
    Finally
      EndUpdate;
    end;
  end;

end;
}

procedure TRALCGIServerHandler.HandleRequest(ARequest: Trequest;
  AResponse: TResponse);
var
  vApp : TRALCGIServerApp;
  vServer : TRALCGIServer;
  vRequest : TRALRequest;
  vResponse: TRALResponse;

  vAux1, vAux2 : String;
begin
  vApp := TRALCGIServerApp(Owner);
  vServer := TRALCGIServer(vApp.Owner);

  vRequest := vServer.CreateRequest;
  vResponse := vServer.CreateResponse;

  vAux1 := GetEnvironmentVariable('PATH_INFO');
  vAux2 := GetEnvironmentVariable('QUERY_STRING');
  if vAux2 <> '' then
    vAux1 := vAux1 + '?' + vAux2;

  vRequest.Query := vAux1;

  vAux1 := GetEnvironmentVariable('REQUEST_METHOD');
  vRequest.Method := HTTPMethodToRALMethod(vAux1);
  vRequest.AcceptEncoding := GetEnvironmentVariable('HTTP_ACCEPT_ENCODING');
  vRequest.ContentType := 'text/html';

  vRequest.RequestText := ARequest.Content;
  try
    vServer.ProcessCommands(vRequest, vResponse);

    AResponse.ContentType := 'text/html';
    AResponse.ContentEncoding := vResponse.ContentEncoding;
    AResponse.Code := vResponse.StatusCode;
    AResponse.Content := vResponse.ResponseText;
  except
    on e : Exception do
      AResponse.Content := 'erro';
  end;
  AResponse.SendContent;

  vRequest.Free;
  vResponse.Free;
end;

{ TRALCGIServerApp }

function TRALCGIServerApp.InitializeWebHandler: TWebHandler;
begin
  Result := TRALCGIServerHandler.Create(Self);
end;

constructor TRALCGIServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCGIApp := TRALCGIServerApp.Create(Self);
end;

destructor TRALCGIServer.Destroy;
begin
  FCGIApp.Free;
  inherited Destroy;
end;

procedure TRALCGIServer.Start;
begin
  FCGIApp.Initialize;
  FCGIApp.Run;
end;

end.

