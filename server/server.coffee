Meteor.methods
  createRoom : (callback) ->
    # Playlists.remove({})
    # Results.remove({})
    if Rooms.findOne({userId: Meteor.userId()}) then return

    Rooms.insert
      userId : Meteor.userId()
      username : Meteor.user().username
      seedId : Meteor.userId()
      currentTrack : undefined
      currentPlaylist : 'default'
      profile:
        image: randomColour()
        description: undefined
      creation_date : new Date()

    Meteor.call "createPlaylist",
      name: 'default'

  setCurrentPlaylist : (params={}) ->
    return unless params.playlistName
    if !Playlists.find({$and: [{userId: Meteor.userId()}, {name: params.playlistName}]}).count()
      Meteor.call "createPlaylist",
        name: params.playlistName
    Rooms.update(
      {userId: Meteor.userId()},
      {$set: {currentPlaylist: params.playlistName}}
    )

  editDescription : (params={}) ->
    return if params.description.length > 100
    return if Meteor.userId() != params.userId
    Rooms.update({userId: params.userId}, {$set: {'profile.description': params.description}})
    unless Rooms.findOne({userId: params.userId}).profile.image
      Rooms.update({userId: params.userId}, {$set: {'profile.image': randomColour()}})

  addTrack : (params={}) ->
    return unless params && params.track && params.playlistName
    return unless params.track.trackId && params.track.user
    unless Playlists.find({name: params.name}).count()
      Meteor.call 'createPlaylist', name: params.playlistName

    count = Playlists.findOne({$and: [{ name:params.playlistName }, {userId: Meteor.userId()}]}).tracks.length

    Playlists.update({$and: [{ name:params.playlistName }, {userId: Meteor.userId()}]}, {
      $addToSet: {
        tracks: {
          _id: new Meteor.Collection.ObjectID()._str
          index : count
          username : Meteor.user().username
          userId : Meteor.userId()
          playlistName : params.playlistName
          trackId : params.track.trackId
          artwork_url : params.track.artwork_url
          description : params.track.description
          genre : params.track.genre
          title : params.track.title
          user : params.track.user
          duration : params.track.duration
          creation_date : new Date()
        }
      }
    })

  switchTrackOrder : (params={}) ->
    return unless params.toIndex && params.fromIndex

    Playlists.update(
      {$and: [{name: params.playlistName}, {userId: Meteor.userId()},  { 'tracks._id': params.toId}]},
      { $set: { 'tracks.$.index' : params. fromIndex } }
    )

    Playlists.update(
      {$and: [{name: params.playlistName}, {userId: Meteor.userId()}, { 'tracks._id': params.fromId}]},
      {$set: {'tracks.$.index' : params. toIndex}}
    )
    Playlists.update(
      {$and: [{name: params.playlistName}, {userId: Meteor.userId()}]},
      {
        $push: {
          tracks: {
            $each: [],
            $sort: { index: 1 }
          }
        }
      }
    )

  createPlaylist : (params={}) ->
    params['name'] = params.name || 'defualt'
    return if Playlists.find({name: params.name}).count()
    Playlists.insert
      userId : Meteor.userId()
      username : Meteor.user().username
      name : params.name
      tracks : params.tracks || []
      position: 0
      creation_date : new Date()

  incrementPlaylist : (name) ->
    return unless name
    if name == 'default'
      console.log Playlists.find({$and: [{userId: Meteor.userId()},{name: name}]}).count()
      if Playlists.find({$and: [{userId: Meteor.userId()},{name: name}]}).count()
        Playlists.update({$and: [{userId: Meteor.userId()},{name: name}]}, {$pop: {tracks: -1}})
    else
      playlist = Playlists.findOne({$and: [{userId: Meteor.userId()},{name: name}]})
      position = if playlist.position < playlist.tracks.length - 1 then playlist.position + 1 else 0
      Playlists.update({$and: [{userId: Meteor.userId()},{name: name}]}, {$set: {position: position}})

  removePlaylist : (params={}) ->
    return unless params.playlistName
    Playlists.remove({$and: [{name: params.playlistName}, {userId: Meteor.userId()}]})

  removeTrackFromPlaylist : (params) ->
    return unless params.playlistName && params._id
    return unless Playlists.find({name: params.playlistName}).count()
    Playlists.update({name: params.playlistName}, {$pull: {tracks: {_id: params._id}}})

  createResult : (params={}) ->
    return unless params
    Results.insert
      username : Meteor.user().username
      userId: Meteor.userId()
      trackId : params.track.id
      artwork_url: params.track.artwork_url
      description: params.track.description
      genre: params.track.genre
      title: params.track.title
      user: params.track.user
      duration: params.track.duration
      creation_date : new Date()

  removeOldResults : (userId) ->
    Results.remove {userId: userId}

  changeSeed : (seedId) ->
    Rooms.update({userId: Meteor.userId()}, {$set: {seedId: seedId}})

  setCurrentTrack : (track) ->
    Rooms.update({userId: Meteor.userId()}, {$set: {currentTrack: track}})

# Setup an onDisconnect handler on UserPresenceSettings (from dpid:user-presence package).
# Usually we update the user count in a room when the user leaves the room manually.
# However, we also need to handle updating the count when a user disconnects.
UserPresenceSettings
  onDisconnect : (userPresence={}) ->
    userId = userPresence.userId
    Rooms.update({userId: userId}, {$set: {currentTrack: undefined}})
    Rooms.update({userId: userId}, {$set: {seedId: userId}})

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
  Results.remove roomId:roomId
