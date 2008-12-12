[ESI]: http://www.w3.org/TR/esi-lang
[Rack::Cache]: http://tomayko.com/src/rack-cache/

TODO: Improve this text.

# Rack::ESI

Rack::ESI is an implementation of a small (but still very useful!) subset of [ESI][]. It allows you to _easily_ cache everything but the user-customized parts of your dynamic pages when used together with [Ryan Tomayko's Rack::Cache][Rack::Cache].

Development of Rails::ESI has just begun and it is not yet ready for anything but exploration.

## Examples

    rackup -p 8080 examples/basic_example_application.ru

With [Rack::Cache][]:

    rackup -p 8080 examples/basic_example_application_with_caching.ru
    
## TODO/FIXME

`grep`/`ack` for TODOs and FIXMEs.
