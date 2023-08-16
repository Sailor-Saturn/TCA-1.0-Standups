import ComposableArchitecture
import SwiftUI

struct StandupsListFeature: Reducer {
    struct State {
        // Cant use simple array since when we're accessing an element through some async work we can not be 100% sure the same element will be there every time
        // Allows to modify any element through their stable ID rather than their positional index
        var standups: IdentifiedArrayOf<Standup> = []
    }
    
    enum Action {
        case addButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.standups.append(
                    Standup(id: UUID(),
                            theme: .allCases.randomElement()!
                           )
                )
                return .none
            }
        }
    }
}

struct StandupsListView: View {
    let store: StoreOf<StandupsListFeature>
    var body: some View {
        WithViewStore(self.store, observe: \.standups/* if you want everything add {$0}*/) { viewStore in
            List {
                ForEach(viewStore.state) { standup in
                    CardView(standup: standup)
                        .listRowBackground(standup.theme.mainColor)
                }
            }
            .navigationTitle("Daily Standups")
            .toolbar {
                ToolbarItem {
                    Button("Add") {
                        viewStore.send(.addButtonTapped)
                    }
                }
            }
        }
        
    }
}
struct StandupsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StandupsListView(
                store: Store(initialState: StandupsListFeature.State(
                    standups: [.mock]
                  )){
                    StandupsListFeature()
                })
        }
    }
}
