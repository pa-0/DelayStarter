object Main: TMain
  Left = 192
  Top = 125
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'DelayStarter'
  ClientHeight = 67
  ClientWidth = 346
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel: TPanel
    Left = 0
    Top = 0
    Width = 346
    Height = 67
    Align = alClient
    BevelOuter = bvNone
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object TextLbl: TLabel
      Left = 0
      Top = 10
      Width = 346
      Height = 43
      Alignment = taCenter
      AutoSize = False
      Caption = #1046#1076#1105#1084' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1103' '#1080#1085#1090#1077#1088#1085#1077#1090'-'#1089#1086#1077#1076#1080#1085#1077#1085#1080#1103'...'#13#1055#1088#1080#1084#1077#1088#1085#1086' '#1086#1089#1090#1072#1083#1086#1089#1100': 0:00'
    end
  end
  object TimerDelay: TTimer
    OnTimer = TimerDelayTimer
    Left = 8
    Top = 32
  end
end
