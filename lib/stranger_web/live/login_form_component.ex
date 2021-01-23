defmodule StrangerWeb.LoginFormComponent do
  use StrangerWeb, :live_component
  use Phoenix.HTML

  @impl true
  def mount(socket) do
    {:ok, assign(socket, %{email: "", password: ""})}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="form-heading"> Login </div>
    <section class="login-section">
      <div class="form-group">
        <label for="email">Email</label>
        <input id="email" name="email" type="email" phx-blur="update_email" phx-target="<%= @myself %>" class="form-control">
      </div>

      <div class="form-group">
        <label for="password">Password</label>
        <input id="password" name="password" type="password" phx-blur="update_password" phx-target="<%= @myself %>" class="form-control">
      </div>

      <div class="form-group">
        <button class="btn btn-success" phx-click="sign_in" phx-target="<%= @myself %>">Sign in</button>
      <div>

      <div class="form-group form-link">
        <a href="#" phx-click="jump_to_1">
          Don't have an Account? Sign Up here.
        </a>
      </div>
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
    {
      :noreply,
      redirect(socket,
        to:
          StrangerWeb.Router.Helpers.session_path(
            socket,
            :sign_in,
            %{email: email, password: password}
          )
      )
    }
  end
end
