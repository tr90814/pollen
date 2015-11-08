Template.roomList.helpers
  rooms : ->
    Rooms.find {}, sort : creation_date : 'desc'

  currentTrack : ->
    if currentTrack = this.currentTrack
      return currentTrack.title + ' - ' + currentTrack.artist

  listenerCount : ->
    count = Rooms.find({seedId: this.userId}).count()-1
    if count < 0 then count = 0
    return count

  notSelf : ->
    this.userId != Meteor.userId()

  results: ->
    if Results.find({userId: Meteor.userId()}).count()
      Results.find {userId: Meteor.userId()}

Template.roomList.events
  "submit [data-action=search]" : (event, template) ->
    event.preventDefault()
    $query = $("[data-value=search]")
    if $query.val() is "" then return

    SCSearch($query.val())

    $query.select()

  "click .queue-track" : () ->
    Meteor.call "addTrack",
      track: this
      playlistName: 'queue'

  "click .farewill-queue-track" : () ->
    Meteor.call "addTrackToFarewill",
      track: this
      playlistName: 'queue'

  "click .play-track" : () ->
    Meteor.call "playTrack",
      track: this
      playlistName: 'queue'

  "click .listen" : () ->
    seedRoom = Rooms.findOne({userId: this.seedId})
    Meteor.call "changeSeed", seedRoom.userId
    Session.set "seedId", seedRoom.seedId

  "click .message .username" : (event) ->
    $query = $(event.target).html()
    SCSearch($query)

SCSearch = (query) ->
  SC.get '/tracks', { q: query, limit: 100 }, (tracks) ->
    if (typeof(tracks) == 'object')
      Meteor.call "removeOldResults"
      for track in tracks
        if track.streamable && track.sharing == "public"
          Meteor.call "createResult",
            roomId : Session.get "roomId"
            track : track
