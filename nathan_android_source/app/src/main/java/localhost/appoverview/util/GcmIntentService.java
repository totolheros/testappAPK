/*
 * Copyright (C) 2013 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package localhost.appoverview.util;

import android.app.IntentService;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.location.Location;
import android.os.Bundle;
import android.os.SystemClock;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import localhost.appoverview.Application;
import localhost.appoverview.R;
import com.google.android.gms.gcm.GoogleCloudMessaging;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * This {@code IntentService} does the actual handling of the GCM message.
 * {@code GcmBroadcastReceiver} (a {@code WakefulBroadcastReceiver}) holds a
 * partial wake lock for this service while the service does its work. When the
 * service is finished, it calls {@code completeWakefulIntent()} to release the
 * wake lock.
 */
public class GcmIntentService extends IntentService {

    public static final int NOTIFICATION_ID = 1;
    private NotificationManager mNotificationManager;

    public GcmIntentService() {
        super("GcmIntentService");
    }
    public static final String TAG = "GCM Demo";

    @Override
    protected void onHandleIntent(Intent intent) {
        Bundle extras = intent.getExtras();
        GoogleCloudMessaging gcm = GoogleCloudMessaging.getInstance(this);
        // The getMessageType() intent parameter must be the intent you received
        // in your BroadcastReceiver.
        String messageType = gcm.getMessageType(intent);

        if (!extras.isEmpty()) {  // has effect of unparcelling Bundle
            /*
             * Filter messages based on message type. Since it is likely that GCM will be
             * extended in the future with new message types, just ignore any message types you're
             * not interested in, or that you don't recognize.
             */

            if(extras.getString("radius") != null && Float.parseFloat(extras.getString("radius")) != 0 &&
                    extras.getString("latitude") != null &&
                    extras.getString("longitude") != null) {

                Log.e(TAG, extras.toString());

                String target_latitude = extras.getString("latitude");
                String target_longitude = extras.getString("longitude");
                double target_radius = Double.parseDouble(extras.getString("radius"))*1000;

                Location target_location = new Location("target");
                target_location.setLatitude(Double.parseDouble(target_latitude));
                target_location.setLongitude(Double.parseDouble(target_longitude));

                Log.e(TAG, "TargetLocation: " + target_location);

                if(CommonUtilities.isInsideLocation(this, null, target_location, target_radius)) {
                    Log.e(TAG, "isInsideRegion, send push notification");
                    sendNotificationSuccess(extras);
                } else {
                    addProximityAlert(extras, target_location, target_radius);
                }

            } else {

                Log.e("NORMAL", "normal notif");

                if (GoogleCloudMessaging.MESSAGE_TYPE_SEND_ERROR.equals(messageType)) {
                    sendNotification("Send error: " + extras.toString());
                } else if (GoogleCloudMessaging.MESSAGE_TYPE_DELETED.equals(messageType)) {
                    sendNotification("Deleted messages on server: " + extras.toString());
                    // If it's a regular GCM message, do some work.
                } else if (GoogleCloudMessaging.MESSAGE_TYPE_MESSAGE.equals(messageType)) {
                    // This loop represents the service doing some work.
                    for (int i = 0; i < 5; i++) {
                        Log.i(TAG, "Working... " + (i + 1)
                                + "/5 @ " + SystemClock.elapsedRealtime());
                        try {
                            Thread.sleep(5000);
                        } catch (InterruptedException e) {
                        }
                    }
                    Log.i(TAG, "Completed work @ " + SystemClock.elapsedRealtime());
                    // Post notification of received message.
                    sendNotificationSuccess(extras);
                    Log.i(TAG, "Received: " + extras.toString());
                }

            }
        }
        // Release the wake lock provided by the WakefulBroadcastReceiver.
        GcmBroadcastReceiver.completeWakefulIntent(intent);
    }

    // Put the message into a notification and post it.
    // This is just one simple example of what you might choose to do with
    // a GCM message.
    private void sendNotification(String msg) {
        mNotificationManager = (NotificationManager)
                this.getSystemService(Context.NOTIFICATION_SERVICE);

        PendingIntent contentIntent = PendingIntent.getActivity(this, 0,
                new Intent(this, Application.class), 0);

        NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(this)
            .setSmallIcon(R.drawable.push_icon)
            .setContentTitle(this.getApplicationContext().getString(R.string.url))
            .setStyle(new NotificationCompat.BigTextStyle()
            .bigText(msg))
            .setContentText(msg)
        ;

        mBuilder.setAutoCancel(true);
        mBuilder.setContentIntent(contentIntent);
        mNotificationManager.notify(NOTIFICATION_ID, mBuilder.build());
    }

    private void sendNotificationSuccess(Bundle extras) {
        mNotificationManager = (NotificationManager)
                this.getSystemService(Context.NOTIFICATION_SERVICE);

        PendingIntent contentIntent = PendingIntent.getActivity(this, 0,
                new Intent(this, Application.class), 0);

        NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(this)
            .setDefaults(Notification.DEFAULT_ALL)
            .setSmallIcon(R.drawable.push_icon)
            .setContentTitle(extras.getString("title"))
            .setStyle(new NotificationCompat.BigTextStyle()
                    .bigText(extras.getString("message")))
            .setContentText(extras.getString("message"))
        ;

        mBuilder.setAutoCancel(true);
        mBuilder.setContentIntent(contentIntent);
        mNotificationManager.notify(NOTIFICATION_ID, mBuilder.build());

        CommonUtilities.markAsDisplayed(extras.getString("message_id"));
    }

    public static void sendLocalNotification(Context context, String title, String message, String message_id) {
        NotificationManager mNotificationManager = (NotificationManager)
                context.getSystemService(Context.NOTIFICATION_SERVICE);

        PendingIntent contentIntent = PendingIntent.getActivity(context, 0,
                new Intent(context, Application.class), 0);

        NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(context)
                .setDefaults(Notification.DEFAULT_ALL)
                .setSmallIcon(R.drawable.push_icon)
                .setContentTitle(title)
                .setStyle(new NotificationCompat.BigTextStyle()
                        .bigText(message))
                .setContentText(message)
                ;

        mBuilder.setAutoCancel(true);
        mBuilder.setContentIntent(contentIntent);
        mNotificationManager.notify(NOTIFICATION_ID, mBuilder.build());

        CommonUtilities.markAsDisplayed(message_id);
    }

    /** GEOLOCATED PUSH NOTIFICATIONS **/
    private void addProximityAlert(Bundle extras, Location target_location, double radius) {

        try {
            JSONObject alert = new JSONObject();
            alert.put("latitude", target_location.getLatitude());
            alert.put("longitude", target_location.getLongitude());
            alert.put("radius", radius);
            alert.put("title", extras.getString("title"));
            alert.put("message", extras.getString("message"));
            alert.put("send_until", extras.getString("send_until"));
            alert.put("message_id", extras.getString("message_id"));

            String key = "push" + extras.getString("message_id");
            SharedPreferences push_prefs = getSharedPreferences("geolocated_push", Context.MODE_APPEND);
            SharedPreferences.Editor editor = push_prefs.edit();
            editor.putString(key, alert.toString());
            editor.commit();
        } catch (JSONException e) {
            e.printStackTrace();
        }

    }
    /** /GEOLOCATED PUSH NOTIFICATIONS **/
}
