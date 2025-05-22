const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const title = data.title;
  const body = data.body;

  if (!title || !body) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Tiêu đề và nội dung thông báo không được để trống.",
    );
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    topic: "all_users",
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Thông báo đã được gửi thành công:", response);
    return {success: true, messageId: response};
  } catch (error) {
    console.error("Lỗi khi gửi thông báo:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Không thể gửi thông báo.",
        error.message,
    );
  }
});

exports.aggregateSearchQueries = functions.firestore
    .document("analytics/{docId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      if (data.event_type === "search" && data.query) {
        const rawSearchQuery = data.query;
        const standardizedQuery = rawSearchQuery.toLowerCase().trim();
        const bookId = data.bookId || "unknown_book_id";

        const aggregatedDocId = `AGG_SEARCH_${
          standardizedQuery.replace(/[^a-z0-9]/g, "_")
        }`;
        const aggregatedSearchRef = admin.firestore()
            .collection("analytics")
            .doc(aggregatedDocId);

        try {
          await admin.firestore().runTransaction(async (transaction) => {
            const doc = await transaction.get(aggregatedSearchRef);
            if (doc.exists) {
              const newCount = (doc.data().searchCount || 0) + 1;
              transaction.update(aggregatedSearchRef, {
                searchCount: newCount,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
              });
            } else {
              transaction.set(aggregatedSearchRef, {
                id: aggregatedDocId,
                bookTitle: rawSearchQuery,
                searchCount: 1,
                bookId: bookId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                document_type: "aggregated_search",
              });
            }
          });
          console.log(`Aggregated search for '${rawSearchQuery}'.`);
        } catch (error) {
          console.error(`Error aggregating search for '${rawSearchQuery}':`,
              error);
        }
      }
      return null;
    });

exports.aggregateDailyTraffic = functions.firestore
    .document("analytics/{docId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const timestamp = data.timestamp ? data.timestamp.toDate() : new Date();
      const dateOnly = new Date(timestamp.getFullYear(),
          timestamp.getMonth(), timestamp.getDate());
      const dateId = dateOnly.toISOString().substring(0, 10);

      const aggregatedDocId = `AGG_TRAFFIC_${dateId}`;
      const dailyTrafficRef = admin.firestore()
          .collection("analytics")
          .doc(aggregatedDocId);

      try {
        await admin.firestore().runTransaction(async (transaction) => {
          const doc = await transaction.get(dailyTrafficRef);
          if (doc.exists) {
            const newCount = (doc.data().searchCount || 0) + 1;
            transaction.update(dailyTrafficRef, {
              searchCount: newCount,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(dailyTrafficRef, {
              id: aggregatedDocId,
              searchCount: 1,
              bookId: "",
              bookTitle: "Daily Traffic",
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              document_type: "aggregated_traffic",
            });
          }
        });
        console.log(`Aggregated daily traffic for '${dateId}'.`);
      } catch (error) {
        console.error(`Error aggregating daily traffic for '${dateId}':`,
            error);
      }
      return null;
    });
