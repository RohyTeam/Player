import { PlayerContext } from "../../../../player/PlayerContext"
import { buildMenuGroup, menuGroups, RohyMenu, RohyMenuItem } from "../../../component/menu/RohyMenu"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { PlayerController } from "../../../../player/PlayerController"
import { CircleIconButton } from "../../../button/CircleIconButton"
import { ControllerMenuButton } from "../ControllerItems"
import { ImportProgressContext, showEasyImportProgressDialog } from "../../../overlay/ImportProgressOverlay"
import { SubtitleInfo } from "../../../../player/subtitle/SubtitleInfo"
import { taskpool } from "@kit.ArkTS"
import { pickSingleSubtitleFile, pickSubtitleFiles } from "../../../../utils/PickerUtils"
import {
  ensurePath,
  existsInFiles,
  fileName,
  fileNameAndExtension, getPathInFiles, mkdirsInFiles } from "../../../../utils/FileUtils"
import { DialogHelper } from "@pura/harmony-dialog"
import { fileIo, fileUri } from "@kit.CoreFileKit"
import { compile } from "../../../../lib/subtitle/ass_compiler"


@Concurrent
function importSubtitle(uri: string, basePath: string) {
  let nameNextension = fileNameAndExtension(uri)
  let name = nameNextension[0]
  let extension = nameNextension[1]
  let added = 0
  while (fileIo.accessSync(`${basePath}/${name}${added == 0 ? "" : ` (${added})`}.${extension}`, fileIo.AccessModeType.EXIST)) {
    added += 1
  }
  if (fileIo.accessSync(`${basePath}/${name}${added == 0 ? "" : ` (${added})`}.${extension}`, fileIo.AccessModeType.EXIST)) {
    fileIo.unlinkSync(`${basePath}/${name}${added == 0 ? "" : ` (${added})`}.${extension}`)
  }
  fileIo.copyFileSync(ensurePath(uri), `${basePath}/${name}${added == 0 ? "" : ` (${added})`}.${extension}`)

  taskpool.Task.sendData(`${name}${added == 0 ? "" : ` (${added})`}.${extension}`)
}

@ComponentV2
struct ControllerSubtitles {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  @Local
  importProgressContext: ImportProgressContext = ImportProgressContext.reach(this.getUIContext())

  build() {
    RohyMenu({
      groups: menuGroups(() => [
        buildMenuGroup(() => [
          {
            options: {
              content: $r('app.string.no_subtitle'),
              symbolEndIcon: this.playerContext.selectedSubtitle == undefined ?
                new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
            },
            action: () => {
              if (this.playerContext.selectedSubtitle == undefined) {
                return
              }
              this.playerContext.selectedSubtitle = undefined
            }
          }
        ]),
        buildMenuGroup(() => {
          if (this.playerContext.subtitles.length == 0) {
            return undefined
          }
          let items: RohyMenuItem[] = []
          this.playerContext.subtitles.forEach((subtitle, index) => {
            if (subtitle.internal) {
              items.push({
                options: {
                  content: subtitle.title ? `${subtitle.title} (#${index})` : $r("app.string.internal_subtitle", `#${index}`),
                  symbolEndIcon: this.playerContext.selectedSubtitle === index ?
                    new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined,
                },
                action: () => {
                  if (this.playerContext.selectedSubtitle == index) {
                    return
                  }
                  this.playerContext.selectedSubtitle = undefined
                  this.playerContext.selectedSubtitle = index
                },
              })
            } else {
              items.push({
                options: {
                  content: subtitle.title ? `${subtitle.title} (#${index})` : $r("app.string.internal_subtitle", `#${index}`),
                  symbolEndIcon: this.playerContext.selectedSubtitle === index ?
                    new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined,
                  builder: (): void => this.externalSubtitleSubMenu(subtitle, index)
                },
                action: () => {},
              })
            }
          })
          return items
        }),
        buildMenuGroup(() => {
          if (this.playerContext.videoSource!.database()) {
            return this.importSubtitleMenuItem()
          } else {
            return this.openSubtitleMenuItem()
          }
        })
      ])
    })
  }

  @Builder
  private externalSubtitleSubMenu(subtitle: SubtitleInfo, index: number) {
    RohyMenu({
      groups: menuGroups(() => [
        buildMenuGroup(() => {
          let menuItems: RohyMenuItem[] = []

          if (this.playerContext.selectedSubtitle !== index) {
            menuItems.push({
              options: {
                content: $r("app.string.enable")
              },
              action: () => {
                if (this.playerContext.selectedSubtitle == index) {
                  return
                }
                this.playerContext.selectedSubtitle = undefined
                this.playerContext.selectedSubtitle = index
              }
            })
          }

          menuItems.push({
            options: {
              content: $r("app.string.delete")
            },
            action: () => {
              DialogHelper.showAlertDialog({
                primaryTitle: $r("app.string.delete_confirm"),
                content: $r("app.string.delete_confirm_desc"),
                primaryButton: {
                  value: $r("app.string.delete"),
                  fontColor: $r("sys.color.warning"),
                  action: () => {
                    if (this.playerContext.selectedSubtitle !== undefined) {
                      if (this.playerContext.subtitles[this.playerContext.selectedSubtitle] == subtitle) {
                        this.playerContext.selectedSubtitle = undefined
                      }
                    }
                    this.playerContext.subtitles.splice(this.playerContext.subtitles.indexOf(subtitle), 1)
                    this.playerContext.videoSource!.metadata().subtitles.splice(this.playerContext.videoSource!.metadata().subtitles.indexOf(subtitle), 1)

                    fileIo.unlinkSync(subtitle.url)
                  }
                },
                secondaryButton: {
                  value: $r("app.string.cancel"),
                  fontColor: $r("sys.color.font_primary")
                },
                onAction: (action: number, dialogId: string): void => {
                  DialogHelper.closeDialog(dialogId)
                }
              })
            }
          })
          return menuItems
        })
      ])
    })
  }

