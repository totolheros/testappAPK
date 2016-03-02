package localhost.appoverview;

import android.app.Activity;
import android.app.ProgressDialog;
import android.os.Bundle;
import android.util.Log;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;


public class HTML5MediaPlayer extends Activity {

    public static WebView webView;
    public static Boolean webViewIsLoaded = false;
    public static String videoUrl = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        if(webViewIsLoaded) return;

        Log.i("HTML5MediaPlayer", "Creating the Activity");
        super.onCreate(savedInstanceState);

        setContentView(R.layout.application);

        String videoId = (String) getIntent().getSerializableExtra("videoId");
        String type = (String) getIntent().getSerializableExtra("videoType");

        Log.i("HTML5MediaPlayer - HTML5MediaPlayer - videoId", videoId);
        Log.i("HTML5MediaPlayer - HTML5MediaPlayer - videoType", type);
        if(type.contains("youtube")) {
            Log.i("HTML5MediaPlayer - HTML5MediaPlayer - Type is", "youtube");
            videoUrl = "http://www.youtube.com/embed/"+videoId;
        } else if(type.contains("vimeo")) {
            Log.i("HTML5MediaPlayer - HTML5MediaPlayer - Type is", "vimeo");
            videoUrl = "http://player.vimeo.com/video/"+videoId;
        } else {
            Log.e("HTML5MediaPlayer", "Unable to find the video type");
            finish();
        }

        webView = (WebView) findViewById(R.id.webView);
        webView.getSettings().setUserAgentString(webView.getSettings().getUserAgentString() + " type/siberian.application");
        WebSettings settings = webView.getSettings();

        settings.setJavaScriptEnabled(true);
        final ProgressDialog pd = ProgressDialog.show(HTML5MediaPlayer.this, "",
                this.getApplicationContext().getString(R.string.load_message), true);
        webView.setInitialScale(1);
        settings.setGeolocationEnabled(true);
        settings.setUseWideViewPort(true);
        settings.setJavaScriptCanOpenWindowsAutomatically(true);
        settings.setSupportZoom(true);
        settings.setSupportMultipleWindows(true);
        settings.setBuiltInZoomControls(true);
        settings.setDisplayZoomControls(true);
        settings.setLoadWithOverviewMode(true);

        webView.setWebViewClient(new WebViewClient() {
            public void onPageFinished(WebView view, String url) {
                pd.dismiss();
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {});

        Log.i("Loading URL", videoUrl);
        // "http://player.vimeo.com/video/10330375?api=1"
        webView.loadUrl(videoUrl);

        webViewIsLoaded = true;
    }

    @Override
    public void onBackPressed() {
        finish();
    }

    @Override
    public void finish() {

        webView.clearHistory();
        webView.clearCache(true);
        webView.loadUrl("about:blank");
        webViewIsLoaded = false;

        super.finish();
    }

}
