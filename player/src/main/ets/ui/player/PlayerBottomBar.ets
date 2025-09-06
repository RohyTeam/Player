import { Sys } from '../../context/SystemContext'
import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { AbilityStorage } from '../../storage/AbilityStorage'
import { Modifiers } from '../attributemodifier/Modifiers'
import { CircleIconButton } from '../button/CircleIconButton'
import { PlayerProgressBar } from './PlayerProgressBar'
import { ComponentContent, SymbolGlyphModifier } from '@kit.ArkUI'
import { pickSingleSubtitleFile, pickSubtitleFiles } from '../../utils/PickerUtils'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { compile } from '../../lib/subtitle/ass_compiler'
import { buildMenuGroup, menuGroups, RohyMenu, RohyMenuItem } from '../component/menu/RohyMenu'
import { Pref } from '../../context/PreferenceContext'
import { ImportProgressContext, ImportProgressOverlayBuilder } from '../overlay/ImportProgressOverlay'
import { ensurePath,
  existsInFiles,
  fileName, fileNameAndExtension, getPathInFiles, mkdirsInFiles } from '../../utils/FileUtils'
import { taskpool } from '@kit.ArkTS'
import { SubtitleInfo } from '../../player/subtitle/SubtitleInfo'
import { DialogHelper } from '@pura/harmony-dialog'

@ObservedV2
export class ControlsContext {
  @Trace
  showTopBarAndBottomBar: boolean = false
  @Trace
  showChapterList: boolean = false
}

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
export struct PlayerBottomBar {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Consumer("showSidebar")
  showSidebar: boolean = false
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!
  @Local
  showAudiosMenu: boolean = false
  @Local
  showSubtitlesMenu: boolean = false
  @Local
  showSpeedMenu: boolean = false

  @Local
  importProgressContext: ImportProgressContext = new ImportProgressContext()

  build() {
    Row() {
      Column() {
        PlayerProgressBar()
        Row() {
          CircleIconButton({
            icon: $r("sys.symbol.gobackward_15"),
            buttonMargin: {
              left: 16,
              bottom: 12
            },
            clickCallback: () => {
              this.playerController.goBackward(15 * 1000)
            }
          })
          this.playAndPauseButton()
          CircleIconButton({
            icon: $r("sys.symbol.goforward_15"),
            buttonMargin: {
              left: 12,
              bottom: 12
            },
            clickCallback: () => {
              this.playerController.goForward(15 * 1000)
            }
          })
          Blank()
            .layoutWeight(1)
          CircleIconButton({
            icon: $r("sys.symbol.questionmark_circle"),
            buttonMargin: {
              right: 16,
              bottom: 12
            },
            clickCallback: () => {
              this.showAudiosMenu = false // refresh menu status
              this.showAudiosMenu = true
            }
          })
            .bindMenu(this.showAudiosMenu!!, this.audiosMenu, {
              onDisappear: () => {
                this.showAudiosMenu = false
              }
            })
          CircleIconButton({
            icon: $r("sys.symbol.questionmark_circle"),
            buttonMargin: {
              right: 16,
              bottom: 12
            },
            clickCallback: () => {
              this.showSubtitlesMenu = false // refresh menu status
              this.showSubtitlesMenu = true
            }
          })
            .bindMenu(this.showSubtitlesMenu!!, this.subtitlesMenu, {
              onDisappear: () => {
                this.showSubtitlesMenu = false
              }
            })
          CircleIconButton({
            icon: $r("sys.symbol.chevron_left_2"),
            buttonMargin: {
              right: 16,
              bottom: 12
            },
            iconRotation: 180,
            clickCallback: () => {
              this.showSpeedMenu = false // refresh menu status
              this.showSpeedMenu = true
            }
          })
            .bindMenu(this.showSpeedMenu!!, this.speedMenu, {
              onDisappear: () => {
                this.showSpeedMenu = false
              }
            })
          if (Sys.isPC()) {
            CircleIconButton({
              icon: $r("sys.symbol.open_sidebar"),
              buttonMargin: {
                right: 16,
                bottom: 12
              },
              clickCallback: () => {
                this.showSidebar = true
              }
            })
          }
        }
        .width("100%")
      }
      .borderRadius(
        Pref.uiUpdatePreview ? {
          topLeft: Pref.innerRadius,
          topRight: Pref.innerRadius,
          bottomLeft: Pref.outerRadius,
          bottomRight: Pref.outerRadius
        } : {
          topLeft: Pref.innerRadius,
          topRight: Pref.innerRadius
        }
      )
      .margin(
        Pref.uiUpdatePreview ? {
          bottom: 8,
          left: 8,
          right: 8
        } : 0
      )
      .layoutWeight(1)
      .attributeModifier(Modifiers.backgroundBlur())
    }
    .width("100%")
  }

