_.extend(Meteor.settings, process.env)

unless process.env.NODE_ENV == "development"
  Kadira.connect(Meteor.settings.KADIRA_ID, Meteor.settings.KADIRA_SECRET)

Meteor.methods
  createRoom : (callback) ->
    # giveEveryoneADefault() # ** Migration example **
    unless Rooms.findOne({userId: Meteor.userId()})

      Rooms.insert
        userId : Meteor.userId()
        username : Meteor.user().username
        seedId : Meteor.userId()
        currentTrack : undefined
        profile:
          image: randomColour()
          colour:
            r: randomRGB()
            g: randomRGB()
            b: randomRGB()
          description: undefined
        creation_date : new Date()

  genreActiveState : (params={})->
    return unless params.name

    Genres.update({name: params.name}, {$set: {active: params.state}})

  recordGenre : (params={}) ->
    return unless params.track && genre = params.track.genre

    if Genres.find({name: genre}).count()
      Genres.update({name: genre}, {$inc: {count: 1}})
    else
      Genres.insert
        name : genre
        count : 1
        colour:
          r: randomRGB()
          g: randomRGB()
          b: randomRGB()
        creation_date : new Date()

  updateGenre : (params={}) ->
    return unless params.colour && params.name

    Genres.update({name: params.name}, {$set: {colour: params.colour}})

  genreColour : (params={}) ->
    return unless params.track && params.track.genre
    profile = Rooms.findOne({userId: Meteor.userId()}).profile
    return unless profile && colour = profile.colour

    for genre in Genres.find({active: true}).fetch()
      if params.track.genre == genre.name
        for band in Object.keys(colour)
          colour[band] = colorCompare(parseInt(colour[band]), parseInt(genre.colour[band]))

    Rooms.update({userId: Meteor.userId()}, {$set: {'profile.colour': colour}})

  playPlaylist : (params={}) ->
    return unless params && params.playlistName
    tracks = Playlists.findOne({$and: [{ name: params.playlistName }, {userId: Meteor.userId()}]}).tracks
    Playlists.update({$and: [{ name: 'queue' }, {userId: Meteor.userId()}]}, {$set: {tracks: tracks}})

  editDescription : (params={}) ->
    return if params.description.length > 100
    return if Meteor.userId() != params.userId
    Rooms.update({userId: params.userId}, {$set: {'profile.description': params.description}})
    unless Rooms.findOne({userId: params.userId}).profile.image
      Rooms.update({userId: params.userId}, {$set: {'profile.image': randomColour()}})

  addTrack : (params={}) ->
    return unless params && params.track && params.playlistName
    return unless params.track.trackId && params.track.user
    unless Playlists.find({name: params.playlistName}).count()
      Meteor.call 'createPlaylist', name: params.playlistName

    if playlist = Playlists.findOne({$and: [{ name:params.playlistName }, {userId: Meteor.userId()}]})
      count = playlist.tracks.length
    else
      count = 0

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
          genre : params.track.genre
          description : params.track.description
          genre : params.track.genre
          title : params.track.title
          user : params.track.user
          duration : params.track.duration
          creation_date : new Date()
        }
      }
    })

  addTrackToFarewill : (params={}) ->
    return unless params && params.track && params.playlistName
    return unless params.track.trackId && params.track.user
    unless Playlists.find({name: params.playlistName}).count()
      Meteor.call 'createPlaylist', name: params.playlistName

    if playlist = Playlists.findOne({$and: [{ name:params.playlistName }, {username: 'farewill'}]})
      count = playlist.tracks.length
    else
      count = 0
    farewill = Meteor.users.findOne({'username': 'farewill'})

    Playlists.update({$and: [{ name:params.playlistName }, {username: 'farewill'}]}, {
      $addToSet: {
        tracks: {
          _id: new Meteor.Collection.ObjectID()._str
          index : count
          username : 'farewill'
          userId : farewill._id
          playlistName : params.playlistName
          trackId : params.track.trackId
          artwork_url : params.track.artwork_url
          genre : params.track.genre
          description : params.track.description
          genre : params.track.genre
          title : params.track.title
          user : params.track.user
          duration : params.track.duration
          creation_date : new Date()
        }
      }
    })

  playTrack : (params={}) ->
    return unless params && params.track && params.playlistName
    return unless params.track.trackId && params.track.user
    createPlaylistIfNeeded(params)

    tracks = Playlists.findOne({$and: [{ name:params.playlistName }, {userId: Meteor.userId()}]}).tracks

    for track in tracks
      track.index = track.index + 1

    Playlists.update({$and: [{ name:params.playlistName }, {userId: Meteor.userId()}]}, {$set: {tracks: tracks}})

    count = Playlists.findOne({$and: [{ name:params.playlistName }, {userId: Meteor.userId()}]}).tracks.length

    Playlists.update({$and: [{ name:params.playlistName }, {userId: Meteor.userId()}]}, {
      $push: {
        tracks: {
          $each: [
            {
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
              genre : params.track.genre
              user : params.track.user
              duration : params.track.duration
              creation_date : new Date()
            }
          ],
          $position: 0
        }
      }
    })

  switchTrackOrder : (params={}) ->
    return unless params.toId && params.fromId && params.playlistName

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
    params['name'] = params.name || 'queue'
    return unless params.name
    return if params.name == 'queue' && Playlists.find({$and: [{userId: Meteor.userId()}, {name: 'queue'}]}).count()

    Playlists.insert
      userId : Meteor.userId()
      username : Meteor.user().username
      name : params.name
      tracks : params.tracks || []
      creation_date : new Date()

  incrementPlaylist : (userId) ->
    if !userId then userId = Meteor.userId()
    if Playlists.find({$and: [{userId: userId}, {name: 'queue'}]}).count()
      Playlists.update({$and: [{userId: userId},{name: 'queue'}]}, {$pop: {tracks: -1}})

  removeLastOfPlaylist: (userId) ->
    if !userId then userId = Meteor.userId()
    if Playlists.find({$and: [{userId: userId}, {name: 'queue'}]}).count()
      Playlists.update({$and: [{userId: userId},{name: 'queue'}]}, {$pop: {tracks: 1}})

  removePlaylist : (params={}) ->
    return unless params.playlistName
    Playlists.remove({$and: [{name: params.playlistName}, {userId: Meteor.userId()}]})

  removeTrackFromPlaylist : (params) ->
    return unless params.playlistName && params._id
    return unless Playlists.find({name: params.playlistName}).count()
    Playlists.update({$and: [{name: params.playlistName}, {userId: Meteor.userId()}]}, {$pull: {tracks: {_id: params._id}}})

  createResult : (params={}) ->
    return unless params
    Results.insert
      username : Meteor.user().username
      userId: Meteor.userId()
      trackId : params.track.id
      artwork_url: params.track.artwork_url
      description: params.track.description
      genre: params.track.genre
      genre: params.track.genre
      title: params.track.title
      user: params.track.user
      duration: params.track.duration
      creation_date : new Date()

  removeOldResults : () ->
    Results.remove {userId: Meteor.userId}

  changeSeed : (seedId) ->
    return unless seedId
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

