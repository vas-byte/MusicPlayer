import SwiftUI
import MediaPlayer

struct ContentView: View {
    @State private var musicPlayer = MPMusicPlayerController.applicationQueuePlayer
    @State private var playlists: [MPMediaPlaylist] = []
    @State private var playlistNames: [String] = []
    @State private var playlistImages: [UIImage?] = []
    @State private var nowPlayingSong: String = "Not Playing"
    @State private var nowPlayingArtist: String = "Unknown Artist"
    @State private var albumArtwork: UIImage? = nil
    @State private var playbackProgress: Double = 0.0
    @State private var totalDuration: Double = 1.0 // Avoid division by zero

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    if let artwork = albumArtwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .cornerRadius(10)
                    } else {
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .foregroundColor(.gray)
                    }
                    
                    Text(nowPlayingSong)
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text(nowPlayingArtist)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Progress Bar
                    ProgressView(value: playbackProgress)
                        .padding(.top, 10)
                        .padding([.leading, .trailing], 20)
                }
                .padding()

                // Playback Controls
                HStack(spacing: 50) {
                    Button(action: previousSong) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 30)) .foregroundColor(.pink)
                    }

                    Button(action: togglePlayPause) {
                        Image(systemName: musicPlayer.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 30)) .foregroundColor(.pink)
                    }

                    Button(action: nextSong) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 30)) .foregroundColor(.pink)
                    }
                }
                .padding()

                // Playlist Section
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(playlistNames.indices, id: \.self) { index in
                            VStack {
                                if playlistImages.indices.contains(index),
                                   let image = playlistImages[index] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "music.note.list")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                }

                                Text(playlistNames[index])
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .onTapGesture {
                                playPlaylist(index: index)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Music Player")
            .onAppear(perform: loadPlaylists)
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                updateProgress()
            }
            
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            updateNowPlaying()
        }
    }
      

    /// Fetch playlists from the media library
    private func loadPlaylists() {
        let query = MPMediaQuery.playlists()
        if let fetchedPlaylists = query.collections as? [MPMediaPlaylist] {
            playlists = fetchedPlaylists
            playlistNames = playlists.map { $0.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "Unknown Playlist" }
            playlistImages = playlists.map { fetchCoverImage(for: $0) }
        }
    }

    /// Fetch album artwork for a given playlist
    private func fetchCoverImage(for playlist: MPMediaPlaylist) -> UIImage? {
        if let firstItem = playlist.items.first,
           let artwork = firstItem.artwork {
            return artwork.image(at: CGSize(width: 100, height: 100))
        }
        return nil
    }

    /// Play a selected playlist
    private func playPlaylist(index: Int) {
        guard playlists.indices.contains(index) else { return }

        let playlist = playlists[index]
        musicPlayer.setQueue(with: playlist)
        musicPlayer.shuffleMode = .songs
        musicPlayer.play()

        updateNowPlaying()
    }

    /// Toggle play/pause
    private func togglePlayPause() {
        if musicPlayer.playbackState == .playing {
            musicPlayer.pause()
        } else {
            musicPlayer.play()
        }
        updateNowPlaying()
    }

    /// Skip to the next song
    private func nextSong() {
        musicPlayer.skipToNextItem()
        updateNowPlaying()
    }

    /// Go back to the previous song
    private func previousSong() {
        musicPlayer.skipToPreviousItem()
        updateNowPlaying()
    }

    /// Update now playing information
    private func updateNowPlaying() {
        guard let currentItem = musicPlayer.nowPlayingItem else {
            nowPlayingSong = "Not Playing"
            nowPlayingArtist = "Unknown Artist"
            albumArtwork = nil
            playbackProgress = 0.0
            totalDuration = 1.0
            return
        }

        nowPlayingSong = currentItem.title ?? "Unknown Song"
        nowPlayingArtist = currentItem.artist ?? "Unknown Artist"

        totalDuration = currentItem.playbackDuration
        playbackProgress = musicPlayer.currentPlaybackTime / totalDuration

        if let artwork = currentItem.artwork {
            albumArtwork = artwork.image(at: CGSize(width: 200, height: 200))
        } else {
            albumArtwork = nil
        }
    }

    /// Update progress bar
    private func updateProgress() {
        guard let currentItem = musicPlayer.nowPlayingItem else {
            playbackProgress = 0.0
            return
        }

        let currentPlaybackTime = musicPlayer.currentPlaybackTime
        playbackProgress = currentPlaybackTime / totalDuration
    }
}

