Template.layout.helpers
  hasRoomId : ->
    if Meteor.userId() and Session.get("roomId") then true else false

  paused : ->
    Session.get('currentSound').paused

  ownQueue : ->
    this.userId == Meteor.userId()

  listenersCount : ->
    Rooms.find({seedId: this.userId}).count()-1

  trackId : ->
    this._id

  message : ->
    seedId = if Session.get('seedId') then Session.get('seedId') else Meteor.userId()
    track  = Messages.find({userId: seedId}).fetch()[0]
    if track
      if (!Session.get('currentSound') || (Session.get('currentSoundId') != track.trackId))
        if Session.get('currentSound')
          stopTrack()
        SC.stream "/tracks/" + track.trackId,
          useHTML5Audio: true
          preferFlash: false
          autoPlay: true
          onfinish: -> nextTrack()
          onplay: -> onPlay(this, track)
          onload: -> setNewTrack(track, this)
          whileplaying: -> timer(this)
      return [track]
    else if Session.get("currentSound")
      stopTrack()

  queued: ->
    seedId = if Session.get('seedId') then Session.get('seedId') else Meteor.userId()
    Messages.find({userId: seedId}, {limit: 10})

Template.layout.events =
  "click .skip"             : ()  -> nextTrack()
  "click .pause"            : ()  -> togglePause(false)
  "click .play"             : ()  -> togglePause(true)
  "click .show-hide-queue"  : ()  -> toggleQueue()
  "dragstart li"            : (e) -> dragStart(e)
  "dragenter li"            : (e) -> dragEnter(e)
  "dragover li"             : (e) -> dragOver(e)
  "dragleave li"            : (e) -> dragLeave(e)
  "drop li"                 : (e) -> drop(e)
  "change .progress"        : ()  -> changeSlider()

toggleQueue = () ->
  queue = $('#player-sticky .queue')
  queue.toggleClass('hidden', !queue.hasClass('hidden'))

changeSlider = () ->
  safety = setTimeout(()->
    sound = Session.get('currentSound')
    position = $('.progress').val()*sound.durationEstimate/100
    soundManager.setPosition(sound.sID, position)
  , 20)

timer = (sound) ->
  $('.timer .time').html(timeFormat(sound.position) + '/' + timeFormat(sound.durationEstimate))
  $('.load').css({width: "#{(sound.duration/sound.durationEstimate) * 100}%" })
  newPosition = (sound.position/sound.durationEstimate) * 100
  progress = $('.progress')
  if Math.abs(newPosition - progress.val()) < 3
    $('.progress').val(newPosition)

timeFormat = (milliSeconds) ->
  time    = Math.floor(milliSeconds / 1000)
  minutes = Math.floor(time / 60)
  seconds = (time % 60)
  if seconds < 10 then seconds = "0" + seconds
  return minutes + ':' + seconds

onPlay = (sound, track) ->
  Meteor.call 'setVirtualTimeStamp', track._id, new Date()
  setNewTrack(track, sound)
  $('.progress').val(0)
  if track.virtualTimeStamp
    position        = new Date() - track.virtualTimeStamp
    currentSound    = Session.get('currentSound')
    currentPosition = soundManager.getSoundById(currentSound.sID).position

    # if position - currentPosition > 50
      # soundManager.setPosition(currentSound.sID, 5000)
      # console.log position
      # console.log currentPosition

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
  Meteor.call 'setVirtualTimeStamp', undefined

setNewTrack = (track, obj) ->
  Session.set "currentSound", obj
  Session.set "currentSoundId", track.trackId

getItem = (e) ->
  if $(e.target).hasClass('item')
    return $(e.target)
  $(e.target).parents('.item')

dragStart = (e) ->
  getItem(e).addClass('dragged')

dragEnter = (e) ->
  e.preventDefault()
  getItem(e).addClass('dragged-over')

dragOver = (e) ->
  e.preventDefault()
  getItem(e).addClass('dragged-over')

dragLeave = (e) ->
  e.preventDefault()
  getItem(e).removeClass('dragged-over')

drop = (e) ->
  player = $('#player-sticky')
  player.find('li').removeClass('dragged-over')
  draggedFrom       = player.find('.dragged')
  draggedTo         = getItem(e)
  draggedFromImg    = draggedFrom.children().clone()
  draggedToImg      = draggedTo.children()

  if draggedFrom.attr('draggable') == true
    draggedFrom.html(draggedToImg)
    draggedTo.html(draggedFromImg)
  player.find('.dragged').removeClass('dragged')
  e.preventDefault()

  Meteor.call('switchMessageOrder', {
    fromId: draggedFrom.attr('data-id'),
    toId: draggedTo.attr('data-id')
  })
