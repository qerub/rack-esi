require "rack"
require "nokogiri"

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

    xml = Nokogiri.XML(body)
    
    xml.search("//esi:include").each do |include_element|
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
      
      include_status, include_headers, include_body = include_response = @app.call(include_env)
      
      raise(Error, "#{include_element["src"]} request failed (code: #{include_status})") unless include_status == 200
      
      new_element = Nokogiri.XML(join_body(include_body)).root
      include_element.replace(new_element)
    end

    xml.search("//esi:remove").remove

    xml.search("//esi:comment").remove

    processed_body = remove_xml_stuff(xml.to_s)
    
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

  private

  def join_body(enumerable_body)
    parts = []
    enumerable_body.each { |part| parts << part }
    return parts.join("")
  end
  
  def remove_xml_stuff(string)
    string.
      gsub(/\A<\?xml version="1.0"\?>/, "").
      gsub(/ xmlns:esi=(?:"[^"]*"|'[^']*')/, "")
  end
end
