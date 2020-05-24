FROM debian:latest

ARG user=${user:-docker}
ARG password=${password:-docker}
ARG lang_short=${lang_short:-de}
ARG lang=${lang:-de_DE:de}
ARG lang_ext=${lang_ext:-de_DE.UTF-8}
# English (US) = standard
ARG variant=${variant:-"German (US keyboard with German letters)"}
# UTC = standard
ARG timezone=${timezone:-"Europe/Berlin"}

ENV DEBIAN_FRONTEND noninteractive
ENV USER ${user}
ENV LANG ${lang_ext}
ENV LANGUAGE ${lang_ext}
ENV LC_ALL "de_DE.UTF-8"
ENV LC_CTYPE "de_DE.UTF-8"

RUN apt-get update -y && apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y locales expect debconf sudo bash openssh-server \
	&& sed -e 's/# en_US.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' -i /etc/locale.gen \
	&& locale-gen de_DE de_DE.UTF-8 && locale > /etc/default/locale \
	&& dpkg-reconfigure locales \
	&& echo "keyboard-configuration keyboard-configuration/modelcode \
		string pc105\nkeyboard-configuration keyboard-configuration/layoutcode \
		string ${lang_short}\nkeyboard-configuration keyboard-configuration/variant \
		string ${variant}\n" | debconf-set-selections \
	&& apt-get install -y xrdp \
	&& sed -e 's/%sudo\(.*\)ALL$/%sudo\1NOPASSWD:ALL/g' -i /etc/sudoers \
	&& useradd -m ${user} -s /bin/bash \
	&& adduser ${user} ssl-cert \
	&& echo ${user}':'${password} | chpasswd \
	&& mkdir -p /var/run/sshd && mkdir xrdp && cd xrdp && rm -rf xrdp && cd /etc/xrdp \
	&& echo "[console]\nname=console\nlib=libvnc.so\n" >> xrdp.ini \
	&& sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
	&& ln -fs /usr/share/zoneinfo/${timezone} /etc/localtime \
	&& dpkg-reconfigure -f noninteractive tzdata

RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections \
	&& apt-get install -y task-mate-desktop \
	&& rm -rf /var/lib/apt/lists/* # clean up the apt install pagackes

EXPOSE 3389 22

CMD service rsyslog start \
	&& service ssh start \
	&& service xrdp start \
	&& tail -f /var/log/syslog