// Gins-Rime · 元书脚本: 时间戳转换

async function output() {
  const text = ($searchText || $pasteboardContent || "").trim();
  const now = new Date();

  if (/^\d{10,13}$/.test(text)) {
    let ts = parseInt(text);
    if (ts < 1e12) ts *= 1000;
    const d = new Date(ts);
    return [
      "UTC+8: " + d.toLocaleString("zh-CN", { timeZone: "Asia/Singapore" }),
      "ISO:   " + d.toISOString(),
    ];
  }

  const unix = Math.floor(now.getTime() / 1000);
  return [
    "Unix:  " + unix,
    "ISO:   " + now.toISOString(),
    "本地:  " + now.toLocaleString("zh-CN", { timeZone: "Asia/Singapore" }),
  ];
}
