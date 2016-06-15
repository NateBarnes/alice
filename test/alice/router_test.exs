defmodule TestHandler do
  use Alice.Router

  # overwrite match for testing purposes
  defp match(routes, %Alice.Conn{}), do: send(self, {:received, routes})

  route ~r/pattern/, :my_route
end

defmodule Alice.RouterTest do
  use ExUnit.Case, async: true
  alias Alice.Router
  alias Alice.Conn

  setup do
    handlers = Application.get_env(:alice, :handlers, [])
    Application.put_env(:alice, :handlers, [TestHandler])
    on_exit(fn -> Application.put_env(:alice, :handlers, handlers) end)
    Router.start_link
    :ok
  end

  test "it remembers routes" do
    assert TestHandler.routes == [{~r/pattern/, :my_route}]
  end

  test "configuring the app with an array of handlers registers the handlers" do
    assert Router.handlers == [TestHandler]
  end

  test "you can only register a handler once" do
    Router.register_handler(TestHandler)
    Router.register_handler(TestHandler)
    assert Router.handlers == [TestHandler]
  end

  test "match_routes calls match_routes on each handler" do
    {:message, :slack, :state}
    |> Conn.make
    |> Router.match_routes
    assert_received {:received, [{~r/pattern/, :my_route}]}
  end

  test "it can put state" do
    conn = Alice.Conn.make(:msg, :slk)
    conn = TestHandler.put_state(conn, :key, :val)
    assert conn.state == %{{TestHandler, :key} => :val}
  end

  test "it can get state" do
    conn = Alice.Conn.make(:msg, :slk, %{{TestHandler, :key} => :val})
    assert :val == TestHandler.get_state(conn, :key)
  end
end
