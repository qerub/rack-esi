require "pathname"

$LOAD_PATH.unshift(Pathname(__FILE__).expand_path.dirname)
$LOAD_PATH.unshift(Pathname(__FILE__).expand_path.dirname.parent.join("lib"))

require "test/unit"
require "rack/esi"

class TestRackESI < Test::Unit::TestCase
  def test_response_passthrough
    mock_app = lambda { [200, {}, ["Hei!"]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_equal_response(mock_app, esi_app)
  end

  def test_xml_response_passthrough
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, [html("<p>Hei!</p>")]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_equal_response(mock_app, esi_app)
  end

  def test_respect_for_content_type
    mock_app = lambda { [200, {"Content-Type" => "application/x-y-z"}, [html_esi("<esi:include src='/header'/><p>Hei!</p>")]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_equal_response(mock_app, esi_app)
  end

  def test_include
    app = Rack::URLMap.new({
      "/"       => lambda { [200, {"Content-Type" => "text/xml"}, [html_esi("<esi:include src='/header'/> Index")]] },
      "/header" => lambda { [200, {"Content-Type" => "text/xml"}, ["<div>Header</div>"]] }
    })

    esi_app = Rack::ESI.new(app)

    expected_body = [html("<div>Header</div> Index")]

    actual_body = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")[2]

    assert_equal_mod_whitespace(expected_body, actual_body)
  end

  def test_invalid_include_element_exception
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, [html_esi("<esi:include/>")]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_raise Rack::ESI::Error do
      esi_app.call({})
    end
  end

  def test_relative_include
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, [html_esi("<esi:include src='tjoho'/>")]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_raise Rack::ESI::Error do
      esi_app.call({})
    end
  end
  
  def test_check_of_status_code
    app = Rack::URLMap.new({
      "/"     => lambda { [200, {"Content-Type" => "text/xml"}, [html_esi("<esi:include src='/fail'/>")]] },
      "/fail" => lambda { [500, {"Content-Type" => "text/xml"}, [":-("]] }
    })

    esi_app = Rack::ESI.new(app)

    assert_raise Rack::ESI::Error do
      esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")
    end
  end

  def test_remove
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, [html_esi("<p>Hei! <esi:remove>Hei! </esi:remove>Hei!</p>")]] }

    esi_app = Rack::ESI.new(mock_app)

    expected_body = [html("<p>Hei! Hei!</p>")]

    actual_body = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")[2]

    assert_equal_mod_whitespace(expected_body, actual_body)
  end

  def test_comment
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, [html_esi("<p>(<esi:comment text='*'/>)</p>")]] }

    esi_app = Rack::ESI.new(mock_app)

    expected_body = [html("<p>()</p>")]

    actual_body = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")[2]

    assert_equal_mod_whitespace(expected_body, actual_body)
  end

  def test_setting_of_content_length
    mock_app = lambda { [200, {"Content-Type" => "text/html"}, [html_esi("Osameli. <esi:comment text='*'/>")]] }

    esi_app = Rack::ESI.new(mock_app)

    response = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")

    assert_equal("24", response[1]["Content-Length"])
  end

  def assert_equal_response(a, b, env = {})
    x = a.call(env)
    y = b.call(env)

    assert_equal(x, y)
  end
  
  def clean_whitespace(string)
    string.gsub(/\s+/, " ").strip.gsub("> <", "><")
  end
  
  def assert_equal_mod_whitespace(a, b)
    assert_equal(clean_whitespace(a.to_s), clean_whitespace(b.to_s))
  end
  
  def html_esi(string)
    '<html xmlns:esi="http://www.edge-delivery.org/esi/1.0">' + string + '</html>'
  end
  
  def html(string)
    '<html>' + string + '</html>'
  end
end