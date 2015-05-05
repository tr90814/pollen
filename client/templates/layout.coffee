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

  queued: ->
    playlist  = Session.get('currentPlaylist')
    seedId    = Session.get('seedId')
    if playlist = Playlists.findOne({$and: [{userId: seedId},{name: playlist}]})
      playlist.tracks.slice(playlist.position).concat(playlist.tracks.slice(0, playlist.position))

  message : ->
    return if Session.get('currentSound') == true
    currentPlaylist = Session.get 'currentPlaylist'
    seedId = Session.get 'seedId'
    playlist = Playlists.findOne({$and: [{userId: seedId},{name: currentPlaylist}]})

    if playlist && playlist.tracks
      if track = playlist.tracks[playlist.position]
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
            onload: -> setPosition(track, this)
            whileplaying: -> timer(this)

        [track]

    else if Session.get "currentSound"
      stopTrack()

Template.layout.events =
  "click .skip"             : ()  -> nextTrack()
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

# Sound manipulation

onPlay = (sound, track) ->
  Meteor.call 'setCurrentTrack',
    title: track.title
    artist: track.user.username
  setNewTrack(track, sound)
  $('.progress').val(0)

togglePause = (bool) ->
  return unless currentSound = Session.get('currentSound')
  action = if bool then "resume" else "pause"
  soundManager[action](currentSound.sID)

nextTrack = () ->
  stopTrack()
  Meteor.call 'incrementPlaylist',
    Session.get 'currentPlaylist'

setNewTrack = (track, obj) ->
  Session.set "currentSound", obj
  Session.set "currentSoundId", track.trackId
  if obj.readyState == 2
    Meteor.call 'incrementPlaylist',
      Session.get 'currentPlaylist'

stopTrack = () ->
  seedId          = Session.get('seedId')
  currentPlaylist = Session.get('currentPlaylist')
  hasTracks       = Playlists.find({$and: [{userId: seedId},{name: currentPlaylist}]}).count()
  if Session.get('currentSound') && hasTracks
    soundManager.stop(Session.get('currentSound').sID)
  Session.set "currentSound", undefined
  Session.set "currentSoundId", undefined
  Meteor.call 'setCurrentTrack', undefined

backToOwnQueue = () ->
  stopTrack()
  Session.set 'currentPlaylist', 'defualt'
  Meteor.call "changeSeed", Meteor.userId()
  Session.set "seedId", Meteor.userId()
  Meteor.call "setCurrentPlaylist",
    playlistName: 'default'

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
    sound = Session.get('currentSound')
    position = $('.progress').val()*sound.durationEstimate/100
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

# Drag Queue items

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
  ul = getItem(e).parents('ul')
  ul.find('li').removeClass('dragged-over')
  draggedFrom       = ul.find('.dragged')
  draggedTo         = getItem(e)
  draggedFromImg    = draggedFrom.children().clone()
  draggedToImg      = draggedTo.children()

  if draggedFrom.attr('draggable') == true
    draggedFrom.html(draggedToImg)
    draggedTo.html(draggedFromImg)
  ul.find('.dragged').removeClass('dragged')
  e.preventDefault()

  Meteor.call 'switchTrackOrder',
    playlistName: Session.get 'currentPlaylist'
    fromIndex: draggedFrom.index()
    toIndex: draggedTo.index()
    fromId: draggedFrom.attr('data-id')
    toId: draggedTo.attr('data-id')
