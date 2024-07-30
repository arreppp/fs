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
                body: `$username shared ${foodNameController.text}`,
            },
            topic: 'new_post',
        };

        await admin.messaging().send(payload);
    });
