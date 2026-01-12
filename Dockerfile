# ============================
# Stage: base image
# ============================
# syntax=docker/dockerfile:1
ARG PCL_VERSION=${PCL_VERSION}
ARG OPENCV_VERSION=${OPENCV_VERSION}
FROM nvidia/cuda:13.0.2-base-ubuntu24.04 AS base-image
RUN apt-get update && apt-get install -y  --no-install-recommends \
    build-essential \ 
    cmake \
    curl \
    g++ \
    libatlas-base-dev \
    libavutil-dev \
    libboost-all-dev \
    libeigen3-dev \
    libflann-dev \
    libgstreamer-plugins-base1.0-dev \
    libgtk3.0-cil-dev \
    libnanoflann-dev \
    libqt5opengl5-dev \
    libopenni-dev \
    libopenni2-dev \
    libusb-1.0-0-dev \
    libvtk9-dev \
    libvtk9-qt-dev \
    libqhull-dev \
    make \
    sudo \
    unzip \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*



# ============================
# Stage: pcl build
# ============================
# Download point cloud library source code once
FROM base-image AS pcl-build
ARG PCL_VERSION
RUN cd /tmp && wget https://github.com/PointCloudLibrary/pcl/archive/pcl-${PCL_VERSION}.tar.gz \
    && tar -xf pcl-${PCL_VERSION}.tar.gz

# PCL build modules (be aware that some modules depend from another ones)
ENV BUILD_MODULES   -DBUILD_2d=ON \
                    -DBUILD_CUDA=OFF \
                    -DBUILD_GPU=ON \
                    -DBUILD_apps=OFF \
                    -DBUILD_benchmarks=OFF \
                    -DBUILD_common=ON \
                    -DBUILD_examples=OFF \
                    -DBUILD_features=ON \
                    -DBUILD_filters=ON \
                    -DBUILD_geometry=ON \
                    -DBUILD_global_tests=OFF \
                    -DBUILD_io=ON \
                    -DBUILD_kdtree=ON \
                    -DBUILD_keypoints=ON \
                    -DBUILD_ml=ON \
                    -DBUILD_octree=ON \
                    -DBUILD_outofcore=ON \
                    -DBUILD_people=ON \
                    -DBUILD_recognition=OFF \
                    -DBUILD_registration=ON \
                    -DBUILD_sample_consensus=ON \
                    -DBUILD_search=ON \
                    -DBUILD_segmentation=ON \
                    -DBUILD_simulation=OFF \
                    -DBUILD_stereo=ON \
                    -DBUILD_surface=ON \
                    -DBUILD_surface_on_nurbs=OFF \
                    -DBUILD_tools=ON \
                    -DBUILD_tracking=ON \
                    -DBUILD_visualization=ON

# Install pcl at /usr
ENV CMAKE_CONFIG -DCMAKE_INSTALL_PREFIX:PATH=/tmp/pcl-pcl-${PCL_VERSION}/install/ \
                 -DCMAKE_BUILD_TYPE=Release

# Set flags support
ENV WITH_CONFIG -DWITH_CUDA=OFF \
                -DWITH_DAVIDSDK=OFF \
                -DWITH_DOCS=OFF \
                -DWITH_DSSDK=OFF \
                -DWITH_ENSENSO=OFF \
                -DWITH_LIBUSB=ON \
                -DWITH_OPENGL=ON \
                -DWITH_OPENMP=ON \
                -DWITH_OPENNI=ON \
                -DWITH_OPENNI2=ON \
                -DWITH_PCAP=OFF \
                -DWITH_PNG=OFF \
                -DWITH_QHULL=ON \
                -DWITH_RSSDK=OFF \
                -DWITH_RSSDK2=OFF \
                -DWITH_VTK=ON
# # Set vtk backend rendering
ARG VTK_CONFIG -DVTK_RENDERING_BACKEND=OpenGL2

# Compile pcl
RUN cd /tmp/pcl-pcl-${PCL_VERSION} \
    && mkdir build install && cd build \
    && cmake ${BUILD_MODULES} ${CMAKE_CONFIG} ${WITH_CONFIG} ../ \
    && make -j$(nproc) \
    && make install

# Unset ENV variables
ENV BUILD_MODULES=
ENV CMAKE_CONFIG=
ENV WITH_CONFIG=

# ============================
# Stage: opencv build
# ============================


FROM base-image AS opencv-build

ARG OPENCV_VERSION
ENV BUILD_MODULES   -DENABLE_FAST_MATH=ON \
                    -DOPENCV_ENABLE_NONFREE=ON \
                    -DOPENCV_GENERATE_PKGCONFIG=ON 

ENV CMAKE_CONFIG    -DCMAKE_BUILD_TYPE=RELEASE \
                    -DCMAKE_INSTALL_PREFIX=/tmp/opencv-${OPENCV_VERSION}/install \
                    -DOPENCV_EXTRA_MODULES_PATH=/tmp/opencv_contrib-${OPENCV_VERSION}/modules 

ENV WITH_CONFIG     -DWITH_OPENGL=ON \
                    -DWITH_QT=ON \
                    -DWITH_OPENNI=ON \
                    -DWITH_OPENNI2=ON \
                    -DWITH_QT=ON

RUN cd /tmp && \
wget -O opencv.zip https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.zip && \
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/refs/tags/${OPENCV_VERSION}.zip && \
unzip opencv.zip && \
unzip opencv_contrib.zip && \
cd /tmp/opencv-${OPENCV_VERSION} && \
mkdir build && \
cd build && \
cmake ${BUILD_MODULES} ${CMAKE_CONFIG} ${WITH_CONFIG} .. && \
make -j$(nproc) && \
make install

# ============================
# Stage: runtime
# ============================
FROM base-image as runtime
ARG PCL_VERSION
ARG OPENCV_VERSION
COPY --from=pcl-build /tmp/pcl-pcl-${PCL_VERSION}/install /usr
COPY --from=opencv-build /tmp/opencv-${OPENCV_VERSION}/install /usr

# Install additional container tools
RUN apt-get update && apt-get install -y  --no-install-recommends \
    python3-pip \
    python3-numpy \
    python3-scipy \
    python3-matplotlib \
    && rm -rf /var/lib/apt/lists/*

# Repository and container related environment variables
ARG CONTAINER_HOME
ENV CONTAINER_HOME=$CONTAINER_HOME


# Setup the User
ARG CONTAINER_USER USER_ID GROUP_ID
ENV CONTAINER_USER=$CONTAINER_USER
ENV USER_ID=$USER_ID
ENV GROUP_ID=$GROUP_ID
RUN useradd -m "${CONTAINER_USER}" && \
    echo "${CONTAINER_USER}:${CONTAINER_USER}" | chpasswd && \
    usermod --shell /bin/bash ${CONTAINER_USER} && \
    usermod -aG sudo ${CONTAINER_USER} && \
    mkdir -p /etc/sudoers.d

RUN echo "${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${CONTAINER_USER} && \
    chmod 0440 /etc/sudoers.d/${CONTAINER_USER} && \
    deluser --remove-home ubuntu&& \
    usermod  --uid ${USER_ID} ${CONTAINER_USER} && \
    groupmod --gid ${GROUP_ID} ${CONTAINER_USER}

USER ${CONTAINER_USER}
# Set and create XDG_RUNTIME_DIR
ENV XDG_RUNTIME_DIR=/tmp/runtime-${CONTAINER_USER}
RUN mkdir -p ${XDG_RUNTIME_DIR}
# Starting params
WORKDIR ${CONTAINER_HOME}
CMD /bin/bash