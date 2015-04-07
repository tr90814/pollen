Template.room.helpers
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.username

  roomUsers : ->
    UserPresences.find {}, sort : "data.username": 1

  queued : ->
    Messages.find({userId: Session.get "roomUserId"}, {limit: 10})

  switchState : ->
    Rooms.findOne(Session.get('roomId')).userId != Session.get("seed")

Template.room.events =
  "click #queue li" : () ->
    Meteor.call "createMessage",
      roomId: Session.get "roomId"
      track: this

  "click .switch-on" : () ->
    Session.set("seed", Rooms.findOne(Session.get('roomId')).userId)

  "click .switch-off" : () ->
    Session.set("seed", Meteor.userId())
