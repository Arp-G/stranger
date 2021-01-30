
<p align="center">
  <img src="./logo.svg" height="100" alt="Stranger image"/>
</p>

# Stranger

[**Stranger**](https://strangerz.herokuapp.com/) allows you connect with random people around the world.

Connect with either video or text chat and make new friends.

[Try Strangers now](https://strangerz.herokuapp.com/)

## A Demo of the app
<img src="https://raw.githubusercontent.com/Arp-G/stranger/master/demo/stranger_demo.gif" alt="Stranger image"/>

## Technology Stack used

* [Phoenix Live View](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) for rich, real-time user experiences
* [MongoDB](https://www.mongodb.com) as database
* [Vonage Video](https://www.vonage.com/communications-apis/video) for interactive live video calls
* [Bootstrap ](https://getbootstrap.com/) for styling

## Some Interesting stuff that I have tried in this project

* Create a [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) only app for rich realtime user experience without the need for any page refreshes.
* Some interesting live view features include..
	*  Multi Step forms
	* Server side form validations and [LiveView uploads](https://hexdocs.pm/phoenix_live_view/uploads.html)
	* Infinite scrolling pages
	* [Live Components](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html) and [LiveView hooks](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks)
* Other interesting stuff include...
	* Use phoenix [PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html) for matching users, active user tracking and text chat
	* Use [ecto embedded schemas](https://hexdocs.pm/ecto/Ecto.Schema.html#embedded_schema/1) along with MongoDB to utilize chagesets for powerfull form validations
	* [Genservers](https://hexdocs.pm/elixir/GenServer.html) for user tracking and chat room tracking
	* Some meta programming to achieve DRY code
	* Use [Vonage Video](https://www.vonage.com/communications-apis/video) apis to setup realtime video chat capabilities


## Setup and run locally

* Make sure you have elixir and npm installed
* Clone this project
* Install and run mongoDb either locally or elsewhere
* Create a new secret config file `config/dev.decret.exs` using the sample file provided `config/env.secrets.exs.sample`
* Prepare assets: Install node packages `cd assets && npm install`
* Run the server from project root `mix phx.server` and visit `http://localhost:4000/`
* Enjoy!
