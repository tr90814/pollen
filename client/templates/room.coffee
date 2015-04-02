Template.room.helpers
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.username

  roomUsers : ->
    UserPresences.find {}, sort : "data.username": 1

  queued: ->
    Messages.find({userId: Session.get "roomUserId"}, {limit: 10})

Template.room.events =
  "click #queue li" : () ->
    Meteor.call "createMessage",
      roomId: Session.get "roomId"
      track: this

  "click switch" : () ->


