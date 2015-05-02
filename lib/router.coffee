# Configure the base template for the application
Router.configure
  layoutTemplate: "layout"
  notFoundTemplate: "home"
  waitOn: ->
    if Meteor.userId()
      unless Session.get "seedId"
        Session.set "seedId", Meteor.userId()
      Meteor.subscribe "roomMessages", Session.get("seedId")

# Define page routes.
Router.map ->

    @.route "/",
      template : "home"

    @.route "/rooms",
      template : "roomList"
      waitOn : ->
        Meteor.subscribe "searchResults", Meteor.username
        Meteor.subscribe "activeRooms"
      action : ->
        Session.set "roomId", null
        Session.set "roomUserId", null
        @.render()

    @.route "/room/:_id",
      template : "room"
      # Subscribe to the room user list and messages associated with this room id.
      # See, server/publications.coffee for publication setup.
      waitOn : ->
        Meteor.subscribe "allRooms"
        if Session.get "roomUserId"
          Meteor.subscribe "roomMessages", Session.get('roomUserId')

      # When navigating to a room we want to call joinRoom so the server can handle it.
      # Then, we set the session roomId. This will reactivley update user presence data.
      action : ->
          Session.set "userName", Meteor.user().username
          Session.set "roomId", @.params._id
          Session.set "roomUserId", Rooms.findOne(@.params._id).userId
          Meteor.call "createRoom", @.params._id, Meteor.user().username

          @.render()
      # Remove user from the list of users on unload
      unload : ->
        Meteor.call "changeSeed", Meteor.userId()
        Session.set "roomId", null

# When navigating to pages, check that we have a userId. If not, then render home page instead.
Router.onBeforeAction ->
  if not Meteor.userId()
    @.render "home"
  else
    @.next()
