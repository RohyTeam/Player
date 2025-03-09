import { DraggableCustomizationOption } from '../pages/components/DraggableCustomization'

export class TopBarOptions {
  ALL_SELECTED: string = "0,1,2"
  REPEAT: number = 0
  MIRROR: number = 1
  ADJUSTMENT: number = 2
}

export class BottomBarOptions {
  ALL_SELECTED: string = "0,1,2,3"
  FILLING_MODE: number = 0
  SPEED: number = 1
  AUDIOS: number = 2
  SUBTITLES: number = 3
}

export class ToolbarOptions {
  static TOP_BAR: TopBarOptions = new TopBarOptions();
  static BOTTOM_BAR: BottomBarOptions = new BottomBarOptions();
}

export const topBarOptions: DraggableCustomizationOption[] = [
  {
    symbolIcon: $r('sys.symbol.repeat'),
    name: $r('app.string.settings_toolbar_option_repeat'),
  },
  {
    symbolIcon: $r('sys.symbol.trapezoid_and_line_vertical'),
    name: $r('app.string.settings_toolbar_option_mirror'),
  },
  {
    symbolIcon: $r('sys.symbol.slider_horizontal_2'),
    name: $r('app.string.settings_toolbar_option_adjustment'),
  }
]

export const bottomBarOptions: DraggableCustomizationOption[] = [
  {
    symbolIcon: $r('sys.symbol.rectangle'),
    name: $r('app.string.settings_toolbar_option_fillingmode'),
  },
  {
    symbolIcon: $r('sys.symbol.timer'),
    name: $r('app.string.settings_toolbar_option_speed'),
  },
  {
    symbolIcon: $r('sys.symbol.speaker_wave_3'),
    name: $r('app.string.settings_toolbar_option_audios'),
  },
  {
    symbolIcon: $r('sys.symbol.textformat'),
    name: $r('app.string.settings_toolbar_option_subtitles'),
  }
]