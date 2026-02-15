//
//  ContentView.swift
//  LuxShot
//
//  Created by luke on 2026/2/14.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store = ScanStore.shared

    @State private var isHoveringNewScan: Bool = false
    @State private var isHoveringClear: Bool = false
    
    @State private var showClearAlert: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var itemToDelete: ScanItem? = nil

    let bgWarm = Color(red: 253/255, green: 251/255, blue: 247/255)
    let textMain = Color(red: 51/255, green: 51/255, blue: 51/255)
    let textMuted = Color(red: 134/255, green: 134/255, blue: 139/255)
    let accentAmber = Color(red: 245/255, green: 158/255, blue: 11/255)
    let accentAmberHover = Color(red: 251/255, green: 191/255, blue: 36/255)
    let borderColor = Color.black.opacity(0.08)

    var body: some View {
        mainInterface
    }
    
    var mainInterface: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    Color.white.opacity(0.3)
                    
                    Button(action: {
                        store.capture(showMain: true)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isHoveringNewScan ? accentAmberHover : accentAmber)
                                .shadow(color: accentAmber.opacity(0.25), radius: 4, y: 2)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                Text("New Scan")
                                    .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            }
                        }
                        .frame(height: 36)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 16)
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHoveringNewScan = hover
                        }
                    }
                }
                .frame(height: 56)
                
                .frame(height: 56)
                
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1)
                
                HStack {
                    Text("HISTORY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textMuted)
                        .tracking(1.0)
                    Spacer()
                    if !store.scanItems.isEmpty {
                        Button(action: {
                            showClearAlert = true
                        }) {
                            Text("Clear")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(isHoveringClear ? .red : textMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { hover in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isHoveringClear = hover
                            }
                            if hover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Color.white.opacity(0.1))
                
                .frame(height: 36)
                .background(Color.white.opacity(0.1))
                
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.scanItems) { item in
                            HistoryRow(item: item, isSelected: store.selectedScanId == item.id, onDelete: {
                                itemToDelete = item
                                showDeleteAlert = true
                            })
                                .onTapGesture {
                                    store.selectedScanId = item.id
                                }
                        }
                    }
                    .padding(12)
                }
                .frame(maxWidth: .infinity)

            }
            .frame(width: 300)
            .background(bgWarm)
            .alert("Delete Scan", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        store.delete(item)
                        itemToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this scan?")
            }
            .alert("Clear All History", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    store.clear()
                }
            } message: {
                Text("Are you sure you want to clear all scan history? This cannot be undone.")
            }



            Rectangle()
                .fill(borderColor)
                .frame(width: 1)
                .ignoresSafeArea(.all, edges: .bottom)

            VStack(spacing: 0) {
                if let selectedId = store.selectedScanId, let selectedItem = store.scanItems.first(where: { $0.id == selectedId }) {
                    ResultView(item: selectedItem)
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 64, weight: .thin))
                            .foregroundColor(Color.gray.opacity(0.25))
                            .padding(.bottom, 24)
                        
                        Text("Ready to capture")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(textMain)
                            .padding(.bottom, 8)
                        
                        HStack(spacing: 4) {
                            Text("Press")
                                .font(.system(size: 14))
                                .foregroundColor(textMuted)
                            
                            HStack(spacing: 3) {
                                Text("⌘")
                                    .font(.system(size: 12))
                                Text("⇧")
                                    .font(.system(size: 12))
                                Text("E")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.1), lineWidth: 1))
                            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                            .foregroundColor(textMain)
                            
                            Text("to start your first scan")
                                .font(.system(size: 14))
                                .foregroundColor(textMuted)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 34/255, green: 197/255, blue: 94/255)) // Green
                            .frame(width: 6, height: 6)
                        Text("Ready")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(textMuted)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("⌘C")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.white)
                            .cornerRadius(3)
                            .shadow(radius: 0.5)
                        Text("to copy")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(textMuted)
                }
                .padding(.horizontal, 16)
                .frame(height: 28)
                .background(Color.white.opacity(0.6))
                .background(.ultraThinMaterial)
            }
            .frame(maxWidth: .infinity)
            .background(bgWarm)
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgWarm)
        .overlay(alignment: .top) {
            ZStack {
                Color.white.opacity(0.5)
                    .background(.ultraThinMaterial)
                
                Text("LuxShot")
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundColor(textMain)
                    .tracking(-0.3)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 88, height: 1)
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        miniSwitch("Links", isOn: $store.autoOpenLinks)
                        miniSwitch("Breaks", isOn: $store.keepLineBreaks)
                        miniSwitch("Copy", isOn: $store.autoCopy)
                    }
                    .padding(.trailing, 16)
                }
                
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(borderColor)
                        .frame(height: 1)
                }
            }
            .frame(height: 32)
            .ignoresSafeArea()
        }
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private func miniSwitch(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isOn.wrappedValue ? textMain : textMuted)
            
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isOn.wrappedValue ? accentAmber : Color.gray.opacity(0.2))
                    .frame(width: 24, height: 14)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .offset(x: isOn.wrappedValue ? 5 : -5)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isOn.wrappedValue.toggle()
                }
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
