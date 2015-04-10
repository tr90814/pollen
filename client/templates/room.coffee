Template.room.helpers
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.username

  roomUsers : ->
    UserPresences.find {}, sort : "data.username": 1

  queued : ->
    seedId = Rooms.findOne(Session.get('roomId')).seedId
    Messages.find({userId: seedId}, {limit: 10})

  switchState : ->
    Rooms.findOne(Session.get('roomId')).userId != Session.get("seed")

Template.room.events =
  "click #queue li" : () ->
    Meteor.call "createMessage",
      roomId: Session.get "roomId"
      track: this

  "click .switch-on" : () ->
    Meteor.call "addSeed", Rooms.findOne(Session.get('roomId')).userId
    Session.set("seed", Rooms.findOne(Session.get('roomId')).seedId)

  "click .switch-off" : () ->
    Meteor.call "addSeed", Meteor.userId()
    Session.set "seed", Meteor.userId()
