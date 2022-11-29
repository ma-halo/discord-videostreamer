FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC
# Install dependencies
RUN apt-get update
RUN apt-get install -y curl git unzip wget
RUN apt-get -y install tzdata
RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash -
RUN apt-get install -y nodejs
RUN npm i -g yarn

# for the VNC connection
EXPOSE 5900
# for the browser VNC client
EXPOSE 5901
# Use environment variables
ENV VNC_PASSWD=123456

# Make sure the dependencies are met
RUN apt-get update \
	&& apt install -y tigervnc-standalone-server fluxbox nginx xterm git net-tools python python-numpy scrot wget software-properties-common vlc avahi-daemon unzip \
	&& sed -i 's/geteuid/getppid/' /usr/bin/vlc \
	&& add-apt-repository ppa:obsproject/obs-studio

RUN git clone --branch v1.3.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC \
	&& git clone --branch v0.10.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
	&& ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Install chrome 88
RUN wget http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_88.0.4324.96-1_amd64.deb
RUN apt-get install -y ./google-chrome-stable_88.0.4324.96-1_amd64.deb

# Install chromedriver 88
RUN wget https://chromedriver.storage.googleapis.com/88.0.4324.27/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip
RUN mv chromedriver /bin

# Copy various files to their respective places
RUN wget -q -O /opt/container_startup.sh https://raw.githubusercontent.com/injnius/discord-videostreamer/main/container_startup.sh
RUN wget -q -O /opt/x11vnc_entrypoint.sh https://raw.githubusercontent.com/injnius/obs-teleport-docker/master/x11vnc_entrypoint.sh
RUN mkdir -p /opt/startup_scripts
RUN wget -q -O /opt/startup_scripts/startup.sh https://raw.githubusercontent.com/injnius/obs-teleport-docker/master/startup.sh
# Update apt for the new obs repository
RUN apt-get update \
	&& mkdir -p /config/obs-studio /root/.config/ \
	&& ln -s /config/obs-studio/ /root/.config/obs-studio \
	&& apt install -y ffmpeg obs-studio \
	&& apt-get clean -y \
# Download and install the plugins for NDI
    && wget -q -O /tmp/obs-teleport.zip https://github.com/fzwoch/obs-teleport/releases/download/0.6.1/obs-teleport.zip \
	&& unzip -qo /tmp/obs-teleport.zip -d /tmp/obs-teleport \
    && wget -q -O /tmp/gh-pages.zip https://github.com/Niek/obs-web/archive/gh-pages.zip \
    && unzip -qo /tmp/gh-pages.zip -d /tmp/gh-pages \
    && rm -rf /var/www/* \
    && cp -r /tmp/gh-pages/obs-web-gh-pages/* /var/www/ \
    && mkdir -p /root/.config/obs-studio/plugins/obs-teleport/bin/64bit \
    && cp /tmp/obs-teleport/linux-x86_64/obs-teleport.so /root/.config/obs-studio/plugins/obs-teleport/bin/64bit/obs-teleport.so \
	&& rm -rf /tmp/obs-teleport \
	&& rm -rf /var/lib/apt/lists/* \
	&& chmod +x /opt/*.sh \
	&& chmod +x /opt/startup_scripts/*.sh 
	 
# Add menu entries to the container
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]