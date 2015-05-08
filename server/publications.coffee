Meteor.publish "allRooms",        () ->           Rooms.find()
Meteor.publish "activeRooms",     () ->           Rooms.find({$or: [{currentTrack: {$ne: undefined}}, {userId: this.userId}]})
Meteor.publish "searchResults",   (username) ->   Results.find "data.username" : username
Meteor.publish "roomUsers",       (username) ->   UserPresences.data
Meteor.publish "roomPlaylists",   (roomUserId) -> return roomPlaylists(roomUserId)
Meteor.publish "playerPlaylists", (userId) ->     return playerPlaylists(userId, this.userId)
Meteor.publish "nodes",           (userId) ->     Rooms.find({seedId: userID})

roomPlaylists = (roomUserId) ->
  unless room = Rooms.findOne({userId: roomUserId})
    return []
  seedId = room.seedId
  if seedId == roomUserId
    return Playlists.find({$and: [{userId : roomUserId}, {name: room.currentPlaylist}]})
  roomPlaylists(seedId)

playerPlaylists = (userId, meteorId) ->
  if userId == meteorId
    Playlists.find({userId: meteorId})
  else
    seedLoop(userId, meteorId)

currentPlaylist = (userId, meteorId) ->
  if userId == meteorId
    Playlists.find({userId: meteorId})

seedLoop = (userId, meteorId) ->
  room = Rooms.findOne({userId: userId})
  if room.seedId == room.userId
    Playlists.find({$and: [{userId: room.userId}, {name: 'default'}]})
  else if room.seedId == meteorId
    return
  else
    seedLoop(room.seedId, meteorId)


# SIMON WORDS TO MUM
