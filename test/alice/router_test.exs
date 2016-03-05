defmodule TestHandler do
  use Alice.Router

  # overwrite match for testing purposes
  defp match(routes, :fake_conn), do: send(self, {:received, routes})

  route ~r/pattern/, :my_route
end

defmodule Alice.RouterTest do
  use ExUnit.Case, async: true
  alias Alice.Router

  setup do
    Router.start_link([TestHandler])
    :ok
  end

  test "it remembers routes" do
    assert TestHandler.routes == [{~r/pattern/, :my_route}]
  end

  test "starting the router with an array of handlers registers them immediately" do
    assert Router.handlers == [TestHandler]
  end

  test "you can only register a handler once" do
    Router.register_handler(TestHandler)
    Router.register_handler(TestHandler)
    assert Router.handlers == [TestHandler]
  end

  test "match_routes calls match_routes on each handler" do
    Router.match_routes(:fake_conn)
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
