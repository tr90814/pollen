Template.room.helpers
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.username

  queued : ->
    if Session.get 'roomId'
      seedId = Rooms.findOne(Session.get('roomId')).seedId
      Messages.find({userId: seedId}, {limit: 10})

  profile : ->
    if Session.get 'roomId'
      Rooms.findOne(Session.get('roomId')).profile

  ownProfile : ->
    if Session.get 'roomId'
      Rooms.findOne(Session.get('roomId')).userId == Meteor.userId()

  roomUsers : ->
    if Session.get 'roomId'
      roomsUserId = Rooms.findOne({_id: Session.get('roomId')}).userId
      Rooms.find({seedId: roomsUserId}).fetch()

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
      Meteor.call "changeSeed", Rooms.findOne(Session.get('roomId')).userId
      Session.set("seedId", Rooms.findOne(Session.get('roomId')).seedId)

  "click .switch-off" : () ->
    Meteor.call "changeSeed", Meteor.userId()
    Session.set "seedId", Meteor.userId()

  "click .edit-description" : () ->
    $('.edit-description').addClass('hidden')
    $('.form-group').removeClass('hidden')

  "submit form.form-group" : () ->
    Meteor.call "editDescription", {
      userId: Meteor.userId()
      description: $('.form-group textarea').val()
    }
    $('.edit-description').removeClass('hidden')
    $('.form-group').addClass('hidden')
    return false

