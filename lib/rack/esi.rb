require "rack"
require "hpricot"

class Rack::ESI
  class Error < ::RuntimeError
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, enumerable_body = original_response = @app.call(env)

    return original_response unless headers["Content-Type"].to_s.match(/(ht|x)ml/) # FIXME: Use another pattern

    body = join_body(enumerable_body)

    return original_response unless body.include?("<esi:")

    xml = Hpricot.XML(body)

    xml.search("esi:include") do |include_element|
      raise(Error, "esi:include without @src") unless include_element["src"]
      raise(Error, "esi:include[@src] must be absolute") unless include_element["src"][0] == ?/

      # FIXME: Check the status of @app.call
      
      src = include_element["src"]
      
      include_env = env.merge({
        "PATH_INFO"      => src,
        "QUERY_STRING"   => "",
        "REQUEST_METHOD" => "GET",
        "REQUEST_PATH"   => src,
        "REQUEST_URI"    => src,
        "SCRIPT_NAME"    => ""
      })
      
      data = join_body(@app.call(inclusion_env)[2])
      new_element = Hpricot::Text.new(data)
      include_element.parent.replace_child(include_element, new_element)
    end

    xml.search("esi:remove").remove

    xml.search("esi:comment").remove

    processed_body = xml.to_s
    processed_headers = headers.merge("Content-Length" => processed_body.size.to_s)

    [status, processed_headers, [processed_body]]
  end

  private

  def join_body(enumerable_body)
    parts = []
    enumerable_body.each { |part| parts << part }
    return parts.join("")
  end
end
