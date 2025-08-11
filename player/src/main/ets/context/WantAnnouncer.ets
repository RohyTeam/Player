@ObservedV2
export class WantAnnouncer {
  @Trace
  announced: boolean = false
}

export const Wanter: WantAnnouncer = new WantAnnouncer()