import { CompiledASS } from '../lib/ass_compiler';

export interface SubtitleEntity {

  index: number,
  name: string,
  language: string,
  path: string,
  compiledASS: CompiledASS

}

@Observed
export class Subtitles extends Array<SubtitleEntity> {
}