// Gins-Rime · 元书脚本: URL 编解码

async function output() {
  const text = ($searchText || $pasteboardContent || "").trim();
  if (!text) return "请输入或复制文本";

  const decoded = decodeURIComponent(text);
  const encoded = encodeURIComponent(text);

  if (text === decoded && text !== encoded) {
    return "编码: " + encoded;
  }
  return ["解码: " + decoded, "编码: " + encoded];
}
