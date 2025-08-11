export interface FileSource {

  getIdentifier(): string

}

export class SingleInstanceFileSource implements FileSource {
  private identifier: string

  constructor(identifier: string) {
    this.identifier = identifier
  }

  getIdentifier(): string {
    return this.identifier
  }
}

export const LocalFiles: SingleInstanceFileSource = new SingleInstanceFileSource("local_files")

export const Photos: SingleInstanceFileSource = new SingleInstanceFileSource("photos")