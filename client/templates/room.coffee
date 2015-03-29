Template.room.helpers
  isSeeder : ->
    return Meteor.user().username == Rooms.findOne({_id: Session.get('roomId')}).seeder

  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.name

  roomUsers : ->
    UserPresences.find {}, sort : "data.username":1

  message : ->
    track = Messages.find({}).fetch()[0]
    if track
      if ((!Session.get('currentSound')) || (Session.get('currentSoundId') != track.trackId))
        if Session.get('currentSound')
          stopTrack()
        SC.stream "/tracks/" + track.trackId,
          useHTML5Audio: true
          preferFlash: false
          autoPlay: true
          onfinish: -> nextTrack()
          onplay: -> setNewTrack(track, this)
          # onload: () ->
          #   if ((this.readyState == 2) && (u.activeState == 'streaming'))
          #     Session.set "currentSound", this
      return [track]
    else if Session.get("currentSound")
      nextTrack()
      return false

  queued: ->
    Messages.find({},{limit: 10})

  results: ->
    if Results.find().count()
      if (Results.find().fetch()[0].username == Meteor.user().username)
        Results.find {}

Template.room.events =
  "submit [data-action=search]" : (event, template) ->
    event.preventDefault()
    $query = $("[data-value=search]")
    if $query.val() is "" then return

    SC.get '/tracks', { q: $query.val() }, (tracks) ->
      if (typeof(tracks) == 'object')
        Meteor.call "removeOldResults"
        for track in tracks
          Meteor.call "createResult",
            roomId : Session.get "roomId"
            track: track

    $query.val ""

  "click .message" : () ->
    Meteor.call "createMessage",
      roomId: this.roomId
      track: this

  "click .skip" : () ->
    nextTrack()

nextTrack = () ->
  stopTrack()
  Meteor.call 'removeOldestTrack'

stopTrack = () ->
  if soundManager
    soundManager.stop(Session.get('currentSound').sID)
    Session.set "currentSound", undefined
    Session.set "currentSoundId", undefined

setNewTrack = (track, obj) ->
  Session.set "currentSound", obj
  Session.set "currentSoundId", track.trackId
  Meteor.call "setRoomTrack", {title: track.title, roomId: Session.get('roomId')}
