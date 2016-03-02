package localhost.appoverview.util;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import localhost.appoverview.Application;
import localhost.appoverview.Browser;
import localhost.appoverview.R;
import com.facebook.share.model.ShareLinkContent;
import com.facebook.share.widget.ShareDialog;
import com.google.android.gms.plus.PlusShare;

import java.util.ArrayList;

public class SocialSharing {

    static final String TAG = "SocialSharing";

    protected Activity activity;

    private static String fbkSharer = "https://www.facebook.com/sharer/sharer.php?u=";
    private static String twtSharer = "https://twitter.com/intent/tweet?";
    private static String gglSharer = "https://plus.google.com/share?url=";

    private Animation slide_down, slide_up;
    private RelativeLayout list_view_layout;
    public ListView listView;

    public SocialSharing(Activity p_activity) {
        activity = p_activity;
        slide_down = AnimationUtils.loadAnimation(activity.getApplicationContext(), R.anim.slide_down);
        slide_up = AnimationUtils.loadAnimation(activity.getApplicationContext(), R.anim.slide_up);
        list_view_layout = (RelativeLayout) activity.findViewById(R.id.list_frame);
    }

    public void open(final String pageName, final String picture, final String contentUrl, final String storeUrl, final String contentMessage, final String customSharingText) {

        final PackageManager pm = activity.getPackageManager();
        String txtMessage = "", txtEmail = "";

        final ArrayList<String> itemname = new ArrayList<String>();
        itemname.add("Facebook");
        itemname.add("Twitter");
        itemname.add("Google+");

        ArrayList<Integer> itemicon = new ArrayList<Integer>();
        itemicon.add(R.drawable.facebook_icon);
        itemicon.add(R.drawable.twitter_icon);
        itemicon.add(R.drawable.googlep_icon);

        try {
            //check if message application is there
            pm.getPackageInfo("com.android.mms", PackageManager.GET_ACTIVITIES);
            txtMessage = pm.getApplicationLabel(pm.getApplicationInfo("com.android.mms", PackageManager.GET_ACTIVITIES)).toString();
            itemname.add(txtMessage);
            itemicon.add(R.drawable.message_icon);
        } catch (PackageManager.NameNotFoundException e) {
        }

        final String finalTextMessage = txtMessage;

        try {
            //check if email application is there
            pm.getPackageInfo("com.android.email", PackageManager.GET_ACTIVITIES);
            txtEmail = pm.getApplicationLabel(pm.getApplicationInfo("com.android.email", PackageManager.GET_ACTIVITIES)).toString();
            itemname.add(txtEmail);
            itemicon.add(R.drawable.email_icon);
        } catch (PackageManager.NameNotFoundException e) {
        }

        final String finalTextEmail = txtEmail;

        CustomListAdapter adapter=new CustomListAdapter(activity, itemname, itemicon);
        listView = (ListView) activity.findViewById(R.id.list);

        listView.setAdapter(adapter);
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {

                String selectedItem = itemname.get(position);
                String packageName = null, shareText = null, shareContent = null, shareUrl = null;

                if(contentMessage != "null" && contentMessage != "") {
                    shareContent = contentMessage;
                } else {
                    shareContent = pageName;
                }

                shareUrl = CommonUtilities.SERVEUR_URL + "application/device/downloadapp/app_id/" + CommonUtilities.APP_ID;
                shareText = customSharingText != null ? customSharingText : String.format(activity.getString(R.string.sharing_text), "\"" + shareContent + "\"", activity.getString(R.string.app_name));

                String baseUrl = activity.getString(R.string.url);
                baseUrl = baseUrl.substring(0, baseUrl.indexOf("/", 10));
                String sharePicture = "";
//                String sharePicture = !picture.equals("null") && !picture.equals("") ? baseUrl+picture : "";
                String error_text = "";

                if(selectedItem == "Facebook") {

                    /**
                     * CREATE AN APP ON https://developers.facebook.com/apps
                     * AND FILL THE FACEBOOK APPID FIELD ON YOUR EDITOR
                     **/
                    try {
                        ShareDialog shareDialog = new ShareDialog(activity);
                        if (ShareDialog.canShow(ShareLinkContent.class)) {
                            ShareLinkContent linkContent = new ShareLinkContent.Builder()
                                .setContentTitle(pageName)
                                .setContentDescription(shareText)
                                .setContentUrl(Uri.parse(shareUrl))
//                                .setImageUrl(Uri.parse(sharePicture))
                                .build();

                            shareDialog.show(linkContent);
                        }
                    } catch (Exception e) {
                        error_text = String.format(activity.getString(R.string.sharing_error), "Facebook");
                    }
                } else if(selectedItem == "Twitter") {

                    try {
                        Intent twitter = new Intent(activity, Browser.class);

                        try {
                            pm.getPackageInfo("com.twitter.android", PackageManager.GET_ACTIVITIES);

                            twitter = new Intent(Intent.ACTION_SEND);
                            twitter.setPackage("com.twitter.android");

                            twitter.setType("image/*");
                            if(!sharePicture.equals("")) {
//                                twitter.putExtra(Intent.EXTRA_STREAM, Uri.parse(sharePicture));
                            }

                            twitter.putExtra(Intent.EXTRA_TEXT, shareText + " " + shareUrl);
                        } catch (PackageManager.NameNotFoundException e) {
                            twitter.putExtra("url", twtSharer + "text=" + shareText + "&url=" + shareUrl);
                            twitter.putExtra(Intent.EXTRA_TEXT, "Twitter");
                        }
                        twitter.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

                        activity.startActivity(twitter);
                    } catch (Exception e) {
                        error_text = String.format(activity.getString(R.string.sharing_error), "Twitter");
                    }

                } else if(selectedItem == "Google+") {

                    try {
                        Intent shareIntent = new PlusShare.Builder(activity.getApplicationContext())
                            .setType("text/plain")
                            .setText(shareText + " " + shareUrl)
//                            .setContentUrl(Uri.parse(shareUrl))
                            .getIntent();

                        activity.startActivityForResult(shareIntent, 0);
                    } catch (Exception e) {
                        error_text = String.format(activity.getString(R.string.sharing_error), "Google+");
                    }

                } else if(selectedItem == finalTextMessage || selectedItem == finalTextEmail) {

                    if(selectedItem == finalTextMessage) {
                        packageName = "com.android.mms";
                    } else {
                        packageName = "com.android.email";
                    }

                    Intent targetedShareIntent = new Intent(android.content.Intent.ACTION_SEND);
                    targetedShareIntent.setType("text/plain");
                    targetedShareIntent.putExtra(Intent.EXTRA_TEXT, shareText + " " + shareUrl);
                    targetedShareIntent.setPackage(packageName);

                    activity.startActivity(targetedShareIntent);

                }

                listView.startAnimation(slide_down);
                list_view_layout.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        list_view_layout.setVisibility(View.GONE);
                    }
                }, slide_down.getDuration());

                if(!error_text.equals("")) {
                    Toast.makeText(activity.getApplicationContext(), error_text, Toast.LENGTH_SHORT).show();
                }
            }
        });

        list_view_layout.setVisibility(View.VISIBLE);
        listView.startAnimation(slide_up);

        list_view_layout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                listView.startAnimation(slide_down);
                v.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        list_view_layout.setVisibility(View.GONE);
                    }
                }, slide_down.getDuration());
            }
        });
    }

    public boolean isVisible() {
        return list_view_layout.getVisibility() == View.VISIBLE;
    }

    public void close() {
        list_view_layout.performClick();
    }
}

class CustomListAdapter extends ArrayAdapter<String> {
    private final Activity context;
    private final ArrayList<String> itemname;
    private final ArrayList<Integer> imgid;

    public CustomListAdapter(Activity context, ArrayList<String> itemname, ArrayList<Integer> imgid) {
        super(context, R.layout.customlist, itemname);

        this.context=context;
        this.itemname=itemname;
        this.imgid=imgid;
    }

    public View getView(int position, View view, ViewGroup parent) {
        LayoutInflater inflater=context.getLayoutInflater();
        View rowView = inflater.inflate(R.layout.customlist, null, true);

        TextView txtTitle = (TextView) rowView.findViewById(R.id.itemName);
        ImageView imageView = (ImageView) rowView.findViewById(R.id.itemIcon);

        txtTitle.setText(itemname.get(position));
        imageView.setImageResource(imgid.get(position));

        return rowView;
    };
}