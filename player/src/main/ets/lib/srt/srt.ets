// 感谢 salut1618(https://gist.github.com/salut1618) 在 https://gist.github.com/korny/c31e1017b2e23c2f4042
// 中分享的建议 srt 解析代码

function srtTimeToSeconds(time: string) {
  let match = time.match(/(\d\d):(\d\d):(\d\d),(\d\d\d)/)!
  let hours = parseInt(match[1]) || 0
  let minutes = parseInt(match[2]) || 0
  let seconds = parseInt(match[3]) || 0
  let milliseconds = parseInt(match[4]) || 0

  return (hours * 60 * 60 * 1000) + (minutes * 60 * 1000) + (seconds * 1000) + (milliseconds);
}

function parseSrtLine(line: string): SrtSubtitleLine {
  let match = line.match(/(\d\d:\d\d:\d\d,\d\d\d) --> (\d\d:\d\d:\d\d,\d\d\d)\n([\S\s]*)/m)!

  return {
    text:  match[3].trim(),
    start: srtTimeToSeconds(match[1]),
    end:   srtTimeToSeconds(match[2])
  };
}

export interface SrtSubtitleLine {

  text: string
  start: number
  end: number

}

export function parseSrtSubtitle(content: string): Array<SrtSubtitleLine> {
  return content.replaceAll('\r', '')
    .split(/(?:^|\n\n)\d+\n|\n+$/g)
    .slice(1, -2)
    .map((rawLine) => {
      return parseSrtLine(rawLine)
    })
}