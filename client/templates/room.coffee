Template.room.helpers
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.username

  queued : ->
    if Session.get 'roomId'
      room = Rooms.findOne(Session.get('roomId'))
      seedId = room.seedId
      if playlist = Playlists.findOne({$and: [{userId: seedId},{name: playlist}]})
        playlist.tracks.slice(playlist.position).concat(playlist.tracks.slice(0, playlist.position))

  profile : ->
    if Session.get 'roomId'
      Rooms.findOne(Session.get('roomId')).profile

  ownProfile : ->
    if Session.get 'roomId'
      Rooms.findOne(Session.get('roomId')).userId == Meteor.userId()

  playlists : ->
    Playlists.find({userId: Session.get('roomUserId')}).fetch()

  tracks : ->
    this.tracks.slice(0,10)

  roomUsers : ->
    if roomId = Session.get 'roomId'
      roomsUserId = Rooms.findOne({_id: roomId}).userId
      Rooms.find({seedId: roomsUserId}).fetch()

  switchState : ->
    if Session.get 'roomId'
      Rooms.findOne(Session.get('roomId')).seedId != Session.get("seedId")

  playlistState : ->
    Session.get('currentPlaylist') != this.name

Template.room.events =
  "click .queue li" : () ->
    Meteor.call "addTrack",
      track: this
      playlistName: Session.get 'currentPlaylist'

  "submit [data-action=create-playlist]" : (event) ->
    event.preventDefault()
    $input = $("[data-value=new-playlist]")
    if $input.val() is "" then return
    Meteor.call "createPlaylist",
      name: $input.val()
      tracks: []
    $input.val('')

  "click .play-playlist" : () ->
    name = $(event.toElement).parents('.playlist').data('name')
    Session.set 'currentPlaylist', name
    Meteor.call 'setCurrentPlaylist',
      playlistName: name

  "click .back-to-queue" : () ->
    seedId          = Session.get('seedId')
    currentPlaylist = Session.get('currentPlaylist')
    hasTracks       = Playlists.find({$and: [{userId: seedId},{name: currentPlaylist}]}).count()

    if Session.get('currentSound') && hasTracks
      soundManager.stop(Session.get('currentSound').sID)

    Session.set 'currentPlaylist', 'defualt'
    Session.set 'currentSound', undefined
    Session.set 'currentSoundId', undefined
    Meteor.call 'setCurrentTrack', undefined
    Meteor.call 'setCurrentPlaylist',
      playlistName: 'default'

  "click .switch-on" : () ->
    if Session.get 'roomId'
      Meteor.call "changeSeed", Rooms.findOne(Session.get('roomId')).userId
      Session.set("currentPlaylist", Rooms.findOne(Session.get('roomId')).currentPlaylist)
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
