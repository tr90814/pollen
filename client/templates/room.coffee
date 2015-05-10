Template.room.helpers
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.username

  admin : ->
    Rooms.findOne({userId: Meteor.userId()}).admin

  genre : ->
    Genres.find()

  genreColour : ->
    colour = this.colour
    'rgb(' + Math.floor(colour.r) + ',' + Math.floor(colour.g) + ',' + Math.floor(colour.b) + ')'

  profileColour : ->
    colour = Rooms.findOne({userId: Meteor.userId()}).profile.colour
    'rgb(' + Math.floor(colour.r) + ',' + Math.floor(colour.g) + ',' + Math.floor(colour.b) + ')'

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
    this.tracks

  isDefault : ->
    this.name == "default"

  roomUsers : ->
    if roomId = Session.get 'roomId'
      roomsUserId = Rooms.findOne({_id: roomId}).userId
      Rooms.find({seedId: roomsUserId}).fetch()

  parentNode : ->
    if nodeId = Session.get 'nodeId'
      Rooms.find({userId: nodeId}).fetch()

  node : ->
    if nodeId = Session.get 'nodeId'
      Rooms.find({$and: [{seedId: nodeId}, {userId: {$ne: nodeId}}]}).fetch()

  switchState : ->
    if Session.get 'roomId'
      Rooms.findOne(Session.get('roomId')).seedId != Session.get("seedId")

  playlistState : ->
    Session.get('currentPlaylist') != this.name

Template.room.events =
  "click .node" : () ->
    Session.set 'nodeId', this.userId

  "click .parentNode" : () ->
    Session.set 'nodeId', this.seedId

  "click .delete-playlist" : () ->
    Meteor.call 'removePlaylist',
      playlistName : this.name
    if this.name == 'default'
      Meteor.call 'createPlaylist',
        name: 'default'
        tracks: []

  "click .remove-track" : () ->
    return unless this.playlistName
    Meteor.call 'removeTrackFromPlaylist',
      playlistName : this.playlistName
      _id : this._id

  "click .queue li" : () ->
    return if this.data('name') == 'default'

    Meteor.call "addTrack",
      track: this
      playlistName: 'default'

  "submit [data-action=update-genre]" : (event) ->
    event.preventDefault()

    colour =
      r: this.r.val()
      g: this.g.val()
      b: this.b.val()

    Meteor.call "updateGenre",
      colour: colour
      name: this.name

  "submit [data-action=create-playlist]" : (event) ->
    event.preventDefault()
    $input = $("[data-value=new-playlist]")
    if $input.val() is "" then return
    Meteor.call "createPlaylist",
      name: $input.val()
      tracks: []
    $input.val('')

  "click .play-playlist" : (event) ->
    name = $(event.toElement).parents('.playlist').data('name')
    Meteor.call 'playPlaylist',
      playlistName: name

  "click .switch-on" : () ->
    if Session.get 'roomId'
      seedRoom = Rooms.findOne(Session.get('roomId'))
      Meteor.call "changeSeed", seedRoom.userId
      Session.set("seedId", seedRoom.seedId)

  "click .edit-description" : () ->
    $('.edit-description').addClass('hidden')
    $('.form-group').removeClass('hidden')

  "submit form.form-group" : () ->
    Meteor.call "editDescription",
      userId: Meteor.userId()
      description: $('.form-group textarea').val()

    $('.edit-description').removeClass('hidden')
    $('.form-group').addClass('hidden')

    return false