createPlaylistIfNeeded = (params) ->
  if !Playlists.find({$and: [{userId: Meteor.userId()}, {name: params.playlistName}]}).count()
    Meteor.call "createPlaylist",
      name: params.playlistName

colorCompare = (existingBand, genreBand) ->
  difference = existingBand - genreBand
  newValue   = existingBand
  if difference != 0
    newValue = existingBand - (difference / Math.abs(difference))
  return newValue

randomRGB = () ->
  return Math.floor(Math.random()*256)

randomColour = () ->
  r = randomRGB()
  g = randomRGB()
  b = randomRGB()
  return 'rgb(' + r + ',' + g + ',' + b + ')'

checkIsValidRoom = (roomId) ->
  if not roomId then false
  room = Rooms.findOne _id:roomId
  if not room then false
  return true

removeRoom = (roomId) ->
  Rooms.remove roomId
  Results.remove roomId:roomId

# ** Migration example **

giveEveryoneADefault = () ->
  Rooms.find({}).forEach((doc)->
    if !Playlists.find({$and: [{name: 'queue'}, {userId: doc.userId}]}).count()
      Playlists.insert
        userId : doc.userId
        username : doc.username
        name : 'queue'
        tracks : []
        creation_date : new Date()
      console.log doc.username + ' added queue'
  )
