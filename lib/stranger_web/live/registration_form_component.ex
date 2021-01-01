defmodule StrangerWeb.RegistrationFormComponent do
  use Phoenix.LiveComponent
  use Phoenix.HTML
  import StrangerWeb.ErrorHelpers
  import StrangerWeb.LiveHelpers

  def render(assigns) do
    ~L"""
      <h2> Section <%= @section %> </h2>
      </form>
        <%= f = form_for @changeset, "#", [phx_change: :validate, phx_submit: :save] %>
        <section class="<%= section_class(@section, 1) %>">
          <p>
            <%= label f, :email %>
            <%= text_input f, :email, ["phx-debounce": "1500"]%>
            <p><%= error_tag f, :email %></p>
          </p>

          <p>
            <%= label f, :password %>
            <%= password_input f, :password, value: input_value(f, :password) %>
            <p><%= error_tag f, :password %></p>
            <%= label f, :password_confirmation %>
            <%= password_input f, :password_confirmation, value: input_value(f, :password_confirmation) %>
            <p><%= error_tag f, :password_confirmation %></p>
          </p>
        </section>

        <section class="<%= section_class(@section, 2) %>">
          <p>
            <%= inputs_for f, :profile, fn fp -> %>
              <p>
                <%= label fp, :first_name %>
                <%= text_input fp, :first_name %>
                <p><%= error_tag fp, :first_name %></p>
              </p>

              <p>
                <%= label fp, :last_name %>
                <%= text_input fp, :last_name %>
                <p><%= error_tag fp, :last_name %></p>
              </p>
            <% end %>
          </p>
          <p>
            <%= submit "Save", "phx-disable-with": "Saving...", class: "btn btn-primary" %>
          </p>
        </section>
      </form>
    """
  end
end
