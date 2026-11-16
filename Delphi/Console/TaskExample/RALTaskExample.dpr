program RALTaskExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, SyncObjs, Variants,
  RALTask;

// Background tasks with PascalRAL (package RALHostingTaskPackage):
//  - a chain of three tasks (read -> count -> report), each getting the Output of the
//    one before as its Input, on the pool every task shares;
//  - a long task cancelled half way, which sees Cancelled and stops;
//  - three tasks at once waited for with WaitAll.

type
  TDemo = class
  public
    Lock: TCriticalSection;
    constructor Create;
    destructor Destroy; override;
    procedure Log(const AText: string);
    procedure Read(Sender: TRALTask);
    procedure Count(Sender: TRALTask);
    procedure Report(Sender: TRALTask);
    procedure Long(Sender: TRALTask);
    procedure Cancelled(Sender: TRALTask);
    procedure Square(Sender: TRALTask);
  end;

constructor TDemo.Create;
begin
  Lock := TCriticalSection.Create;
end;

destructor TDemo.Destroy;
begin
  Lock.Free;
  inherited Destroy;
end;

procedure TDemo.Log(const AText: string);
begin
  Lock.Acquire;
  try
    WriteLn(AText);
    Flush(Output);
  finally
    Lock.Release;
  end;
end;

procedure TDemo.Read(Sender: TRALTask);
begin
  // pretend to read a file: its text is the Output
  Sleep(200);
  Sender.Output := 'one two three four five';
  Log('read: ' + VarToStr(Sender.Output));
end;

procedure TDemo.Count(Sender: TRALTask);
var
  vWords: TStringList;
begin
  vWords := TStringList.Create;
  try
    vWords.Delimiter := ' ';
    vWords.DelimitedText := VarToStr(Sender.Input);
    Sender.Output := vWords.Count;
  finally
    vWords.Free;
  end;
  Log('count: ' + VarToStr(Sender.Output) + ' words');
end;

procedure TDemo.Report(Sender: TRALTask);
begin
  Log('report: the file has ' + VarToStr(Sender.Input) + ' words');
end;

procedure TDemo.Long(Sender: TRALTask);
var
  vStep: Integer;
begin
  for vStep := 1 to 50 do
  begin
    if Sender.Cancelled then
    begin
      Log('long task: stopping at step ' + IntToStr(vStep));
      Exit;
    end;
    Sleep(20);
  end;
end;

procedure TDemo.Cancelled(Sender: TRALTask);
begin
  Log('long task: cancelled');
end;

procedure TDemo.Square(Sender: TRALTask);
begin
  Sleep(100);
  Sender.Output := Sender.Input * Sender.Input;
end;

var
  FDemo: TDemo;
  FRead, FCount, FReport, FLong: TRALTask;
  FSquares: array[0..2] of TRALTask;
  FIdx: Integer;
begin
  FDemo := TDemo.Create;
  FRead := TRALTask.Create(nil);
  FCount := TRALTask.Create(nil);
  FReport := TRALTask.Create(nil);
  FLong := TRALTask.Create(nil);
  for FIdx := 0 to 2 do
    FSquares[FIdx] := TRALTask.Create(nil);
  try
    FRead.OnExecute := FDemo.Read;
    FCount.OnExecute := FDemo.Count;
    FReport.OnExecute := FDemo.Report;
    FRead.Next := FCount;
    FCount.Next := FReport;
    FRead.Run;
    FReport.WaitFor;  // the last one: the whole chain

    FLong.OnExecute := FDemo.Long;
    FLong.OnCancel := FDemo.Cancelled;
    FLong.Run;
    Sleep(200);
    FLong.Cancel;
    FLong.WaitFor;

    for FIdx := 0 to 2 do
    begin
      FSquares[FIdx].OnExecute := FDemo.Square;
      FSquares[FIdx].Run(FIdx + 2);
    end;
    if TRALTask.WaitAll(FSquares, 5000) then
      FDemo.Log(Format('squares: %s %s %s', [VarToStr(FSquares[0].Output),
        VarToStr(FSquares[1].Output), VarToStr(FSquares[2].Output)]));
  finally
    for FIdx := 0 to 2 do
      FSquares[FIdx].Free;
    FLong.Free;
    FReport.Free;
    FCount.Free;
    FRead.Free;
    FDemo.Free;
  end;
end.
