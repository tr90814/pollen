Meteor.methods
  createRoom : (callback) ->
    if Rooms.findOne({userId: Meteor.userId()}) then return
    Rooms.insert
      userId : Meteor.userId()
      username : Meteor.user().username
      user_count : 0
      listener_count : 0
      seedId : Meteor.userId()
      creation_date : new Date()
      position: 0

  setPosition : (position) ->
    Rooms.update({userId: Meteor.userId()}, {$set: {position: position}})

  joinRoom : (roomId) ->
    if not checkIsValidRoom roomId then return

    roomUsers = UserPresences.find "data.roomId" : roomId
    Rooms.update roomId, $set: user_count: roomUsers.count()+1

  leaveRoom : (roomId) ->
    if not checkIsValidRoom roomId then return

    roomUsers = UserPresences.find "data.roomId" : roomId
    roomUsersCount = roomUsers.count()-1
    # if roomUsersCount <= 0
    #   removeRoom roomId
    # else
    Rooms.update roomId, $set: user_count:roomUsersCount

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

  addSeed : (seedId) ->
    amount = if seedId then 1 else (-1)
    Rooms.update({userId: Meteor.userId()}, {$set: {seedId: seedId}})
    Rooms.update({userId: Meteor.userId()}, {$inc: {listener_count: amount}})

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


checkIsValidRoom = (roomId) ->
  if not roomId then false
  room = Rooms.findOne _id:roomId
  if not room then false
  return true

removeRoom = (roomId) ->
  Rooms.remove roomId
  Messages.remove roomId:roomId
  Results.remove roomId:roomId
