export interface AudioEntity {

  index: number,
  name: string,
  language: string

}

@Observed
export class Audios extends Array<AudioEntity> {
}