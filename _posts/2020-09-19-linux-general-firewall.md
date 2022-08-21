---
title: "linux 防火墙开放端口"
layout: post
---

> 注意：不是直接关闭防火墙(这样很危险)，而是开放指定某个端口

## 启动防火墙

```java
systemctl start|stop|status firewalld
```

## 查看已经开放的端口

```shell
firewall-cmd --list-all
```

输出内容中的 **ports** 就是已经开放的端口信息

## 添加http服务

```shell
firewall-cmd --add-service=http --permanent
```

**--permanent:** 永久性添加

## 添加端口

```shell
firewall-cmd --add-port=80/tcp --permanent
```

添加80端口,协议为tcp

**添加完端口后，需要reload一下** `firewall-cmd --reload`
