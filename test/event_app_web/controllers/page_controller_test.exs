defmodule EventAppWeb.PageControllerTest do
  use EventAppWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Event feed"
  end
end
