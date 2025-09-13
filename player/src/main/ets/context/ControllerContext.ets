import { DraggableItem } from "../ui/component/inner/InnerDraggable";
import { indexToDraggableItem } from "../ui/player/controller/ControllerItemMappings";
import { Pref } from "./PreferenceContext";

@ObservedV2
export class ControllerContext {

  @Trace
  topBar: DraggableItem[] = []
  @Trace
  bottomBar: DraggableItem[] = []
  @Trace
  topBarFolded: DraggableItem[] = []
  @Trace
  bottomBarFolded: DraggableItem[] = []

  public static init() {
    Con.topBar = Pref.topBar.map(indexToDraggableItem)
    Con.bottomBar = Pref.bottomBar.map(indexToDraggableItem)
    Con.topBarFolded = Pref.topBarFolded.map(indexToDraggableItem)
    Con.bottomBarFolded = Pref.bottomBarFolded.map(indexToDraggableItem)
  }

  public static save() {
    Pref.topBar = Con.topBar.map((it) => it.index)
    Pref.bottomBar = Con.bottomBar.map((it) => it.index)
    Pref.topBarFolded = Con.topBarFolded.map((it) => it.index)
    Pref.bottomBarFolded = Con.bottomBarFolded.map((it) => it.index)
  }

}

export let Con: ControllerContext = new ControllerContext()