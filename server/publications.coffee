Meteor.publish "allRooms",      () ->         Rooms.find()
Meteor.publish "activeRooms",   () ->         Rooms.find({$or: [{currentTrack: {$ne: undefined}}, {userId: this.userId}]})
Meteor.publish "searchResults", (username) -> Results.find "data.username" : username
Meteor.publish "roomUsers",     (username) -> UserPresences.data
Meteor.publish "nodes",         (userId) ->   Rooms.find({seedId: userID})
Meteor.publish "allGenres",     (userId) ->   if Rooms.findOne({userId: userId}).admin then Genres.find() else []
Meteor.publish "playlists",     (args) ->     if this.userId then getPlaylists(args, this.userId) else []

getPlaylists = (args, meteorId) ->
  return unless args.seedId
  userId = if args.seedId == meteorId then meteorId else seedLoop(args.seedId, meteorId)

  if args.roomUserId && args.roomUserId != meteorId
    room = roomLoop(args.roomUserId)
    Playlists.find({
      $or: [
        {$and: [{userId: userId}, {name: 'default'}]},
        {$and: [{userId: room.userId}, {name: 'default'}]},
        {userId: meteorId}
      ]})
  else
    Playlists.find({
      $or: [
        {$and: [{userId: userId}, {name: 'default'}]},
        {userId: meteorId}
      ]})

roomLoop = (roomUserId) ->
  return false unless room = Rooms.findOne({userId: roomUserId})
  return room if room.seedId == roomUserId
  roomLoop(seedId)

seedLoop = (userId, meteorId) ->
  room = Rooms.findOne({userId: userId})
  if room.seedId == room.userId
    return room.userId
  else if room.seedId == meteorId
    return false
  else
    seedLoop(room.seedId, meteorId)

# Fix genres
# Fix double play
# Fix listeners count

# SIMON WORDS TO MUM
