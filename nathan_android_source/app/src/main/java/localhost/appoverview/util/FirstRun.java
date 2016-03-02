package localhost.appoverview.util;

import android.content.SharedPreferences;
import android.util.Log;

public class FirstRun {

    private static final String TAG = "FirstRun";

    public static boolean isFirstRunning(SharedPreferences prefs) {
        Log.e(TAG, "isFirstRunning");

        boolean first_running = prefs.getBoolean("firstRunning", true);
        if(first_running) {
            prefs.edit().putBoolean("firstRunning", false).commit();
        }

        return first_running;
    }

}