object dm: Tdm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 243
  Width = 295
  object conexao: TFDConnection
    Params.Strings = (
      'Database=D:\atualizacao\lucedata_bridge\BRIDGE_BD.FDB'
      'User_Name=SYSDBA'
      'Password=masterkey'
      'Protocol=TCPIP'
      'Server=localhost'
      'Port=3054'
      'DriverID=FB')
    ConnectedStoredUsage = [auRunTime]
    LoginPrompt = False
    Left = 32
    Top = 32
  end
  object wait: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 144
    Top = 96
  end
  object sqlite_link: TFDPhysSQLiteDriverLink
    Left = 144
    Top = 160
  end
end
