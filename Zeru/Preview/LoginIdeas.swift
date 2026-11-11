//
//  LoginIdeas.swift
//  Zeru
//
//  Quatre directions natives pour l'écran de connexion.
//  Fichier de prévisualisation (DEBUG) : ouvre-le dans Xcode pour le canvas,
//  ou lance l'app avec `-login-idea 1` … `-login-idea 4` pour les captures.
//

#if DEBUG
import SwiftUI

// MARK: - Décor commun

/// Fond ambiant : deux halos de couleur sur du noir, comme les fonds
/// « profonds » d'iOS (Musique, Siri, App Store).
struct LoginIdeaBackground: View {
    var accent: Color = .accentColor

    var body: some View {
        ZStack {
            Color.black
            Circle()
                .fill(accent.opacity(0.30))
                .frame(width: 480, height: 480)
                .blur(radius: 140)
                .offset(x: -140, y: -320)
            Circle()
                .fill(Color(red: 0.20, green: 0.32, blue: 0.95).opacity(0.22))
                .frame(width: 440, height: 440)
                .blur(radius: 160)
                .offset(x: 160, y: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

/// L'icône de l'app avec son liseré de verre.
struct LoginIdeaIcon: View {
    var size: CGFloat = 64

    var body: some View {
        Image("IconPreviewClassic")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 18, y: 10)
    }
}

/// Champ de saisie en verre, avec son état de focus.
struct LoginIdeaField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var highlighted: Bool = false
    var focus: FocusState<Int?>.Binding
    var index: Int

    private var isFocused: Bool { highlighted || focus.wrappedValue == index }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(isFocused ? 0.95 : 0.5))
                .frame(width: 22)
                .contentTransition(.symbolEffect(.replace))

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboard)
            .focused(focus, equals: index)
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(isFocused ? 0.11 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(isFocused ? 0.30 : 0.10), lineWidth: 1)
        )
        .animation(.snappy(duration: 0.22), value: isFocused)
        .frame(maxWidth: .infinity)
    }
}

/// Le bouton principal, en verre teinté (Liquid Glass).
struct LoginIdeaPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(.accentColor)
    }
}

struct LoginIdeaFooter: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("En te connectant, tu acceptes les")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.30))
            Text("Conditions d'utilisation d'Izly")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Idée 1 · Le guichet
//
// Une seule question à la fois, comme les feuilles d'authentification d'Apple :
// l'identifiant, puis le mot de passe. Le champ se remplace par une transition
// poussée, le titre s'interpole, les points de progression s'étirent.

struct LoginIdeaOne: View {
    @State private var step = 0
    @State private var identifier = "camille.moreau@etu.u-paris.fr"
    @State private var password = ""
    @FocusState private var focus: Int?
    @State private var appeared = false

    private var isIdentifierStep: Bool { step == 0 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            header

            Spacer(minLength: 44)

            VStack(spacing: 22) {
                titleBlock
                field
                dots
            }

            Spacer(minLength: 20)

            actionButton

            Button("Découvrir la démo") {}
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 14)

            Spacer(minLength: 16)

