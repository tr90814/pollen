bodyParser = Meteor.npmRequire('body-parser')
Picker.middleware(bodyParser.urlencoded({ extended: false }))
Picker.middleware(bodyParser.json())
searchCache = undefined

Picker.route '/hubot', (params, req, res, next) ->
  console.log req.body
  res.setHeader 'access-control-allow-methods', 'POST'

  userId = Meteor.users.findOne({username: 'farewill'})._id

  if req.body.text.indexOf('$skip') != -1
    Meteor.call 'incrementPlaylist', userId
    res.end("Skipped to next track.")
  else if req.body.text.indexOf('$help') != -1
    res.end("Usage:" +
      "\n/eargasm $search [search term] - returns a list of search results with an index." +
      "\n/eargasm $add [index] - then adds the track at that index in the results." +
      "\n/eargasm [search query] - adds the first result from the query entered." +
      "\n/eargasm $skip - skip the current song." +
      "\n/eargasm $undo - remove the last song in the queue." +
      "\n/eargasm $help - this help string." +
      "\n the playlist is at pollen-seed.herokuapp.com under the 'farewill' username.")
  else if req.body.text.indexOf('$undo') != -1
    Meteor.call 'removeLastOfPlaylist', userId
    res.end("Removed last track in queue.")
  else if req.body.text.indexOf('$search') != -1
    Meteor.call 'search', req.body.text.replace('$search', ''), (err, tracks) ->
      searchCache = tracks
      send = "Do /eargasm $add [index] with the track you want to add."
      tracks.map (track, index) ->
        send += "\n index: #{index} | #{track.user.username} - #{track.title}"
      res.end(send)
  else if req.body.text.indexOf('$add') != -1
    track = searchCache[req.body.text.replace('$add', '').trim()]
    obj = {playlistName: 'queue', track: track}
    obj.track['username'] = 'farewill'
    obj.track['userId'] = userId
    obj.track['trackId'] = obj.track.id
    Meteor.call 'addTrackToFarewill', obj
    res.end("Added track '#{obj.track.user.username} - #{obj.track.title}' to Farewill queue!")
  else
    Meteor.call 'search', req.body.text, (err, tracks) ->
      track = tracks[0]
      obj = {playlistName: 'queue', track: track}
      obj.track['username'] = 'farewill'
      obj.track['userId'] = userId
      obj.track['trackId'] = obj.track.id
      Meteor.call 'addTrackToFarewill', obj
      res.end("Added track '#{obj.track.user.username} - #{obj.track.title}' to Farewill queue!")

Meteor.methods
  search: (query) ->
    res = HTTP.get("http://api.soundcloud.com/tracks/?q=#{query}&client_id=4e881f300e2625f432fa0556d5404e68", {})
    results = _.filter(res.data, (track) -> track.streamable && track.sharing == "public")
    return results
