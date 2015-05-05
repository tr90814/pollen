Template.roomList.helpers
  rooms : ->
    # Rooms.find {userId: {$ne: Meteor.userId()}}, sort : creation_date : 'desc'
    Rooms.find {}, sort : creation_date : 'desc'

  currentTrack : ->
    if currentTrack = this.currentTrack
      return currentTrack.title + ' - ' + currentTrack.artist

  listenerCount : ->
    count = Rooms.find({seedId: this.userId}).count()-1
    if count < 0 then count = 0
    return count

  results: ->
    if Results.find({userId: Meteor.userId()}).count()
      Results.find {userId: Meteor.userId()}

  playlists: ->
    Playlists.find({},{name: {$ne: Session.get('currentPlaylist')}})

Template.roomList.events
  "submit [data-action=search]" : (event, template) ->
    event.preventDefault()
    $query = $("[data-value=search]")
    if $query.val() is "" then return

    SCSearch($query.val())

    $query.val ""

  "click .play" : () ->
    Meteor.call "addTrack",
      track: this
      playlistName: Session.get 'currentPlaylist'

  "click .message .username" : () ->
    $query = $(event.target).html()
    SCSearch($query)

  "click .add-to-playlist" : () ->
    popup = $('.playlist-selection')

    popup.data('track', this)
    popup.removeClass('hidden')

  "click .playlist-selection input" : () ->
    container = $('.playlist-selection')
    container.addClass('hidden')
    name = $(event.toElement).data('name')
    if name == 'current'
      Session.get 'currentPlaylist'

    Meteor.call "addTrack",
      playlistName: name
      track: container.data('track')

  "click .playlist-selection .cancel" : () ->
    $('.playlist-selection').addClass('hidden')

SCSearch = (query) ->
  SC.get '/tracks', { q: query }, (tracks) ->
    if (typeof(tracks) == 'object')
      Meteor.call "removeOldResults", Meteor.userId()
      for track in tracks
        if track.streamable && track.sharing == "public"
          Meteor.call "createResult",
            roomId : Session.get "roomId"
            track : track
