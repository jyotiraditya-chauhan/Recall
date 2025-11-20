import SwiftUI

struct MemoryCard: View {
    let memory: MemoryEntity
    var onToggleComplete: (() -> Void)?
    var onDelete: (() -> Void)?
    var onEdit: (() -> Void)?
    var onReschedule: (() -> Void)?
    
    @State private var showActionMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(memory.title)
                    .font(.appHeadline)
                    .foregroundColor(AppColor.white)
                    .lineLimit(2)

                Spacer()

                Button(action: {
                    onToggleComplete?()
                }) {
                    Image(systemName: memory.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(memory.isCompleted ? .green : AppColor.grey)
                }
            }

            if let description = memory.description, !description.isEmpty {
                Text(description)
                    .font(.appBodyText)
                    .foregroundColor(AppColor.grey)
                    .lineLimit(3)
            }

            HStack(spacing: 8) {
                PriorityBadge(priority: memory.priority)

                if let dateToRemember = memory.dateToRemember {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dateToRemember.formatted(date: .abbreviated, time: .omitted))
                            .font(.appCaption)
                    }
                    .foregroundColor(AppColor.grey)
                }

                Spacer()

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
            }

            if !memory.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(memory.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.appCaption)
                                .foregroundColor(AppColor.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColor.primary.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            if memory.relatedPerson != nil || memory.relatedTo != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let person = memory.relatedPerson {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                            Text(person)
                                .font(.appCaption)
                        }
                        .foregroundColor(AppColor.grey)
                    }

                    if let relatedTo = memory.relatedTo {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                            Text(relatedTo)
                                .font(.appCaption)
                        }
                        .foregroundColor(AppColor.grey)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#1C1C1C"))
        .cornerRadius(12)
        .opacity(memory.isCompleted ? 0.6 : 1.0)
        .onLongPressGesture {
            showActionMenu = true
        }
        .confirmationDialog("Memory Actions", isPresented: $showActionMenu, titleVisibility: .visible) {
            if memory.isCompleted {
                Button("Mark as Incomplete") {
                    onToggleComplete?()
                }
            } else {
                Button("Mark as Complete") {
                    onToggleComplete?()
                }
            }
            
            if onReschedule != nil {
                Button("Reschedule") {
                    onReschedule?()
                }
            }
            
            if onEdit != nil {
                Button("Edit") {
                    onEdit?()
                }
            }
            
            if onDelete != nil {
                Button("Delete", role: .destructive) {
                    onDelete?()
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(memory.title)
        }
    }
}

struct PriorityBadge: View {
    let priority: MemoryPriority

    var body: some View {
        Text(priority.rawValue)
            .font(.appCaption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: priority.color))
            .cornerRadius(8)
    }
}
