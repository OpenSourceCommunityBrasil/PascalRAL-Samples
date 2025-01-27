unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF MSWINDOWS}
    Windows,
  {$ENDIF}
  {$IFDEF FPC}
    DynLibs,
  {$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  Menus, Buttons, StdCtrls, DBGrids, ZDataset, DB, RALSwaggerModule, Themes,
  RALAuthentication, RALSynopseServer, RALServer, RALResponse, RALRequest, Grids, RALToken;

type

  { Tfprincipal }

  Tfprincipal = class(TForm)
    Abrir1: TMenuItem;
    basic: TRALServerBasicAuth;
    bGravarUsuario: TSpeedButton;
    bIniciarServer: TSpeedButton;
    ckAutoStart: TCheckBox;
    ckSwagger: TCheckBox;
    DBGrid2: TDBGrid;
    dbgUsuarios: TDBGrid;
    dsModulos: TDataSource;
    dsUsuarios: TDataSource;
    Encerrar1: TMenuItem;
    ePassUsuario: TEdit;
    eServerPorta: TEdit;
    eUserUsuario: TEdit;
    iconTray: TTrayIcon;
    Image1: TImage;
    imgList: TImageList;
    jwt: TRALServerJWTAuth;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    memModulosmod_file: TStringField;
    memModulosmod_handle: TLargeintField;
    memModulosmod_name: TStringField;
    memPop: TPopupMenu;
    N1: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    pgPrincipal: TPageControl;
    pooler: TRALSynopseServer;
    qUsuariosativo: TStringField;
    qUsuarioscodigo: TLongintField;
    qUsuariossenha: TStringField;
    qUsuariosusuario: TStringField;
    rbAuthBasic: TRadioButton;
    rbAuthJWT: TRadioButton;
    rbAuthNenhuma: TRadioButton;
    swagger: TRALSwaggerModule;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    memModulos: TZMemTable;
    qUsuarios: TZQuery;
    procedure Abrir1Click(Sender: TObject);
    procedure basicValidate(ARequest: TRALRequest; AResponse: TRALResponse;
      var AResult: boolean);
    procedure bGravarUsuarioClick(Sender: TObject);
    procedure bIniciarServerClick(Sender: TObject);
    procedure DBGrid2DblClick(Sender: TObject);
    procedure dbgUsuariosCellClick(Column: TColumn);
    procedure dbgUsuariosDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure Encerrar1Click(Sender: TObject);
    procedure eServerPortaChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure iconTrayDblClick(Sender: TObject);
    procedure jwtGetToken(ARequest: TRALRequest; AResponse: TRALResponse;
      AParams: TRALJWTParams; var AResult: boolean);
    procedure jwtValidate(ARequest: TRALRequest; AResponse: TRALResponse;
      AParams: TRALJWTParams; var AResult: boolean);
  private
    FCanClose : boolean;
    FCodUsuario : integer;
    FProcessando : boolean;
    procedure carregaSubModules;
    procedure startServer;
    procedure novoUsuario;
    procedure proximoUsuario;
    procedure criarMemTable;

    function drawCheckBox(canv : TCanvas; rct : TRect; sel : boolean = True) : boolean; overload;
    function drawCheckBox(hwd : THandle; rct : TRect; sel : boolean = True) : boolean; overload;
    procedure setIconTray(AIndex: integer);
public

  end;

var
  fprincipal: Tfprincipal;

implementation

{$R *.lfm}

uses
  uglobal_vars, udm, udm_rest;

var
  start_module: function(server : TRALServer): Boolean; cdecl;
  desc_module : function : string; cdecl;
  config_module : procedure; cdecl;

{ Tfprincipal }

procedure Tfprincipal.bIniciarServerClick(Sender: TObject);
begin
  if bIniciarServer.Tag = 0 then begin
    startServer;
    bIniciarServer.Tag := 1;
    bIniciarServer.ImageIndex := 1;
    setIconTray(3);
    bIniciarServer.Caption := 'Parar';
  end
  else begin
    pooler.Stop;
    setIconTray(4);
    bIniciarServer.Tag := 0;
    bIniciarServer.ImageIndex := 0;
    bIniciarServer.Caption := 'Iniciar';
  end;
end;

procedure Tfprincipal.DBGrid2DblClick(Sender: TObject);
begin
  Pointer(config_module) := GetProcAddress(memModulosmod_handle.AsInteger, 'config_module');
  if Assigned(config_module) then
    config_module();
end;

procedure Tfprincipal.dbgUsuariosCellClick(Column: TColumn);
var
  q1 : TZQuery;
  ativo : string;
begin
  if Column.Index = 2 then begin

    if qUsuariosATIVO.AsString = 'S' then
      ativo := 'N'
    else
      ativo := 'S';

    q1 := TZQuery.Create(nil);
    try
      q1.Connection := dm.conexao;
      q1.Close;
      q1.SQL.Clear;
      q1.SQL.Add('update usuarios');
      q1.SQL.Add('set ativo = :ativo');
      q1.SQL.Add('where codigo = :codigo');
      q1.ParamByName('codigo').AsInteger := qUsuariosCODIGO.AsInteger;
      q1.ParamByName('ativo').AsString := ativo;
      q1.ExecSQL;

      novoUsuario;

      qUsuarios.Close;
      qUsuarios.Open;
    finally
      FreeAndNil(q1);
    end;
  end;
end;

procedure Tfprincipal.dbgUsuariosDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  dbgUsuarios.Canvas.Brush.Color := clWhite;
  dbgUsuarios.Canvas.Brush.Style := bsSolid;
  dbgUsuarios.Canvas.FillRect(Rect);

  if (DataCol = 2) then
    dbgUsuarios.Canvas.Font.Color := clWhite;
  dbgUsuarios.DefaultDrawColumnCell(Rect, DataCol, Column, State);

  if (DataCol = 2) and (qUsuarios.Active) then
    drawCheckBox(dbgUsuarios.Canvas, Rect, qUsuariosATIVO.AsString = 'S');
end;

procedure Tfprincipal.Encerrar1Click(Sender: TObject);
begin
  FCanClose := True;
  Close;
end;

procedure Tfprincipal.eServerPortaChange(Sender: TObject);
begin
  if FProcessando then
    Exit;

  gb_serverport := StrToIntDef(eServerPorta.Text, 8000);

  gb_authtype := 3;
  if rbAuthJWT.Checked then
    gb_authtype := 1
  else if rbAuthBasic.Checked then
    gb_authtype := 2;

  gb_modswager := ckSwagger.Checked;
  gb_autostart := ckAutoStart.Checked;

  salvarConfiguracoes;

  if pooler.Active then
    startServer;
end;

procedure Tfprincipal.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caNone;
  if FCanClose then begin
    CloseAction := caFree;
    Application.Terminate;
  end;
end;

procedure Tfprincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;
  Self.Hide;
end;

procedure Tfprincipal.FormCreate(Sender: TObject);
begin
  setIconTray(4);

  criarMemTable;
  carregaSubModules;

  FCanClose := False;

  qUsuarios.Close;
  qUsuarios.Open;

  novoUsuario;

  FProcessando := True;

  eServerPorta.Text := IntToStr(gb_serverport);

  rbAuthJWT.Checked := gb_authtype = 1;
  rbAuthBasic.Checked := gb_authtype = 2;
  rbAuthNenhuma.Checked := gb_authtype = 3;

  ckSwagger.Checked := gb_modswager;
  ckAutoStart.Checked := gb_autostart;

  FProcessando := False;
  pgPrincipal.ActivePageIndex := 0;

  Application.ProcessMessages;

  if gb_autostart then
    bIniciarServer.Click
  else
    Self.Show;
end;

procedure Tfprincipal.iconTrayDblClick(Sender: TObject);
begin
  Self.Show;
end;

procedure Tfprincipal.jwtGetToken(ARequest: TRALRequest;
  AResponse: TRALResponse; AParams: TRALJWTParams; var AResult: boolean);
var
  dm_rest : Tdm_rest;
begin
  dm_rest := Tdm_rest.Create(nil);
  try
    dm_rest.getJWTToken(ARequest, AResponse, AParams, AResult);
  finally
    FreeAndNil(dm_rest);
  end;
end;

procedure Tfprincipal.jwtValidate(ARequest: TRALRequest;
  AResponse: TRALResponse; AParams: TRALJWTParams; var AResult: boolean);
var
  dm_rest : Tdm_rest;
begin
  dm_rest := Tdm_rest.Create(nil);
  try
    dm_rest.validJWToken(ARequest, AResponse, AParams, AResult);
  finally
    FreeAndNil(dm_rest);
  end;
end;

procedure Tfprincipal.Abrir1Click(Sender: TObject);
begin
  Self.Show;
end;

procedure Tfprincipal.basicValidate(ARequest: TRALRequest;
  AResponse: TRALResponse; var AResult: boolean);
var
  dm_rest : Tdm_rest;
begin
  dm_rest := Tdm_rest.Create(nil);
  try
    dm_rest.validBasicAuth(ARequest, AResponse, AResult);
  finally
    FreeAndNil(dm_rest);
  end;
end;

procedure Tfprincipal.bGravarUsuarioClick(Sender: TObject);
var
  q1 : TZQuery;
  bErro : boolean;
begin
  bErro := False;

  q1 := TZQuery.Create(nil);
  try
    q1.Connection := dm.conexao;
    q1.Close;
    q1.SQL.Clear;
    q1.SQL.Add('select count(*) from usuarios');
    q1.SQL.Add('where usuario = :usuario');
    if FCodUsuario = -1 then begin
      q1.SQL.Add('  and codigo <> :codigo');
      q1.ParamByName('codigo').AsInteger := FCodUsuario;
    end;
    q1.ParamByName('usuario').AsString := eUserUsuario.Text;
    q1.Open;

    if q1.Fields[0].AsInteger > 0 then begin
      ShowMessage('Usuário já existe');
      bErro := True;
    end;
  finally
    FreeAndNil(q1);
  end;

  if bErro then
    Exit;

  q1 := TZQuery.Create(nil);
  try
    q1.Connection := dm.conexao;
    q1.Close;
    q1.SQL.Clear;
    if FCodUsuario = -1 then begin
      proximoUsuario;
      q1.SQL.Add('insert into usuarios(codigo, usuario, senha)');
      q1.SQL.Add('values(:codigo, :usuario, :senha)');
    end
    else begin
      q1.SQL.Add('update usuarios');
      q1.SQL.Add('set usuario = :usuario,');
      q1.SQL.Add('    senha = :senha');
      q1.SQL.Add('where codigo = :codigo');
    end;
    q1.ParamByName('codigo').AsInteger := FCodUsuario;
    q1.ParamByName('usuario').AsString := eUserUsuario.Text;
    q1.ParamByName('senha').AsString := ePassUsuario.Text;
    q1.ExecSQL;

    novoUsuario;

    qUsuarios.Close;
    qUsuarios.Open;
  finally
    FreeAndNil(q1);
  end;
end;

procedure Tfprincipal.carregaSubModules;
var
  F: TSearchRec;
  Ret : Integer;

  procedure carregaBiblioteca(ADLL : string);
  var
    vDLL : THandle;
    vDesc : string;
  begin
    vDLL := SafeLoadLibrary(ADLL);

    if vDLL <> NilHandle then begin
      try
        Pointer(start_module) := GetProcAddress(vDLL, 'start_module');
        if Assigned(start_module) then
          start_module(pooler);

        vDesc := '';
        Pointer(desc_module) := GetProcAddress(vDLL, 'desc_module');
        if Assigned(desc_module) then begin
          vDesc := desc_module();

          memModulos.Append;
          memModulosmod_handle.AsInteger := vDLL;
          memModulosmod_file.AsString := ExtractFileName(ADLL);
          memModulosmod_name.AsString := vDesc;
          memModulos.Post;
        end;
      except

      end;
    end;
  end;

begin
  memModulos.Close;
  memModulos.Open;

  {$IFDEF LINUX}
    Ret := FindFirst('*.so', faAnyFile, F);
  {$ENDIF}
  {$IFDEF WINDOWS}
    Ret := FindFirst('*.dll', faAnyFile, F);
  {$ENDIF}
  try
    repeat
      if F.Name <> '' then
        carregaBiblioteca(F.Name);
      Ret := FindNext(F);
    until Ret <> 0;
  finally
    FindClose(F);
  end;
end;

procedure Tfprincipal.startServer;
begin
  pooler.Stop;

  pooler.Port := StrToIntDef(eServerPorta.Text, 8000);

  swagger.Server := nil;
  if gb_modswager then
    swagger.Server := pooler;

  case gb_authtype of
    1 : pooler.Authentication := jwt;
    2 : pooler.Authentication := basic;
    3 : pooler.Authentication := nil;
  end;

  pooler.Start;
end;

procedure Tfprincipal.novoUsuario;
begin
  FCodUsuario := -1;
  eUserUsuario.Text := '';
  ePassUsuario.Text := '';
end;

procedure Tfprincipal.proximoUsuario;
var
  q1 : TZQuery;
begin
  q1 := TZQuery.Create(nil);
  try
    q1.Connection := dm.conexao;
    q1.Close;
    q1.SQL.Clear;
    q1.SQL.Add('select max(codigo) from usuarios');
    q1.Open;

    FCodUsuario := q1.Fields[0].AsInteger + 1;
  finally
    FreeAndNil(q1);
  end;
end;

procedure Tfprincipal.criarMemTable;
begin
  memModulos.FieldDefs.Add('mod_handle', ftLargeint);
  memModulos.FieldDefs.Add('mod_name', ftString, 50);
  memModulos.FieldDefs.Add('mod_file', ftString, 50);
end;

function Tfprincipal.drawCheckBox(canv: TCanvas; rct: TRect; sel: boolean): boolean;
begin
  Result := drawCheckBox(canv.Handle,rct,sel);
end;

function Tfprincipal.drawCheckBox(hwd: THandle; rct: TRect; sel: boolean): boolean;
var
  det : TThemedElementDetails;
  x,y : integer;
begin
  Result := ThemeServices.ThemesEnabled;
  if ThemeServices.ThemesEnabled then begin
    if sel then
      det := ThemeServices.GetElementDetails(tbCheckBoxCheckedNormal)
    else
      det := ThemeServices.GetElementDetails(tbCheckBoxUncheckedNormal);
    ThemeServices.DrawElement(hwd,det,rct);
  end
  else begin
    Result := False;
    x := Trunc(rct.Left + ((rct.Right-rct.Left) / 2) - 6.5);
    y := Trunc(rct.Top + ((rct.Bottom-rct.Top) / 2) - 6.5);

    rct.Left := x;
    rct.Top := y;
    rct.Right := x + 13;
    rct.Bottom := y + 13;

    if sel then
      DrawFrameControl(hwd, rct, DFC_BUTTON, DFCS_BUTTONCHECK or DFCS_CHECKED)
    else
      DrawFrameControl(hwd, rct, DFC_BUTTON, DFCS_BUTTONCHECK);
  end;
end;

procedure Tfprincipal.setIconTray(AIndex: integer);
var
  vIco : TIcon;
begin
  vIco := TIcon.Create;
  try
    imgList.GetIcon(AIndex, vIco);
    iconTray.Icon.Assign(vIco);
  finally
    FreeAndNil(vIco);
  end;
end;

end.

