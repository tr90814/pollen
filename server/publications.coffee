Meteor.publish "allRooms",      () ->         Rooms.find()
Meteor.publish "roomMessages",  (userId) ->   Messages.find userId : userId
Meteor.publish "searchResults", (username) -> Results.find "data.username" : username
# Meteor.publish "roomUsers",   (seedId) ->   Rooms.find "data.seedId" : seedId
Messages.allow({
  remove: -> return true
})
