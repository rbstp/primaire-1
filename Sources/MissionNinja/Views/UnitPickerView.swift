import SwiftUI

/// One subject's year, block by block, in the order the class goes through
/// them. Each one opens the same dojo the week does, with the material that
/// block teaches.
struct UnitPickerView: View {
    let curriculum: Curriculum
    let catalog: WeekCatalog

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(curriculum.units) { unit in
                        if let lesson = curriculum.lesson(unit.id) {
                            NavigationLink {
                                DojoView(week: lesson, catalog: catalog)
                            } label: {
                                row(unit)
                            }
                            .buttonStyle(BrickButtonStyle(tone: .night, studs: 6, minHeight: 66, cornerRadius: 12))
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(curriculum.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                BrickTitle(text: curriculum.title)
            }
        }
    }

    private func row(_ unit: CurriculumUnit) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(unit.title)
                    .font(Typography.body)
                    .foregroundStyle(.ninjaCream)
                if let focus = unit.focus {
                    Text(focus)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.cream.opacity(0.6).color)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.ninjaBlade)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
