Meteor.publish "allRooms",      () ->           Rooms.find()
Meteor.publish "activeRooms",   () ->           Rooms.find({$or: [{currentTrack: {$ne: undefined}}, {userId: this.userId}]})
Meteor.publish "searchResults", (username) ->   Results.find "data.username" : username
Meteor.publish "roomUsers",     (username) ->   UserPresences.data
Meteor.publish "tracks",        (roomId) ->     return findTracks(Rooms.findOne({userId: roomId}).userId)
Meteor.publish "playlists",     (roomUserId) -> return playlistsByRoom(roomUserId, this.userId)

# Messages.allow({
#   remove: -> return true
# })

findTracks = (userId) ->
  room   = Rooms.findOne({userId: userId})
  seedId = room.seedId
  if seedId == userId
    return Playlists.find({$and: [{userId : userId}, {name: room.currentPlaylist}]})
  findTracks(seedId)

playlistsByRoom = (roomUserId, userId) ->
  if userId == roomUserId
    Playlists.find({userId: roomUserId})
  else
    room = Rooms.findOne({userId: roomUserId})
    Playlists.find({$and: [{userId: roomUserId}, {name: room.currentPlaylist}]})


# Add animation to the slider to make it smooth
# Playlists
# DJ merge
# search for users
# paginate tracks
# listener tree - know your sub leachers.  abor.js

# loop/radio
# artist search link
# playlist.
# search track - if someone else listening - show up
# like sticking your head out of the window
# its alive - not a filing cabinet
# what are the metrics for tree ranking - how many followers/how long youve been on



# SIMON WORDS TO MUM
