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

# Install basic dependencies
RUN apt-get update
RUN apt install -y curl git unzip wget tzdata

COPY container_startup.sh /opt/
COPY x11vnc_entrypoint.sh /opt/
RUN mkdir -p /opt/startup_scripts
COPY startup.sh /opt/startup_scripts/


## Install Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt install -y ./google-chrome-stable_current_amd64.deb

## Install required libraries for RobotJS
RUN apt-get install -y xvfb libxtst-dev libpng++-dev python-pip make build-essential manpages-dev

## Node
RUN npm install -g node-gyp
RUN node-gyp rebuild

## Puppeteer libraries
RUN apt install -y gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget

# finalise
RUN apt-get update \
	&& apt-get clean -y \
	&& chmod +x /opt/*.sh \
	&& chmod +x /opt/startup_scripts/*.sh 
	 
# Add menu entries to the container
VOLUME ["/config"]

ENTRYPOINT ["/opt/container_startup.sh"]