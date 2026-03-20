<div align="center">
<p><a href="README.md">English</a> | 简体中文 </p>
</div>

# DockerHarmony
由于 OpenHarmony 的 userland 可以运行在 Linux kernel 上，因此 OpenHarmony 的容器化是可行的。

该项目将 OpenHarmony 的 mini rootfs 做成 Docker 容器镜像，使我们能够使用 Linux 服务器来运行和测试我们的命令行程序，而不用依赖 OpenHarmony 物理设备。

## 支持的架构
仅支持 arm64

## 用法
从 Docker Hub 拉取镜像并运行
```sh
docker pull hqzing/dockerharmony:latest
docker run -itd --name=ohos hqzing/dockerharmony:latest
docker exec -it ohos sh
```

从 GitHub Container Registry 拉取镜像并运行
```sh
docker pull ghcr.io/hqzing/dockerharmony:latest
docker run -itd --name=ohos ghcr.io/hqzing/dockerharmony:latest
docker exec -it ohos sh
```

可用的标签
| 标签       | 描述                                                         |
|------------|----------------------------------------------------------    |
| latest     | 最新的正式版本（当前等价于 6.0）                             |
| 6.0        | 基于 OpenHarmony 6.0 Release 制作的镜像                      |
| main       | 主干版本，基于本仓库 main 分支的最新构建脚本进行构建         | 

## 需要更多软件?
OpenHarmony 的根文件系统（rootfs）主要由三个部分组成：[musl libc](https://musl.libc.org)、[toybox](https://landley.net/toybox) 和 [mksh](https://github.com/MirBSD/mksh)。命令行实用工具（Command-line utilities）由 `toybox` 提供，它只提供了很少量的命令。

由于 OpenHarmony 目前还没有包管理器，所以我们没法通过一条命令去自动下载安装软件包，只能手动下载。

为了方便用户手动下载软件，容器镜像中预置了一个 `curl`。

许多为 aarch64-linux-musl 平台编译的软件都可以在这个容器中运行。例如，来自 Alpine Linux 软件仓库的 `make` 就是兼容的:

```sh
package_name="make"
alpine_repository="http://dl-cdn.alpinelinux.org/alpine/v3.22/main/aarch64"
curl -fsSL ${alpine_repository}/APKINDEX.tar.gz | tar -zx -C /tmp
package_version=$(grep -A1 "^P:${package_name}$" /tmp/APKINDEX | sed -n "s/^V://p")
apk_file_name=${package_name}-${package_version}.apk
curl -L -O ${alpine_repository}/${apk_file_name}
tar -zxf ${apk_file_name} -C /

# 现在你可以使用 make 命令了
```

你也可以在 [这个社区](https://gitcode.com/OpenHarmonyPCDeveloper) 进行探索，里面有一些已经移植到 OpenHarmony 平台上的软件。

## 在 GitHub 工作流中使用
要在 GitHub 工作流中使用这个镜像，首先你使用的执行机需要是 arm64 架构的。GitHub 提供了 arm64 架构的 [partner runner images](https://github.com/actions/partner-runner-images)，我们可以免费使用它们。

需要注意的是，GitHub 上许多预置的工作流（例如 actions/checkout）依赖于 Node.js 运行时环境，我们需要为此做一些特殊准备。

```yml
jobs:
  buid:
    name: build
    runs-on: ubuntu-24.04-arm
    container:
      image: hqzing/dockerharmony:latest
      volumes:
        - /opt/node24:/__e/node24:rw,rshared
    steps:
      - name: Setup node for actions
        run: |
          curl -L -O https://github.com/hqzing/ohos-node/releases/download/v24.2.0/node-v24.2.0-openharmony-arm64.tar.gz
          mkdir /__e/node24/bin
          tar -zxf node-v24.2.0-openharmony-arm64.tar.gz -C /opt
          ln -s /opt/node-v24.2.0-openharmony-arm64/bin/node /__e/node24/bin/node
      - name: Checkout
        uses: actions/checkout@v5
      # 编写你的业务
```

这个方案参考了：https://github.com/actions/runner/issues/801.

## 从源码构建镜像

环境要求:
- Ubuntu 22.04 x64（不支持 24.04）
- 至少 300GB 的可用磁盘空间
- 机器上安装了 Docker
- 一个通畅的网络环境，可以正常访问 GitHub、Gitee 等网站
- 使用 root 用户 (OpenHarmony 源码里面的 build.sh 就需要 root, 因此这个项目也同样需要)

建议:
- 建议构建之前重置你的构建机，使用一个干净全新的构建机来进行构建。这可以避免很多因环境问题导致的构建失败。
- 建议使用尽可能高的带宽和 CPU 规格，因为构建一个操作系统需要下载和编译非常多的文件。

构建容器镜像的命令如下：
```sh
git clone https://github.com/hqzing/dockerharmony.git
cd dockerharmony
./build-images.sh
./build-curl.sh
./build-rootfs.sh
DOCKER_BUILDKIT=1 docker buildx build --platform linux/arm64 -t dockerharmony:latest .
```

由于构建机是 x64 架构的，而容器是 arm64 架构的，所以你不能直接在构建机上运行这个容器。

如果你想在构建机上运行这个容器，你需要安装 QEMU 并注册 QEMU 解释器。

你可以使用 `tonistiigi/binfmt` 镜像，通过一条命令完成这件事：

```sh
docker run --privileged --rm tonistiigi/binfmt --install all
```

现在你可以在 x64 宿主机上运行 arm64 容器了：

```sh
docker run --name=ohos -itd --platform linux/arm64 dockerharmony:latest
```

由于软件模拟的速度远慢于原生 arm64 硬件，建议仅将此方法用于快速验证。
