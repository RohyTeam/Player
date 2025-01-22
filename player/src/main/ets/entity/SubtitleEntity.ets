import { CompiledASS } from "../lib/ass_compiler";

export interface SubtitleEntity {

  index: number,
  name: string,
  language: string,
  compiledASS: CompiledASS

}

@Observed
export class Subtitles extends Array<SubtitleEntity> {}