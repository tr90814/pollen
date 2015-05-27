Template.layout.helpers
  hasRoomId : ->
    if Meteor.userId() and Session.get("roomId") then true else false

  paused : ->
    Session.get('currentSound').paused

  playlists: ->
    Playlists.find({$and: [{userId: Meteor.userId()},{name: {$ne: 'default'}}]})

  ownQueue : ->
    this.userId == Meteor.userId()

  listenersCount : ->
    Rooms.find({seedId: this.userId}).count()-1

  trackId : ->
    this._id

  queued: ->
    if Meteor.userId() != Session.get('seedId')
      playlist = Playlists.findOne({$and: [{userId: {$ne: Meteor.userId()}}, {name: 'default'}]})
    else playlist = Playlists.findOne({$and: [{userId: Meteor.userId()}, {name: 'default'}]})
    if playlist then return playlist.tracks

  message : ->
    return if Session.get('currentSound') == true
    playMessage()

Template.layout.events =
  "click .skip"             : ()  -> nextTrack()
  "click .mute"             : ()  -> toggleMute()
  "click .pause"            : ()  -> togglePause(false)
  "click .play"             : ()  -> togglePause(true)
  "click .show-hide-queue"  : ()  -> toggleQueue()
  "click .switch-off"       : ()  -> backToOwnQueue()
  "dragstart li"            : (e) -> dragStart(e)
  "dragenter li"            : (e) -> dragEnter(e)
  "dragover li"             : (e) -> dragOver(e)
  "dragleave li"            : (e) -> dragLeave(e)
  "drop li"                 : (e) -> drop(e)
  "change .progress"        : ()  -> changeSlider()

  "click .add-to-playlist" : () ->
    popup = $('.playlist-selection')

    popup.data('track', this)
    popup.removeClass('hidden')

  "click .playlist-selection input" : (event) ->
    container = $('.playlist-selection')
    name      = $(event.toElement).data('name')

    container.addClass('hidden')

    Meteor.call "addTrack",
      playlistName: name
      track: container.data('track')

  "click .playlist-selection .cancel" : () ->
    $('.playlist-selection').addClass('hidden')

# Sound manipulation

playMessage = () ->
  if Meteor.userId() != Session.get('seedId')
    playlist = Playlists.findOne({$and: [{userId: {$ne: Meteor.userId()}}, {name: 'default'}]})
  else playlist = Playlists.findOne({$and: [{userId: Meteor.userId()}, {name: 'default'}]})

  if playlist && playlist.tracks
    if track = playlist.tracks[0]
      noTrackPlaying       = !Session.get('currentSound')
      nextTrackIsDifferent = Session.get('currentSoundId') != track.trackId

      if noTrackPlaying || nextTrackIsDifferent
        if Session.get('currentSound')
          stopTrack()
        else
          Session.set 'currentSound', true
        SC.stream "/tracks/" + track.trackId,
          useHTML5Audio: true
          preferFlash: false
          autoPlay: true
          onfinish: -> nextTrack()
          onplay: -> onPlay(this, track)
          onload: -> updateSound(this)
          whileplaying: -> timer(this)

        Meteor.call 'genreColour',
          track: track
        Meteor.call 'recordGenre',
          track: track

      [track]

    else
      stopTrack()

  else
    stopTrack()

toggleMute = () ->
  if soundManager
    if soundManager.muted
      soundManager.unmute()
    else
      soundManager.mute()

onPlay = (sound, track) ->
  Meteor.call 'setCurrentTrack',
    title: track.title
    artist: track.user.username
  setNewTrack(track, sound)
  $('.progress').val(0)

togglePause = (bool) ->
  if currentSound = Session.get('currentSound')
    action = if bool then "resume" else "pause"
    soundManager[action](currentSound.sID)
  else
    playMessage()

nextTrack = () ->
  stopTrack()
  Meteor.call 'incrementPlaylist'

setNewTrack = (track, obj) ->
  Session.set "currentSound", obj
  Session.set "currentSoundId", track.trackId

  if obj.readyState == 2
    Meteor.call 'incrementPlaylist'

stopTrack = () ->
  Meteor.call 'setCurrentTrack', undefined

  console.log Session.get('currentSound')

  if Session.get('currentSound')
    soundManager.stop(Session.get('currentSound').sID)

  Session.set "currentSound", undefined
  Session.set "currentSoundId", undefined

backToOwnQueue = () ->
  stopTrack()
  Meteor.call "changeSeed", Meteor.userId()
  Session.set "seedId", Meteor.userId()
  Meteor.call "setCurrentTrack", undefined

updateSound = (sound) ->
  Session.set "currentSound", sound

# Misc helpers

toggleQueue = () ->
  queue = $('#player-sticky .queue')
  queue.toggleClass('hidden', !queue.hasClass('hidden'))

getSeedId = () ->
  if Session.get('seedId')
    return Session.get('seedId')
  Meteor.userId()

# Track time and loading

changeSlider = () ->
  safety = setTimeout(()->
    sound    = Session.get('currentSound')
    position = $('.progress').val()*sound.durationEstimate/100
    soundManager.getSoundById(sound.sID).setPosition(position)
  , 20)

timer = (sound) ->
  $('.timer .time').html(timeFormat(sound.position) + '/' + timeFormat(sound.durationEstimate))
  $('.load').css({width: "#{(sound.duration/sound.durationEstimate) * 100}%" })
  newPosition = (sound.position/sound.durationEstimate) * 100
  progress = $('.progress')
  if Math.abs(newPosition - progress.val()) < 3
    progress.val(newPosition)

timeFormat = (milliSeconds) ->
  time    = Math.floor(milliSeconds / 1000)
  minutes = Math.floor(time / 60)
  seconds = (time % 60)
  if seconds < 10 then seconds = "0" + seconds
  return minutes + ':' + seconds

# Drag Queue items

getItem = (e) ->
  if $(e.target).hasClass('track')
    return $(e.target)
  $(e.target).parents('.track')

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
  ul = getItem(e).parents('ul')
  ul.find('li').removeClass('dragged-over')
  e.preventDefault()

  draggedFrom       = ul.find('.dragged')
  draggedTo         = getItem(e)
  draggedFromImg    = draggedFrom.children().clone()
  draggedToImg      = draggedTo.children()
  playlistName      = ul.parents('.playlist').data('name') || 'default'

  if draggedFrom.attr('draggable') == true
    draggedFrom.html(draggedToImg)
    draggedTo.html(draggedFromImg)

  draggedToIndex    = draggedTo.index()
  draggedFromIndex  = draggedFrom.index()

  return if draggedFromIndex == -1 || draggedToIndex == -1

  Meteor.call 'switchTrackOrder',
    playlistName: playlistName
    fromIndex: draggedFromIndex
    toIndex: draggedToIndex
    fromId: draggedFrom.attr('data-id')
    toId: draggedTo.attr('data-id')

  ul.find('.dragged').removeClass('dragged')