  @Builder
  private playAndPauseButton() {
    if (!this.playerContext.video || this.playerContext.paused) {
      CircleIconButton({
        icon: $r("sys.symbol.play_fill"),
        buttonMargin: {
          left: 12,
          bottom: 12
        },
        clickCallback: () => {
          if (!this.playerContext.video) {
            return
          }
          this.playerController.play()
        }
      })
    } else {
      CircleIconButton({
        icon: $r("sys.symbol.pause"),
        buttonMargin: {
          left: 12,
          bottom: 12
        },
        clickCallback: () => {
          if (!this.playerContext.video) {
            return
          }
          this.playerController.pause()
        }
      })
    }
  }

  @Builder
  private speedMenu() {
    Menu() {
      ForEach([0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0], (speed: number) => {
        if (this.playerContext.playSpeed == speed) {
          MenuItem({
            content: this.speedToText(speed),
            symbolEndIcon: new SymbolGlyphModifier($r("sys.symbol.checkmark")).fontSize(24)
          })
        } else {
          MenuItem({
            content: this.speedToText(speed),
          })
            .onClick(() => {
              this.playerController.setSpeed(speed)
            })
        }
      })
    }
  }

  @Builder
  private audiosMenu() {
    RohyMenu({
      groups: menuGroups(() => [
        buildMenuGroup(() => {
          let items: RohyMenuItem[] = []
          this.playerContext.audios.forEach((audio, index) => {
            items.push({
              options: {
                content: audio.title,
                symbolEndIcon: this.playerContext.selectedAudio === index ?
                  new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
              },
              action: () => {
                if (this.playerContext.selectedAudio == index) {
                  return
                }

                let deselect = this.playerContext.audios[this.playerContext.selectedAudio].index
                this.playerContext.selectedAudio = index

                let paused = this.playerContext.paused
                if (!paused) {
                  this.playerController.pause()
                }
                this.playerController.deselectTrack(deselect)
                this.playerController.selectTrack(audio.index)
                this.playerController.seek(this.playerContext.currentPosition)
                if (!paused) {
                  this.playerController.play()
                }
              }
            })
          })
          return items
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

  @Builder
  private subtitlesMenu() {
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

              let importProgressOverlayComponent: ComponentContent<ImportProgressContext> = new ComponentContent(
                this.getUIContext(),
                wrapBuilder(ImportProgressOverlayBuilder),
                this.importProgressContext
              );

              this.getUIContext().getPromptAction().openCustomDialog(
                importProgressOverlayComponent,
                {
                  autoCancel: false,
                  onWillDismiss: () => {
                  }
                }
              )

              if (!existsInFiles(`videos/${this.playerContext.videoSource?.identity()}/external_subtitles`)) {
                mkdirsInFiles(`videos/${this.playerContext.videoSource?.identity()}/external_subtitles`)
              }

              let taskGroup = new taskpool.TaskGroup()
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
                    this.playerContext.subtitles.push(subtitleInfo)
                    this.playerContext.videoSource?.metadata().subtitles.push(subtitleInfo)
                  }
                  this.importProgressContext.current += 1
                  if (this.importProgressContext.current >= this.importProgressContext.total) {
                    this.getUIContext().getPromptAction().closeCustomDialog(importProgressOverlayComponent)
                    importProgressOverlayComponent.dispose()
                  }
                })
                task.onExecutionFailed((err) => {
                  console.error(`error when importing subtitle: ${err.message}`)
                  this.importProgressContext.current += 1
                  if (this.importProgressContext.current >= this.importProgressContext.total) {
                    this.getUIContext().getPromptAction().closeCustomDialog(importProgressOverlayComponent)
                    importProgressOverlayComponent.dispose()
                    // TODO: 显示所有的错误和问题
                  }
                })

                taskGroup.addTask(task)
              }

              taskpool.execute(taskGroup)
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
                let compiledASS = compile(fileIo.readTextSync(new fileUri.FileUri(file).path), void 0)
                let title = compiledASS.info.Title
                if (title == undefined || title == "") {
                  title = new fileUri.FileUri(file).name
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
                  title: new fileUri.FileUri(file).name,
                  language: undefined,
                  url: file,
                  type: 'pgs',
                  internal: false
                })
              } else if (file.endsWith(".srt")) {
                this.playerContext.subtitles.push({
                  title: new fileUri.FileUri(file).name,
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

  private speedToText(speed: number): ResourceStr {
    switch (speed) {
      case 0.25:
        return $r("app.string.speed_0_25")
      case 0.5:
        return $r("app.string.speed_0_50")
      case 0.75:
        return $r("app.string.speed_0_75")
      case 1.25:
        return $r("app.string.speed_1_25")
      case 1.5:
        return $r("app.string.speed_1_50")
      case 1.75:
        return $r("app.string.speed_1_75")
      case 2:
        return $r("app.string.speed_2_00")
      default:
        return $r("app.string.speed_1_00")
    }
  }
}