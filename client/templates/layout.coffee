# Template helpers
Template.layout.helpers
  # Determines if the user is logged in and has a room id.
  # This is used to see if a "Leave Room" link should be displayed.
  hasRoomId : -> if Meteor.userId() and Session.get("roomId") then true else false

  paused : -> Session.get('currentSound').paused

  message : ->
    track = Messages.find({userId: Meteor.userId()}).fetch()[0]
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
    Messages.find({userId: Meteor.userId()}, {limit: 10})


Template.layout.events =
  "click .skip" : () -> nextTrack()

  "click .pause" : () -> togglePause(false)

  "click .play" : () -> togglePause(true)

  "dragstart li" : (e) -> dragStart(e)

  "dragenter li" : (e) -> dragEnter(e)

  "dragleave li" : (e) -> dragLeave(e)

  "drop li" : (e) -> drop(e)

  "dragover li" : (e) -> dragOver(e)

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
  Meteor.call "setRoomTrack", track.title

dragStart = (e) ->
  $(e.target).addClass('dragged')

dragEnter = (e) ->
  e.preventDefault()
  $(e.target).addClass('dragged-over')

dragOver = (e) ->
  e.preventDefault()
  $(e.target).addClass('dragged-over')

dragLeave = (e) ->
  e.preventDefault()
  $(e.target).removeClass('dragged-over')

drop = (e) ->
  player = $('#player')
  player.find('li').removeClass('dragged-over')
  draggedFrom       = player.find('.dragged')
  draggedFromImg    = draggedFrom.find('img').clone()
  draggedToImg      = $(e.target).find('img')
  draggedFrom.html(draggedToImg)
  $(e.target).html(draggedFromImg)
  player.find('.dragged').removeClass('dragged')
  e.preventDefault()