  private importSubtitleMenuItem(): RohyMenuItem[] {
    return [
      {
        options: {
          content: $r('app.string.import_subtitle')
        },
        action: () => {
          pickSubtitleFiles(this.getUIContext(), 500)
            .then((urls) => {
              if (urls.length == 0)
                return

              this.importProgressContext.current = 0
              this.importProgressContext.total = urls.length

              this.importProgressContext.subProgressTotal = 0

              let tasks: taskpool.Task[] = []
              let subtitleInfos: SubtitleInfo[] = []

              let cancelled = false
              let finished = false

              let startedTask: taskpool.Task[] = []

              let importProgressDialogId = showEasyImportProgressDialog(() => {
                cancelled = true
                for (let task of tasks) {
                  if (!task.isDone() && startedTask.indexOf(task) < 0) {
                    try {
                      taskpool.cancel(task)
                    } catch (_) {
                    }
                  }
                }
              })

              if (!existsInFiles(`videos/${this.playerContext.videoSource?.identity()}/external_subtitles`)) {
                mkdirsInFiles(`videos/${this.playerContext.videoSource?.identity()}/external_subtitles`)
              }

              let plusOne = () => {
                this.importProgressContext.current += 1
                if (this.importProgressContext.current >= this.importProgressContext.total) {
                  DialogHelper.closeDialog(importProgressDialogId)
                  if (!cancelled && !finished) {
                    finished = true
                    for (let subtitleInfo of subtitleInfos) {
                      this.playerContext.subtitles.push(subtitleInfo)
                      this.playerContext.videoSource?.metadata().subtitles.push(subtitleInfo)
                    }
                    // TODO: 显示所有的错误和问题
                  }
                }
              }

              for (let uri of urls) {
                let task = new taskpool.Task(importSubtitle, uri, getPathInFiles(`videos/${this.playerContext.videoSource?.identity()}/external_subtitles`))
                task.onReceiveData((finalName: string) => {
                  let subtitleInfo: SubtitleInfo | undefined = undefined
                  if (uri.endsWith(".ass")) {
                    subtitleInfo = {
                      title: finalName,
                      language: undefined,
                      url: getPathInFiles(`videos/${this.playerContext.videoSource?.identity()}/external_subtitles/${finalName}`),
                      type: 'ass',
                      internal: false
                    }
                  } else if (uri.endsWith(".sup")) {
                    subtitleInfo = {
                      title: finalName,
                      language: undefined,
                      url: getPathInFiles(`videos/${this.playerContext.videoSource?.identity()}/external_subtitles/${finalName}`),
                      type: 'pgs',
                      internal: false
                    }
                  } else if (uri.endsWith(".srt")) {
                    subtitleInfo = {
                      title: finalName,
                      language: undefined,
                      url: getPathInFiles(`videos/${this.playerContext.videoSource?.identity()}/external_subtitles/${finalName}`),
                      type: 'srt',
                      internal: false
                    }
                  }
                  if (subtitleInfo != undefined) {
                    subtitleInfos.push(subtitleInfo)
                  }
                  this.importProgressContext.current += 1
                  plusOne()
                })
                task.onExecutionFailed((err) => {
                  this.importProgressContext.current += 1
                  plusOne()
                })

                tasks.push(task)
              }

              for (let task of tasks) {
                if (cancelled)
                  break
                taskpool.execute(task)
                startedTask.push(task)
              }
            })
        }
      }
    ]
  }

  private openSubtitleMenuItem(): RohyMenuItem[] {
    return [
      {
        options: {
          content: $r('app.string.open_subtitle')
        },
        action: () => {
          pickSingleSubtitleFile(this.getUIContext())
            .then((file) => {
              if (file == undefined) {
                return
              }
              if (file.endsWith(".ass")) {
                let compiledASS = compile(fileIo.readTextSync(ensurePath(file)), void 0)
                let title = compiledASS.info.Title
                if (title == undefined || title == "") {
                  title = fileName(file)
                }
                this.playerContext.subtitles.push({
                  title: title,
                  language: undefined,
                  url: file,
                  type: 'ass',
                  internal: false
                })
              } else if (file.endsWith(".sup")) {
                this.playerContext.subtitles.push({
                  title: fileName(file),
                  language: undefined,
                  url: file,
                  type: 'pgs',
                  internal: false
                })
              } else if (file.endsWith(".srt")) {
                this.playerContext.subtitles.push({
                  title: fileName(file),
                  language: undefined,
                  url: file,
                  type: 'srt',
                  internal: false
                })
              }
            })
        }
      }
    ]
  }

}

@Builder
function subtitlesMenu() {
  ControllerSubtitles()
}

@Builder
export function subtitlesMenuItem() {
  MenuItem() {
    MenuItem({
      symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.AI_subtitles")),
      content: $r("app.string.subtitles"),
      builder: subtitlesMenu
    })
  }
}

@Builder
export function subtitlesButton(margin: Margin) {
  ControllerMenuButton({
    icon: $r("sys.symbol.AI_subtitles"),
    buttonMargin: margin
  }) {
    subtitlesMenu()
  }
}