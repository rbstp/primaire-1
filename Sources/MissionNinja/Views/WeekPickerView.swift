import SwiftUI

/// Every lesson plan the app carries, newest first, for the evenings we want
/// to go back over a week that is done.
struct WeekPickerView: View {
    let catalog: WeekCatalog

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(catalog.weeks) { week in
                        NavigationLink {
                            DojoView(week: week, catalog: catalog)
                        } label: {
                            HStack {
                                Text(week.title)
                                    .font(Typography.body)
                                    .foregroundStyle(.ninjaCream)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.ninjaBlade)
                            }
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(BrickButtonStyle(tone: .night, studs: 6, minHeight: 54, cornerRadius: 10))
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Les semaines")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                BrickTitle(text: "Les semaines")
            }
        }
    }
}
