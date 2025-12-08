object Dm: TDm
  OnCreate = DataModuleCreate
  Height = 373
  Width = 517
  object Conn: TFDConnection
    Params.Strings = (
      
        'Database=D:\99Coders\CursoEcommerce\Fontes\Database\ECOMMERCE.FD' +
        'B'
      'User_Name=SYSDBA'
      'Password=masterkey'
      'Protocol=TCPIP'
      'Server=127.0.0.1'
      'DriverID=FB')
    LoginPrompt = False
    Left = 48
    Top = 32
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    VendorLib = 'C:\Program Files (x86)\Firebird\Firebird_3_0\fbclient.dll'
    Left = 224
    Top = 32
  end
end
