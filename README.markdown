behaveJS
========

Overview
--------

  behaveJS is a plugin which allows for easily implementing unobtrusive Javascript in a Rails application.
  It provides extensions to standard Rails helpers as well as a Prototype based Javascript library that together
  enable you write Javascript that is reusable, organized, unobtrusive, and efficient. 
  The plugin consists of three main components:

* [Controller](http://wiki.github.com/rightscale/behaveJS/controller "Controller")
* [Behavior](http://wiki.github.com/rightscale/behaveJS/behavior "Behavior")
* [RemoteAction](http://wiki.github.com/rightscale/behaveJS/remoteaction "RemoteAction")
  
How does it work? ( in 20 seconds or less )
-------------------------------------------

  Within your application's layout file, a call to `behaveJS_bootstrap` helper method is placed
  right after all necessary Javascript files. Whenever an action is rendered using this layout, 
  behaveJS automatically creates an instance of a Javascript controller that is analogous to the controller
  used by Rails and invokes the same action. The Javascript controllers are responsible for the configuration
  of various UI components and promote object-oriented client-side code. Behaviors are then computed, taking into 
  account the current controller/action, and are integrated into the UI utilizing event delegation. Below is some 
  sample code utilizing behaveJS Controllers and Behaviors. An example of RemoteActions can be found [here](http://wiki.github.com/rightscale/behaveJS/remoteaction "RemoteAction").

#### Layout: ####
  
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
      <head>
        <title>behaveJS Demo</title>
        <%= javascript_include_tag "prototype" %>
        <%= javascript_include_tag "behaveJS" %>
        <%= javascript_include_tag "behaveJS_application" %>
    
        <%= behaveJS_bootstrap %>
      </head>
    
      <body>
        <div id="header">
          <%= link_to("Feedback", feedback_path, :behaves => { :click => :showDialog, :ready => :somethingElse }) %>
        </div>
        <%= yield %>
      </body>
    </html>
  
#### Rails Action: ####
  
    class ProfilesController < ApplicationContriller  
      def edit
        @profile = current_user.profile
        
        # pass the redirect location into the Javascript
        behaveJS_data[:successRedirect] = profile_path(@profile)
        render :action => "edit"
      end
    end
    
#### Javascript: ####
    
    behaveJS.addBehaviors(
    {
      showDialog : function(event)
      {
        event.stop();
        DialogLib.open(this.href);
      },
      somethingElse : function(event)
      {
        // this function was called as soon as the element became available in the DOM. Do something useful!
        console.log("Element is now ready")
        console.log(this);
      }
    });
  
    behaveJS.createController("Profiles",
    {
      initialize : function($super)
      {
        // this controller is inherited from the Application controller, so we call 
        // the parent constructor
        $super();
      },
      edit : function()
      {
        // called when rendering the "edit" action of the "profiles" controller
        this.uploadWidget = new PhotoUploader($("photos"));
        this.onSuccess    = this.onUploadSuccess.bind(this);
        this.onFailure    = this.onUploadFailure.bind(this);
      },
      onUploadFailure : function()
      {
        alert("Sorry your upload failed! Please try again.");
      },
      onUploadSuccess : function()
      {
        alert("Thanks for your photo!");
        
        // look Ma! I'm not hardcoding URLs in my Javascript!
        window.location.href = behaveJS.settings.successRedirect;
      }
    });

Installing behaveJS
------------------

* Install with `bash > script/plugin install git://github.com/rightscale/behaveJS.git`
* Include the necessary Javascript files in your layout with `<%= javascript_include_tag "behaveJS", "behaveJS_application" %>`. If you are using asset_packager, simply add these two files to your `asset_packages.yml` file. Either way, make sure that they are added after the inclusion of Prototype.
* Place the following method call `<%= behaveJS_bootstrap %>` right after all of your asset includes and you should be good to go!

Requirements
------------

* [Prototype](http://prototypejs.org/ "Prototype") JavaScript framework, version 1.6.0.2 or higher. 
* Rails 2.1.2, 2.2.2, and 2.3.2 are all compatible. Older versions may be as well, but were not tested.
  
What exactly does behaveJS provide again?
-----------------------------------------

* Extensions to Rails helpers that integrate with the behaveJS Javascript framework for unobtrusive functionality
* A full featured library for creating Javascript [Controllers](http://wiki.github.com/rightscale/behaveJS/controller "Controllers"), [Behaviors](http://wiki.github.com/rightscale/behaveJS/behavior "Behaviors"), and [RemoteActions](http://wiki.github.com/rightscale/behaveJS/remoteaction "RemoteActions")
* Ability to easily override how confirmation messages are displayed in your app
* Peace, Love, and Rock n' Roll!

And now a word from our sponsors
--------------------------------
  
  It's always important to know what exactly the plugins you use in your Rails app do, so don't be shy. 
  Pop open Textmate and take a look around the source. It is fairly documented and even has some tests! wooo!