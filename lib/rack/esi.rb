require "rack"
require "hpricot"

class Rack::ESI
  class Error < ::RuntimeError
  end

  def initialize(app, max_depth = 5)
    @app = app
    @max_depth = max_depth.to_i
  end

  def call(env)
    process_request(env)
  end

  private

  def process_request(env, level = 0)
    raise(Error, "Too many levels of ESI processing: level #{level} reached. We were about to request: #{env['REQUEST_URI']} // #{env['PATH_INFO']}") if level > @max_depth

    status, headers, enumerable_body = original_response = @app.call(env.dup)

    return original_response unless headers["Content-Type"].to_s.match(/(ht|x)ml/) # FIXME: Use another pattern

    body = join_body(enumerable_body)

    return original_response unless body.include?("<esi:")

    xml = Hpricot.XML(body)

    xml.search("esi:include") do |include_element|
      raise(Error, "esi:include without @src") unless include_element["src"]
      raise(Error, "esi:include[@src] must be absolute") unless include_element["src"][0] == ?/

      src = include_element["src"]

      # TODO: Test this
      include_env = env.merge({
        "PATH_INFO"      => src,
        "QUERY_STRING"   => "",
        "REQUEST_METHOD" => "GET",
        "SCRIPT_NAME"    => ""
      })
      include_env.delete("HTTP_ACCEPT_ENCODING")
      include_env.delete("REQUEST_PATH")
      include_env.delete("REQUEST_URI")

      include_status, include_headers, include_body = include_response = process_request(include_env, level + 1)

      raise(Error, "#{include_element["src"]} request failed (code: #{include_status})") unless include_status == 200

      new_element = Hpricot::Text.new(join_body(include_body))
      include_element.parent.replace_child(include_element, new_element)
    end

    xml.search("esi:remove").remove

    xml.search("esi:comment").remove

    processed_body = xml.to_s

    # TODO: Test this
    processed_headers = headers.merge({
      "Content-Length" => processed_body.size.to_s,
      "Cache-Control"  => "private, max-age=0, must-revalidate"
    })
    processed_headers.delete("Expires")
    processed_headers.delete("Last-Modified")
    processed_headers.delete("ETag")

    [status, processed_headers, [processed_body]]
  end

  def join_body(enumerable_body)
    parts = []
    enumerable_body.each { |part| parts << part }
    return parts.join("")
  end
end
