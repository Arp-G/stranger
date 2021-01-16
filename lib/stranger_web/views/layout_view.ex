defmodule StrangerWeb.LayoutView do
  use StrangerWeb, :view

  def active_class(conn, path) do
    current_path = address_format(conn.request_path)
    link_path = address_format(path)
    IO.inspect("#{current_path}    #{link_path}")
    if current_path == link_path, do: 'active-nav', else: ''
  end

  defp address_format(path) do
    path
    |> String.split("/")
    |> Enum.at(1)
  end
end
