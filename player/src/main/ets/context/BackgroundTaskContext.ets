import { WantAgent, wantAgent } from "@kit.AbilityKit";
import backgroundTaskManager from "@ohos.resourceschedule.backgroundTaskManager";
import { ensureContext } from "../utils/AbilityUtils";
import { Sys } from "./SystemContext";
import { BusinessError } from "@kit.BasicServicesKit";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { PlayerController } from "../player/PlayerController";

export class BackgroundTaskContext {

  private static started: boolean = false

  public static startBackgroundTask(context: UIContext | Context, playerController: PlayerController) {
    if (BackgroundTaskContext.started)
      return
    BackgroundTaskContext.started = true
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: "org.rohy.player",
          abilityName: "PlayerAbility",
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    wantAgent.getWantAgent(wantAgentInfo)
      .then((wantAgentObj) => {
      backgroundTaskManager.startBackgroundRunning(
        ensureContext(context),
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
        wantAgentObj
      ).then(() => {
        hilog.info(0, 'backgroundTask', 'startBackgroundRunning succeeded');
      }).catch((err: BusinessError) => {
        hilog.error(-1, 'backgroundTask', `startBackgroundRunning failed Cause: ${err.code} - ${err.message}`);
      });
    });
    backgroundTaskManager.on("continuousTaskCancel", (info: backgroundTaskManager.ContinuousTaskCancelInfo) => {
      playerController.pause()
      BackgroundTaskContext.started = false
      backgroundTaskManager.off('continuousTaskCancel')
    });
  }

  public static stopBackgroundTask(context: UIContext | Context): void {
    if (!BackgroundTaskContext.started)
      return
    BackgroundTaskContext.started = false
    backgroundTaskManager.off('continuousTaskCancel')
    backgroundTaskManager.stopBackgroundRunning(ensureContext(context))
      .then(() => {
        hilog.info(0, 'backgroundTask', 'stopBackgroundRunning succeeded');
      }).catch((err: BusinessError) => {
      hilog.error(-1, 'backgroundTask', `stopBackgroundRunning failed Cause: ${err.code} - ${err.message}`);
      });
  }

}