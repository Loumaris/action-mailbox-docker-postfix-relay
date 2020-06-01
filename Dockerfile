FROM ubuntu:focal

# smtp port
EXPOSE 25

# set build arguments
ARG TLD=example.org
ARG URL=https://example.org/rails/action_mailbox/relay/inbound_emails
ARG INGRESS_PASSWORD=12345abcdef

# some env config
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=C.UTF-8

# add local user for postfix
RUN useradd -m -s /bin/bash deploy

# configure and install postfix with some default values
RUN echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt && \
    echo "postfix postfix/mailname string $TLD" >> preseed.txt && \
    echo $TLD >> /etc/mailname && \
    debconf-set-selections preseed.txt

RUN apt update && \
    apt-get install -q -y postfix nano libsqlite3-dev libxml2-dev ruby ruby-dev build-essential zlib1g-dev && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN echo "$TLD    forward_to_rails:" >> /etc/postfix/transport && \
    echo "@$TLD   deploy@$TLD" >> /etc/postfix/virtual_aliases && \
    chmod 644 /etc/postfix/virtual_aliases /etc/postfix/transport

RUN echo "transport_maps = hash:/etc/postfix/transport" >> /etc/postfix/main.cf && \
    echo "virtual_alias_maps = hash:/etc/postfix/virtual_aliases" >> /etc/postfix/main.cf

RUN echo 'forward_to_rails   unix  -       n       n       -       -       pipe' >> /etc/postfix/master.cf && \
    echo '  flags=Xhq user=deploy:deploy argv=/usr/local/bin/relay.sh' >> /etc/postfix/master.cf && \
    echo '  ${nexthop} ${user}' >> /etc/postfix/master.cf

RUN postmap /etc/postfix/transport && \
    postmap /etc/postfix/virtual_aliases && \
    postconf maillog_file=/dev/stdout

# add relay script and replace placeholder with build args
ADD scripts/relay.sh /usr/local/bin/relay.sh

RUN sed -i "s|_URL_|$URL|g" /usr/local/bin/relay.sh && \
    sed -i "s|_PASSWORD_|$INGRESS_PASSWORD|g" /usr/local/bin/relay.sh && \
    chmod a+x /usr/local/bin/relay.sh

# install rails as api just as relay gateway
RUN echo "gem: --no-document" >  /etc/gemrc && \
    gem install bundler rails --no-document && \
    cd /home/deploy && \
    rails new --api -T -J -G app && \
    chown deploy:deploy -R /home/deploy /usr/local/bin/relay.sh

CMD [ "/usr/sbin/postfix", "-c", "/etc/postfix", "-vv", "start-fg" ]