package localhost.appoverview;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.Display;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ListAdapter;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import localhost.appoverview.util.AudioPlayer;
import localhost.appoverview.util.CommonUtilities;
import localhost.appoverview.util.SocialSharing;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.InputStream;

public class AudioMediaPlayer extends Activity {

    private SocialSharing socialSharing;
    private AudioPlayer audioPlayer;
    private ImageButton playlist;
    private ImageView audioMediaPlayerImage;
    private ListView playlist_view;
    private Animation slide_from_left, slide_to_left;
    private RelativeLayout playlist_layout;

    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.media_player);

        socialSharing = new SocialSharing(this);

        slide_from_left = AnimationUtils.loadAnimation(getApplicationContext(), android.R.anim.slide_in_left);
        slide_to_left = AnimationUtils.loadAnimation(getApplicationContext(), R.anim.slide_out_left);
        audioMediaPlayerImage = (ImageView) findViewById(R.id.audio_media_player_image);
        playlist_layout = (RelativeLayout) findViewById(R.id.playlist_frame);

        //initialize the media playerca
        audioPlayer = initAudioPlayer();

        setCoverImage();
    }

    private AudioPlayer initAudioPlayer() {
        playlist = (ImageButton) findViewById(R.id.media_playlist);

        Boolean isRadio = getIntent().getBooleanExtra("isRadio", false);
        int audioPlaylistOffset = getIntent().getIntExtra("audioOffset", 0);
        String albums = getIntent().getStringExtra("albums");
        String audioPlaylist = getIntent().getStringExtra("audioPlaylist");

        if(isRadio) {
            playlist.setVisibility(View.GONE);
        } else {
            playlist.setVisibility(View.VISIBLE);
        }

        AudioPlayer iAudioPlayer;
        if(AudioPlayer.getInstance() != null) {
            iAudioPlayer = AudioPlayer.getInstance();
            iAudioPlayer.updatePlayer(this, isRadio, audioPlaylistOffset, audioPlaylist, albums);
            iAudioPlayer.initAudioMediaPlayerButtons();
        } else {
            iAudioPlayer = new AudioPlayer(this, isRadio, audioPlaylistOffset, audioPlaylist, albums);
        }

        //set the playlist view
        final AudioPlayer.PlaylistAdapter playlistAdapter = iAudioPlayer.getPlaylistAdapter();

        playlist_view = (ListView) findViewById(R.id.playlist);
        playlist_view.setAdapter(playlistAdapter);
        playlist_view.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                if(playlistAdapter != null) {
                    playlistAdapter.currentOffset = position;
                    playlistAdapter.notifyDataSetChanged();
                }

                audioPlayer.setAudioPlaylistOffset(position);
                setCoverImage();
                audioPlayer.initGenericMediaButtons();

                playlist_view.startAnimation(slide_to_left);
                playlist_layout.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        playlist_layout.setVisibility(View.GONE);
                    }
                }, slide_to_left.getDuration());
            }
        });

        //return the AudioPlayer instance
        return iAudioPlayer;
    }

    private void setCoverImage() {
        //set the cover image
        int album_offset = 0;
        String cover = "";

        if(!audioPlayer.isRadio) {
            try {
                if(audioPlayer.getAudioPlaylist().getJSONObject(audioPlayer.getAudioPlaylistOffset()).has("albumId")) {
                    album_offset = audioPlayer.getAudioPlaylist().getJSONObject(audioPlayer.getAudioPlaylistOffset()).getInt("albumId");
                    cover = audioPlayer.getAlbums().getJSONObject(album_offset).getString("artworkUrl");

                    if(cover.contains("default_album")) {
                        cover = "";
                    } else if(!cover.startsWith("http:") && !cover.startsWith("https:")) {
                        cover = CommonUtilities.SERVEUR_URL + cover;
                    }
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        if (!cover.equals("")) {
            new DownloadImage().execute(cover);
        } else {
            audioMediaPlayerImage.setImageResource(R.drawable.startup_image);
        }
    }

    public void purchase(View v) {
        Intent intent = new Intent(this, Browser.class);
        intent.putExtra("url", audioPlayer.getPurchaseUrl());
        startActivity(intent);
    }

    public void playlist(View v) {
        playlist_view.startAnimation(slide_from_left);
        playlist_layout.setVisibility(View.VISIBLE);
    }

    public void share(View v) {
        String sharing_text;
        if(audioPlayer.isRadio) {
            sharing_text = String.format(getString(R.string.sharing_radioplayer_text), "\"" + audioPlayer.getAudioTitle() + "\"", getString(R.string.app_name));
        } else {
            sharing_text = String.format(getString(R.string.sharing_audioplayer_text), "\"" + audioPlayer.getAudioTitle() + "\"", "\"" + audioPlayer.getAudioArtist() + "\"",getString(R.string.app_name));
        }

        socialSharing.open("", "", "", "", "", sharing_text);
    }

    public void minimize(View v) {
        finish();
    }

    public void close(View v) {
        audioPlayer.destroy();
        finish();
    }

    @Override
    public void onBackPressed() {
        if(playlist_layout.getVisibility() == View.VISIBLE) {
            playlist_view.startAnimation(slide_to_left);
            playlist_layout.postDelayed(new Runnable() {
                @Override
                public void run() {
                    playlist_layout.setVisibility(View.GONE);
                }
            }, slide_to_left.getDuration());
        } else if(socialSharing.isVisible()) {
            socialSharing.close();
        } else {
            finish();
        }
    }

    // DownloadImage AsyncTask
    private class DownloadImage extends AsyncTask<String, Void, Bitmap> {

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
        }

        @Override
        protected Bitmap doInBackground(String... URL) {

            Display display = getWindowManager().getDefaultDisplay();
            int width = display.getWidth() > display.getHeight() ? display.getHeight() : display.getWidth();
            width -= 40;

            String imageURL = URL[0].replace("100x100bb", width + "x" + width + "bb");

            Bitmap bitmap = null;
            try {
                // Download Image from URL
                InputStream input = new java.net.URL(imageURL).openStream();
                // Decode Bitmap
                bitmap = BitmapFactory.decodeStream(input);
            } catch (Exception e) {
                e.printStackTrace();
            }
            return bitmap;
        }

        @Override
        protected void onPostExecute(Bitmap result) {
            audioMediaPlayerImage.setImageBitmap(result);
        }
    }
}