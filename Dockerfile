FROM osrf/ros:humble-desktop-full

ARG WORKSPACE=humble_dev_ws
WORKDIR /root/$WORKSPACE

ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics
ENV QT_X11_NO_MITSHM=1
ENV EDITOR=nano
ENV XDG_RUNTIME_DIR=/tmp

RUN apt-get update && apt-get install -y \
    cmake \
    curl \
    gazebo \
    libglu1-mesa-dev \
    nano \
    python3-pip \
    python3-pydantic \
    python3-colcon-common-extensions \
    ros-humble-gazebo-ros \
    ros-humble-gazebo-ros-pkgs \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-joint-state-publisher \
    ros-humble-robot-localization \
    ros-humble-plotjuggler-ros \
    ros-humble-robot-state-publisher \
    ros-humble-ros2bag \
    ros-humble-rosbag2-storage-default-plugins \
    ros-humble-rqt-tf-tree \
    ros-humble-rmw-fastrtps-cpp \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-slam-toolbox \
    ros-humble-turtlebot3* \
    ros-humble-turtlebot3-msgs \
    ros-humble-twist-mux \
    ros-humble-usb-cam \
    ros-humble-xacro \
    ruby-dev \
    rviz \
    sudo \
    tmux \
    wget \
    xorg-dev \
    zsh

RUN pip3 install setuptools==58.2.0

RUN wget https://github.com/openrr/urdf-viz/releases/download/v0.38.2/urdf-viz-x86_64-unknown-linux-gnu.tar.gz && \
    tar -xvzf urdf-viz-x86_64-unknown-linux-gnu.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/urdf-viz && \
    rm -f urdf-viz-x86_64-unknown-linux-gnu.tar.gz

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.2/zsh-in-docker.sh)" -- \
    -p git \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions

RUN gem install tmuxinator && \
    wget https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh -O /usr/local/share/zsh/site-functions/_tmuxinator

# 安装 librealsense
RUN sudo apt-get update && sudo apt-get install -y \
    libssl-dev \
    libusb-1.0-0-dev \
    libudev-dev \
    pkg-config \
    libgtk-3-dev \
    libglfw3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cd /root && \
    git clone https://github.com/IntelRealSense/librealsense.git && \
    cd librealsense && \
    mkdir build && \
    cd build && \
    cmake ../ -DBUILD_EXAMPLES=true -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make install

# 安装 ament_cmake
RUN sudo apt-get update && sudo apt-get install -y \
    ros-humble-ament-cmake \
    python3-ament-package \
    ros-humble-rosidl-typesupport-c \
    ros-humble-rosidl-default-generators

# 设置 CMAKE_PREFIX_PATH
ENV CMAKE_PREFIX_PATH=/opt/ros/humble:$CMAKE_PREFIX_PATH

# # 克隆 realsense-ros 仓库并构建
RUN cd /root/$WORKSPACE && \
    mkdir -p src && \
    cd src && \
    git clone https://github.com/IntelRealSense/realsense-ros.git
    # cd .. && \
    # rosdep update && \
    # rosdep install -i --from-path src --rosdistro $ROS_DISTRO --skip-keys=librealsense2 -y && \
    # colcon build --symlink-install

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN echo "export DISABLE_AUTO_TITLE=true" >> /root/.zshrc
RUN echo 'LC_NUMERIC="en_US.UTF-8"' >> /root/.zshrc
RUN echo "source /opt/ros/humble/setup.zsh" >> /root/.zshrc
RUN echo "source /usr/share/gazebo/setup.sh" >> /root/.zshrc

RUN echo 'alias rosdi="rosdep install --from-paths src --ignore-src --rosdistro=${ROS_DISTRO} -y"' >> /root/.zshrc
RUN echo 'alias cbuild="colcon build --symlink-install"' >> /root/.zshrc
RUN echo 'alias ssetup="source ./install/local_setup.zsh"' >> /root/.zshrc
RUN echo 'alias cyclone="export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp"' >> /root/.zshrc
RUN echo 'alias fastdds="export RMW_IMPLEMENTATION=rmw_fastrtps_cpp"' >> /root/.zshrc
RUN echo 'export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp' >> /root/.zshrc
RUN echo 'export TURTLEBOT3_MODEL=waffle' >> /root/.zshrc

RUN echo "autoload -U bashcompinit" >> /root/.zshrc
RUN echo "bashcompinit" >> /root/.zshrc
RUN echo 'eval "$(register-python-argcomplete3 ros2)"' >> /root/.zshrc
RUN echo 'eval "$(register-python-argcomplete3 colcon)"' >> /root/.zshrc

RUN sudo sed -i 's/robot_model_type: "differential"/robot_model_type: "nav2_amcl::DifferentialMotionModel"/g' /opt/ros/humble/share/turtlebot3_navigation2/param/waffle.yaml

CMD [ "tmuxinator", "start", "-p", "/root/.session.yml" ]
