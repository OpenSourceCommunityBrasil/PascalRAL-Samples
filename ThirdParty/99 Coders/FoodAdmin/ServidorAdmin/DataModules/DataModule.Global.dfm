object DmGlobal: TDmGlobal
  OnCreate = DataModuleCreate
  Height = 301
  Width = 337
  object conn: TFDConnection
    Params.Strings = (
      
        'Database=D:\99Coders\CursoFood\Admin\Fontes\ServidorAdmin\DB\ban' +
        'co.db'
      'LockingMode=Normal'
      'DriverID=SQLite')
    ConnectedStoredUsage = []
    LoginPrompt = False
    BeforeConnect = connBeforeConnect
    Left = 72
    Top = 40
  end
  object FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    Left = 184
    Top = 80
  end
end
