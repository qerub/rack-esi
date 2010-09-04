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
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, ["<p>Hei!</p>"]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_equal_response(mock_app, esi_app)
  end

  def test_respect_for_content_type
    mock_app = lambda { [200, {"Content-Type" => "application/x-y-z"}, ["<esi:include src='/header'/><p>Hei!</p>"]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_equal_response(mock_app, esi_app)
  end

  def test_include
    app = Rack::URLMap.new({
      "/"       => lambda { [200, {"Content-Type" => "text/xml"}, ["<esi:include src='/header'/>, Index"]] },
      "/header" => lambda { [200, {"Content-Type" => "text/xml"}, ["Header"]] }
    })

    esi_app = Rack::ESI.new(app)

    expected_body = ["Header, Index"]

    actual_body = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")[2]

    assert_equal(expected_body, actual_body)
  end

  def test_invalid_include_element_exception
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, ["<esi:include/>"]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_raise Rack::ESI::Error do
      esi_app.call({})
    end
  end

  def test_relative_include
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, ["<esi:include src='tjoho'/>"]] }
    esi_app = Rack::ESI.new(mock_app)

    assert_raise Rack::ESI::Error do
      esi_app.call({})
    end
  end
  
  def test_check_of_status_code
    app = Rack::URLMap.new({
      "/"     => lambda { [200, {"Content-Type" => "text/xml"}, ["<esi:include src='/fail'/>"]] },
      "/fail" => lambda { [500, {"Content-Type" => "text/xml"}, [":-("]] }
    })

    esi_app = Rack::ESI.new(app)

    assert_raise Rack::ESI::Error do
      esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")
    end
  end

  def test_remove
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, ["<p>Hei! <esi:remove>Hei! </esi:remove>Hei!</p>"]] }

    esi_app = Rack::ESI.new(mock_app)

    expected_body = ["<p>Hei! Hei!</p>"]

    actual_body = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")[2]

    assert_equal(expected_body, actual_body)
  end

  def test_comment
    mock_app = lambda { [200, {"Content-Type" => "text/xml"}, ["<p>(<esi:comment text='*'/>)</p>"]] }

    esi_app = Rack::ESI.new(mock_app)

    expected_body = ["<p>()</p>"]

    actual_body = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")[2]

    assert_equal(expected_body, actual_body)
  end

  def test_setting_of_content_length
    mock_app = lambda { [200, {"Content-Type" => "text/html"}, ["Osameli. <esi:comment text='*'/>"]] }

    esi_app = Rack::ESI.new(mock_app)

    response = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/")

    assert_equal("9", response[1]["Content-Length"])
  end

  def test_recursive_inclusions
    app = Rack::URLMap.new({
      "/a" => lambda { [200, {"Content-Type" => "text/xml"}, ["A<esi:include src='/b'/>"]] },
      "/b" => lambda { [200, {"Content-Type" => "text/xml"}, ["B<esi:include src='/c'/>"]] },
      "/c" => lambda { [200, {"Content-Type" => "text/xml"}, ["C"]] }
    })

    esi_app = Rack::ESI.new(app)

    expected_body = ["ABC"]

    actual_body = esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/a")[2]

    assert_equal(expected_body, actual_body)
  end

  def test_check_of_recursion_depth
    app = Rack::URLMap.new({
      "/a" => lambda { [200, {"Content-Type" => "text/xml"}, ["A<esi:include src='/b'/>"]] },
      "/b" => lambda { [200, {"Content-Type" => "text/xml"}, ["B<esi:include src='/a'/>"]] },
    })

    esi_app = Rack::ESI.new(app)

    assert_raise(Rack::ESI::Error) do
      esi_app.call("SCRIPT_NAME" => "", "PATH_INFO" => "/a")[2]
    end
  end

  def assert_equal_response(a, b, env = {})
    x = a.call(env)
    y = b.call(env)

    assert_equal(x, y)
  end
end