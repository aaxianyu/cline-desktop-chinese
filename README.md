# cline-zh —— Cline 桌面端中文汉化补丁

非官方的 [Cline](https://github.com/cline/cline) 桌面端（Windows，Tauri + WebView2 架构）中文汉化工具。
不修改任何程序文件，通过 WebView2 调试协议在运行时注入 DOM 翻译脚本，按词典把英文界面实时替换为中文。

> 本项目（代码、词典翻译、文档）**全程由 Cline（AI Agent）自主完成**，人类仅提出需求与验收。

> 免责声明：本项目与 Cline 官方无关，仅供学习与个人使用。翻译内容为社区贡献，可能存在不准之处。

## 原理

- Cline 桌面端的 UI 是 Brotli 压缩内嵌在 `cline-app.exe` 里的，无法直接改二进制；
- WebView2 支持 `WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS` 环境变量，可借此开启**仅本机**的
  CDP 调试端口（默认 9223）；
- 工具启动应用后经 CDP 向页面注入 `translator.js`（DOM 翻译脚本）与 `zh-cn.json` 词典；
- 翻译脚本对界面文本节点与 placeholder/title/aria-label 属性做实时替换：
  DOMContentLoaded 全量翻译 + MutationObserver 增量翻译 + 定时兜底；
- 不修改 exe，应用自动更新后仍可使用；用正常方式启动应用即为英文原版。

## 环境要求

- Windows 10/11（WebView2 Runtime，系统一般自带）
- [Node.js](https://nodejs.org/) ≥ 18（零第三方依赖）

## 快速上手

```bat
:: 1. 完全退出正在运行的 Cline, 然后:
start-zh.cmd

:: 2. 验证汉化效果
node ui-check.mjs
```

想用英文界面时，直接双击正常的 Cline 图标启动即可。

## 词典扩充工作流（推荐）

发现没翻译的地方时：

```bat
:: ① 把 Cline 停在那个页面(下拉菜单/弹窗保持打开也行), 列出未翻译文案:
node find.mjs
::    结果在 out\todo.txt, 词典模板在 out\todo-template.json

:: ② 把新词条手动加进 zh-cn.json 后, 热更新(正在运行的界面立即生效, 无需重启):
node apply-dict.mjs

:: 更多采集器(抓到的文案都在 out\ 目录):
node harvest-settings.mjs     :: 自动遍历设置面板各分类页抓取文案
node harvest-submenus.mjs     :: 采集模型选择器/弹层菜单
node harvest-customize.mjs    :: 遍历"自定义"各分类标签
node harvest-acct-tabs.mjs    :: 遍历"账户"各标签
node harvest-addprovider.mjs  :: 采集"添加提供商"表单
node scan-runtime.mjs         :: 从内嵌 JS 代码块扫描任务执行期文案
node cline-zh.mjs dump        :: 全量抓取(应用未运行时), 产物在 out\
```

抓到的文案保存于 `out\`，可以据此为 `zh-cn.json` 补词条。

### 词典格式

`zh-cn.json` 为 `{ "英文原文": "中文译文" }`。支持**正则词条**：以 `^` 开头的 key
会被当作正则匹配，用 `$1`/`$2` 引用捕获组，适合带数字/时间的动态文案：

```json
{
  "^Thought for (\\d+)s$": "思考了 $1 秒",
  "^Worked for (\\d+)m (\\d+)s and made (\\d+) tool calls$": "工作 $1 分 $2 秒, 执行 $3 次工具调用"
}
```

注意：

- 保持原文完全一致（含大小写、省略号 `…` 与 `...`、弯引号 `’` 等）；
- 部分按钮被 CSS 转成大写显示（如 `EVENT`），DOM 里实际是 `Event`，两种都建议加入；
- 工具名、提供商名、模型名请勿翻译。

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `start-zh.cmd` | 一键汉化启动器 |
| `cline-zh.mjs` | 主工具：`run` 汉化启动 / `dump` 抓取文案 / `verify` 验证 / `kill` 关闭 |
| `translator.js` | 注入页面的 DOM 翻译脚本 |
| `zh-cn.json` | 中英词典（内置 500+ 条，含正则词条，可自行扩充） |
| `apply-dict.mjs` | 把 `zh-cn.json` 热更新到运行中的实例 |
| `find.mjs` | 列出当前页面未翻译文案 |
| `harvest-*.mjs` / `scan-runtime.mjs` | 各界面的文案采集器 |
| `ui-check.mjs` | 检查界面有无英文残留 |

## 常用参数

```bat
node cline-zh.mjs run --port 9223 --exe "C:\你的路径\cline-app.exe" --dict zh-cn.json
```

- `--exe`：手动指定 cline-app.exe 路径（默认自动探测常见安装位置，也可用环境变量 `CLINE_EXE`）
- `--port`：CDP 调试端口（默认 9223，被占用时换一个）

## 已知限制

- 托盘右下角菜单（New Session / Settings / Quit）是 Tauri 原生菜单，不经过 WebView，仍为英文；
- 调试端口仅监听 127.0.0.1，且只在通过本工具启动的应用实例存续期间开启；
  本机其他进程理论上可借该端口控制页面，介意者用完即关；
- 翻译仅作用于界面文案；聊天内容、代码块、输入框内文本不会被改动
  （脚本显式跳过 `pre/code/textarea`）；
- 应用大版本更新后若出现新文案，按上面的工作流补词典即可。

## 故障排查

- **提示"无法连接调试端口"**：Cline 正在以普通方式运行（无调试端口）。先完全退出
  （`node cline-zh.mjs kill` 或托盘退出），再用 `start-zh.cmd` 启动；
- **启动后仍是英文**：确认工具窗口保持运行（注入器随应用退出而退出）；
- **换端口**：`start-zh.cmd` 与各工具均可加 `--port <端口>`。

## License

[MIT](LICENSE)
