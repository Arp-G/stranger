defmodule StrangerWeb.DashboardLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML

  @impl true
  def mount(params, session, socket) do
    {:ok, socket}
  end
end

# p = "live_view_upload-1609522426-906582229084086-5"
# Avatar.url({user.profile.avatar, user}, signed: true)
