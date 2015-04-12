# Template helpers
Template.layout.helpers
  # Determines if the user is logged in and has a room id.
  # This is used to see if a "Leave Room" link should be displayed.
  hasRoomId : -> if Meteor.userId() and Session.get("roomId") then true else false

  paused : -> Session.get('currentSound').paused

  message : ->
    if Session.get('seedId')
      seedId = Session.get('seedId')
    else
      seedId = Meteor.userId()
    track = Messages.find({userId: seedId}).fetch()[0]
    if track
      # console.log soundManager.getSoundById(Session.get('currentSound').sID).position
      if ((!Session.get('currentSound')) || (Session.get('currentSoundId') != track.trackId))
        if Session.get('currentSound')
          stopTrack()
        SC.stream "/tracks/" + track.trackId,
          useHTML5Audio: true
          preferFlash: false
          autoPlay: true
          onload: -> setPosition(this, seedId)
          onfinish: -> nextTrack()
          onplay: -> setNewTrack(track, this)
          # whileplaying: -> sendPosition(this)
          # onload: () ->
          #   if ((this.readyState == 2) && (u.activeState == 'streaming'))
          #     Session.set "currentSound", this
      return [track]
    # else if Session.get("currentSound")
    #   console.log 'next track'
    #   nextTrack()
    #   return false

  queued: ->
    if Session.get('seedId')
      seedId = Session.get('seedId')
    else
      seedId = Meteor.userId()
    Messages.find({userId: seedId}, {limit: 10})

Template.layout.events =
  "click .skip" : () ->
    nextTrack()

  "click .pause" : () ->
    togglePause(false)

  "click .play" : () ->
    togglePause(true)

togglePause = (bool) ->
  currentSound = Session.get('currentSound')
  if bool
    soundManager.resume(currentSound.sID)
  else
    soundManager.pause(currentSound.sID)

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

sendPosition = (sound) ->
  Meteor.call 'setPosition', sound.position

setPosition = (sound) ->
  soundManager.setPosition(sound, Rooms.findOne({userId: seedId}).position)

