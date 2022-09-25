---
title: "为Macos的sudo命令启用TouchID认证"
layout: post
---

平时我们在 Macos 终端使用了 `sudo` 命令后需要输入账户密码，本文记录为 `sudo` 命令开启 `TouchID` 认证。

在终端中执行 `sudo vim /etc/pam.d/sudo`，打开文件后在最前面加入 `auth       sufficient     pam_tid.so`，然后重新打开终端再执行 `sudo` 就会提示使用指纹认证了。
