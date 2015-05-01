Meteor.methods
  createRoom : (callback) ->
    if Rooms.findOne({userId: Meteor.userId()}) then return
    Rooms.insert
      userId : Meteor.userId()
      username : Meteor.user().username
      seedId : Meteor.userId()
      currentTrack : undefined
      profile:
        image: randomColour()
        description: undefined
      creation_date : new Date()

  editDescription : (params={}) ->
    return if params.description.length > 100
    return if Meteor.userId() != params.userId
    Rooms.update({userId: params.userId}, {$set: {'profile.description': params.description}})
    unless Rooms.findOne({userId: params.userId}).profile.image
      Rooms.update({userId: params.userId}, {$set: {'profile.image': randomColour()}})

  createMessage : (params={}) ->
    return unless params
    Messages.insert
      username : Meteor.user().username
      userId : Meteor.userId()
      creation_date : new Date()
      trackId : params.track.trackId
      artwork_url : params.track.artwork_url
      description : params.track.description
      genre : params.track.genre
      title : params.track.title
      user : params.track.user
      duration : params.track.duration
      virtualTimeStamp : undefined

  setVirtualTimeStamp : (id, time) ->
    return unless id && Messages.findOne({_id: id})
    userId = Messages.findOne({_id: id}).userId
    if userId == Meteor.userId()
      Messages.update({_id: id}, {$set: {virtualTimeStamp: time}})

  switchMessageOrder : (params={}) ->
    from = Messages.findOne({_id: params.fromId})
    to   = Messages.findOne({_id: params.toId})

    to['_id'] = params.fromId
    from['_id'] = params.toId

    Messages.update({_id: params.fromId}, to)
    Messages.update({_id: params.toId}, from)

  createResult : (params={}) ->
    return unless params
    Results.insert
      username : Meteor.user().username
      userId: Meteor.userId()
      creation_date : new Date()
      trackId : params.track.id
      artwork_url: params.track.artwork_url
      description: params.track.description
      genre: params.track.genre
      title: params.track.title
      user: params.track.user
      duration: params.track.duration

  removeOldResults : (userId) ->
    Results.remove {userId: userId}

  removeOldestTrack : ->
    if Messages.find({userId: Meteor.userId()}).count()
      _id = Messages.find({userId: Meteor.userId()}).fetch()[0]._id
      Messages.remove({_id: _id})

  changeSeed : (seedId) ->
    Rooms.update({userId: Meteor.userId()}, {$set: {seedId: seedId}})

  setCurrentTrack : (track) ->
    Rooms.update({userId: Meteor.userId()}, {$set: {currentTrack: track}})

# Setup an onDisconnect handler on UserPresenceSettings (from dpid:user-presence package).
# Usually we update the user count in a room when the user leaves the room manually.
# However, we also need to handle updating the count when a user disconnects.
UserPresenceSettings
  onDisconnect : (userPresence={}) ->
    if not userPresence.data or not userPresence.data.roomId then return
    roomId = userPresence.data.roomId
    if not checkIsValidRoom roomId then return
    # If no users left in the room, then remove after a short delay if still empty.
    # The delay is handle the edge case where the user is the only one in the room and they refresh
    # the page or get disconnected for a moment.
    roomUsers = UserPresences.find "data.roomId" : roomId
    roomUsersCount = roomUsers.count()-1
    # if roomUsersCount <= 0
    #   Meteor.setTimeout ->
    #     roomUsers = UserPresences.find "data.roomId" : roomId
    #     roomUsersCount = roomUsers.count()
    #     if roomUsersCount <= 0 then removeRoom roomId
    #   , 1000
    # else
    Rooms.update roomId, $set: user_count:roomUsersCount

    userId = userPresence.userId
    Rooms.update({userId: userId}, {$set: {seedId: userId}})
    console.log userId

randomColour = () ->
  r = randomRGB()
  g = randomRGB()
  b = randomRGB()
  return 'rgb(' + r + ',' + g + ',' + b + ')'

randomRGB = () ->
  return Math.floor(Math.random()*256)

checkIsValidRoom = (roomId) ->
  if not roomId then false
  room = Rooms.findOne _id:roomId
  if not room then false
  return true

removeRoom = (roomId) ->
  Rooms.remove roomId
  Messages.remove roomId:roomId
  Results.remove roomId:roomId
