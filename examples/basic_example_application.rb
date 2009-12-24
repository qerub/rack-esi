require "rack"

class BasicExampleApplication
  def call(env)
    request  = Rack::Request.new(env)
    response = Rack::Response.new
    
    if request.path_info == "/"
      action = "index"
    else
      action = request.path_info[1..-1]
    end
    
    if ACTIONS.include?(action)
      send(action, request, response)
    else
      response.status = 404
      response.write("404 Not Found")
    end
    
    response.finish
  end

  private
  
  ACTIONS = %<index header login logout>

  def index(request, response)
    sleep(2) # A heavy computation...

    response.status = 200
    response["Cache-Control"] = "public, max-age=10"
    response.write(%{
      <title>BasicExampleApplication</title>
      <esi:include src="/header"/>
      <p>Welcome!</p>
    }.gsub(/^\s*/, "").strip)
  end

  def header(request, response)
    response.status = 200
    response["Cache-Control"] = "private, max-age=0, must-revalidate"

    if request.cookies["logged_in"].to_s == "true"
      username = request.cookies["username"]
      response.write(%{<p>You're logged in as #{username}. <a href="/logout">Log out.</a></p>})
    else
      response.write(%{<p>You're not logged in. <a href="/login">Click here to log in!</a></p>})
    end
  end
  
  def login(request, response)
    response.set_cookie("logged_in", "true")
    response.set_cookie("username", "John Doe")
    response.redirect("/")
  end

  def logout(request, response)
    response.delete_cookie("logged_in")
    response.delete_cookie("username")
    response.redirect("/")
  end
end
