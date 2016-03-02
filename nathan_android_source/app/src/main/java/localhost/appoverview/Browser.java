package localhost.appoverview;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.ImageButton;

import localhost.appoverview.util.CommonUtilities;

public class Browser extends Activity {
    private ImageButton bBack;
    private ImageButton bForward;
    private ImageButton bReload;
    private Button bDone;
    private WebView webView;
    private boolean mIsLoadFinish = false;

    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.browser);

        webView = (WebView) findViewById(R.id.webView);
        webView.getSettings().setSupportZoom(true);
        webView.getSettings().setBuiltInZoomControls(true);
        webView.getSettings().setDisplayZoomControls(false);

        webView.getSettings().setUseWideViewPort(true);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setUseWideViewPort(true);
        webView.getSettings().setJavaScriptCanOpenWindowsAutomatically(true);
        webView.setScrollBarStyle(WebView.SCROLLBARS_INSIDE_OVERLAY);

        webView.addJavascriptInterface(new JsInterface(), "android");

        bBack = (ImageButton) findViewById(R.id.bBack);
        bForward = (ImageButton) findViewById(R.id.bForward);
        bReload = (ImageButton) findViewById(R.id.bReload);
        bDone = (Button) findViewById(R.id.bDone);

        String url = (String) getIntent().getSerializableExtra("url");

        // Setup for button controller
        bReload.setOnClickListener(new ImageButton.OnClickListener() {
            @Override
            public void onClick(View v) {
                webView.reload();
                enableControllerButton();
            }
        });
        bBack.setOnClickListener(new ImageButton.OnClickListener() {
            @Override
            public void onClick(View v) {
                webView.goBack();
                enableControllerButton();
            }
        });
        bForward.setOnClickListener(new ImageButton.OnClickListener() {
            @Override
            public void onClick(View v) {
                webView.goForward();
                enableControllerButton();
            }
        });

        bDone.setOnClickListener(new ImageButton.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                Log.i("url : ", url);
                if (url.contains("close/1") || Application.webView.getUrl().equals(url)) {
                    finish();
                    return false;
                } else {
                    view.loadUrl(url);
                }
                return true;
            }

            @Override
            public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon) {

            }

            @Override
            public void onPageFinished(WebView view, String url) {
                mIsLoadFinish = true;
                enableControllerButton();

                if (url.contains("https://m.facebook.com") && url.contains("/dialog/oauth")) {
                    view.loadUrl("javascript:window.android.getHtml(document.body.innerHTML);");
                }
            }
        });

        webView.setWebChromeClient(new WebChromeClient());

        webView.loadUrl(url);
    }

    @Override
    public void onBackPressed() {
        finish();
    }

    public void closeFacebook() {
        Intent resultIntent = new Intent();
        resultIntent.putExtra(CommonUtilities.WEBVIEW_RESULT_IDENTIFIER, "facebook");
        setResult(CommonUtilities.WEBVIEW_RESULTCODE, resultIntent);
        finish();
    }

    public void enableControllerButton() {

        if (mIsLoadFinish) {
            bReload.setEnabled(true);
            if (webView.canGoBack()) {
                bBack.setClickable(true);
                bBack.setEnabled(true);
                bBack.setAlpha(1f);
            } else {
                bBack.setClickable(false);
                bBack.setEnabled(false);
                bBack.setAlpha(0.5f);
            }
            if (webView.canGoForward()) {
                bForward.setClickable(true);
                bForward.setEnabled(true);
                bForward.setAlpha(1f);
            } else {
                bForward.setClickable(false);
                bForward.setEnabled(false);
                bForward.setAlpha(0.5f);
            }
        } else {
            bBack.setClickable(false);
            bBack.setEnabled(false);
            bForward.setClickable(false);
            bForward.setEnabled(false);
            bBack.setAlpha(0.5f);
            bForward.setAlpha(0.5f);
        }
    }

    class JsInterface {

        @JavascriptInterface
        public void getHtml(String html) {

            if(html.isEmpty()) {
                Browser.this.runOnUiThread(new Runnable() {
                    public void run() {
                        Browser.this.closeFacebook();
                    }
                });
            }
        }

    }

}