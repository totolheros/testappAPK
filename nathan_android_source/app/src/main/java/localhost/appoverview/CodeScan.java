package localhost.appoverview;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.LinearLayout;
import android.widget.Toast;

import com.google.zxing.Result;

import java.util.ArrayList;

import me.dm7.barcodescanner.zxing.ZXingScannerView;


public class CodeScan extends Activity implements ZXingScannerView.ResultHandler {

    private static final String FLASH_STATE = "FLASH_STATE";
    private static final String AUTO_FOCUS_STATE = "AUTO_FOCUS_STATE";
    private static final String SELECTED_FORMATS = "SELECTED_FORMATS";
    private ZXingScannerView mScannerView;
    private boolean mFlash;
    private boolean mAutoFocus;
    private ArrayList<Integer> mSelectedIndices;
    private ArrayList<String> protocols;
    private LinearLayout scanView;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);

        protocols = (ArrayList<String>) getIntent().getSerializableExtra("protocols");

        //remove ProgressDialog
        Application.scanProgress.dismiss();

        if(state != null) {
            mFlash = state.getBoolean(FLASH_STATE, false);
            mAutoFocus = state.getBoolean(AUTO_FOCUS_STATE, true);
            mSelectedIndices = state.getIntegerArrayList(SELECTED_FORMATS);
        } else {
            mFlash = false;
            mAutoFocus = true;
            mSelectedIndices = null;
        }

        mScannerView = new ZXingScannerView(this);

        setContentView(mScannerView);
    }

    @Override
    public void onResume() {
        super.onResume();
        mScannerView.setResultHandler(this);
        mScannerView.startCamera();
        mScannerView.setFlash(mFlash);
        mScannerView.setAutoFocus(mAutoFocus);
    }

    @Override
    public void onPause() {
        super.onPause();
        mScannerView.stopCamera();
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putBoolean(FLASH_STATE, mFlash);
        outState.putBoolean(AUTO_FOCUS_STATE, mAutoFocus);
        outState.putIntegerArrayList(SELECTED_FORMATS, mSelectedIndices);
    }

    @Override
    public void handleResult(Result result) {
        final String content = result.getText();
        String format = result.getBarcodeFormat().toString();

        boolean foundProtocol = false;

        for(int i = 0; i < protocols.size(); i++) {
            String protocol = protocols.get(i);

            if(content.startsWith(protocol)) {
                 if(protocol.equals("http:") || protocol.equals("https:")) {
                     Intent intent = new Intent(this, Browser.class);
                     intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                     intent.putExtra("url", content);
                     startActivity(intent);
                 } else if(protocol.equals("tel:") || protocol.equals("geo:")) {
                     startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(content)));
                 } else if(protocol.equals("sendback:")) {
                     String value = content.substring(("sendback:").length());
                     Application.webView.loadUrl("javascript:if(window.Application) { Application.fireCallback('success', 'openScanCamera', '"+value+"'); }");
                     this.finish();
                 }
                foundProtocol = true;
            } else if(protocol.equals("ctc:")) {
                AlertDialog.Builder adbuilder = new AlertDialog.Builder(this);
                adbuilder.setMessage(content)
                        .setPositiveButton(R.string.done, new DialogInterface.OnClickListener() {
                            public void onClick(DialogInterface dialog, int id) {
                                mScannerView.startCamera();
                            }
                        })
                        .setNeutralButton(R.string.copy, new AlertDialog.OnClickListener() {
                            public void onClick(DialogInterface dialog, int id) {
                                ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                                ClipData clip = ClipData.newPlainText("codescan", content);
                                clipboard.setPrimaryClip(clip);
                                Toast.makeText(getApplicationContext(), R.string.copied_success, Toast.LENGTH_LONG).show();
                                mScannerView.startCamera();
                            }
                        });
                AlertDialog dialog = adbuilder.create();
                dialog.show();
                foundProtocol = true;
            }
        }

        if(!foundProtocol) {
            AlertDialog.Builder adbuilder = new AlertDialog.Builder(this);
            adbuilder.setMessage(R.string.qrcode_unsupported)
                .setPositiveButton(R.string.done, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        CodeScan.this.finish();
                    }
                });
            AlertDialog dialog = adbuilder.create();
            dialog.show();
        }
    }
}
