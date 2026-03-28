// Gins-Rime · 元书脚本: Base64 编解码
// 输入: $searchText 或剪贴板

async function output() {
  const CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(str) {
    const bytes = [];
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i);
      if (code > 0x7f) bytes.push(0xc0 | (code >> 6), 0x80 | (code & 0x3f));
      else bytes.push(code);
    }
    let result = "";
    for (let i = 0; i < bytes.length; i += 3) {
      const b0 = bytes[i], b1 = bytes[i+1] ?? 0, b2 = bytes[i+2] ?? 0;
      result += CHARS[b0 >> 2];
      result += CHARS[((b0 & 3) << 4) | (b1 >> 4)];
      result += bytes[i+1] !== undefined ? CHARS[((b1 & 0xf) << 2) | (b2 >> 6)] : "=";
      result += bytes[i+2] !== undefined ? CHARS[b2 & 0x3f] : "=";
    }
    return result;
  }

  function decode(str) {
    const clean = str.replace(/[^A-Za-z0-9+/]/g, "");
    const lookup = Object.fromEntries([...CHARS].map((c, i) => [c, i]));
    const bytes = [];
    for (let i = 0; i < clean.length; i += 4) {
      const b0 = lookup[clean[i]], b1 = lookup[clean[i+1]];
      const b2 = lookup[clean[i+2]], b3 = lookup[clean[i+3]];
      bytes.push((b0 << 2) | (b1 >> 4));
      if (clean[i+2] !== "=") bytes.push(((b1 & 0xf) << 4) | (b2 >> 2));
      if (clean[i+3] !== "=") bytes.push(((b2 & 3) << 6) | b3);
    }
    return String.fromCharCode(...bytes);
  }

  const text = ($searchText || $pasteboardContent || "").trim();
  if (!text) return "请输入或复制文本";

  const isBase64 = /^[A-Za-z0-9+/]+=*$/.test(text) && text.length % 4 === 0;
  if (isBase64) {
    return ["解码: " + decode(text), "编码: " + encode(text)];
  }
  return "编码: " + encode(text);
}
