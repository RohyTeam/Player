import { SubtitleInfo } from "../player/subtitle/SubtitleInfo";
import { VideoMetadata } from "./VideoMetadata";

export interface SavedVideoMetadata {

  metadata: VideoMetadata
  identity: string
  subtitles: SubtitleInfo[]

}