import SwiftUI
import ComposableArchitecture

struct StandupFormFeature: Reducer {
    struct State: Equatable {
        // @BindingState helps to avoid adding too much of actions +
        // implementing the action on the body of the reducer when we
        // are just setting the field
        @BindingState var focus: Field?
        @BindingState var standup: Standup
        
        enum Field: Hashable, Equatable {
            case attendee(Attendee.ID)
            case title
        }
        
        init(focus: Field? = nil, standup: Standup) {
            self.focus = focus
            self.standup = standup
            
            if self.standup.attendees.isEmpty {
                self.standup.attendees.append(Attendee(id: UUID()))
            }
        }
    }
    
    enum Action: BindableAction {
        case addAttendeeButtonTapped
        case deleteAttendees(indices: IndexSet)
        case binding(BindingAction<State>) // On this binding action, we will derive the bindings that are as @Binding State
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
            // Takes care of any binding actions, it will update the
        // vars that use the Binding Action .onChange(of: \.standup.title ....)
        
        // You can also listen for changes on the Binding Reducer
        Reduce { state, action in
            switch action {
            case .addAttendeeButtonTapped:
                let attendee = Attendee(id: Attendee.ID())
                state.standup.attendees.append(attendee)
                state.focus = .attendee(attendee.id)
                
                return .none
                
            case .deleteAttendees(let indices):
                state.standup.attendees.remove(atOffsets: indices)
                if state.standup.attendees.isEmpty {
                    // Make sure we always have at least one attendee
                    state.standup.attendees.append(Attendee(id: Attendee.ID()))
                }
                
                guard let firstIndex = indices.first
                else { return .none }
                // This logic is very complicated
                let index = min(
                    firstIndex, state.standup.attendees.count - 1
                )
                state.focus = .attendee(state.standup.attendees[index].id)
                return .none

            case .binding(_):
                return .none
            }
        }
    }
}

struct StandupFormView: View {
    let store: StoreOf<StandupFormFeature>
    // The focus state can only be handled on the view
    @FocusState var focus: StandupFormFeature.State.Field?
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    TextField("Title", text: viewStore.$standup.title) // This derives the binding of the string so when someone types a text on here we will send it through the binding action
                        .focused(self.$focus, equals: .title)
                    HStack {
                        Slider(
                            value: viewStore.$standup.duration.minutes, in: 5...30, step: 1
                        ) {
                            Text("Length")
                        }
                        Spacer()
                        Text(viewStore.standup.duration.formatted(.units()))
                    }
                    ThemePicker(selection: viewStore.$standup.theme)
                } header: {
                    Text("Standup Info")
                }
                Section {
                    ForEach(viewStore.$standup.attendees) { $attendee in
                        TextField("Name", text: $attendee.name)
                            .focused(self.$focus, equals: .attendee(attendee.id))
                        // Now if I delete an attendee the focus will be placed on the nearest element to the deleted item
                    }
                    .onDelete { indices in
                        viewStore.send(.deleteAttendees(indices: indices))
                    }
                    
                    Button("Add attendee") {
                        viewStore.send(.addAttendeeButtonTapped)
                    }
                } header: {
                    Text("Attendees")
                }
            }
            // viewStore.$focus is the source of truth, when
            .bind(viewStore.$focus, to: self.$focus)
        }
    }
}

extension Duration {
  fileprivate var minutes: Double {
    get { Double(self.components.seconds / 60) }
    set { self = .seconds(newValue * 60) }
  }
}

struct ThemePicker: View {
    @Binding var selection: Theme
    
    var body: some View {
        Picker("Theme", selection: self.$selection) {
            ForEach(Theme.allCases) { theme in
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.mainColor)
                    Label(theme.name, systemImage: "paintpalette")
                        .padding(4)
                }
                .foregroundColor(theme.accentColor)
                .fixedSize(horizontal: false, vertical: true)
                .tag(theme)
            }
        }
    }
}

struct StandupForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StandupFormView(
              store: Store(initialState: StandupFormFeature.State(standup: .mock)) {
                StandupFormFeature()
              }
            )
          }
    }
}
