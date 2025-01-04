object Dtm: TDtm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 222
  Width = 338
  object Conn: TFDConnection
    Params.Strings = (
      'DriverID=SQLite')
    LoginPrompt = False
    BeforeConnect = ConnBeforeConnect
    Left = 144
    Top = 72
  end
end
