import SwiftUI

struct AddMemorySheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = HomeViewModel.shared

    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority: MemoryPriority = .medium
    @State private var dateToRemember: Date?
    @State private var showDatePicker = false
    @State private var relatedPerson = ""
    @State private var relatedTo = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Add New Memory")
                            .font(.appScreenTitle)
                            .foregroundColor(AppColor.white)
                            .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.appLabel)
                                .foregroundColor(AppColor.grey)

                            TextField("", text: $title)
                                .font(.appBodyLarge)
                                .foregroundColor(AppColor.white)
                                .padding()
                                .background(Color(hex: "#1C1C1C"))
                                .cornerRadius(12)
                                .placeholder(when: title.isEmpty) {
                                    Text("What do you want to remember?")
                                        .font(.appBodyLarge)
                                        .foregroundColor(AppColor.grey.opacity(0.5))
                                        .padding(.leading, 16)
                                }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.appLabel)
                                .foregroundColor(AppColor.grey)

                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Add more details...")
                                        .font(.appBodyText)
                                        .foregroundColor(AppColor.grey.opacity(0.5))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }

                                TextEditor(text: $description)
                                    .font(.appBodyText)
                                    .foregroundColor(AppColor.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color(hex: "#1C1C1C"))
                                    .cornerRadius(12)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.appLabel)
                                .foregroundColor(AppColor.grey)

                            HStack(spacing: 12) {
                                ForEach(MemoryPriority.allCases, id: \.self) { priority in
                                    Button(action: {
                                        selectedPriority = priority
                                    }) {
                                        Text(priority.rawValue)
                                            .font(.appBodyText)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedPriority == priority ?
                                                Color(hex: priority.color) :
                                                Color(hex: "#1C1C1C")
                                            )
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color(hex: priority.color), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Date to Remember")
                                    .font(.appLabel)
                                    .foregroundColor(AppColor.grey)

                                Spacer()

                                if dateToRemember != nil {
                                    Button(action: {
                                        dateToRemember = nil
                                        showDatePicker = false
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppColor.grey)
                                    }
                                }
                            }

                            Button(action: {
                                showDatePicker.toggle()
                                if dateToRemember == nil {
                                    dateToRemember = Date()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(AppColor.primary)
                                    Text(dateToRemember?.formatted(date: .long, time: .omitted) ?? "Select Date")
                                        .font(.appBodyText)
                                        .foregroundColor(dateToRemember != nil ? AppColor.white : AppColor.grey)
                                    Spacer()
                                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                        .foregroundColor(AppColor.grey)
                                }
                                .padding()
                                .background(Color(hex: "#1C1C1C"))
                                .cornerRadius(12)
                            }

                            if showDatePicker, let date = dateToRemember {
                                DatePicker("", selection: Binding(
                                    get: { date },
                                    set: { dateToRemember = $0 }
                                ), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .padding()
                                .background(Color(hex: "#1C1C1C"))
                                .cornerRadius(12)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Related Person (Optional)")
                                .font(.appLabel)
                                .foregroundColor(AppColor.grey)

                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppColor.primary)

                                TextField("", text: $relatedPerson)
                                    .font(.appBodyText)
                                    .foregroundColor(AppColor.white)
                                    .placeholder(when: relatedPerson.isEmpty) {
                                        Text("e.g., Mom, John, Dr. Smith")
                                            .font(.appBodyText)
                                            .foregroundColor(AppColor.grey.opacity(0.5))
                                    }
                            }
                            .padding()
                            .background(Color(hex: "#1C1C1C"))
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Related To (Optional)")
                                .font(.appLabel)
                                .foregroundColor(AppColor.grey)

                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(AppColor.primary)

                                TextField("", text: $relatedTo)
                                    .font(.appBodyText)
                                    .foregroundColor(AppColor.white)
                                    .placeholder(when: relatedTo.isEmpty) {
                                        Text("e.g., Work, Project, Event")
                                            .font(.appBodyText)
                                            .foregroundColor(AppColor.grey.opacity(0.5))
                                    }
                            }
                            .padding()
                            .background(Color(hex: "#1C1C1C"))
                            .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags (Optional)")
                                .font(.appLabel)
                                .foregroundColor(AppColor.grey)

                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(AppColor.primary)

                                TextField("", text: $tagInput)
                                    .font(.appBodyText)
                                    .foregroundColor(AppColor.white)
                                    .placeholder(when: tagInput.isEmpty) {
                                        Text("Type and press return to add")
                                            .font(.appBodyText)
                                            .foregroundColor(AppColor.grey.opacity(0.5))
                                    }
                                    .onSubmit {
                                        if !tagInput.isEmpty {
                                            tags.append(tagInput.trimmingCharacters(in: .whitespaces))
                                            tagInput = ""
                                        }
                                    }
                            }
                            .padding()
                            .background(Color(hex: "#1C1C1C"))
                            .cornerRadius(12)

                            if !tags.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                                .font(.appCaption)
                                                .foregroundColor(AppColor.white)

                                            Button(action: {
                                                tags.removeAll { $0 == tag }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColor.grey)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(AppColor.primary.opacity(0.3))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }

                        Button(action: saveMemory) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            } else {
                                Text("Save Memory")
                                    .font(.appButtonLarge)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            }
                        }
                        .background(AppColor.primary)
                        .cornerRadius(30)
                        .disabled(title.isEmpty || viewModel.isLoading)
                        .opacity(title.isEmpty ? 0.5 : 1.0)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .scrollDismissesKeyboard(.automatic)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColor.white)
                    }
                }
            }
        }
    }

    private func saveMemory() {
        guard !title.isEmpty else { return }

        let memory = MemoryEntity(
            userId: "",
            title: title,
            description: description.isEmpty ? nil : description,
            priority: selectedPriority,
            dateToRemember: dateToRemember,
            relatedPerson: relatedPerson.isEmpty ? nil : relatedPerson,
            relatedTo: relatedTo.isEmpty ? nil : relatedTo,
            tags: tags,
            source: .manual
        )

        Task {
            await viewModel.createMemory(memory)
            dismiss()
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
