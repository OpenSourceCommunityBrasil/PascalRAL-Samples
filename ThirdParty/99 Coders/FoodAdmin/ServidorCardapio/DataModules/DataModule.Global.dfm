object Dm: TDm
  OnCreate = DataModuleCreate
  Height = 325
  Width = 398
  object Conn: TFDConnection
    Params.Strings = (
      
        'Database=D:\99Coders\Posts\399 - Criando o servidor em Horse de ' +
        'um card'#225'pio digital\Fontes\DB\banco.db'
      'LockingMode=Normal'
      'DriverID=SQLite')
    ConnectedStoredUsage = []
    LoginPrompt = False
    BeforeConnect = ConnBeforeConnect
    Left = 72
    Top = 48
  end
end
