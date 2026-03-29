## 部署方式

1. 打包 `scheme/shared/` + `scheme/hamster/` + `dicts/` 为 `.zip`
2. 元书设置 → 输入方案 → 导入方案
3. 或通过 Wi-Fi 上传到 Rime 目录
4. 执行"重新部署"

## 目录说明

元书有两个目录：**应用文件**和**键盘文件**。每次重新部署，应用文件会覆盖键盘文件。如果有自造词，需要在重新部署前从键盘文件目录手动拷回。

## 皮肤

皮肤使用 jsonnet 模板系统，见 `scheme/hamster/skins/`。jsonnet 编译为 YAML 后由元书读取，`config.yaml` 负责映射键盘类型到对应的布局文件。

## 脚本

脚本使用 **JavaScript**（不是 Lua），见 `scheme/hamster/scripts/`。

元书 v3 脚本格式：

```js
async function output() {
  // $searchText  — 当前输入框内容
  // $pasteboardContent — 剪贴板
  // $http()     — 网络请求（需 Pro）
  return "结果文本";
}
```
