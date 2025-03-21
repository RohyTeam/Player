import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DateUtil } from '@pura/harmony-utils';
import { fileIo, picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { currentFormattedTime, formattedStringToDate } from '../util/TimeUtil';

const LOG_FORMAT = "[${time}][${tag}][${level}] ${message}\n"
const LOG_WITH_ERR_FORMAT = "[${time}][${tag}][${level}] ${message}, Error: [${error_message}](${error_code})\n"

export interface LogOptions {
  file?: boolean
  domain?: number
  tag?: string
  error?: BusinessError
}

const NO_FILE_OPTIONS: LogOptions = {
  file: false
}

interface FileWithStat {
  file: string
  mtime: number
}

// 日志系统仅输出业务内容，请勿在 aboutToAppear 或 aboutToDisappear 中输出控件渲染信息导致滥用
export class Rlog { // 意为 Rohy Logger

  private static logfile: string = ``

  public static exportLog(context: common.Context, fileName: string): Promise<boolean> {
    Rlog.debug("start: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
    return new Promise((resultReturner) => {
      fileIo.access(`${context.cacheDir}/logs`, fileIo.AccessModeType.EXIST)
        .then((directoryExists) => {
          if (directoryExists) {
            Rlog.debug("logs directory exists", NO_FILE_OPTIONS)
            fileIo.access(`${context.cacheDir}/logs/${fileName}`, fileIo.AccessModeType.EXIST)
              .then((exists) => {
                if (exists) {
                  Rlog.debug("log file exists", NO_FILE_OPTIONS)

                  const documentSaveOptions = new picker.DocumentSaveOptions();
                  documentSaveOptions.newFileNames = [fileName];
                  documentSaveOptions.fileSuffixChoices = ['日志文件|.log'];
                  const documentViewPicker = new picker.DocumentViewPicker(context);
                  documentViewPicker.save(documentSaveOptions)
                    .then((documentSaveResult: Array<string>) => {
                      let uri = documentSaveResult[0]
                      fileIo.open(uri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
                        .then((file) => {

                          fileIo.readText(`${context.cacheDir}/logs/${fileName}`)
                            .then((logContent) => {
                              fileIo.write(file.fd, logContent)
                                .then(() => {
                                  Rlog.debug("log file exported", NO_FILE_OPTIONS)
                                  fileIo.close(file)
                                    .then(() => {
                                      Rlog.debug("dest file closed", NO_FILE_OPTIONS)
                                      Rlog.debug("end: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
                                      resultReturner(true)
                                    })
                                    .catch((err: BusinessError) => {
                                      Rlog.debug("failed to close log file", NO_FILE_OPTIONS)
                                      Rlog.debug("end: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
                                      resultReturner(false)
                                    })
                                })
                                .catch((err: BusinessError) => {
                                  Rlog.debug("failed to write log content to dest file", NO_FILE_OPTIONS)
                                  Rlog.debug("end: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
                                  resultReturner(false)
                                })
                            })
                            .catch((err: BusinessError) => {
                              Rlog.debug("failed to open log file", NO_FILE_OPTIONS)
                              Rlog.debug("end: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
                              resultReturner(false)
                            })
                        })
                        .catch((err: BusinessError) => {
                          Rlog.debug("failed to open dest file", NO_FILE_OPTIONS)
                          Rlog.debug("end: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
                          resultReturner(false)
                        })
                    })
                    .catch((err: BusinessError) => {
                      Rlog.debug("failed to use picker", NO_FILE_OPTIONS)
                      Rlog.debug("end: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
                      resultReturner(false)
                    })
                } else {
                  resultReturner(false)
                }
              })
          } else {
            Rlog.debug("logs directory not exists", NO_FILE_OPTIONS)
            Rlog.debug("end: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
            resultReturner(false)
          }
        })
        .catch((error: BusinessError) => {
          Rlog.debug(`failed to list logs`, { file: false, error: error })
          Rlog.debug("end: invoke of Rlog#exportLog function", NO_FILE_OPTIONS)
          resultReturner(false) // 不确定会出现什么情况，但是这种情况一般这个文件夹就不存在了
        })
    })
  }

  public static listLogs(context: common.Context): Promise<string[]> {
    Rlog.debug("start: invoke of Rlog#listLogs function", NO_FILE_OPTIONS)
    return new Promise((resultReturner) => {
      fileIo.access(`${context.cacheDir}/logs`, fileIo.AccessModeType.EXIST)
        .then((exists) => {
          if (exists) {
            Rlog.debug("logs directory exists", NO_FILE_OPTIONS)
            fileIo.listFile(
              `${context.cacheDir}/logs`,
              {
                recursion: false,
                filter: {
                  suffix: ['.log'],
                  excludeMedia: true
                }
              }
            ).then((files) => {
              if (files.length > 0) {
                Rlog.debug(`${files.length} log${files.length == 1 ? "" : "s"} ${files.length == 1 ? "has" :
                  "have"} been listed`, NO_FILE_OPTIONS)
                Rlog.debug("end: invoke of Rlog#listLogs function", NO_FILE_OPTIONS)
                resultReturner(files)
              } else {
                Rlog.debug("logs directory is empty", NO_FILE_OPTIONS)
                Rlog.debug("end: invoke of Rlog#listLogs function", NO_FILE_OPTIONS)
                resultReturner([])
              }
            })
          } else {
            Rlog.debug("logs directory not exists", NO_FILE_OPTIONS)
            Rlog.debug("end: invoke of Rlog#listLogs function", NO_FILE_OPTIONS)
            resultReturner([])
          }
        })
        .catch((error: BusinessError) => {
          Rlog.debug(`failed to list logs`, { file: false, error: error })
          Rlog.debug("end: invoke of Rlog#listLogs function", NO_FILE_OPTIONS)
          resultReturner([]) // 不确定会出现什么情况，但是这种情况一般这个文件夹就不存在了
        })
    })
  }

  public static listGroupedLogs(context: common.Context): Promise<Record<string, string[]>> {
    Rlog.debug("start: invoke of Rlog#listGroupedLogs function", NO_FILE_OPTIONS)
    return new Promise((resultReturner) => {
      fileIo.access(`${context.cacheDir}/logs`, fileIo.AccessModeType.EXIST)
        .then((exists) => {
          if (exists) {
            Rlog.debug("logs directory exists", NO_FILE_OPTIONS)
            fileIo.listFile(
              `${context.cacheDir}/logs`,
              {
                recursion: false,
                filter: {
                  suffix: ['.log'],
                  excludeMedia: true
                }
              }
            ).then((files) => {
              if (files.length > 0) {
                Rlog.debug(`${files.length} log${files.length == 1 ? "" : "s"} ${files.length == 1 ? "has" :
                  "have"} been listed`, NO_FILE_OPTIONS)
                Rlog.debug("end: invoke of Rlog#listGroupedLogs function", NO_FILE_OPTIONS)
                let groupedLogs: Record<string, string[]> = {}
                for (let file of files) {
                  let date = formattedStringToDate(file, 'yyyy-MM-dd-HH-mm-ss-fff-debug.log')
                  let minToDayDate = DateUtil.getFormatDateStr(date, 'yyyy-MM-dd')
                  if (groupedLogs[minToDayDate] == undefined) {
                    groupedLogs[minToDayDate] = []
                  }
                  groupedLogs[minToDayDate].push(file)
                }
                resultReturner(groupedLogs)
              } else {
                Rlog.debug("logs directory is empty", NO_FILE_OPTIONS)
                Rlog.debug("end: invoke of Rlog#listGroupedLogs function", NO_FILE_OPTIONS)
                resultReturner({})
              }
            })
          } else {
            Rlog.debug("logs directory not exists", NO_FILE_OPTIONS)
            Rlog.debug("end: invoke of Rlog#listGroupedLogs function", NO_FILE_OPTIONS)
            resultReturner({})
          }
        })
        .catch((error: BusinessError) => {
          Rlog.debug(`failed to list logs`, { file: false, error: error })
          Rlog.debug("end: invoke of Rlog#listGroupedLogs function", NO_FILE_OPTIONS)
          resultReturner({}) // 不确定会出现什么情况，但是这种情况一般这个文件夹就不存在了
        })
    })
  }

  private static clearHistory(context: common.Context, reserve?: number): Promise<void> {
    Rlog.debug("start: invoke of Rlog#clearHistory function", NO_FILE_OPTIONS)
    return new Promise((resultReturner) => {
      fileIo.access(`${context.cacheDir}/logs`, fileIo.AccessModeType.EXIST)
        .then((exists) => {
          if (exists) {
            Rlog.debug("logs directory exists, do clear", NO_FILE_OPTIONS)
            fileIo.listFile(
              `${context.cacheDir}/logs`,
              {
                recursion: false
              }
            ).then((files) => {
              if (files.length > 0) {
                let clearedFiles = 0
                if (reserve == undefined || reserve <= 0) {
                  Rlog.debug("all logs will be cleared", NO_FILE_OPTIONS)
                  for (let file of files) {
                    if (file == Rlog.logfile) { // 防止删除当前的日志
                      continue
                    }
                    Rlog.debug(`clearing log file: ${file}`, NO_FILE_OPTIONS)
                    fileIo.unlinkSync(`${context.cacheDir}/logs/${file}`)
                    clearedFiles += 1
                  }
                } else {
                  Rlog.debug(`${reserve} log${reserve == 1 ? "" : "s"} will be cleared`, NO_FILE_OPTIONS)
                  let skipped = 0
                  for (let file of files
                    .map<FileWithStat>(fileName => {
                      return {
                        file: fileName,
                        mtime: fileIo.statSync(`${context.cacheDir}/logs/${fileName}`).mtime
                      }
                    })
                    .sort((a, b) => b.mtime - a.mtime)
                  ) {
                    if (file.file == Rlog.logfile) { // 防止删除当前的日志
                      continue
                    }
                    if (skipped < reserve) { // 将更近的文件保留
                      skipped += 1
                      continue
                    }
                    Rlog.debug(`clearing log file: ${file.file}`, NO_FILE_OPTIONS)
                    fileIo.unlinkSync(`${context.cacheDir}/logs/${file.file}`)
                    clearedFiles += 1
                  }
                }
                Rlog.debug(`${clearedFiles} log${clearedFiles == 1 ? "" : "s"} ${files.length == 1 ? "has" :
                  "have"} been cleared`, NO_FILE_OPTIONS)
                Rlog.debug("end: invoke of Rlog#clearHistory function", NO_FILE_OPTIONS)
                resultReturner()
              } else {
                Rlog.debug("logs directory is empty, clear is not in need", NO_FILE_OPTIONS)
                Rlog.debug("end: invoke of Rlog#clearHistory function", NO_FILE_OPTIONS)
                resultReturner()
              }
            })
              .catch((error: BusinessError) => {
                Rlog.debug(`failed to list logs`, { file: false, error: error })
                Rlog.debug("end: invoke of Rlog#clearHistory function", NO_FILE_OPTIONS)
                resultReturner() // 不确定会出现什么情况，但是这种情况一般这个文件夹就不存在了
              })
          } else {
            Rlog.debug("logs directory not exists, clear is not in need", NO_FILE_OPTIONS)
            Rlog.debug("end: invoke of Rlog#clearHistory function", NO_FILE_OPTIONS)
            resultReturner()
          }
        })
        .catch((error: BusinessError) => {
          Rlog.debug(`failed to clear logs`, { file: false, error: error })
          Rlog.debug("end: invoke of Rlog#clearHistory function", NO_FILE_OPTIONS)
          resultReturner() // 不确定会出现什么情况，但是这种情况一般这个文件夹就不存在了
        })
    })
  }

  public static startTracking(context: common.Context) {
    Rlog.logfile = `${context.cacheDir}/logs/${DateUtil.getFormatDateStr(
      Date.now(),
      'yyyy-MM-dd-HH-mm-ss-fff'
    )}-debug.log`
    let save5logsOnly = AppStorage.get<boolean>('save5logsOnly')
    if ((save5logsOnly != undefined && save5logsOnly == true) || (save5logsOnly == undefined)) {
      Rlog.clearHistory(context, 5)
        .then(() => {
          Rlog.startTracking0(context)
        })
        .catch((error: BusinessError) => {
          Rlog.debug(`failed to clear logs`, { file: false, error: error })
          Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
        })
    } else {
      Rlog.startTracking0(context)
    }
  }

  private static startTracking0(context: common.Context) {
    fileIo.access(`${context.cacheDir}/logs`, fileIo.AccessModeType.EXIST)
      .then((exists) => {
        if (exists) {
          fileIo.open(Rlog.logfile, fileIo.OpenMode.CREATE)
            .then((file) => {
              Rlog.debug("logs directory exists, mkdir is not in need", NO_FILE_OPTIONS)
              fileIo.close(file)
                .then(() => {
                  Rlog.debug("log file created", NO_FILE_OPTIONS)
                  Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
                })
                .catch((error: BusinessError) => {
                  Rlog.debug(`error occurs when closing the file handle`, { file: false, error: error })
                  Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
                })
            })
            .catch((error: BusinessError) => {
              Rlog.debug(`failed to create log file`, { file: false, error: error })
              Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
            })
        } else {
          Rlog.debug("logs directory not exists, need to be created", NO_FILE_OPTIONS)
          fileIo.mkdir(`${context.cacheDir}/logs`, true)
            .then(() => {
              Rlog.debug("logs directory created", NO_FILE_OPTIONS)
              fileIo.open(Rlog.logfile, fileIo.OpenMode.CREATE)
                .then((file) => {
                  fileIo.close(file)
                    .then(() => {
                      Rlog.debug("log file created", NO_FILE_OPTIONS)
                      Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
                    })
                    .catch((error: BusinessError) => {
                      Rlog.debug(`error occurs when closing the file handle`, { file: false, error: error })
                      Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
                    })
                })
                .catch((error: BusinessError) => {
                  Rlog.debug(`failed to create log file`, { file: false, error: error })
                  Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
                })
            })
            .catch((error: BusinessError) => {
              Rlog.debug(`failed to create logs directory`, { file: false, error: error })
              Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
            })
        }
      })
      .catch((error: BusinessError) => {
        Rlog.debug(`failed to start tracking`, { file: false, error: error })
        Rlog.debug("end: invoke of Rlog#startTracking function", NO_FILE_OPTIONS)
      })
  }

  private static formatMessage(level: hilog.LogLevel, message: string, domain?: number, tag?: string, file?: boolean,
    error?: BusinessError) {
    domain = domain || 0
    file = file == undefined ? true : file
    tag = tag || 'output'
    let logMessage =
      error ? `[Rlog][${tag}] ${message}, Error: [${error.message}](${error.code})` : `[Rlog][${tag}] ${message}`

    if (file != undefined && file) {
      let fileMessage: string
      if (error != undefined) {
        fileMessage = LOG_WITH_ERR_FORMAT.replaceAll("${time}", currentFormattedTime())
          .replaceAll("${tag}", tag)
          .replaceAll("${message}", message)
          .replaceAll("${level}", `${logLevelString(level)}`)
          .replaceAll("${error_message}", error.message)
          .replaceAll("${error_code}", `${error.code}`)
          .replaceAll("${domain}", `${domain}`)
      } else {
        fileMessage = LOG_FORMAT.replaceAll("${time}", currentFormattedTime())
          .replaceAll("${tag}", tag)
          .replaceAll("${message}", message)
          .replaceAll("${level}", `${logLevelString(level)}`)
          .replaceAll("${domain}", `${domain}`)
      }
      fileIo.open(
        Rlog.logfile,
        fileIo.OpenMode.APPEND | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.NONBLOCK
      ).then((file) => {
        fileIo.write(file.fd, fileMessage)
          .then(() => {
            fileIo.close(file)
          })
          .catch((error: BusinessError) => {
            // 日志输出很重要，用 fatal 输出
            Rlog.fatal(`failed to write to logfile!`, { file: false, tag: tag, error: error })
          })
      })
        .catch((error: BusinessError) => {
          // 日志输出很重要，用 fatal 输出
          Rlog.fatal(`failed to open logfile, cannot output to file!`, { file: false, tag: tag, error: error })
        })
    }
    // 同时也输出在控制台中，方便调试时直接查看
    switch (level) {
      case hilog.LogLevel.DEBUG:
        hilog.debug(domain, tag, logMessage)
        break
      case hilog.LogLevel.INFO:
        hilog.info(domain, tag, logMessage)
        break
      case hilog.LogLevel.WARN:
        hilog.warn(domain, tag, logMessage)
        break
      case hilog.LogLevel.ERROR:
        hilog.error(domain, tag, logMessage)
        break
      case hilog.LogLevel.FATAL:
        hilog.fatal(domain, tag, logMessage)
        break
    }
  }

  public static debug(message: string, extra?: LogOptions) {
    if (extra != undefined) {
      Rlog.formatMessage(hilog.LogLevel.DEBUG, message, extra.domain, extra.tag, extra.file, extra.error)
    } else {
      Rlog.formatMessage(hilog.LogLevel.DEBUG, message)
    }
  }

  public static info(message: string, extra?: LogOptions) {
    if (extra != undefined) {
      Rlog.formatMessage(hilog.LogLevel.INFO, message, extra.domain, extra.tag, extra.file, extra.error)
    } else {
      Rlog.formatMessage(hilog.LogLevel.INFO, message)
    }
  }

  public static warn(message: string, extra?: LogOptions) {
    if (extra != undefined) {
      Rlog.formatMessage(hilog.LogLevel.WARN, message, extra.domain, extra.tag, extra.file, extra.error)
    } else {
      Rlog.formatMessage(hilog.LogLevel.INFO, message)
    }
  }

  public static error(message: string, extra?: LogOptions) {
    if (extra != undefined) {
      Rlog.formatMessage(hilog.LogLevel.ERROR, message, extra.domain, extra.tag, extra.file, extra.error)
    } else {
      Rlog.formatMessage(hilog.LogLevel.INFO, message)
    }
  }

  public static fatal(message: string, extra?: LogOptions) {
    if (extra != undefined) {
      Rlog.formatMessage(hilog.LogLevel.FATAL, message, extra.domain, extra.tag, extra.file, extra.error)
    } else {
      Rlog.formatMessage(hilog.LogLevel.INFO, message)
    }
  }
}

function logLevelString(level: hilog.LogLevel): string {
  if (level == hilog.LogLevel.DEBUG) {
    return "DEBUG"
  } else if (level == hilog.LogLevel.INFO) {
    return "INFO"
  } else if (level == hilog.LogLevel.WARN) {
    return "WARN"
  } else if (level == hilog.LogLevel.ERROR) {
    return "ERROR"
  } else if (level == hilog.LogLevel.FATAL) {
    return "FATAL"
  }
  return "UNKNOWN"
}