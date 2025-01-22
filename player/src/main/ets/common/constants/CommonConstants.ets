/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Common constants for all features.
 */
export class CommonConstants {
  /**
   * Idle state of avPlayer.
   */
  static readonly AV_PLAYER_IDLE_STATE: string = 'idle';

  /**
   * Initialized state of avPlayer.
   */
  static readonly AV_PLAYER_INITIALIZED_STATE: string = 'initialized';

  /**
   * Prepared state of avPlayer.
   */
  static readonly AV_PLAYER_PREPARED_STATE: string = 'prepared';

  /**
   * Playing state of avPlayer.
   */
  static readonly AV_PLAYER_PLAYING_STATE: string = 'playing';

  /**
   * Pause state of avPlayer.
   */
  static readonly AV_PLAYER_PAUSED_STATE: string = 'paused';

  /**
   * Completed state of avPlayer.
   */
  static readonly AV_PLAYER_COMPLETED_STATE: string = 'completed';

  /**
   * Stopped state of avPlayer.
   */
  static readonly AV_PLAYER_STOPPED_STATE: string = 'stopped';

  /**
   * Release state of avPlayer.
   */
  static readonly AV_PLAYER_RELEASE_STATE: string = 'released';

  /**
   * Error state of avPlayer.
   */
  static readonly AV_PLAYER_ERROR_STATE: string = 'error';

  /**
   * Video detail hsp name.
   */
  static readonly VIDEO_DETAIL_HSP_NAME: string = 'videoDetail';

  /**
   * Product video name.
   */
  static readonly PRODUCT_VIDEO_NAME: string = 'product.mp4';

  /**
   * Update time of av player.
   */
  static readonly AV_PLAYER_UPDATE_TIME: string = 'updateTime';

  /**
   * Current time of av player.
   */
  static readonly AV_PLAYER_CURRENT_TIME: string = 'currentTime';

  /**
   * Total time of av player.
   */
  static readonly AV_PLAYER_TOTAL_TIME: string = 'totalTime';

  /**
   * Progress of av player.
   */
  static readonly AV_PLAYER_PROGRESS: string = 'progress';

  /**
   * Initial time.
   */
  static readonly INITIAL_TIME: string = '00:00:00';

  /**
   * List space.
   */
  static readonly LIST_SPACE: string = '12vp';

  /**
   * Video grid column list.
   */
  static readonly VIDEO_GRID_COLUMNS: string[] = ['1fr 1fr', '1fr 1fr 1fr', '1fr 1fr 1fr 1fr', '1fr 1fr 1fr 1fr 1fr',
    '1fr 1fr 1fr 1fr 1fr 1fr 1fr'];

  /**
   * colon.
   */
  static readonly COLON: string = ':';

  /**
   * Time prefix.
   */
  static readonly TIME_PREFIX: string = '0';

  /**
   * Empty time.
   */
  static readonly EMPTY_TIME: string = '00';

  /**
   * Window util.
   */
  static readonly WINDOW_UTIL: string = 'windowUtil';

  /**
   * Full percent.
   */
  static readonly FULL_PERCENT: string = '100%';

  /**
   * One hundred for progress.
   */
  static readonly PROGRESS_HUNDRED: number = 100;

  /**
   * One thousand for progress.
   */
  static readonly PROGRESS_THOUSAND: number = 1000;

  /**
   * Second in hour.
   */
  static readonly SECOND_IN_HOUR: number = 3600;

  /**
   * Second in minute.
   */
  static readonly SECOND_IN_MINUTE: number = 60;

  /**
   * Zero.
   */
  static readonly ZERO: number = 0;

  /**
   * One.
   */
  static readonly ONE: number = 1;

  /**
   * Three.
   */
  static readonly THREE: number = 3;

  /**
   * FOUR.
   */
  static readonly FOUR: number = 4;

  /**
   * Ten.
   */
  static readonly TEN: number = 10;

  /**
   *  Constant for screen dpi.
   */
  static readonly SCREEN_DPI_CONSTANT: number = 160;

  /**
   * Font weight 500.
   */
  static readonly FONT_WEIGHT_500: number = 500;

  /**
   * Font weight 700.
   */
  static readonly FONT_WEIGHT_700: number = 700;

  /**
   * Text opacity.
   */
  static readonly TEXT_OPACITY: number[] = [0.4, 0.5, 0.6, 1, 0.8];

  /**
   * Divider opacity.
   */
  static readonly DIVIDER_OPACITY: number = 0.05;

  /**
   * X component surface width.
   */
  static readonly X_COMPONENT_SURFACE_WIDTH: number = 1920;

  /**
   * X component surface height.
   */
  static readonly X_COMPONENT_SURFACE_HEIGHT: number = 1080;

  /**
   * Video aspect ratio.
   */
  static readonly VIDEO_ASPECT_RATIO: number = 1.78;

  /**
   * Previous one row aspect ratio.
   */
  static readonly PREVIOUS_ONE_ROW_RATIO: number = 1.56;

  /**
   * Default window width.
   */
  static readonly DEFAULT_WINDOW_WIDTH: number = 320;

  /**
   * Device types.
   */
  static readonly DEVICE_TYPES: string[] = ['2in1', 'tablet', 'phone'];
}


