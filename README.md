fluent-plugin-nats
==================

NATS plugin for fluent Event Collector

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
