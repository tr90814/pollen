# Publish all rooms so that they can be displayed in the room list.
Meteor.publish "allRooms", -> Rooms.find()
# Publish the room messages filtered by a roomId.
Meteor.publish "roomMessages", (userId) -> Messages.find userId : userId
# Publish the users that are in a given room by roomId.
# Meteor.publish "roomUsers", (seedId) -> Rooms.find "data.seedId" : seedId

Meteor.publish "searchResults", (username) -> Results.find "data.username" : username

Messages.allow({
  remove: -> return true
})
