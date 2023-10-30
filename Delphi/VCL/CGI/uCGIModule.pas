unit uCGIModule;

interface

uses
  System.SysUtils, System.Classes,
  RALCGIServerDatamodule;

type
  TCGIModule = class(TRALWebModule)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CGIModule: TCGIModule;

implementation

{$R *.dfm}

end.
