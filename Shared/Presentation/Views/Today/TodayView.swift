//
//  ContentView.swift
//  Shared
//
//  Created by Titouan Van Belle on 04.01.21.
//

import Combine
import SwiftUI
import CoreData

struct TodayView: View {

    @StateObject var store: TodayStore

    let viewFactory: ViewFactory

    private var isPresentingAlert: Binding<Bool> {
        Binding<Bool>(
            get: { store.alertErrorMessage != nil },
            set: { _ in store.send(event: .dismissError) }
        )
    }
    
    var body: some View {
        #if os(macOS)
          view
            .frame(minWidth: 400, minHeight: 600)
        #else
            view
        #endif
    }
}

fileprivate extension TodayView {
    var view: some View {
        ZStack(alignment: .top) {
            Daisy.color.primaryBackground
                .edgesIgnoringSafeArea(.all)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header
                    if !store.reminders.isEmpty {
                        reminders
                        seeAllButon
                            .animation(nil)
                    }
                    Color.clear
                        .frame(height: 70)
                }
                .padding(.horizontal, 28)
                .padding(.top, 40)
            }

            if store.reminders.isEmpty {
                GeometryReader { proxy in
                    emptyView
                        .frame(width: 2 * proxy.size.width / 3)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
            }

            VStack {
                Spacer()
                createReminderButton
            }

        }
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: store.action(for: .loadReminders))
        .alert(isPresented: isPresentingAlert) {
            Alert(title: Text("global.error".localized), message: Text(store.alertErrorMessage!))
        }
        .sheet(isPresented: $store.isSheetPresented) {
            if case .allReminders = store.sheetContentType {
                viewFactory.makeRemindersView()
            } else if case .reminder(let reminder) = store.sheetContentType {
                viewFactory.makeReminderView(for: reminder)
            }
        }
    }

    var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Date().formatted(using: .full))
                    .font(Daisy.font.largeTitle)
                    .foregroundColor(Daisy.color.quartiaryForeground)

                Text("today.title".localized + " 👋")
                    .font(Daisy.font.h1)
                    .foregroundColor(Daisy.color.primaryForeground)

                Text("today.subtitle".localized(with: store.reminders.count))
                    .lineLimit(2)
                    .font(Daisy.font.largeTitle)
                    .foregroundColor(Daisy.color.secondaryForeground)
            }

            Spacer()
        }
    }

    var reminders: some View {
        ReminderList(
            sections: [store.reminders],
            shouldShowSectionTitles: false,
            onToggle: { withAnimation(.interactiveSpring(), store.action(for: .toggleReminder($0))) },
            onDelete: { withAnimation(.interactiveSpring(), store.action(for: .deleteReminder($1))) },
            onTap: { store.send(event: .selectReminder($0)) }
        )
    }

    var seeAllButon: some View {
        HStack {
            Spacer()
            Button(action: store.action(for: .seeAllReminders)) {
                Text("See all reminder")
                    .font(Daisy.font.largeBody)
                    .foregroundColor(Daisy.color.secondaryForeground)
            }
            Spacer()
        }
    }

    var emptyView: some View {
        VStack(spacing: 30) {
            Image("NoReminders")
                .resizable()
                .aspectRatio(contentMode: .fit)

            VStack(spacing: 6) {
                Text("today.empty_view.title".localized)
                    .font(Daisy.font.largeTitle)
                    .foregroundColor(Daisy.color.primaryForeground)

                Text("today.empty_view.subtitle".localized)
                    .font(Daisy.font.largeBody)
                    .foregroundColor(Daisy.color.secondaryForeground)
                    .multilineTextAlignment(.center)
            }
        }
    }

    var createReminderButton: some View {
        Button(action: { store.send(event: .createNewReminder) }) {
            Text("today.create_reminder".localized)
                .font(Daisy.font.smallButton)
                .foregroundColor(Daisy.color.white)
                .padding(.horizontal, 32)
        }
        .background(
            RoundedCorners(radius: 24)
                .fill(Daisy.color.tertiaryForeground)
                .frame(height: 48)
                .shadow(color: Daisy.color.black.opacity(0.5), radius: 16, x: 0, y: 8)
        )
        .accessibilityIdentifier(.createReminderButton)
        .padding(.bottom, 28)
    }
}
