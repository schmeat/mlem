//
//  AccountListView.swift
//  Mlem
//
//  Created by Sjmarf on 22/12/2023.
//

import Dependencies
import SwiftUI

struct QuickSwitcherView: View {
    var body: some View {
        Group {
            List {
                AccountListView(isQuickSwitcher: true)
            }
        }
        .hoistNavigation(.dismiss)
        .fancyTabScrollCompatible()
    }
}

struct AccountListView: View {
    @Environment(\.setAppFlow) var setFlow
    
    @AppStorage("accountSort") var accountSort: AccountSortMode = .custom
    @AppStorage("groupAccountSort") var groupAccountSort: Bool = false
    @EnvironmentObject var appState: AppState
    
    @ObservedObject var accountsTracker: SavedAccountTracker
    
    @State private var isShowingInstanceAdditionSheet: Bool = false
    
    @State var isSwitching: Bool = false
    
    struct AccountGroup {
        let header: String
        let accounts: [SavedAccount]
    }
    
    let isQuickSwitcher: Bool
    
    init(isQuickSwitcher: Bool = false) {
        // We have to create an ObservedObject here so that changes to the accounts list create view updates
        @Dependency(\.accountsTracker) var accountsTracker: SavedAccountTracker
        self._accountsTracker = ObservedObject(wrappedValue: accountsTracker)
        self.isQuickSwitcher = isQuickSwitcher
    }
    
    var shouldAllowReordering: Bool {
        (accountSort == .custom || accountsTracker.savedAccounts.count == 2) && !isQuickSwitcher
    }
    
    var body: some View {
        Group {
            if !isSwitching {
                if accountsTracker.savedAccounts.count > 3, groupAccountSort {
                    ForEach(Array(accountGroups.enumerated()), id: \.offset) { offset, group in
                        Section {
                            ForEach(group.accounts, id: \.self) { account in
                                AccountButtonView(
                                    account: account,
                                    caption: accountSort != .instance || group.header == "Other" ? .instanceAndTime : .timeOnly,
                                    isSwitching: $isSwitching
                                )
                            }
                        } header: {
                            if offset == 0 {
                                topHeader(text: group.header)
                            } else {
                                Text(group.header)
                            }
                        }
                    }
                } else {
                    Section(header: topHeader()) {
                        ForEach(accounts, id: \.self) { account in
                            AccountButtonView(account: account, isSwitching: $isSwitching)
                        }
                        .onMove(perform: shouldAllowReordering ? reorderAccount : nil)
                    }
                }
                Section {
                    Button {
                        isShowingInstanceAdditionSheet = true
                    } label: {
                        Label("Add Account", systemImage: "plus")
                    }
                    .accessibilityLabel("Add a new account.")
                }
            }
        }
        .sheet(isPresented: $isShowingInstanceAdditionSheet) {
            AddSavedInstanceView(onboarding: false)
        }
    }
    
    @ViewBuilder
    func topHeader(text: String? = nil) -> some View {
        HStack {
            if let text {
                Text(text)
            }
            if !isQuickSwitcher, accountsTracker.savedAccounts.count > 2 {
                Spacer()
                sortModeMenu()
            }
        }
    }
    
    @ViewBuilder
    func sortModeMenu() -> some View {
        Menu {
            Picker("Sort", selection: $accountSort) {
                ForEach(AccountSortMode.allCases, id: \.self) { sortMode in
                    Label(sortMode.label, systemImage: sortMode.systemImage).tag(sortMode)
                }
            }
            .onChange(of: accountSort) { newValue in
                if newValue == .custom {
                    groupAccountSort = false
                }
            }
            if accountsTracker.savedAccounts.count > 3 {
                Divider()
                Toggle(isOn: $groupAccountSort) {
                    Label("Grouped", systemImage: "square.stack.3d.up.fill")
                }
                .disabled(accountSort == .custom)
            }
        } label: {
            HStack(alignment: .center, spacing: 2) {
                Text("Sort by: \(accountSort.label)")
                    .font(.caption)
                    .textCase(nil)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .fontWeight(.semibold)
            .foregroundStyle(.blue)
        }
        .textCase(nil)
    }
}
