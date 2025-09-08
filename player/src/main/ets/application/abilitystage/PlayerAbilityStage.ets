import { AbilityStage, Want } from '@kit.AbilityKit'
import { PreferenceContext } from '../../context/PreferenceContext'
import { Sys, SystemContext } from '../../context/SystemContext'
import { DB } from '../../database/DatabaseManager'
import { randomString } from '../../utils/StringUtils'
import { JSON, taskpool } from '@kit.ArkTS'
import { superContext } from '../../utils/AbilityUtils'
import { fileIo } from '@kit.CoreFileKit'
import { parseVtt } from '../../lib/subtitle/vtt/VttParser'

@Concurrent
function periodJob(): void {
  PreferenceContext.save(superContext())
}

export default class PlayerAbilityStage extends AbilityStage {
  private static superContext: Context | undefined = undefined
  private static task: taskpool.Task = new taskpool.Task(periodJob)

  async onCreate(): Promise<void> {
    PlayerAbilityStage.superContext = this.context
    await DB.init(this.context)
    PreferenceContext.load(this.context)
    SystemContext.start()
    taskpool.executePeriodically(10 * 60 * 1000, PlayerAbilityStage.task, taskpool.Priority.LOW)

    // 软件崩溃后不会清空 temp 文件夹，手动清空
    if (fileIo.accessSync(this.context.tempDir, fileIo.AccessModeType.EXIST)) {
      fileIo.rmdirSync(this.context.tempDir)
    }

    try {
      const vttContent = `WEBVTT - 这是一个电影的字幕文件

NOTE 样式定义
STYLE
---
::cue {
  background-color: transparent;
  color: white;
  font-family: Arial, sans-serif;
}
::cue(v[voice="Narrator"]) {
  font-style: italic;
  color: #ccc;
}
---

NOTE 定义一个区域用于演职员表
REGION
id:creditroll
lines:4
width:100%
regionanchor:50%,100%
viewportanchor:50%,100%
scroll:up

NOTE 第一章
intro
00:00:10.500 --> 00:00:13.000 line:90% align:center
<c .title>电影的标题</c>

2
00:00:15.000 --> 00:00:18.000
<v Narrator>在很久很久以前...</v>

3
00:01:30.000 --> 00:01:35.000
<v Bob>你好，Alice！今天过得怎么样？</v>

4
00:01:40.000 --> 00:01:45.000
<v Alice>还不错！<i>就是有点忙</i>。</v>

NOTE 影片结束的演职员表
00:55:00.000 --> 00:55:10.000 region:creditroll
导演：某某某
编剧：某某某
主演：某某某`;
      const result = parseVtt(vttContent);
      console.log("解析结果:", JSON.stringify(result));
    } catch (error) {
      console.error("VTT 解析错误:", error);
    }
  }

  onDestroy(): void {
    PreferenceContext.save(this.context)
    SystemContext.stop()
    taskpool.cancel(PlayerAbilityStage.task)
  }

  onAcceptWant(want: Want): string {
    if (Sys.isPC()) {
      return `RohyPlayer_${randomString(16)}`
    }
    return 'RohyPlayer'
  }

  public static getContext(): Context {
    return PlayerAbilityStage.superContext!!
  }
}