Meteor.publish "allRooms",      () ->         Rooms.find()
Meteor.publish "activeRooms",   () ->         Rooms.find({currentTrack: {$ne: undefined}})
Meteor.publish "roomMessages",  (userId) ->   Messages.find userId : userId
Meteor.publish "searchResults", (username) -> Results.find "data.username" : username
# Meteor.publish "roomUsers",   (seedId) ->   Rooms.find "data.seedId" : seedId
Meteor.publish "roomUsers", (username) -> UserPresences.data
Messages.allow({
  remove: -> return true
})

# Add animation to the slider to make it smooth
# Playlists
# DJ merge
# search for users
# paginate tracks
# listener tree - know your sub leachers.

# loop/radio
# artist search link
# playlist.
# search track - if someone else listening - show up
# like sticking your head out of the window
# its alive - not a filing cabinet
# what are the metrics for tree ranking - how many followers/how long youve been on



#SIMON WORDS TO MUM
