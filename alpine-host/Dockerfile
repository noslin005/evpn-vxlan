FROM alpine:latest

RUN apk update && \
    apk add --no-cache \
    libteam \
    open-lldp \
    iputils \
    iproute2 \
    bind-tools \
    tcpdump \
    curl \
    wget \
    netcat-openbsd \
    bash \
    scapy \
    iperf3 \
    sudo

RUN adduser -u 1000 -G wheel -D alpine && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY entrypoint.sh /home/alpine/
RUN chmod +x /home/alpine/entrypoint.sh

USER alpine 

ENTRYPOINT ["/home/alpine/entrypoint.sh"]

CMD []
