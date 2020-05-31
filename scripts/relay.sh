#!/bin/bash -l

export HOME=/home/deploy
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
export URL=_URL_
export INGRESS_PASSWORD=_PASSWORD_

cd /home/deploy/app && bundle exec rails action_mailbox:ingress:postfix