Template.room.helpers
  roomName : ->
    room = Rooms.findOne Session.get "roomId"
    room ?= name : "Current Room"
    room.username

  admin : ->
    Rooms.findOne({userId: Meteor.userId()}).admin

  genre : ->
    Genres.find({}, {sort: {count: -1}})

  active : ->
    this.active

  genreColour : ->
    colour = this.colour
    'rgb(' + Math.floor(colour.r) + ',' + Math.floor(colour.g) + ',' + Math.floor(colour.b) + ')'

  profileColour : ->
    colour = Rooms.findOne({userId: Meteor.userId()}).profile.colour
    'rgb(' + Math.floor(colour.r) + ',' + Math.floor(colour.g) + ',' + Math.floor(colour.b) + ')'

  queued : ->
    if playlist = Playlists.findOne({$and: [{userId: {$ne: Meteor.userId()}}, {name: 'queue'}]})
      return playlist.tracks

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

  isQueue : ->
    this.name == "queue" || this.playlistName == 'queue'

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

  oneNode : ->
    if nodeId = Session.get 'nodeId'
      Rooms.find({$and: [{seedId: nodeId}, {userId: {$ne: nodeId}}]}).count() == 1

  nodes : ->
    if nodeId = Session.get 'nodeId'
      Rooms.find({$and: [{seedId: nodeId}, {userId: {$ne: nodeId}}]}).count() > 1

  switchState : ->
    if Session.get 'roomId'
      Rooms.findOne(Session.get('roomId')).userId != Session.get("seedId")

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
    if this.name == 'queue'
      Meteor.call 'createPlaylist',
        name: 'queue'
        tracks: []

  "click .queue-track" : () ->
    return if this.playlistName == 'queue' && this.userId == Meteor.userId()

    Meteor.call "addTrack",
      track: this
      playlistName: 'queue'

  "submit [data-action=update-genre]" : (event) ->
    event.preventDefault()
    form = $(event.target)
    li   = form.parents('li.genre')

    colour =
      r: form.find('.r').val()
      g: form.find('.g').val()
      b: form.find('.b').val()

    Meteor.call "updateGenre",
      colour: colour
      name: li.data('name')

  "click .change-active" : (event) ->
    state = $(event.target).data('state')
    li    = $(event.target).parents('li.genre')

    Meteor.call "genreActiveState",
      name: li.data('name')
      state: state

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
