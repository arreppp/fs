const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnNewPost = functions.firestore
    .document('foods/{foodId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        const payload = {
            notification: {
                title: 'New Post',
                body: `A new post has been added by ${data.username}`,
            },
            topic: 'new_post',
        };

        await admin.messaging().send(payload);
    });
