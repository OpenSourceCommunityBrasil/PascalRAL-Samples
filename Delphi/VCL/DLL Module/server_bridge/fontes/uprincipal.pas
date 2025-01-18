unit uprincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RALCustomObjects, RALServer,
  RALSynopseServer, RALAuthentication, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Buttons,
  Data.DB, Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls, RALSwaggerModule,
  Vcl.Imaging.pngimage;

type
  Tfprincipal = class(TForm)
    pooler: TRALSynopseServer;
    jwt: TRALServerJWTAuth;
    basic: TRALServerBasicAuth;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    eServerPorta: TEdit;
    bIniciarServer: TSpeedButton;
    Label2: TLabel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    TabSheet2: TTabSheet;
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    Label3: TLabel;
    eUserUsuario: TEdit;
    Label4: TLabel;
    ePassUsuario: TEdit;
    bGravarUsuario: TSpeedButton;
    RadioButton3: TRadioButton;
    Panel2: TPanel;
    swagger: TRALSwaggerModule;
    Image1: TImage;
    CheckBox1: TCheckBox;
    procedure bIniciarServerClick(Sender: TObject);
  private
    { Private declarations }
    procedure carregaSubModules;
  public
    { Public declarations }
  end;

var
  fprincipal: Tfprincipal;

implementation

{$R *.dfm}

var
  start_module: function(server : TRALServer): Boolean; stdcall;

procedure Tfprincipal.bIniciarServerClick(Sender: TObject);
begin
  carregaSubModules;
  pooler.Stop;
  pooler.Port := StrToIntDef(eServerPorta.Text, 8000);
  pooler.Start;
end;

procedure Tfprincipal.carregaSubModules;
var
  F: TSearchRec;
  Ret : Integer;

  procedure carregaBiblioteca(ADLL : string);
  var
    vDLL : THandle;
  begin
    vDLL := SafeLoadLibrary(ADLL);

    if vDLL <> HMODULE(0) then begin
      try
        start_module := GetProcAddress(vDLL, 'start_module');
        if Assigned(start_module) then
          start_module(pooler);
      except

      end;
    end;
  end;

begin
  Ret := FindFirst('*.dll', faAnyFile, F);
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

end.