            LoginIdeaFooter()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 26)
        .background { LoginIdeaBackground() }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .sensoryFeedback(.selection, trigger: step)
    }

    private var header: some View {
        HStack(spacing: 12) {
            LoginIdeaIcon(size: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text("Zeru")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Ton compte Izly")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isIdentifierStep ? "On commence par toi." : "Et ton mot de passe.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.interpolate)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(isIdentifierStep ? "Ton email ou ton numéro Izly." : "Celui qui protège ton compte.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .contentTransition(.interpolate)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
    }

    private var field: some View {
        ZStack {
            if isIdentifierStep {
                LoginIdeaField(
                    icon: "envelope",
                    placeholder: "Email ou numéro",
                    text: $identifier,
                    keyboard: .emailAddress,
                    focus: $focus,
                    index: 0
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            } else {
                LoginIdeaField(
                    icon: "lock",
                    placeholder: "Mot de passe",
                    text: $password,
                    isSecure: true,
                    focus: $focus,
                    index: 1
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color.accentColor : Color.white.opacity(0.15))
                    .frame(width: index == step ? 20 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
    }

    private var actionButton: some View {
        LoginIdeaPrimaryButton(
            title: isIdentifierStep ? "Continuer" : "Se connecter",
            systemImage: isIdentifierStep ? "arrow.right" : "lock.open.fill"
        ) {
            if isIdentifierStep {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    step = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focus = 1 }
            } else {
                focus = nil
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }
}

// MARK: - Idée 2 · La carte qui se déplie
//
// L'icône s'ouvre en une carte de verre qui se déplie (rotation 3D + ressort),
// puis les champs apparaissent en décalé. Le geste est celui d'une carte Apple
// Wallet qui s'ouvre.

struct LoginIdeaTwo: View {
    @State private var expanded = false
    @State private var identifier = "camille.moreau@etu.u-paris.fr"
    @State private var password = ""
    @FocusState private var focus: Int?

    var body: some View {
        VStack {
            Spacer()
            card
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .background { LoginIdeaBackground() }
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.78)) {
                    expanded = true
                }
            }
        }
    }

    private var card: some View {
        VStack(spacing: 18) {
            LoginIdeaIcon(size: expanded ? 52 : 72)

            if expanded {
                VStack(spacing: 12) {
                    LoginIdeaField(
                        icon: "envelope",
                        placeholder: "Email ou numéro",
                        text: $identifier,
                        keyboard: .emailAddress,
                        focus: $focus,
                        index: 0
                    )
                    LoginIdeaField(
                        icon: "lock",
                        placeholder: "Mot de passe",
                        text: $password,
                        isSecure: true,
                        focus: $focus,
                        index: 1
                    )
                }
                .transition(.opacity.combined(with: .offset(y: 14)))

                LoginIdeaPrimaryButton(title: "Se connecter", systemImage: "arrow.right") {}
                    .transition(.opacity.combined(with: .offset(y: 14)))

                Button("Découvrir la démo") {}
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .transition(.opacity)
            } else {
                Text("Zeru")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .transition(.opacity)
            }
        }
        .padding(expanded ? 22 : 16)
        .frame(maxWidth: expanded ? .infinity : nil)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: expanded ? 30 : 26, style: .continuous))
        .rotation3DEffect(
            .degrees(expanded ? 0 : -72),
            axis: (x: 1, y: 0, z: 0),
            anchor: .top,
            perspective: 0.6
        )
        .scaleEffect(expanded ? 1 : 0.9)
        .shadow(color: .black.opacity(0.35), radius: 30, y: 18)
        .animation(.spring(response: 0.8, dampingFraction: 0.78), value: expanded)
    }
}

// MARK: - Idée 3 · La lentille
//
// Un mesh gradient qui respire en fond, et une lentille de verre dont le focus
// glisse d'un champ à l'autre. C'est le langage « ambient » d'iOS 26/27.

struct LoginIdeaThree: View {
    @State private var identifier = "camille.moreau@etu.u-paris.fr"
    @State private var password = ""
    @State private var lensFocus: Int? = 0
    @FocusState private var focus: Int?
    @Namespace private var lensNamespace
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            header

            Spacer(minLength: 40)

            lens

            Spacer(minLength: 24)

            LoginIdeaPrimaryButton(title: "Se connecter", systemImage: "arrow.right") {}
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

            Button("Découvrir la démo") {}
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 14)

            Spacer(minLength: 16)

            LoginIdeaFooter()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 26)
        .background { LoginIdeaMeshBackground() }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            LoginIdeaIcon(size: 52)
            Text("Zeru")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Ton compte Izly, sans prise de tête.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private var lens: some View {
        VStack(spacing: 10) {
            fieldRow(
                index: 0,
                icon: "envelope",
                placeholder: "Email ou numéro",
                text: $identifier,
                keyboard: .emailAddress
            )
            fieldRow(
                index: 1,
                icon: "lock",
                placeholder: "Mot de passe",
                text: $password,
                isSecure: true
            )
        }
        .padding(10)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func fieldRow(
        index: Int,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        ZStack {
            if lensFocus == index {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accentColor.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.45), lineWidth: 1)
                    )
                    .matchedGeometryEffect(id: "lens-focus", in: lensNamespace)
            }

            LoginIdeaField(
                icon: icon,
                placeholder: placeholder,
                text: text,
                isSecure: isSecure,
                keyboard: keyboard,
                highlighted: lensFocus == index,
                focus: $focus,
                index: index
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                lensFocus = index
            }
        }
    }
}

