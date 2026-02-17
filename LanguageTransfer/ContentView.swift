//
//  ContentView.swift
//  Language Transfer - Spanish
//
//  Created by OpenClaw on 2026-02-17.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "globe.americas")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 80))
                
                Text("Language Transfer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Spanish")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Divider()
                    .padding(.horizontal, 40)
                
                Text("Welcome to the learning journey")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button {
                    // TODO: Start first lesson
                } label: {
                    Label("Start Learning", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationTitle("Spanish")
        }
    }
}

#Preview {
    ContentView()
}
