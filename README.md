## ROS2 Humble for Innowing Workshop

```shell
docker pull casualiq/iw_ros2_docker:latest
./run.sh -w dev_ws -i casualiq/iw_ros2_docker:latest -r
```

## USBIP Installation
Install usbip for Windows
[Link](https://github.com/dorssel/usbipd-win/releases)

Install usbip for WSL

```shell
sudo apt install linux-tools-virtual hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip $(command -v ls /usr/lib/linux-tools/*/usbip | tail -n1) 20
```