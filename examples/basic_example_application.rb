require "rack"

class BasicExampleApplication
  def initialize
    @map = initialize_map
  end
  
  def call(env)
    @map.call(env)
  end
  
  private
  
  def initialize_map
    Rack::URLMap.new({
      "/"       => method(:index),
      "/header" => method(:header)
    })
  end
  
  def index(env)
    body = %{
      <title>BasicExampleApplication</title>
      <esi:include src="/header"/>
      <p>Welcome!</p>
    }.gsub(/^\s*/, "").strip
    [200, {"Content-Type" => "text/html"}, [body]]
  end
  
  def header(env)
    body = %{<p>#{Time.now} &ndash; You're not logged in. <a href="#">Click here to login!</a></p>}
    [200, {"Content-Type" => "text/html"}, [body]]
  end
end
