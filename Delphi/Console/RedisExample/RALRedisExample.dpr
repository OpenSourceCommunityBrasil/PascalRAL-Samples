program RALRedisExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, SyncObjs, Contnrs,
  RALTypes, RALRedisClient, RALRedisSubscriber, RALRedisStore;

// Redis and Valkey with PascalRAL (package RALStoreRedisPackage):
//  - commands: strings with expiry, counters, hashes;
//  - a pipeline of 1000 commands in one round trip, against 1000 round trips;
//  - pub/sub: a subscriber on its own connection gets what is published;
//  - two stores, as two servers would have, counting one limit together.
// The server comes from RAL_REDIS_HOST, RAL_REDIS_PORT and RAL_REDIS_PASSWORD
// (default 127.0.0.1:6379 without a password).

type
  TDemo = class
  public
    Lock: TCriticalSection;
    Messages: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Arrived(Sender: TObject; const AChannel, APattern: StringRAL;
      const APayload: RawByteString);
  end;

constructor TDemo.Create;
begin
  Lock := TCriticalSection.Create;
  Messages := TStringList.Create;
end;

destructor TDemo.Destroy;
begin
  Messages.Free;
  Lock.Free;
  inherited Destroy;
end;

procedure TDemo.Arrived(Sender: TObject; const AChannel, APattern: StringRAL;
  const APayload: RawByteString);
begin
  // the subscriber's own thread: keep it short and thread safe (the main thread prints)
  Lock.Acquire;
  try
    Messages.Add('  received on ' + string(AChannel) + ': ' + string(APayload));
  finally
    Lock.Release;
  end;
end;

function Env(const AName, ADefault: string): string;
begin
  Result := GetEnvironmentVariable(AName);
  if Result = '' then
    Result := ADefault;
end;

var
  Demo: TDemo;
  Redis: TRALRedisClient;
  Subscriber: TRALRedisSubscriber;
  StoreA, StoreB: TRALRedisStore;
  Pipe: TRALRedisPipeline;
  Replies: TObjectList;
  Value: RawByteString;
  Fields: TStringList;
  Start: TDateTime;
  I, Allowed: Integer;
begin
  Demo := TDemo.Create;
  Redis := TRALRedisClient.Create(nil);
  Subscriber := TRALRedisSubscriber.Create(nil);
  StoreA := TRALRedisStore.Create(nil);
  StoreB := TRALRedisStore.Create(nil);
  Fields := TStringList.Create;
  try
    Redis.Host := StringRAL(Env('RAL_REDIS_HOST', '127.0.0.1'));
    Redis.Port := StrToInt(Env('RAL_REDIS_PORT', '6379'));
    Redis.Password := StringRAL(Env('RAL_REDIS_PASSWORD', ''));
    try
      Redis.Ping;
    except
      on E: Exception do
      begin
        WriteLn('Redis did not answer: ', E.Message);
        Exit;
      end;
    end;
    WriteLn('Connected to ', Redis.Host, ':', Redis.Port);

    WriteLn('1. Commands');
    Redis.SetValue('demo:greeting', 'hello', 60000);
    if Redis.GetValue('demo:greeting', Value) then
      WriteLn('  demo:greeting = ', string(Value), ', lives ',
        Redis.TimeToLive('demo:greeting'), ' ms more');
    WriteLn('  visits: ', Redis.Increment('demo:visits'));
    Redis.HashSet('demo:customer:42', 'name', 'Ana');
    Redis.HashSet('demo:customer:42', 'city', 'Recife');
    Redis.HashGetAll('demo:customer:42', Fields);
    WriteLn('  demo:customer:42 = ', Fields.CommaText);

    WriteLn('2. Pipeline');
    Redis.Delete(['demo:counter']);
    Start := Now;
    for I := 1 to 1000 do
      Redis.Increment('demo:counter');
    WriteLn('  1000 INCR one by one: ', Round((Now - Start) * 86400000), ' ms');
    Pipe := Redis.NewPipeline;
    try
      for I := 1 to 1000 do
        Pipe.Add(['INCR', 'demo:counter']);
      Start := Now;
      Replies := Pipe.Execute;
      try
        WriteLn('  1000 INCR in one pipeline: ', Round((Now - Start) * 86400000),
          ' ms, last value ', TRALRedisReply(Replies[Replies.Count - 1]).AsInteger);
      finally
        Replies.Free;
      end;
    finally
      Pipe.Free;
    end;

    WriteLn('3. Pub/sub');
    Subscriber.Client := Redis;
    Subscriber.Channels.Add('demo:news');
    Subscriber.OnMessage := Demo.Arrived;
    Subscriber.Active := True;
    if Subscriber.WaitSubscribed(1, 3000) then
    begin
      for I := 1 to 3 do
        Redis.Publish('demo:news', RawByteString('news number ' + IntToStr(I)));
      I := 0;
      while (Demo.Messages.Count < 3) and (I < 3000) do
      begin
        Sleep(10);
        Inc(I, 10);
      end;
      Demo.Lock.Acquire;
      try
        for I := 0 to Demo.Messages.Count - 1 do
          WriteLn(Demo.Messages[I]);
      finally
        Demo.Lock.Release;
      end;
    end;
    Subscriber.Active := False;

    WriteLn('4. Two servers, one limit');
    StoreA.Client := Redis;
    StoreB.Client := Redis;
    StoreA.KeyPrefix := 'demo:limit:';
    StoreB.KeyPrefix := 'demo:limit:';
    StoreA.Clear;
    // each "server" counts the same client; together they allow 5 per minute
    Allowed := 0;
    for I := 1 to 4 do
    begin
      if StoreA.Increment('client-1', 1, 60000) <= 5 then
        Inc(Allowed);
      if StoreB.Increment('client-1', 1, 60000) <= 5 then
        Inc(Allowed);
    end;
    WriteLn('  8 requests on two servers, ', Allowed, ' allowed (the limit is 5)');
    StoreA.Clear;
    Redis.Delete(['demo:greeting', 'demo:visits', 'demo:customer:42', 'demo:counter']);
  finally
    Fields.Free;
    StoreA.Free;
    StoreB.Free;
    Subscriber.Free;
    Redis.Free;
    Demo.Free;
  end;
end.
