defmodule StrangerWeb.RegistrationFormComponent do
  use StrangerWeb, :live_component

  def render(assigns) do
    ~L"""
      <div class="form_heading"> Create Profile </div>
      <%= f = form_for @changeset, "#", [phx_change: :validate, phx_submit: :save] %>
        <section class="<%= section_class(@section, 1) %>">
          <div class="form-group">
            <span class="required_field"> * </span>
            <%= label f, :email %>
            <%= email_input f, :email, phx_blur: "validate_email", class: "form-control" %>
            <p><%= error_tag f, :email %></p>
          </div>

          <div class="form-group">
            <span class="required_field"> * </span>
            <%= label f, :password %>
            <%= password_input f, :password, value: input_value(f, :password), class: "form-control" %>
            <p><%= error_tag f, :password %></p>

            <span class="required_field"> * </span>
            <%= label f, :password_confirmation %>
            <%= password_input f, :password_confirmation, value: input_value(f, :password_confirmation), class: "form-control" %>
            <p><%= error_tag f, :password_confirmation %></p>
          </div>
        </section>

        <section class="<%= section_class(@section, 2) %>">
          <p>
            <%= inputs_for f, :profile, fn fp -> %>
              <div class="form-group">
                <span class="required_field"> * </span>
                <%= label fp, :first_name %>
                <%= text_input fp, :first_name, class: "form-control" %>
                <p><%= error_tag fp, :first_name %></p>
              </div>

              <div class="form-group">
                <span class="required_field"> * </span>
                <%= label fp, :last_name %>
                <%= text_input fp, :last_name, class: "form-control" %>
                <p><%= error_tag fp, :last_name %></p>
              </div>

              <div class="form-group">
                <%= label fp, :dob %>
                <%= date_input fp, :dob, value: format_date(fp), class: "form-control" %>
                <p><%= error_tag fp, :dob %></p>
              </div>
            <% end %>
          </p>
        </section>

        <section class="<%= section_class(@section, 3) %>">
          <p>
            <%= inputs_for f, :profile, fn fp -> %>
              <div class="form-group avatar-input">
                <%= if entry = List.last(@uploads.avatar.entries) do %>
                  <%= live_img_preview entry, width: 75 %>
                  <a href="#" phx-click="cancel-upload" phx-value-ref="<%= entry.ref %>">&times</a>
                <% else %>
                  <%= img_tag(StrangerWeb.Router.Helpers.static_path(StrangerWeb.Endpoint, "/images/avatar_placeholder.png"), class: "avatar_img") %>
                <% end %>
              </div>

              <div class="form-group avatar-input">
                <%= live_file_input @uploads.avatar, phx_blur: :on_upload %>
                <p><%= error_tag fp, :avatar %></p>
                <br>
              </div>

              <div class="form-group avatar-input">
                <%= if entry = List.last(@uploads.avatar.entries) do %>
                  Uploaded - <strong><%= entry.progress %>%</strong>
                <% end %>
              </div>

              <div class="form-group">
                <%= label fp, :country %>
                <%= text_input fp, :country, class: "form-control", placeholder: "Where are you from ?" %>
                <p><%= error_tag fp, :country %></p>
              </div>

              <div class="form-group">
                <%= label fp, :bio %>
                <%= textarea fp, :bio, class: "form-control", placeholder: "Write something about yourself. You can mention your hobbies, passion, etc", rows: 5 %>
                <p><%= error_tag fp, :bio %></p>
              </div>

            <% end %>
          </p>
          <p>
            <%= submit "Create Profile !", "phx-disable-with": "Saving...", class: "btn btn-success" %>
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
