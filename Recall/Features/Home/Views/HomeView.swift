import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel.shared
    @StateObject private var authViewModel = AuthenticationViewModel.shared
    @EnvironmentObject var router: Router
    @State private var showAddMemorySheet = false
    @State private var searchText = ""
    @State private var showFilterOptions = false
    @State private var selectedMemory: MemoryEntity?
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case edit(MemoryEntity)
        case reschedule(MemoryEntity)
        
        var id: String {
            switch self {
            case .edit(let memory):
                return "edit-\(memory.id ?? "")"
            case .reschedule(let memory):
                return "reschedule-\(memory.id ?? "")"
            }
        }
    }

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
                            guard let memoryId = memory.id, !memoryId.isEmpty else { return }
                            Task { @MainActor in
                                await viewModel.toggleMemoryCompletion(memoryId)
                            }
                        },
                        onDelete: {
                            guard let memoryId = memory.id, !memoryId.isEmpty else { return }
                            Task { @MainActor in
                                await viewModel.deleteMemory(memoryId)
                            }
                        },
                        onEdit: {
                            activeSheet = .edit(memory)
                        },
                        onReschedule: {
                            activeSheet = .reschedule(memory)
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
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .edit(let memory):
                    EditMemorySheet(memory: memory) { updatedMemory in
                        Task { @MainActor in
                            await viewModel.updateMemory(updatedMemory)
                            activeSheet = nil
                        }
                    }
                case .reschedule(let memory):
                    RescheduleMemorySheet(memory: memory) { updatedMemory in
                        Task { @MainActor in
                            await viewModel.updateMemory(updatedMemory)
                            activeSheet = nil
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            print("🏠 HomeView appeared - memories count: \(viewModel.memories.count)")
            if let userId = authViewModel.currentUser?.id {
                print("👤 Current user ID: \(userId)")
            } else {
                print("❌ No current user found")
            }
        }
    }
}

// MARK: - Edit Memory Sheet
struct EditMemorySheet: View {
    let memory: MemoryEntity
    let onSave: (MemoryEntity) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priority: MemoryPriority = .medium
    @State private var tags: [String] = []
    @State private var relatedPerson: String = ""
    @State private var relatedTo: String = ""
    @State private var newTag: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.appBodyLarge)
                            .foregroundColor(AppColor.white)
                        
                        TextField("Enter memory title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .background(Color(hex: "#1C1C1C"))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.appBodyLarge)
                            .foregroundColor(AppColor.white)
                        
                        TextField("Enter description (optional)", text: $description, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                            .background(Color(hex: "#1C1C1C"))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.appBodyLarge)
                            .foregroundColor(AppColor.white)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(MemoryPriority.allCases, id: \.self) { priority in
                                Text(priority.rawValue).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Person")
                            .font(.appBodyLarge)
                            .foregroundColor(AppColor.white)
                        
                        TextField("Person name (optional)", text: $relatedPerson)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .background(Color(hex: "#1C1C1C"))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related To")
                            .font(.appBodyLarge)
                            .foregroundColor(AppColor.white)
                        
                        TextField("Related context (optional)", text: $relatedTo)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .background(Color(hex: "#1C1C1C"))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.appBodyLarge)
                            .foregroundColor(AppColor.white)
                        
                        HStack {
                            TextField("Add tag", text: $newTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .background(Color(hex: "#1C1C1C"))
                            
                            Button("Add") {
                                if !newTag.isEmpty && !tags.contains(newTag) {
                                    tags.append(newTag)
                                    newTag = ""
                                }
                            }
                            .foregroundColor(AppColor.primary)
                        }
                        
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack {
                                            Text(tag)
                                                .font(.appCaption)
                                            
                                            Button("×") {
                                                tags.removeAll { $0 == tag }
                                            }
                                            .foregroundColor(.red)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppColor.primary.opacity(0.3))
                                        .cornerRadius(8)
                                        .foregroundColor(AppColor.white)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button("Save Changes") {
                        var updatedMemory = memory
                        updatedMemory.title = title
                        updatedMemory.description = description.isEmpty ? nil : description
                        updatedMemory.priority = priority
                        updatedMemory.relatedPerson = relatedPerson.isEmpty ? nil : relatedPerson
                        updatedMemory.relatedTo = relatedTo.isEmpty ? nil : relatedTo
                        updatedMemory.tags = tags
                        updatedMemory.updatedAt = Date()
                        
                        onSave(updatedMemory)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.appBodyLarge)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColor.primary)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.primary)
                }
            }
        }
        .onAppear {
            title = memory.title
            description = memory.description ?? ""
            priority = memory.priority
            relatedPerson = memory.relatedPerson ?? ""
            relatedTo = memory.relatedTo ?? ""
            tags = memory.tags
        }
    }
}

// MARK: - Reschedule Memory Sheet
struct RescheduleMemorySheet: View {
    let memory: MemoryEntity
    let onSave: (MemoryEntity) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var hasDate = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("Reschedule Memory")
                        .font(.appScreenTitle)
                        .foregroundColor(AppColor.white)
                    
                    Text(memory.title)
                        .font(.appHeadline)
                        .foregroundColor(AppColor.grey)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                VStack(spacing: 20) {
                    Toggle("Set reminder date", isOn: $hasDate)
                        .font(.appBodyLarge)
                        .foregroundColor(AppColor.white)
                        .tint(AppColor.primary)
                    
                    if hasDate {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .colorScheme(.dark)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button("Save Reschedule") {
                        var updatedMemory = memory
                        updatedMemory.dateToRemember = hasDate ? selectedDate : nil
                        updatedMemory.updatedAt = Date()
                        
                        onSave(updatedMemory)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.appBodyLarge)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColor.primary)
                    .cornerRadius(12)
                    
                    if memory.dateToRemember != nil {
                        Button("Remove Date") {
                            var updatedMemory = memory
                            updatedMemory.dateToRemember = nil
                            updatedMemory.updatedAt = Date()
                            
                            onSave(updatedMemory)
                            dismiss()
                        }
                        .foregroundColor(.red)
                        .font(.appBodyLarge)
                    }
                }
            }
            .padding()
            .background(Color.black)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.primary)
                }
            }
        }
        .onAppear {
            if let existingDate = memory.dateToRemember {
                selectedDate = existingDate
                hasDate = true
            } else {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                hasDate = false
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Router())
}
