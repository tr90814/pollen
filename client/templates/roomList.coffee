# Template helpers
Template.roomList.helpers
  # Find rooms and sort by create date.
  rooms : ->
    Rooms.find {userId: {$ne: Meteor.userId()}}, sort : creation_date : 'desc'

  currentTrack : ->
    seedId = this.seedId || Meteor.userId()
    track = Messages.find({userId: seedId}).fetch()[0]

  results: ->
    if Results.find({userId: Meteor.userId()}).count()
      Results.find {userId: Meteor.userId()}

# Template events
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
