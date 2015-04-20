Meteor.publish "allRooms",      () ->         Rooms.find()
Meteor.publish "roomMessages",  (userId) ->   Messages.find userId : userId
Meteor.publish "searchResults", (username) -> Results.find "data.username" : username
# Meteor.publish "roomUsers",   (seedId) ->   Rooms.find "data.seedId" : seedId
Meteor.publish "roomUsers", (username) -> UserPresences.data
Messages.allow({
  remove: -> return true
})


# Add animation to the slider to maek it smooth
# Playlists
# DJ merge
# search for users
# paginate tracks
