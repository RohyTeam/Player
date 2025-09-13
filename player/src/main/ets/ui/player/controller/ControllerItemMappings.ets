import { Pref } from "../../../context/PreferenceContext";
import { DraggableItem } from "../../component/inner/InnerDraggable";

let controllerButtons: DraggableItem[] = [{
  index: 0,
  id: 'mirror_flip',
  icon: $r('sys.symbol.trapezoid_and_line_vertical'),
  isSymbol: true,
  name: $r('app.string.mirror_flip')
},{
  index: 1,
  id: 'loop_playing',
  icon: $r('sys.symbol.repeat'),
  isSymbol: true,
  name: $r('app.string.loop_playing')
},{
  index: 2,
  id: 'visual_effect',
  icon: $r('sys.symbol.camera_filters'),
  isSymbol: true,
  name: $r('app.string.visual_effect')
},{
  index: 3,
  id: 'chapter_list',
  icon: $r('sys.symbol.bookmark'),
  isSymbol: true,
  name: $r('app.string.chapter_list')
},{
  index: 4,
  id: 'surface_filling_mode',
  icon: $r('sys.symbol.resolution_video'),
  isSymbol: true,
  name: $r('app.string.surface_filling_mode')
},{
  index: 5,
  id: 'audios',
  icon: $r('sys.symbol.sound'),
  isSymbol: true,
  name: $r('app.string.audios')
},{
  index: 6,
  id: 'subtitles',
  icon: $r('sys.symbol.AI_subtitles'),
  isSymbol: true,
  name: $r('app.string.subtitles')
},{
  index: 7,
  id: 'speed',
  icon: $r('sys.symbol.video_speed'),
  isSymbol: true,
  name: $r('app.string.speed')
}]

export function indexToDraggableItem(index: number): DraggableItem {
  if (index === 0) {
    return {
      index: 0,
      id: 'mirror_flip',
      icon: $r('sys.symbol.trapezoid_and_line_vertical'),
      isSymbol: true,
      name: $r('app.string.mirror_flip')
    }
  } else if (index === 1) {
    return {
      index: 1,
      id: 'loop_playing',
      icon: $r('sys.symbol.repeat'),
      isSymbol: true,
      name: $r('app.string.loop_playing')
    }
  } else if (index === 2) {
    return {
      index: 2,
      id: 'visual_effect',
      icon: $r('sys.symbol.camera_filters'),
      isSymbol: true,
      name: $r('app.string.visual_effect')
    }
  } else if (index === 3) {
    return {
      index: 3,
      id: 'chapter_list',
      icon: $r('sys.symbol.bookmark'),
      isSymbol: true,
      name: $r('app.string.chapter_list')
    }
  } else if (index === 4) {
    return{
      index: 4,
      id: 'surface_filling_mode',
      icon: $r('sys.symbol.resolution_video'),
      isSymbol: true,
      name: $r('app.string.surface_filling_mode')
    }
  } else if (index === 5) {
    return {
      index: 5,
      id: 'audios',
      icon: $r('sys.symbol.sound'),
      isSymbol: true,
      name: $r('app.string.audios')
    }
  } else if (index === 6) {
    return {
      index: 6,
      id: 'subtitles',
      icon: $r('sys.symbol.AI_subtitles'),
      isSymbol: true,
      name: $r('app.string.subtitles')
    }
  } else if (index === 7) {
    return {
      index: 7,
      id: 'speed',
      icon: $r('sys.symbol.video_speed'),
      isSymbol: true,
      name: $r('app.string.speed')
    }
  }
  throw Error()
}

export function listHidButtons(): number[] {
  let buttons: number[] = []
  for (let i of [0, 1, 2, 3, 4, 5, 6, 7]) {
    if (Pref.topBar.includes(i))
      continue
    if (Pref.topBarFolded.includes(i))
      continue
    if (Pref.bottomBar.includes(i))
      continue
    if (Pref.bottomBarFolded.includes(i))
      continue
    buttons.push(i)
  }
  return buttons
}