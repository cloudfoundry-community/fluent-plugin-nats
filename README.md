fluent-plugin-nats
==================

[NATS](https://github.com/derekcollison/nats) plugin for
[fluentd](https://github.com/fluent/fluentd) Event Collector

[![Build Status](https://secure.travis-ci.org/achied/fluent-plugin-nats.png)](http://travis-ci.org/achied/fluent-plugin-nats)

## Requirements

| fluent-plugin-nats | Fluentd     | Ruby   |
|--------------------|-------------|--------|
| >= 1.0.0           | >= v0.14.20 | >= 2.1 |
| < 1.0.0            | >= v0.12.0  | >= 1.9 |

# Getting Started
Setup the NATS input:

~~~~~
  <source>
    @type nats
    tag nats
    host localhost
    port 4222
    user nats
    password nats
    queues fluent.>,fluent2.>
    ssl false
  </source>
~~~~~

Setup the match output:

~~~~
  <match nats.fluent.**>
    @type stdout
  </match>
~~~~

# Configuration

## Plugin helpers

* thread

* See also: Fluent::Plugin::Input

## Fluent::Plugin::NATSInput

* **host** (string) (optional): NATS server hostname
  * Default value: `localhost`.
* **user** (string) (optional): Username for authorized connection
  * Default value: `nats`.
* **password** (string) (optional): Password for authorized connection
  * Default value: `nats`.
* **port** (integer) (optional): NATS server port
  * Default value: `4222`.
* **queues** (array) (optional): Subscribing queue names
  * Default value: `["fluent.>"]`.
* **queue** (string) (optional):
  * Default value: `fluent.>`.
  * Obsoleted: Use `queues` instead
* **tag** (string) (optional): The tag prepend before queue name
  * Default value: `nats`.
* **ssl** (bool) (optional): Enable secure SSL/TLS connection
* **max_reconnect_attempts** (integer) (optional): The max number of reconnect tries
  * Default value: `150`.
* **reconnect_time_wait** (integer) (optional): The number of seconds to wait between reconnect tries
  * Default value: `2`.

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
