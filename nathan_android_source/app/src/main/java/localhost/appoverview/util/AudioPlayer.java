package localhost.appoverview.util;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Handler;
import android.util.Log;
import android.view.Display;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.BaseAdapter;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ListAdapter;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import localhost.appoverview.R;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Random;
import java.util.concurrent.TimeUnit;

public class AudioPlayer implements SeekBar.OnSeekBarChangeListener {

    private static AudioPlayer ourInstance;
    private final String TAG = "AudioPlayer";
    public static MediaPlayer player;

    //Views
    private TextView duration;
    private SeekBar seekbar;
    private ImageButton purchase;
    private ImageButton repeat;
    private ImageButton shuffle;
    private ImageButton next;
    private ImageButton forward;
    private ImageButton play_pause;
    private ImageButton rewind;
    private ImageButton previous;

    //Vars
    private Activity activity;
    private boolean isShuffling;
    private String repeatType;
    private JSONArray audioPlaylistShuffle;
    private TextView audioName;
    private int audioPlaylistMediaNumber;
    private String cover;
    private Uri audioUri;
    private Uri currentMediaUri;
    private String audioPurchaseUrl;
    private double finalTime;
    private ProgressDialog progressDialog;
    private int timeElapsed;
    private Handler durationHandler;
    private int forwardTime = 2000;
    private int backwardTime = 2000;
    private String audioTitle;
    private String audioArtist;
    private PlaylistAdapter playlistAdapter;

    public Boolean isRadio;
    public int audioPlaylistOffset;
    public JSONArray audioPlaylist;
    public JSONArray albums;

    public static AudioPlayer getInstance() {
        return ourInstance;
    }

    public AudioPlayer(Activity p_activity, Boolean p_isRadio, int p_audioPlaylistOffset, String p_audioPlaylist, String p_albums) {

        initVars(p_activity, p_isRadio, p_audioPlaylistOffset, p_audioPlaylist, p_albums);

        isShuffling = false;
        repeatType = "";

        ourInstance = this;

        initAudioMediaPlayerButtons();
    }

    private void initVars(Activity p_activity, Boolean p_isRadio, int p_audioPlaylistOffset, String p_audioPlaylist, String p_albums) {
        activity = p_activity;

        finalTime = 0;
        isRadio = p_isRadio;

        audioPlaylistShuffle = new JSONArray();
        audioPlaylistOffset = p_audioPlaylistOffset;
        try {
            audioPlaylist = new JSONArray(p_audioPlaylist);
            audioPlaylistMediaNumber = audioPlaylist.length() - 1;
            albums = new JSONArray(p_albums);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        duration = (TextView) activity.findViewById(R.id.audio_duration);

        playlistAdapter = new PlaylistAdapter(activity, audioPlaylist, audioPlaylistOffset);
    }

    private void initPlayer() {

        try {

            durationHandler = new Handler();

            if(!isRadio) {
                finalTime = audioPlaylist.getJSONObject(audioPlaylistOffset).getDouble("duration");
            }

            if(audioPlaylist.getJSONObject(audioPlaylistOffset).has("purchaseUrl")) {
                audioPurchaseUrl = audioPlaylist.getJSONObject(audioPlaylistOffset).getString("purchaseUrl");
            }

            audioUri = Uri.parse(audioPlaylist.getJSONObject(audioPlaylistOffset).getString("streamUrl"));
            audioTitle = audioPlaylist.getJSONObject(audioPlaylistOffset).getString("name");

            if(audioPlaylist.getJSONObject(audioPlaylistOffset).has("artistName")) {
                audioArtist = audioPlaylist.getJSONObject(audioPlaylistOffset).getString("artistName");
            }

            audioName.setText(audioTitle);
            seekbar.setMax((int) finalTime);

            if(player == null) {
                player = new MediaPlayer();
            }

            if(!audioUri.equals(currentMediaUri)) {
                progressDialog = ProgressDialog.show(activity, "", activity.getApplicationContext().getString(R.string.load_message), true, true, new DialogInterface.OnCancelListener() {
                    @Override
                    public void onCancel(DialogInterface dialogInterface) {
                        destroy();
                        activity.finish();
                    }
                });

                player.reset();
                player.setDataSource(activity.getApplicationContext(), audioUri);
                player.prepareAsync();
                player.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                    @Override
                    public void onPrepared(MediaPlayer mediaPlayer) {
                        play_pause();
                        progressDialog.dismiss();
                    }
                });
                player.setOnErrorListener(new MediaPlayer.OnErrorListener() {
                    @Override
                    public boolean onError(final MediaPlayer mp, final int what, final int extra) {
                        player.reset();
                        currentMediaUri = null;
                        progressDialog.dismiss();
                        Toast.makeText(activity.getApplicationContext(), R.string.audio_player_stream_error, Toast.LENGTH_LONG).show();
                        return true;
                    }
                });
                player.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
                    @Override
                    public void onCompletion(MediaPlayer mediaPlayer) {
                        if(currentMediaUri != null) {
                            if (repeatType == "one") {
                                player.seekTo(0);
                            } else {
                                next();
                            }
                        }
                    }
                });

