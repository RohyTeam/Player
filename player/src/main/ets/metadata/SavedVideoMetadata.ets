import { SendableSubtitleInfo, SubtitleInfo } from '../player/subtitle/SubtitleInfo';
import { SendableVideoMetadata, VideoMetadata } from './VideoMetadata';
import { collections, lang } from '@kit.ArkTS';

export interface SavedVideoMetadata {

  metadata: VideoMetadata
  identity: string
  subtitles: SubtitleInfo[]

}

@Sendable
export class SendableSavedVideoMetadata {

  metadata: SendableVideoMetadata
  identity: string
  subtitles: collections.Array<SendableSubtitleInfo>

  public constructor(
    metadata: SendableVideoMetadata,
    identity: string,
    subtitles: collections.Array<SendableSubtitleInfo>,
  ) {
    this.metadata = metadata
    this.identity = identity
    this.subtitles = subtitles
  }

}