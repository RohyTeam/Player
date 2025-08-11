import { FileSource } from './FileSource';

export interface PickedFile {

  source: FileSource,
  url: string,
  title?: string

}