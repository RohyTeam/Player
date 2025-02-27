<p align="center"><img src="./AppScope/resources/base/media/app_icon.png" style="width: 128px; height: 128px;"  alt="logo"></p>
<h1 align="center">Rohy 播放器</h1>
<p align="center">基于 ArkUI 原生开发的鸿蒙本地媒体播放器.</p>

## 目标
可以在 Issues 中提交您的建议！
- [x] 完全的字幕功能支持
- [x] 音量控制
- [x] 屏幕亮度调节
- [x] WebDAV 支持
- [ ] emby 支持
- [ ] FTP 支持
- [ ] ...

## 已知问题
- [x] ~~ASS 字幕支持不完全~~（已修复）
- [ ] 添加文件时，关闭 webdav 文件浏览器后选择 picker 的半模态窗口没有消失
- [ ] 无法解析视频的内封字幕
- [ ] 接续功能对大视频文件支持不明确
- [x] ~~应用接续时无法继承进度、音轨选项、字幕等控制器选项~~（仅支持进度条）
- [ ] ...

## 导入此项目
1. 从华为的 [下载官网](https://developer.huawei.com/consumer/cn/download/) 分别下载 DevEco Studio 和 仓颉支持插件（该插件需要申请才能获得，[申请地址](https://developer.huawei.com/consumer/cn/activityDetail/cangjie-beta/)）
2. 使用 git 工具将此项目的代码拉取至本地：`git clone https://github.com/RohyTeam/Player.git`
3. 使用 DevEco Studio 打开此项目
4. 删除测试相关的代码，寻找的办法就是寻找哪些地方使用了 Secrets 这个类

## 编译
如果你想自行编译本项目，可以根据如下步骤进行操作：
1. 先完成 [导入此项目](#导入此项目) 中的所有步骤
2. 点击菜单栏 File->Project Structure，在弹出的窗口中选择左侧 Project 栏，再从上方打开 Signing Configs 栏
3. 在打开的栏中找到 Automatically generate signature 选项，勾选后点击 OK，会自动打开浏览器让你登录你的华为账号
4. 登录之后，点击菜单栏 Build->Build Hap(s)/APP(s)->Build Hap(s) 后 DevEco Studio 便会开始编译
5. 编译后在 `./player/build/default/outputs/` 文件夹下就能找到签名与未签名的包

## 安装
首先，在开始安装前，请确保你的设备已经开启开发者模式并开启 USB 调试功能  
- 如果你有能完成 [编译](#编译) 的条件，你可以直接将设备通过数据线连接至电脑，在 DevEco 中选择你的设备并点击运行，软件会自动编译并安装到你的设备上  
- 如果你没有编译条件，你可以直接在 [Releases](https://github.com/RohyTeam/Player/releases) 中下载编译好的安装包，使用第三方工具 [AutoInstaller](https://github.com/likuai2010/auto-installer) 进行安装

## 鸣谢
- [Zhenye Wei](https://github.com/weizhenye) - 他开发的 [ass-compiler](https://github.com/weizhenye/ass-compiler) 为本项目提供字幕功能做了支持.