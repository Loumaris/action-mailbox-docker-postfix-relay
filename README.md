# ruby on rails action mailbox postfix relay with docker

If you want to use [rails action mailbox](https://guides.rubyonrails.org/action_mailbox_basics.html) you need either a smtp-api
like sendgrid or an email service like postfix, qmail or exim.

Configure an email server to use it as relay service and pipe all incoming e-mail to a script is not very easy, that's
why I created the docker image with a basic postfix service. It works pretty good so far.

## how it works

* configure you rails project's action mailbox to use the [relay](https://guides.rubyonrails.org/action_mailbox_basics.html#postfix)
* build this container and run it. (see how to build)
* you need expose port 25 to the docker container
* configure your DNS server to point to the docker container (be careful with changing the mx records!)
* every e-mail which will be send to the domain will be redirected to the deploy user which will call
  a simple shell script and push it to your action mailbox ingress with the relay task.
* in this container is a simple rails api application which is only used to call the rake task `rails action_mailbox:ingress:postfix`

## how to build

You need to pass the domain you want to receive e-mails and your action mailbox url and password to the docker build:

```shell
git clone git@github.com:Loumaris/action-mailbox-docker-postfix-relay.git
cd action-mailbox-docker-postfix-relay
docker build  -t rails/actionrelay \
              --build-arg TLD=example.org
              --build-arg URL=http://example.org/rails/action_mailbox/relay/inbound_emails
              --build-arg INGRESS_PASSWORD=12345 .
```

#### build args

some more details about the build args:

| build arg        | explanation                                               | example                                                          |
|------------------|-----------------------------------------------------------|------------------------------------------------------------------|
| TLD              | your domain you want to send emails, e.g. foo@example.org | TLD=example.org                                                  |
| URL              | the action mailbox ingress url                            | URL=http://example.org/rails/action_mailbox/relay/inbound_emails |
| INGRESS_PASSWORD | the password of your action mailbox                       | INGRESS_PASSWORD=12345                                           |

## support

If you have any questions, feel free to contact me or open an issue.