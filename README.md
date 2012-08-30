fluent-plugin-nats
==================

NATS plugin for fluent Event Collector

[![Build Status](https://secure.travis-ci.org/achied/fluent-plugin-nats.png)](http://travis-ci.org/achied/fluent-plugin-nats)


# Getting Started
Setup the NATS input:

~~~~~
  <source>
    type nats
    host localhost
    port 4222
    user nats
    password nats
    queue fluent.>
  </source>
~~~~~
