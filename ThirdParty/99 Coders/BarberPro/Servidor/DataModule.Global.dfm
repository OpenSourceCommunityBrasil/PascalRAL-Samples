object DmGlobal: TDmGlobal
  OnCreate = DataModuleCreate
  Height = 316
  Width = 445
  object Conn: TFDConnection
    Params.Strings = (
      'LockingMode=Normal'
      'DriverID=SQLite')
    LoginPrompt = False
    Left = 96
    Top = 64
  end
end
