# SetRunAsAdmin

批量把 `.exe` 或 `.lnk` 设置为“以管理员身份运行”。

## 用法

- 把一个或多个 `.exe` / `.lnk` 拖到 `SetRunAsAdmin.bat`
- 或双击打开脚本，把文件拖入窗口后按 Enter

## 支持

- 多文件拖入
- 中文路径
- 带空格路径
- `.exe` 兼容性设置
- `.lnk` 快捷方式自身管理员运行标记

## 注意

- `.exe` 设置写入当前用户注册表：
  `HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers`
- `.lnk` 会修改快捷方式文件本身
- 设置后启动程序时可能会弹出 UAC

## 测试记录

已测试：

- 单个 `.exe`
- 多个 `.exe`
- 中文路径
- 带空格路径
- `.lnk`
- 不支持文件类型
- 文件不存在
- 保留已有兼容性设置
