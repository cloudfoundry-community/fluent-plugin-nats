fluent-plugin-nats
==================

[NATS](https://github.com/derekcollison/nats) plugin for
[fluentd](https://github.com/fluent/fluentd) Event Collector

[![Build Status](https://secure.travis-ci.org/achied/fluent-plugin-nats.png)](http://travis-ci.org/achied/fluent-plugin-nats)


# Getting Started
Setup the NATS input:

~~~~~
  <source>
    type nats
    tag nats
    host localhost
    port 4222
    user nats
    password nats
    queue fluent.>,fluent2.>
    ssl false
  </source>
~~~~~

Setup the match output:

~~~~
  <match nats.fluent.**>
    type stdout
  </match>
~~~~

# Suitable Queues

## Components
* dea.>
* cloudcontrollers.>
* router.>
* cloudcontroller.>
* vcap.>
* droplet.>
* healthmanager.>

## Services
* FilesystemaaS.>
* AtmosaaS.>
* MongoaaS.>
* MyaaS.>
* Neo4jaaS.>
* AuaaS.>
* RMQaaS.>
* RaaS.>
