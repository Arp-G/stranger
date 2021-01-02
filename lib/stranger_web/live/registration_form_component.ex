defmodule StrangerWeb.RegistrationFormComponent do
  use Phoenix.LiveComponent
  use Phoenix.HTML
  import StrangerWeb.ErrorHelpers
  import StrangerWeb.LiveHelpers

  def render(assigns) do
    ~L"""
      <%= if entry = List.last(@uploads.avatar.entries) do %>
        <%= live_img_preview entry, width: 75 %>
        <a href="#" phx-click="cancel-upload" phx-value-ref="<%= entry.ref %>">&times</a>
      <% end %>
      <%= f = form_for @changeset, "#", [phx_change: :validate, phx_submit: :save] %>
        <section class="<%= section_class(@section, 1) %>">
          <p>
            <%= label f, :email %>
            <%= email_input f, :email, ["phx-debounce": "1500"]%>
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
                <%= live_file_input @uploads.avatar, phx_blur: :on_upload %>
                <br>
                <%= if entry = List.last(@uploads.avatar.entries) do %>
                  Uploaded - <strong><%= entry.progress %>%</strong>
                <% end %>
              </p>
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

              <p>
                <%= label fp, :dob %>
                <%= date_input fp, :dob, value: date_time_to_date(fp.params["dob"]) %>
                <p><%= error_tag fp, :dob %></p>
              </p>

              <p>
                <%= label fp, :bio %>
                <%= textarea fp, :bio %>
                <p><%= error_tag fp, :bio %></p>
              </p>

            <% end %>
          </p>
          <p>
            <%= submit "Save", "phx-disable-with": "Saving...", class: "btn btn-primary" %>
          </p>
        </section>
      </form>
      <p>
      <a href="#" phx-click="jump_to_0">
        Already have an Account? Sign in here.
      </a>
    </p>
    """
  end
end
