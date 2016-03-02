/*
 * Copyright 2012 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package localhost.appoverview.util;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.os.AsyncTask;
import android.util.Log;

import localhost.appoverview.Application;

import java.io.DataOutputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.charset.Charset;

/**
 * Helper class providing methods and constants common to other classes in the
 * app.
 */
public final class CommonUtilities {

    public static final String APP_ID = "1";

    public static final String WEBVIEW_RESULT_IDENTIFIER = "webview_result_identifier";
    public static final int WEBVIEW_RESULTCODE = 2;

    public static final String SERVEUR_URL = "http://localhost/";

    public static final String REGISTER_DEVICE_URL = "push/android/registerdevice";

    static final String MARK_DISPLAYED_URL = "push/android/markdisplayed";

    static final String UPDATE_POSITION_URL = "push/android/updateposition";

    public static final String SENDER_ID = "";

    public static final String PROPERTY_REG_ID = "registration_id";
    public static final String PROPERTY_APP_VERSION = "app_id";

    static final int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;

    /**
     * Tag used on log messages.
     */
    public static final String TAG = "GCMRegistration";

    /**
     * Intent used to display a message in the screen.
     */
    static final String DISPLAY_MESSAGE_ACTION =
            "com.siberian.app.DISPLAY_MESSAGE";

    /**
     * Intent's extra that contains the message to be displayed.
     */
    static final String EXTRA_MESSAGE = "message";

    public static Boolean isInsideLocation(Context context, Location current_location, Location searchLocation, double radiusLocation) {

        if(current_location == null) {
            current_location = getLastBestLocation(context);
        }

        if(current_location != null) {
            float distanceMeters = current_location.distanceTo(searchLocation);
            return (distanceMeters <= radiusLocation);
        } else {
            return false;
        }
    }

    public static void markAsDisplayed(String message_id) {
        new AsyncPost(message_id).execute();
    }

    private static Location getLastBestLocation(Context pContext) {
        LocationManager locationManager = (LocationManager) pContext.getSystemService(Context.LOCATION_SERVICE);
        Location locationGPS = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
        Location locationNet = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);

        long GPSLocationTime = 0;
        if (null != locationGPS) {
            GPSLocationTime = locationGPS.getTime();
        }

        long NetLocationTime = 0;
        if (null != locationNet) {
            NetLocationTime = locationNet.getTime();
        }

        if ( 0 < GPSLocationTime - NetLocationTime ) {
            Log.e(TAG, "Located by GPS");
            return locationGPS;
        } else {
            Log.e(TAG, "Located by network");
            return locationNet;
        }
    }

    public static class AsyncPost extends AsyncTask<String, Void, String> {

        private String message_id;

        public AsyncPost(String pMessage_id){
            message_id = pMessage_id;
        }

        @Override
        protected String doInBackground(String... urls) {

            String server_url = CommonUtilities.SERVEUR_URL + CommonUtilities.MARK_DISPLAYED_URL;
            String params = "registration_id=" + Application.regid + "&message_id=" + message_id;

            try {
                post(server_url, params);

                return "marked as displayed";
            } catch (IOException e) {
                e.printStackTrace();
                return "failed to mark as displayed";
            }

        }

        private void post(String endpoint, String params) throws IOException {

            URL url;
            try {
                url = new URL(endpoint);
            } catch (MalformedURLException e) {
                throw new IllegalArgumentException("invalid url: " + endpoint);
            }

            byte[] postData = params.getBytes( Charset.forName("UTF-8"));
            int postDataLength = postData.length;
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();

            conn.setDoOutput(true);
            conn.setDoInput(true);
            conn.setInstanceFollowRedirects(false);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            conn.setRequestProperty("charset", "utf-8");
            conn.setRequestProperty("Content-Length", Integer.toString( postDataLength));
            conn.setUseCaches(false);

            try {

                DataOutputStream wr = new DataOutputStream( conn.getOutputStream());
                wr.write( postData );
                wr.close();

                int status = conn.getResponseCode();
                if (status != 200) {
                    throw new IOException("Post failed with error code " + status);
                }

                conn.disconnect();

            } catch (IOException e) {
                Log.e(CommonUtilities.TAG, e.getMessage());
            } finally {
                if (conn != null) {
                    conn.disconnect();
                }
            }

        }

    }

}
