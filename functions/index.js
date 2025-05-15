const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.kickUser = functions.https.onCall(async (data, context) => {
  const { roomId, userIdToKick } = data;
  const callerUid = context.auth?.uid;

  if (!callerUid) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');

  const roomRef = admin.database().ref(`rooms/${roomId}`);
  const roomSnapshot = await roomRef.once('value');
  const room = roomSnapshot.val();
  if (!room.admins.includes(callerUid)) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can kick users.');
  }

  await roomRef.child('members').child(userIdToKick).remove();
  return { success: true };
});

exports.sendMessageNotification = functions.database
    .ref('messages/{roomId}/{messageId}')
    .onCreate(async (snapshot, context) => {
      const message = snapshot.val();
      const payload = {
        notification: {
          title: 'New Message',
          body: `${message.userId}: ${message.content ?? 'Sent a message'}`,
        },
      };
      await admin.messaging().sendToTopic(`room_${context.params.roomId}`, payload);
    });