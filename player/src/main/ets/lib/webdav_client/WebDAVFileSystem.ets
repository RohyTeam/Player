import { XMLParser } from "@ifbear/fast-xml-parser"
import { StrUtil } from "@pura/harmony-utils"

const arrayTags = [
  "response",
  "lockentry"
]

const parser = new XMLParser({
  ignoreAttributes: false,
  removeNSPrefix: true,
  attributeNamePrefix: "_",
  isArray: (tagName, jPath, isLeafNode, isAttribute) => {
    if (arrayTags.indexOf(tagName) >= 0) { // 强制这些标签被解析为数组
      return true
    }
    return false
  }
})

export interface WebDAVFile {

  displayName: string
  path: string
  fullPath: string

}

export function parseFiles(parentDir: string, xmlData: ArrayBuffer): WebDAVFile[] {
  console.error(`beginning parsing`)
  let root = parser.parse(StrUtil.bufferToStr(xmlData)) as XmlRoot
  let fullpath: string
  if (!parentDir.endsWith("/")) {
    fullpath = `${parentDir}/`
  } else {
    fullpath = parentDir
  }

  let baseHrefLength = `${root.multistatus.response[0].href}/`.length

  console.error(`root is ${JSON.stringify(root)}`)
  return root.multistatus.response
    .map((response) => {
      let name = response.propstat.prop.displayname as string
      let path = response.href.substring(baseHrefLength)
      return {
        displayName: name,
        path: path,
        fullPath: `${fullpath}${path}`
      } as WebDAVFile
    })
}

// 下面的实际不需要使用，只是方便理解结构

interface XmlRoot {
  multistatus: XmlMultistatus
}

interface XmlMultistatus {
  response: XmlResponse[]
}

interface XmlResponse {
  href: string
  propstat: XmlPropstat
}

interface XmlPropstat {
  prop: XmlProp
  status: string
}

interface XmlProp {
  displayname: string
  creationdate: string
  supportedlock: XmlSupportedLock
  // 如果是 string 说明这是个文件，因为这玩意变成了空标签，fast xml parser 就会认为里面是一个空字符串而把这个值设置为字符串
  resourcetype: XmlResourceType | string
  getlastmodified: string
  getcontentlength: number | undefined
  getcontenttype: string | undefined
}

interface XmlSupportedLock {
  lockentry: XmlLockEntry[]
}

interface XmlLockEntry {
  lockscope: XmlLockScope
  locktype: XmlLockType
}

interface XmlLockScope {
  exclusive: object | undefined
}

interface XmlLockType {
  write: object | undefined
}

interface XmlResourceType {
  collection: object | undefined
}