import { PreferencesUtil } from '@pura/harmony-utils'
import { DraggableCustomizationOption } from '../pages/components/DraggableCustomization'

export class TopBarOptions {
  ALL_SELECTED: string = "0,1,2"
  PORTRAIT_DEFAULT_SELECTED: string = "0,1"
  REPEAT: number = 0
  MIRROR: number = 1
  ADJUSTMENT: number = 2
}

export class BottomBarOptions {
  ALL_SELECTED: string = "0,1,2,3"
  PORTRAIT_DEFAULT_SELECTED: string = "1,3"
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

export function getTopBarButtons(): string {
  let selected = PreferencesUtil.getStringSync('toolbar_landscape_topbar', '')
  let topBarLandscapeSelected: number[] = []
  if (selected.length > 0) {
    if (selected.indexOf(',') > 0) {
      topBarLandscapeSelected = selected.split(',').map((value) => parseInt(value))
    } else {
      topBarLandscapeSelected = [parseInt(selected)]
    }
  }
  return topBarLandscapeSelected.map((value) => {
    if (value == ToolbarOptions.TOP_BAR.REPEAT) {
      return "repeat"
    } else if (value == ToolbarOptions.TOP_BAR.MIRROR) {
      return "mirror"
    } else if (value == ToolbarOptions.TOP_BAR.ADJUSTMENT) {
      return "adjustment"
    } else {
      return "unknown"
    }
  }).join(', ')
}

export function getBottomBarButtons(): string {
  let selected = PreferencesUtil.getStringSync('toolbar_landscape_bottombar', '')
  let bottomBarLandscapeSelected: number[] = []
  if (selected.length > 0) {
    if (selected.indexOf(',') > 0) {
      bottomBarLandscapeSelected = selected.split(',').map((value) => parseInt(value))
    } else {
      bottomBarLandscapeSelected = [parseInt(selected)]
    }
  }
  return bottomBarLandscapeSelected.map((value) => {
    if (value == ToolbarOptions.BOTTOM_BAR.FILLING_MODE) {
      return "filling mode"
    } else if (value == ToolbarOptions.BOTTOM_BAR.SPEED) {
      return "speed"
    } else if (value == ToolbarOptions.BOTTOM_BAR.AUDIOS) {
      return "audios"
    } else if (value == ToolbarOptions.BOTTOM_BAR.SUBTITLES) {
      return "subtitles"
    } else {
      return "unknown"
    }
  }).join(', ')
}