const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();

// Send push notification on new message
exports.sendMessageNotification = functions.firestore
  .document("groups/{groupId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();
    const groupId = context.params.groupId;
    const messageSender = messageData.sender;
    const messageBody = messageData.message;

    // Get the FCM tokens of all users in the group
    const groupRef = admin.firestore().collection("groups").doc(groupId);
    const groupDoc = await groupRef.get();
    const groupData = groupDoc.data();

    const userTokens = groupData.userTokens;

    // Send notification to each user in the group (except the sender)
    const notifications = userTokens
      .filter((token) => token !== messageSender)
      .map((token) => {
        return admin.messaging().send({
          token: token,
          notification: {
            title: "New Message",
            body: messageBody,
          },
        });
      });

    // Send notifications
    await Promise.all(notifications);
    return null;
  });
