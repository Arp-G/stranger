defmodule StrangerWeb.LoginFormComponent do
  use Phoenix.LiveComponent
  use Phoenix.HTML

  @impl true
  def mount(socket) do
    {:ok, assign(socket, %{email: "", password: ""})}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <section>
      <p>
        <label for="email">Email</label>
        <input id="email" name="email" type="email" phx-blur="update_email" phx-target="<%= @myself %>">
      </p>

      <p>
        <label for="password">Password</label>
        <input id="password" name="password" type="password" phx-blur="update_password" phx-target="<%= @myself %>">
      </p>

      <p>
        <button class="btn btn-primary" phx-click="sign_in" phx-target="<%= @myself %>">Sign in</button>
      </p>
      <p>
        <a href="#" phx-click="jump_to_1">
          Don't have an Account? Sign Up here.
        </a>
      </p>
    </section>
    """
  end

  @impl true
  def handle_event("update_email", %{"value" => email}, socket) do
    {:noreply, assign(socket, email: email)}
  end

  @impl true
  def handle_event("update_password", %{"value" => password}, socket) do
    {:noreply, assign(socket, password: password)}
  end

  @impl true
  def handle_event("sign_in", _attrs, %{assigns: %{email: email, password: password}} = socket) do
    # StrangerWeb.Router.Helpers.session_path

    {
      :noreply,
      redirect(socket,
        to: StrangerWeb.Router.Helpers.session_path(socket, :sign_in, %{email: email, password: password})
      )
    }
  end
end
