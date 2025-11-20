import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel.shared
    @StateObject private var authViewModel = AuthenticationViewModel.shared
    @EnvironmentObject var router: Router
    @State private var showAddMemorySheet = false
    @State private var searchText = ""
    @State private var showFilterOptions = false

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Memories")
                        .font(.appScreenTitle)
                        .foregroundColor(AppColor.white)

                    if let user = authViewModel.currentUser {
                        Text("Welcome back, \(user.displayName)")
                            .font(.appBodyText)
                            .foregroundColor(AppColor.grey)
                    }
                }

                Spacer()

                Button(action: {
                    router.push(.profile)
                }) {
                    if let user = authViewModel.currentUser, let imageUrl = user.profileImageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Text(user.initials)
                                .font(.appHeadline)
                                .foregroundColor(.white)
                        }
                        .frame(width: 45, height: 45)
                        .background(AppColor.primary)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 45))
                            .foregroundColor(AppColor.primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColor.grey)

                    TextField("", text: $viewModel.searchText)
                        .font(.appBodyText)
                        .foregroundColor(AppColor.white)
                        .placeholder(when: viewModel.searchText.isEmpty) {
                            Text("Search memories...")
                                .font(.appBodyText)
                                .foregroundColor(AppColor.grey.opacity(0.5))
                        }
                }
                .padding()
                .background(Color(hex: "#1C1C1C"))
                .cornerRadius(12)

                Button(action: {
                    showFilterOptions.toggle()
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.selectedPriorityFilter != nil || viewModel.showCompletedOnly ? AppColor.primary : AppColor.grey)
                }
            }
            .padding(.horizontal, 20)

            if showFilterOptions {
                filterOptionsView
            }
        }
        .padding(.bottom, 12)
        .background(Color.black)
    }

    private var filterOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Priority")
                .font(.appLabel)
                .foregroundColor(AppColor.grey)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.selectedPriorityFilter = nil
                    }) {
                        Text("All")
                            .font(.appBodyText)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedPriorityFilter == nil ? AppColor.primary : Color(hex: "#1C1C1C"))
                            .cornerRadius(20)
                    }

                    ForEach(MemoryPriority.allCases, id: \.self) { priority in
                        Button(action: {
                            viewModel.selectedPriorityFilter = priority
                        }) {
                            Text(priority.rawValue)
                                .font(.appBodyText)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedPriorityFilter == priority ? Color(hex: priority.color) : Color(hex: "#1C1C1C"))
                                .cornerRadius(20)
                        }
                    }
                }
            }

            Toggle(isOn: $viewModel.showCompletedOnly) {
                Text("Show Completed Only")
                    .font(.appBodyText)
                    .foregroundColor(AppColor.white)
            }
            .tint(AppColor.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "#1C1C1C"))
    }

    private var memoriesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredMemories) { memory in
                    MemoryCard(
                        memory: memory,
                        onToggleComplete: {
                            Task {
                                await viewModel.toggleMemoryCompletion(memory.id ?? "")
                            }
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteMemory(memory.id ?? "")
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(AppColor.primary.opacity(0.3))

            Text("No Memories Yet")
                .font(.appScreenTitle)
                .foregroundColor(AppColor.white)

            Text("Start storing your thoughts and\nthings you want to remember")
                .font(.appBodyText)
                .foregroundColor(AppColor.grey)
                .multilineTextAlignment(.center)

            Button(action: {
                showAddMemorySheet = true
            }) {
                Text("Add Your First Memory")
                    .font(.appButtonText)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(AppColor.primary)
                    .cornerRadius(30)
            }
            .padding(.top, 10)

            Spacer()
        }
    }

    private var floatingAddButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button(action: {
                    showAddMemorySheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(AppColor.primary)
                        .clipShape(Circle())
                        .shadow(color: AppColor.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                if viewModel.isLoading && viewModel.memories.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(AppColor.primary)
                    Spacer()
                } else if viewModel.filteredMemories.isEmpty {
                    emptyStateView
                } else {
                    memoriesListView
                }
            }

            floatingAddButton
        }
        .sheet(isPresented: $showAddMemorySheet) {
            AddMemorySheet()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomeView()
        .environmentObject(Router())
}
