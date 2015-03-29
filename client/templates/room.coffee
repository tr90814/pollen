# Template helpers
Template.room.helpers
  # Find the room name from the Rooms collection by room id.
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.name
  # Retrieve the users sorted by username.
  # The UserPresences collection will only contain relevant room users since the server publishes by roomId.
  roomUsers : ->
    UserPresences.find {}, sort : "data.username":1
  # Find the messages in the room by room id.
  # Like UserPresences, the Messages collection subscribed to only contains messages associated with the current roomId.
  message : ->
    track = Messages.find({}).fetch()[0]
    if track
      if ((!Session.get('currentSound')) || (Session.get('currentSoundId') != track.trackId))
        if Session.get('currentSound')
          stopTrack()
        console.log track
        SC.stream "/tracks/" + track.trackId,
          useHTML5Audio: true
          preferFlash: false
          autoPlay: true
          onfinish: -> nextTrack()
          onplay: () ->
            Session.set "currentSound", this
            Session.set "currentSoundId", track.trackId
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

# Template events
Template.room.events =
  # Create a message on form submit.
  # Note: It is recommended to use 'submit' instead of 'click' since it will handle all submit cases.
  "submit [data-action=search]" : (event, template) ->
    event.preventDefault()
    $query = $("[data-value=search]")
    if $query.val() is "" then return
    # Call the Meteor.method function on the server to handle putting it into the messages collection.
    SC.get '/tracks', { q: $query.val() }, (tracks) ->
      if (typeof(tracks) == 'object')
        Meteor.call "removeOldResults"
        for track in tracks
          Meteor.call "createResult",
            roomId : Session.get "roomId"
            track: track
    # Clear the form
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
