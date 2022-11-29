FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC

# for the VNC connection
EXPOSE 5900
# for the browser VNC client
EXPOSE 5901
# Use environment variables
ENV VNC_PASSWD=123456

# Set working directory
RUN mkdir -p /opt/startup_scripts
RUN mkdir -p /config_data
WORKDIR /config_data

# Install dependencies
RUN apt-get update
RUN apt-get install -y curl git unzip wget tzdata
RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash -
RUN apt-get install -y nodejs
RUN npm i -g yarn discord.js@^11.6.4 puppeteer@^8.0.0

RUN apt install -y tigervnc-standalone-server fluxbox nginx xterm git net-tools python python-numpy scrot wget software-properties-common vlc avahi-daemon unzip

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
RUN wget -q -O /opt/x11vnc_entrypoint.sh https://raw.githubusercontent.com/injnius/discord-videostreamer/main/x11vnc_entrypoint.sh
RUN mkdir -p /opt/startup_scripts
RUN wget -q -O /opt/startup_scripts/startup.sh https://raw.githubusercontent.com/injnius/discord-videostreamer/main/startup.sh
# Update apt for the new obs repository
RUN apt-get update \
	&& apt-get clean -y \
	&& chmod +x /opt/*.sh \
	&& chmod +x /opt/startup_scripts/*.sh 
	 
# Add menu entries to the container
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]