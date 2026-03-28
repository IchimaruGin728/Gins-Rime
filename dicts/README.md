# dicts/

此目录存放外挂词库文件。Git 仅跟踪 `zhwiki.dict.yaml`（由 CI 构建），其余文件需手动从上游获取。

## 需要手动获取的文件

### tone_moe.dict.yaml
来源：https://github.com/suiginko/moetype/releases
下载"带声调-无辅助码"版本，放到此目录。

### en_dicts/（整个目录）
来源：https://github.com/iDvel/rime-ice
需要的文件：
- `en_dicts/en.dict.yaml`
- `en_dicts/en_ext.dict.yaml`

### melt_eng.schema.yaml
来源：https://github.com/iDvel/rime-ice
复制根目录的 `melt_eng.schema.yaml` 到 `scheme/shared/`。

## CI 自动构建

### zhwiki.dict.yaml
由 `.github/workflows/build-zhwiki.yml` 每周自动构建，从 GitHub Release 下载。
