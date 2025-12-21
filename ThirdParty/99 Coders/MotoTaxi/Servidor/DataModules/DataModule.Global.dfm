object Dm: TDm
  OnCreate = DataModuleCreate
  Height = 480
  Width = 640
  object Conn: TFDConnection
    Params.Strings = (
      'Database=D:\Mototaxi\Database\BANCO.FDB'
      'User_Name=SYSDBA'
      'Password=masterkey'
      'Protocol=TCPIP'
      'Server=127.0.0.1'
      'Port=3050'
      'DriverID=FB')
    LoginPrompt = False
    Left = 112
    Top = 80
  end
  object FDPhysFBDriverLink: TFDPhysFBDriverLink
    Left = 248
    Top = 80
  end
end
