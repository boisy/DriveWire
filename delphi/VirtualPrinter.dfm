object VirtualPrinterForm: TVirtualPrinterForm
  Left = 314
  Top = 123
  Width = 742
  Height = 583
  Caption = 'Virtual Printer Window'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 16
    Top = 16
    Width = 705
    Height = 481
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object Button1: TButton
    Left = 16
    Top = 512
    Width = 75
    Height = 25
    Caption = 'Print'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 648
    Top = 512
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 2
    OnClick = Button2Click
  end
end