                currentMediaUri = audioUri;
            }

            if(player != null && player.isPlaying()) {
                //transform into pause
                play_pause.setImageResource(R.drawable.ic_pause);
                refresh();
            }

            if(player.getCurrentPosition() > 0) {
                duration.setText(String.format("%02d:%02d", TimeUnit.MILLISECONDS.toMinutes((long) player.getCurrentPosition()), TimeUnit.MILLISECONDS.toSeconds((long) player.getCurrentPosition()) - TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes((long) player.getCurrentPosition()))));
            }

            playlistAdapter.currentOffset = audioPlaylistOffset;
            playlistAdapter.notifyDataSetChanged();

        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
    }

    public void initAudioMediaPlayerButtons() {
        //Views
        repeat = (ImageButton) activity.findViewById(R.id.media_repeat);
        rewind = (ImageButton) activity.findViewById(R.id.media_rewind);
        forward = (ImageButton) activity.findViewById(R.id.media_forward);
        shuffle = (ImageButton) activity.findViewById(R.id.media_shuffle);
        purchase = (ImageButton) activity.findViewById(R.id.media_purchase);

        initGenericMediaButtons();
    }

    public void initGenericMediaButtons() {
        audioName = (TextView) activity.findViewById(R.id.media_name);
        previous = (ImageButton) activity.findViewById(R.id.media_previous);
        play_pause = (ImageButton) activity.findViewById(R.id.media_play);
        next = (ImageButton) activity.findViewById(R.id.media_next);
        seekbar = (SeekBar) activity.findViewById(R.id.seek_bar);

        if(isRadio) {
            initForRadios();
        } else {
            initForMusics();
        }

        initButtonListeners();

        initPlayer();
    }

    private void initForMusics() {
        duration.setVisibility(View.VISIBLE);
        seekbar.setVisibility(View.VISIBLE);
        purchase.setVisibility(View.VISIBLE);
        seekbar.setClickable(true);
        seekbar.setOnSeekBarChangeListener(this);
        repeat.setClickable(true);
        repeat.getDrawable().setColorFilter(null);
        setRepeatDrawable();
        previous.setClickable(true);
        previous.getDrawable().setColorFilter(null);
        rewind.setClickable(true);
        rewind.getDrawable().setColorFilter(null);
        forward.setClickable(true);
        forward.getDrawable().setColorFilter(null);
        next.setClickable(true);
        next.getDrawable().setColorFilter(null);
        shuffle.setClickable(true);
        if(isShuffling) {
            shuffle.getDrawable().setColorFilter(activity.getResources().getColor(R.color.blue_audioplayer), PorterDuff.Mode.MULTIPLY);
        } else {
            shuffle.getDrawable().setColorFilter(null);
        }
    }

    private void initForRadios() {
        duration.setVisibility(View.GONE);
        seekbar.setVisibility(View.GONE);
        purchase.setVisibility(View.GONE);
        seekbar.setClickable(false);
        repeat.setClickable(false);
        repeat.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
        previous.setClickable(false);
        previous.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
        rewind.setClickable(false);
        rewind.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
        forward.setClickable(false);
        forward.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
        next.setClickable(false);
        next.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
        shuffle.setClickable(false);
        shuffle.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
    }

    private void initButtonListeners() {

        repeat.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                repeat();
            }
        });

        previous.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                previous();
            }
        });

        rewind.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                rewind();
            }
        });

        play_pause.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                play_pause();
            }
        });

        forward.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                forward();
            }
        });

        next.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                next();
            }
        });

        shuffle.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                shuffle();
            }
        });

    }

    private void refresh() {
        durationHandler.postDelayed(updateSeekBarTime, 100);
    }

    //handler to change seekBarTime
    private Runnable updateSeekBarTime = new Runnable() {
        public void run() {
            if (player != null) {
                //get current position
                timeElapsed = player.getCurrentPosition();
                //set seekbar progress
                seekbar.setProgress((int) timeElapsed);
                //set time remaing
                duration.setText(String.format("%02d:%02d", TimeUnit.MILLISECONDS.toMinutes((long) timeElapsed), TimeUnit.MILLISECONDS.toSeconds((long) timeElapsed) - TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes((long) timeElapsed))));

                //repeat yourself that again in 100 miliseconds
                durationHandler.postDelayed(this, 100);
            }
        }

    };

    private void play_pause() {
        if(player.isPlaying()) {
            //Pause
            player.pause();

            //transform into play
            play_pause.setImageResource(R.drawable.ic_play);
        } else {
            //Play
            player.start();

            //transform into pause
            play_pause.setImageResource(R.drawable.ic_pause);
            timeElapsed = player.getCurrentPosition();
            seekbar.setProgress((int) timeElapsed);
        }

        if(!isRadio) {
            if(audioPurchaseUrl.equals("null") || audioPurchaseUrl.equals("")) {
                purchase.setClickable(false);
                purchase.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
            } else {
                purchase.setClickable(true);
                purchase.getDrawable().setColorFilter(null);
            }

            if(audioPlaylistOffset == audioPlaylistMediaNumber && !isShuffling){
                next.setClickable(false);
                next.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
            } else {
                next.setClickable(true);
                next.getDrawable().setColorFilter(null);
            }

            if(audioPlaylistOffset == 0 && !isShuffling) {
                previous.setClickable(false);
                previous.getDrawable().setColorFilter(Color.GRAY, PorterDuff.Mode.MULTIPLY);
            } else {
                previous.setClickable(true);
                previous.getDrawable().setColorFilter(null);
            }
        }

        refresh();
    }

    private void previous() {
        if(audioPlaylistOffset != 0) {
            audioPlaylistOffset--;
            initPlayer();
        }
    }

    private void randomSong() {
        Random random = new Random();
        audioPlaylistOffset = random.nextInt(audioPlaylistMediaNumber);

        while (audioPlaylistShuffle.toString().contains("" + audioPlaylistOffset)) {
            if(audioPlaylistOffset == audioPlaylistMediaNumber) {
                audioPlaylistOffset = 0;
            } else {
                audioPlaylistOffset++;
            }
        }

        audioPlaylistShuffle.put(audioPlaylistOffset);
    }

    private void next() {
        if (isShuffling) {

            if(audioPlaylistShuffle.length()-1 == audioPlaylistMediaNumber) {
                if(repeatType == "all") {
                    audioPlaylistShuffle = new JSONArray();

                    randomSong();
                } else {
                    return;
                }
            } else {
                randomSong();
            }

        } else if (audioPlaylistOffset != audioPlaylistMediaNumber) {
            audioPlaylistOffset++;
        } else if (repeatType == "all") {
            audioPlaylistOffset = 0;
        }

        initPlayer();
    }


    private void forward() {
        if ((timeElapsed + forwardTime) > 0 && !isRadio) {
            timeElapsed = timeElapsed + backwardTime;

            //seek to the exact second of the track
            player.seekTo((int) timeElapsed);
        }
    }

    private void rewind() {
        if ((timeElapsed + forwardTime) > 0 && !isRadio) {
            timeElapsed = timeElapsed - backwardTime;

            //seek to the exact second of the track
            player.seekTo((int) timeElapsed);
        }
    }

    private void shuffle() {
        isShuffling = !isShuffling;
        audioPlaylistShuffle = new JSONArray();
        if(isShuffling) {
            shuffle.getDrawable().setColorFilter(activity.getResources().getColor(R.color.blue_audioplayer), PorterDuff.Mode.MULTIPLY);
        } else {
            shuffle.getDrawable().setColorFilter(null);
        }
    }

    private void repeat() {
        if (repeatType.equals("")) {
            repeatType = "all";
        } else if (repeatType.equals("all")) {
            repeatType = "one";
        } else if (repeatType.equals("one")) {
            repeatType = "";
        }

        setRepeatDrawable();
    }

    private void setRepeatDrawable() {
        if (repeatType.equals("")) {
            repeat.setImageResource(R.drawable.ic_repeat);
            repeat.getDrawable().setColorFilter(null);
        } else if (repeatType.equals("all")) {
            repeat.getDrawable().setColorFilter(activity.getResources().getColor(R.color.blue_audioplayer), PorterDuff.Mode.MULTIPLY);
        } else if (repeatType.equals("one")) {
            repeat.setImageResource(R.drawable.ic_repeat_one);
            repeat.getDrawable().setColorFilter(activity.getResources().getColor(R.color.blue_audioplayer), PorterDuff.Mode.MULTIPLY);
        }
    }

    //PUBLICS
    public  void updatePlayer(Activity p_activity, Boolean p_isRadio, int p_audioPlaylistOffset, String p_audioPlaylist, String p_albums) {
        initVars(p_activity, p_isRadio, p_audioPlaylistOffset, p_audioPlaylist, p_albums);
    }
    public JSONArray getAudioPlaylist() { return audioPlaylist; }
    public JSONArray getAlbums() { return albums; }
    public PlaylistAdapter getPlaylistAdapter() { return playlistAdapter; }
    public int getAudioPlaylistOffset() { return audioPlaylistOffset; }
    public String getPurchaseUrl() { return audioPurchaseUrl; }
    public String getAudioTitle() { return audioTitle; }
    public String getAudioArtist() { return audioArtist; }
    public String getAlbumName(int albumId) {
        try {
            return albums.getJSONObject(albumId).getString("name");
        } catch (JSONException e) {
            return "";
        }
    }
    public String getArtwork() { return cover; }
    public void setActivity(Activity p_activity) {
        activity = p_activity;
    }
    public void setAudioPlaylistOffset(int offset) { audioPlaylistOffset = offset; }

    @Override
    public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        if(fromUser) {
            player.seekTo(progress);
        }
        if(progress >= finalTime) {
            if(repeatType == "one") {
                player.seekTo(0);
            } else {
                next();
            }
        }
    }

    @Override
    public void onStartTrackingTouch(SeekBar seekBar) {}

    @Override
    public void onStopTrackingTouch(SeekBar seekBar) {}

    public static void destroy() {
        if(player != null) {
            player.stop();
            player.release();
            player = null;
            ourInstance = null;
        }
    }

    public class PlaylistAdapter extends BaseAdapter implements ListAdapter {

        private final Activity activity;
        private final JSONArray jsonArray;
        public int currentOffset;

        public PlaylistAdapter(Activity activity, JSONArray jsonArray, int currentOffset) {
            assert activity != null;
            assert jsonArray != null;

            this.jsonArray = jsonArray;
            this.activity = activity;
            this.currentOffset = currentOffset;
        }

        @Override public int getCount() {
            if(null==jsonArray)
                return 0;
            else
                return jsonArray.length();
        }

        @Override public JSONObject getItem(int position) {
            if(null==jsonArray) return null;
            else
                return jsonArray.optJSONObject(position);
        }

        @Override public long getItemId(int position) {
            JSONObject jsonObject = getItem(position);

            return jsonObject.optLong("id");
        }

        @Override public View getView(int position, View convertView, ViewGroup parent) {
            if (convertView == null) {
                convertView = activity.getLayoutInflater().inflate(R.layout.media_player_playlist, null);
            }

            if(convertView.getResources() != null) {
                int color = Color.BLACK;
                if (position == this.currentOffset) {
                    color = activity.getResources().getColor(R.color.blue_audioplayer);
                }

                convertView.setBackgroundColor(color);
            }

            TextView txtTitle = (TextView) convertView.findViewById(R.id.itemTitle);
            TextView txtAlbum = (TextView) convertView.findViewById(R.id.itemAlbum);

            JSONObject json_data = getItem(position);
            if(null!=json_data ){
                String audioTitle = activity.getString(R.string.unknown);
                String audioAlbum = activity.getString(R.string.unknown);
                try {
                    audioTitle = json_data.getString("name") + " - " + json_data.getString("artistName");
                    if(json_data.getString("albumName") != "null") {
                        audioAlbum = json_data.getString("albumName");
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                txtTitle.setText(audioTitle);
                txtAlbum.setText(audioAlbum);
            }

            return convertView;
        }

    }
}


