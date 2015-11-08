bodyParser = Meteor.npmRequire('body-parser')
Picker.middleware(bodyParser.urlencoded({ extended: false }))
Picker.middleware(bodyParser.json())

Picker.route '/hubot', (params, req, res, next) ->
  console.log req.body
  res.setHeader 'access-control-allow-methods', 'POST'

  userId = Meteor.users.findOne({username: 'farewill'})._id

  if req.body.test == 'skip'
    Meteor.call 'incrementPlaylist', userId
    res.end("Skipped to next track.")
  else
    Meteor.call 'search', req.body.text, (err, res) ->
      obj = {playlistName: 'queue', track: res}
      obj.track['username'] = 'farewill'
      obj.track['userId'] = userId
      obj.track['trackId'] = obj.track.id
      Meteor.call 'addTrackToFarewill', obj
    res.end("Added track to Farewill queue!")

Meteor.methods
  search: (query) ->
    res = HTTP.get("http://api.soundcloud.com/tracks/?q=#{query}&client_id=4e881f300e2625f432fa0556d5404e68", {})
    firstResult = res.data[0]
    return firstResult
