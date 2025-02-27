export interface VirtualNode {

  displayName: string
  name: string
  size: number
  isDirectory: boolean

}

export interface VirtualFileSystem {

  listFiles: (path: string) => Promise<VirtualNode[]>
  visibleFilter: (node: VirtualNode) => boolean
  onFileSelected: (path: string, node: VirtualNode) => void

}

@Component
export struct FileTreeView {
  @Prop
  @Require
  path: string
  @Prop
  @Require
  fileSystem: VirtualFileSystem
  @Prop
  loaded: boolean = false
  @State
  fileSystemCache: VirtualNode[] = []
  @Consume('filePickerPageController')
  filePickerPageController: NavPathStack

  build() {
    NavDestination() {
      List() {
        if (this.loaded) {
          ForEach(this.fileSystemCache, (virtualFile: VirtualNode) => {
            if (this.fileSystem.visibleFilter(virtualFile)) {
              ListItem() {
                Row() {
                  Image($r(virtualFile.isDirectory ? "app.media.hidisk_icon_folder" : "app.media.hidisk_icon_video"))
                    .width(40)
                    .height(40)
                    .margin({
                      left: 8,
                      top: 8,
                      bottom: 8
                    })
                  Text(virtualFile.name)
                    .margin({
                      left: 8,
                      top: 16,
                      bottom: 16
                    })
                }
                .width("100%")
              }
              .onAppear(() => {
                console.error(`trying to show files`)
              })
              .onClick(() => {
                console.error(`going to another directory`)
                if (virtualFile.isDirectory) {
                  this.filePickerPageController.pushPath({
                    name: this.path.length > 1 ? this.path + "/" + virtualFile.name : `/${virtualFile.name}`
                  })
                } else {
                  this.fileSystem.onFileSelected(this.path.length > 1 ? this.path + "/" + virtualFile.name :
                    `/${virtualFile.name}`, virtualFile)
                }
              })
              .align(Alignment.Start)
              .backgroundColor($r("app.color.rohy_settings_background"))
              .width("90%")
            }
          })
        } else {
          ListItem() {
            Column() {
              Blank()
                .layoutWeight(2)
              LoadingProgress()
                .enableLoading(true)
                .color($r("app.color.icon_secondary"))
                .width(64)
                .height(64)
              Blank()
                .layoutWeight(3)
            }
            .backgroundColor(Color.Transparent)
            .height("100%")
            .width("100%")
          }
          .backgroundColor(Color.Transparent)
          .height("100%")
          .width("100%")
        }
      }
      .onAppear(() => {
        if (!this.loaded && this.fileSystemCache.length == 0) {
          console.error(`entering a directory`)
          this.fileSystem.listFiles(this.path)
            .then((files) => {
              console.error(`listed over`)
              this.fileSystemCache = files
              console.error(`value set`)
              this.loaded = true
              console.error(`load status set`)
            })
        } else {
          this.loaded = true
        }
      })
      .backgroundColor($r("app.color.rohy_settings_background"))
      .height("100%")
      .width("100%")
    }
    .backgroundColor(Color.Transparent)
    .hideTitleBar(true)
    .hideToolBar(true)
    .width("100%")
    .height("100%")
  }
}

@Component
export struct VirtualFilePicker {
  @Prop
  @Require
  title: ResourceStr
  @Prop
  @Require
  fileSystem: VirtualFileSystem
  @Link
  show: boolean
  @Provide('filePickerPageController')
  filePickerPageController: NavPathStack = new NavPathStack()

  build() {
    Column() {
      this.titleBar()
      Blank()
        .height(8)
        .width("100%")
      Column() {
        Navigation(this.filePickerPageController) {
          FileTreeView({
            path: "/",
            fileSystem: this.fileSystem
          })
        }
        .navDestination(this.PageControllerDestination)
        .backgroundColor(Color.Transparent)
        .height('100%')
        .width('100%')
        .mode(NavigationMode.Stack)
        .hideTitleBar(true)
        .hideBackButton(true)
        .hideToolBar(true)
      }
      .backgroundColor($r("app.color.rohy_settings_background"))
      .height("100%")
      .width("100%")
    }
    .backgroundColor(Color.Transparent)
    .height("100%")
    .width("100%")
  }

  @Builder
  PageControllerDestination(path: string) {
    FileTreeView({
      path: path,
      fileSystem: this.fileSystem
    })
  }

  @Builder
  titleBar() {
    Row() {
      Text(this.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.font_primary"))
        .margin(16)
      Blank()
        .layoutWeight(1)

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.xmark"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .onClick(() => {
        this.show = false
      })
      .align(Alignment.Center)
      .margin({
        right: 12
      })
      .width(40)
      .height(40)
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .margin({
      left: 8,
      right: 8,
      top: 8
    })
    .backgroundColor($r("app.color.rohy_settings_background"))
  }
}