/// Le mesh gradient animé : des points qui dérivent lentement, comme les fonds
/// de Musique ou de Siri. Aucun shader custom, uniquement `MeshGradient`.
struct LoginIdeaMeshBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            MeshGradient(
                width: 3,
                height: 3,
                points: points(t),
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.10),
                    Color(red: 0.10, green: 0.09, blue: 0.26),
                    Color(red: 0.04, green: 0.05, blue: 0.10),
                    Color(red: 0.09, green: 0.12, blue: 0.32),
                    Color(red: 0.24, green: 0.18, blue: 0.50),
                    Color(red: 0.06, green: 0.09, blue: 0.24),
                    Color(red: 0.04, green: 0.05, blue: 0.10),
                    Color(red: 0.10, green: 0.10, blue: 0.28),
                    Color(red: 0.04, green: 0.05, blue: 0.10)
                ]
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private func points(_ t: TimeInterval) -> [SIMD2<Float>] {
        let a = Float(sin(t * 0.25)) * 0.06
        let b = Float(cos(t * 0.21)) * 0.06
        let c = Float(sin(t * 0.19)) * 0.05
        return [
            SIMD2(0, 0), SIMD2(0.5 + a, 0), SIMD2(1, 0),
            SIMD2(0, 0.5 + b), SIMD2(0.5 + b, 0.5 + c), SIMD2(1, 0.5 + a),
            SIMD2(0, 1), SIMD2(0.5 + c, 1), SIMD2(1, 1)
        ]
    }
}

// MARK: - Idée 4 · L'empreinte
//
// Face ID d'abord : le glyphe respire, le bouton principal déverrouille.
// Les identifiants restent accessibles derrière un lien, dans une feuille
// de verre qui monte du bas.

struct LoginIdeaFour: View {
    @State private var showForm = false
    @State private var identifier = "camille.moreau@etu.u-paris.fr"
    @State private var password = ""
    @FocusState private var focus: Int?
    @State private var appeared = false
    @State private var unlocked = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 32)

            if showForm {
                formSheet
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                hero
                    .transition(.opacity)
            }

            Spacer(minLength: 20)

            LoginIdeaFooter()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 26)
        .background { LoginIdeaBackground() }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .sensoryFeedback(.success, trigger: unlocked)
    }

    private var hero: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.16))
                    .frame(width: 150, height: 150)
                    .blur(radius: 24)

                Circle()
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    .frame(width: 132, height: 132)

                Image(systemName: unlocked ? "checkmark" : "faceid")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.breathe, options: .repeating, isActive: !unlocked)
            }
            .scaleEffect(appeared ? 1 : 0.82)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text("Bon retour, Camille.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Déverrouille Zeru avec Face ID.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .multilineTextAlignment(.center)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            VStack(spacing: 14) {
                LoginIdeaPrimaryButton(
                    title: unlocked ? "C'est bon" : "Se connecter avec Face ID",
                    systemImage: unlocked ? "checkmark" : "faceid"
                ) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        unlocked = true
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        showForm = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focus = 0 }
                } label: {
                    Text("Utiliser mes identifiants")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
        }
    }

    private var formSheet: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Tes identifiants")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    focus = nil
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        showForm = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 30, height: 30)
                        .glassEffect(.regular, in: Circle())
                }
                .buttonStyle(.plain)
            }

            LoginIdeaField(
                icon: "envelope",
                placeholder: "Email ou numéro",
                text: $identifier,
                keyboard: .emailAddress,
                focus: $focus,
                index: 0
            )
            LoginIdeaField(
                icon: "lock",
                placeholder: "Mot de passe",
                text: $password,
                isSecure: true,
                focus: $focus,
                index: 1
            )

            LoginIdeaPrimaryButton(title: "Se connecter", systemImage: "arrow.right") {}
        }
        .padding(22)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

// MARK: - Hôte de captures

enum LoginIdeaDebug {
    /// `-login-idea 1` … `-login-idea 4` : affiche une idée au lieu de l'app.
    static var selectedIdea: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-login-idea"),
              index + 1 < arguments.count,
              let value = Int(arguments[index + 1]) else {
            return nil
        }
        return value
    }
}

struct LoginIdeaDebugHost: View {
    let idea: Int

    var body: some View {
        Group {
            switch idea {
            case 1: LoginIdeaOne()
            case 2: LoginIdeaTwo()
            case 3: LoginIdeaThree()
            case 4: LoginIdeaFour()
            default: LoginIdeaOne()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("1 · Le guichet") {
    LoginIdeaOne()
}

#Preview("2 · La carte se déplie") {
    LoginIdeaTwo()
}

#Preview("3 · La lentille") {
    LoginIdeaThree()
}

#Preview("4 · L'empreinte") {
    LoginIdeaFour()
}
#endif
