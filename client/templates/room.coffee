Template.room.helpers
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.username

  roomUsers : ->
    UserPresences.find {}, sort : "data.username": 1

  queued : ->
    if Session.get 'roomId'
      seedId = Rooms.findOne(Session.get('roomId')).seedId
      Messages.find({userId: seedId}, {limit: 10})

  switchState : ->
    if Session.get 'roomId'
      Rooms.findOne(Session.get('roomId')).seedId != Session.get("seedId")

Template.room.events =
  "click #queue li" : () ->
    Meteor.call "createMessage",
      roomId: Session.get "roomId"
      track: this

  "click .switch-on" : () ->
    if Session.get 'roomId'
      Meteor.call "addSeed", Rooms.findOne(Session.get('roomId')).userId
      Session.set("seedId", Rooms.findOne(Session.get('roomId')).seedId)

  "click .switch-off" : () ->
    Meteor.call "addSeed", Meteor.userId()
    Session.set "seedId", Meteor.userId()
