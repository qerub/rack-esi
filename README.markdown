[ESI]: http://www.w3.org/TR/esi-lang
[Rack::Cache]: http://tomayko.com/src/rack-cache/

# Rack::ESI

Rack::ESI is an implementation of a small (but still very useful!) subset of [ESI][] (Edge Side Includes). ESI tackles the problem of caching dynamic web content by recognizing that some content parts are static (at least for a while) and thereby cachable. Rack::ESI's primary raison d'être is to act as a substitue for real ESI processors during application development to keep your software setup simple. However, it can also be used standalone in production together with [Ryan Tomayko's Rack::Cache][Rack::Cache] to enable caching without leaving the rosy world of Ruby.

## Currently Supported Expressions

* `<esi:include src="/..."/>` where `src` is an absolute path to be handled by the Rack application.
* `<esi:remove>...</esi:remove>`
* `<esi:comment text="..."/>`

## Examples

    rackup examples/basic_example_application.ru

With [Rack::Cache][]:

    rackup examples/basic_example_application_with_caching.ru
