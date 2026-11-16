/// LiveBindings over the JSON a TRALClient gets (RAL 2.0, RALClientLiveBindingsPackage):
/// the grid and the edit are bound in the form (LiveBindings designer) to a
/// TAdapterBindSource whose Adapter is a TRALJSONBindSourceAdapter. A TRALInProcServer
/// in the form plays the API, so the example runs alone.
unit Principal;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.Bindings.Outputs,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Data.Bind.EngExt, Vcl.Bind.DBEngExt, Vcl.Bind.Grid, Vcl.Bind.Editors, Data.Bind.Components,
  Data.Bind.Grid, Data.Bind.ObjectScope,
  RALTypes, RALMIMETypes, RALRequest, RALResponse, RALServer, RALClient, RALInProc, RALLiveBindings;

type
  TfPrincipal = class(TForm)
    pnlTopo: TPanel;
    btnCarregar: TButton;
    btnJSON: TButton;
    edNome: TEdit;
    lblNome: TLabel;
    gridPessoas: TStringGrid;
    mmJSON: TMemo;
    RALClient1: TRALClient;
    RALJSONBindSourceAdapter1: TRALJSONBindSourceAdapter;
    AdapterBindSource1: TAdapterBindSource;
    BindingsList1: TBindingsList;
    LinkGridToDataSource1: TLinkGridToDataSource;
    LinkControlToFieldNome: TLinkControlToField;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCarregarClick(Sender: TObject);
    procedure btnJSONClick(Sender: TObject);
  private
    FServidor: TRALInProcServer;
    procedure Pessoas(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure SelfTest;
  end;

var
  fPrincipal: TfPrincipal;

implementation

{$R *.dfm}

procedure TfPrincipal.Pessoas(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  // the API: a list of people as JSON
  AResponse.Answer(200, '[{"id":1,"name":"Ana","score":9.5,"active":true},' +
    '{"id":2,"name":"Bruno","score":7,"active":false},' +
    '{"id":3,"name":"Carla","score":8.25,"active":true}]', rctAPPLICATIONJSON);
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  FServidor := TRALInProcServer.Create(Self);
  FServidor.ServerName := 'api';
  FServidor.CreateRoute('pessoas', Pessoas);
  FServidor.Active := True;
  RALClient1.EngineType := 'InProc';
  RALClient1.BaseURL.Text := 'inproc://api';
  if ParamStr(1) = '--selftest' then
    SelfTest;
end;

procedure TfPrincipal.FormDestroy(Sender: TObject);
begin
  FServidor.Active := False;
end;

procedure TfPrincipal.btnCarregarClick(Sender: TObject);
begin
  // GET pessoas: the grid and the edit follow the adapter
  RALJSONBindSourceAdapter1.Execute;
end;

procedure TfPrincipal.btnJSONClick(Sender: TObject);
begin
  // what was edited in the grid or in the edit, back as JSON
  mmJSON.Lines.Text := RALJSONBindSourceAdapter1.ToJSON;
end;

procedure TfPrincipal.SelfTest;
var
  vLog: TStringList;
begin
  vLog := TStringList.Create;
  try
    btnCarregarClick(nil);
    AdapterBindSource1.First;
    vLog.Add('grid ' + gridPessoas.Cells[1, 1] + ' ' + gridPessoas.Cells[1, 3]);
    vLog.Add('edit ' + edNome.Text);
    AdapterBindSource1.Next;
    vLog.Add('edit2 ' + edNome.Text);
    vLog.SaveToFile(ChangeFileExt(ParamStr(0), '.selftest.txt'));
  finally
    vLog.Free;
  end;
  Application.Terminate;
end;

end.
