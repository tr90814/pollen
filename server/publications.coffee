Meteor.publish "allRooms",        () ->           Rooms.find()
Meteor.publish "activeRooms",     () ->           Rooms.find({$or: [{currentTrack: {$ne: undefined}}, {userId: this.userId}]})
Meteor.publish "searchResults",   (username) ->   Results.find "data.username" : username
Meteor.publish "roomUsers",       (username) ->   UserPresences.data
Meteor.publish "roomPlaylists",   (roomUserId) -> return roomPlaylists(roomUserId)
Meteor.publish "playerPlaylists", (userId) ->     return playerPlaylists(userId, this.userId)

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
    seedLoop(userId)

currentPlaylist = (userId, meteorId) ->
  if userId == meteorId
    Playlists.find({userId: meteorId})

seedLoop = (userId) ->
  room = Rooms.findOne({userId: userId})
  if room.seedId == userId
    Playlists.find({$and: [{userId: userId}, {name: room.currentPlaylist}]})
  else
    seedLoop(room.seedId)


# SIMON WORDS TO MUM
