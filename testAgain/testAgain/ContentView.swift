//
//  ContentView.swift
//  testAgain
//
//  Created by Porcher, RJ on 4/16/25.
//

import SwiftUI
import AVFoundation

struct Song: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
}

class PlaylistManager: ObservableObject {
    @Published var playlists: [String: [Song]] = [
        "Workout": [Song(name: "Lying 4 Fun", imageName: "workout1"), Song(name: "I Am", imageName: "workout2")],
        "Relax": [Song(name: "Eternal Sunshine", imageName: "relax1"), Song(name: "Sold Out Dates", imageName: "relax2")],
        "Party": [Song(name: "Crushed Up", imageName: "party1"), Song(name: "Faneto", imageName: "party2")]
    ]
    
    func addSong(to playlist: String, song: Song) {
        playlists[playlist, default: []].append(song)
    }
    
    func createPlaylist(name: String) {
        guard !name.isEmpty else { return }
        playlists[name] = []
    }
}

struct ContentView: View {
    @StateObject private var playlistManager = PlaylistManager()
    
    var body: some View {
        TabView {
            LibraryView()
                .environmentObject(playlistManager)
                .tabItem {
                    Label("Library", systemImage: "music.note.list")
                }
            
            DiscoverView()
                .environmentObject(playlistManager)
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
            
            PlaylistView()
                .environmentObject(playlistManager)
                .tabItem {
                    Label("Playlist", systemImage: "list.bullet")
                }
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var searchText = ""
    @State private var selectedGenre = "All"
    @State private var addToPlaylistSheet: Bool = false
    @State private var selectedSong: Song? = nil
    @State private var showAddSongSheet: Bool = false // State to show the Add Song sheet

    let genres = ["All", "Pop", "R&B", "Jazz", "Gospel", "Hip-Hop"]
    let allSongs: [String: [Song]] = [
        "Pop": [Song(name: "Human Nature", imageName: "pop1"), Song(name: "Lost", imageName: "pop2"), Song(name: "Until the End of Time", imageName: "pop3"), Song(name: "Bad Guy", imageName: "pop4")],
        "R&B": [Song(name: "Blame", imageName: "rnb1"), Song(name: "Who Hurt You?", imageName: "rnb2"), Song(name: "Holding On", imageName: "rnb3"), Song(name: "Blue Dream", imageName: "rnb4")],
        "Jazz": [Song(name: "Blues March", imageName: "jazz1"), Song(name: "Breezin'", imageName: "jazz2"), Song(name: "Misty", imageName: "jazz3"), Song(name: "All I see in You", imageName: "jazz4")],
        "Gospel": [Song(name: "Have Me", imageName: "gospel1"), Song(name: "Worth It", imageName: "gospel2"), Song(name: "Forever", imageName: "gospel3"), Song(name: "Listen", imageName: "gospel4")],
        "Hip-Hop": [Song(name: "Mannequin Challenge", imageName: "hiphop1"), Song(name: "Still Prevail", imageName: "hiphop2"), Song(name: "Bandit", imageName: "hiphop3"), Song(name: "Drive Me Crazy", imageName: "hiphop4")]
    ]
    
    var filteredSongs: [Song] {
        let songs = selectedGenre == "All" ? allSongs.values.flatMap { $0 } : (allSongs[selectedGenre] ?? [])
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Genre Picker
                Picker("Select Genre", selection: $selectedGenre) {
                    ForEach(genres, id: \.self) { genre in
                        Text(genre).tag(genre)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Search songs")
                
                // Songs List
                List(filteredSongs) { song in
                    HStack {
                        NavigationLink(destination: SongDetailView(songName: song.name, imageName: song.imageName)) {
                            HStack {
                                Image(song.imageName)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                Text(song.name)
                            }
                        }
                        Spacer()
                        Button(action: {
                            selectedSong = song
                            addToPlaylistSheet = true
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarItems(trailing: Button(action: {
                showAddSongSheet = true // Show the "Add Song" sheet
            }) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            })
            .sheet(isPresented: $addToPlaylistSheet) {
                if let selectedSong = selectedSong {
                    AddToPlaylistView(song: selectedSong)
                        .environmentObject(playlistManager)
                }
            }
            .sheet(isPresented: $showAddSongSheet) {
                AddSongView()
                    .environmentObject(playlistManager)
            }
        }
    }
}

struct AddSongView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @Environment(\.dismiss) var dismiss
    @State private var songName: String = ""
    @State private var imageName: String = ""
    @State private var playlistName: String = "Workout"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Song Information")) {
                    TextField("Song Name", text: $songName)
                    TextField("Image Name", text: $imageName)
                }
                
                Section(header: Text("Playlist")) {
                    Picker("Select Playlist", selection: $playlistName) {
                        ForEach(playlistManager.playlists.keys.sorted(), id: \.self) { playlist in
                            Text(playlist).tag(playlist)
                        }
                    }
                }
                
                Button("Add Song") {
                    if !songName.isEmpty && !imageName.isEmpty {
                        let newSong = Song(name: songName, imageName: imageName)
                        playlistManager.addSong(to: playlistName, song: newSong)
                        dismiss()
                    }
                }
                .disabled(songName.isEmpty || imageName.isEmpty) // Disable button if fields are empty
            }
            .navigationTitle("Add New Song")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
}

struct DiscoverView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var searchText = ""
    @State private var addToPlaylistSheet: Bool = false
    @State private var selectedSong: Song? = nil

    let recommendedSongs: [Song] = [
        Song(name: "Gospel song of the week", imageName: "gospel1"),
        Song(name: "5 Star", imageName: "trending1"),
        Song(name: "Taste", imageName: "trending2"),
        Song(name: "YOUR WAY'S BETTER", imageName: "trending3"),
        Song(name: "NEW DROP", imageName: "trending4")
    ]
    
    var filteredRecommendedSongs: [Song] {
        if searchText.isEmpty {
            return recommendedSongs
        } else {
            return recommendedSongs.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Search recommendations")
                
                // Recommended Songs List
                List(filteredRecommendedSongs) { song in
                    HStack {
                        NavigationLink(destination: SongDetailView(songName: song.name, imageName: song.imageName)) {
                            HStack {
                                Image(song.imageName)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                Text(song.name)
                            }
                        }
                        Spacer()
                        Button(action: {
                            selectedSong = song
                            addToPlaylistSheet = true
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .sheet(isPresented: $addToPlaylistSheet) {
                if let selectedSong = selectedSong {
                    AddToPlaylistView(song: selectedSong)
                        .environmentObject(playlistManager)
                }
            }
        }
    }
}

struct PlaylistView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var newPlaylistName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Add New Playlist
                HStack {
                    TextField("New Playlist Name", text: $newPlaylistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: {
                        playlistManager.createPlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                    .padding()
                }
                
                // Playlist List
                List {
                    ForEach(playlistManager.playlists.keys.sorted(), id: \.self) { playlist in
                        Section(header: Text(playlist)) {
                            ForEach(playlistManager.playlists[playlist]!) { song in
                                HStack {
                                    Image(song.imageName)
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    Text(song.name)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Playlists")
        }
    }
}

struct AddToPlaylistView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    let song: Song
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(playlistManager.playlists.keys.sorted(), id: \.self) { playlist in
                    Button(action: {
                        playlistManager.addSong(to: playlist, song: song)
                        dismiss()
                    }) {
                        Text(playlist)
                    }
                }
            }
            .navigationTitle("Add '\(song.name)' to Playlist")
        }
    }
}

struct SongDetailView: View {
    let songName: String
    let imageName: String
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        VStack(spacing: 20) {
            Image(imageName)
                .resizable()
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .padding()
            
            Text(songName)
                .font(.largeTitle)
                .padding()
            
            // Play/Pause Button
            Button(action: {
                isPlaying.toggle()
                if isPlaying {
                    playAudio()
                } else {
                    audioPlayer?.pause()
                }
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .onDisappear {
            audioPlayer?.stop()
        }
        .navigationTitle(songName)
    }

    private func playAudio() {
        if let url = Bundle.main.url(forResource: "preview", withExtension: "mp3") { // Replace with dynamic URLs if needed
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Error playing audio: \(error.localizedDescription)")
            }
        } else {
            print("Audio file not found.")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
    }
}
#Preview {
    ContentView()
}
