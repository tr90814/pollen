Template.roomList.helpers
  rooms : ->
    # Rooms.find {userId: {$ne: Meteor.userId()}}, sort : creation_date : 'desc'
    Rooms.find {}, sort : creation_date : 'desc'

  currentTrack : ->
    if currentTrack = this.currentTrack
      return currentTrack.title + ' - ' + currentTrack.artist

  listenerCount : ->
    Rooms.find(userId: this.seedId).count()-1

  results: ->
    if Results.find({userId: Meteor.userId()}).count()
      Results.find {userId: Meteor.userId()}

Template.roomList.events
  "submit [data-action=search]" : (event, template) ->
    event.preventDefault()
    $query = $("[data-value=search]")
    if $query.val() is "" then return

    SC.get '/tracks', { q: $query.val() }, (tracks) ->
      if (typeof(tracks) == 'object')
        Meteor.call "removeOldResults", Meteor.userId()
        for track in tracks
          Meteor.call "createResult",
            roomId : Session.get "roomId"
            track : track

    $query.val ""

  "click .message" : () ->
    Meteor.call "createMessage",
      track: this
