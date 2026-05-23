# ==========================================
# STAGE 1: SBC / DEPLOYMENT (Sangat Ringan, Tanpa GUI)
# ==========================================
FROM ros:jazzy-ros-base AS sbc

ENV DEBIAN_FRONTEND=noninteractive

# Update apt dan perbaikan nama package libgeographiclib-dev
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-setuptools \
    ros-jazzy-mavros \
    ros-jazzy-mavros-extras \
    libgeographiclib-dev \
    geographiclib-tools \
    iproute2 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN sudo mkdir -p /usr/share/GeographicLib \
    && sudo geographiclib-get-geoids egm96-5 \
    && sudo geographiclib-get-gravity egm96 \
    && sudo geographiclib-get-magnetic wmm2020

RUN pip3 install --no-cache-dir --break-system-packages future pymavlink dronekit mavproxy numpy pandas

WORKDIR /app
CMD ["bash", "-c", "source /opt/ros/jazzy/setup.bash && ros2 launch mavros apm.launch.py fcu_url:=/dev/ttyACM0:57600"]


# ==========================================
# STAGE 2: LITE DEV (PC Low-End, Menggunakan User Bawaan Image)
# ==========================================
FROM osrf/ros:jazzy-desktop AS lite

ENV DEBIAN_FRONTEND=noninteractive

# Perbaikan nama package libgeographiclib-dev untuk tim PC
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-setuptools \
    python3-colcon-common-extensions \
    git wget nano iproute2 \
    ros-jazzy-mavros \
    ros-jazzy-mavros-extras \
    libgeographiclib-dev \
    geographiclib-tools \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN sudo mkdir -p /usr/share/GeographicLib \
    && sudo geographiclib-get-geoids egm96-5 \
    && sudo geographiclib-get-gravity egm96 \
    && sudo geographiclib-get-magnetic wmm2020

RUN pip3 install --no-cache-dir --break-system-packages future pymavlink dronekit mavproxy numpy pandas

# MODIFIKASI USER: Memanfaatkan user 'ubuntu' (UID/GID 1000) yang sudah ada di base image
# Kita ganti namanya jadi 'pilot' agar sesuai dengan folder workspace-mu
ARG USERNAME=pilot
RUN usermod -l $USERNAME ubuntu \
    && groupmod -n $USERNAME ubuntu \
    && usermod -d /home/$USERNAME -m $USERNAME \
    && usermod -aG sudo,dialout $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME/workspace

# Auto-source ROS2 dan deteksi IP default gateway Windows
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc \
    && echo "export WIN_IP=\$(ip route show default | awk '{print \$3}')" >> ~/.bashrc


# ==========================================
# STAGE 3: FULL DEV (PC High-End + Gazebo Harmonic)
# ==========================================
FROM lite AS full

USER root

# Pasang simulator Gazebo modern (ros-gz) untuk distro Jazzy
RUN apt-get update && apt-get install -y \
    ros-jazzy-ros-gz \
    && rm -rf /var/lib/apt/lists/*

USER $USERNAME

# Env var untuk akselerasi grafis Nvidia & WSLg
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
ENV QT_X11_NO_MITSHM=1
