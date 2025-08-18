import SwiftUI

struct GrapePicker: View {
  @Environment(\.locale) var locale
  @State var model = Model()
  @Binding var grape: Grape?
  @Environment(\.dismiss) var dismiss
  
  @Observable
  final class Model {
    var searchText = ""
    var grapes: [Grape] = [
      Grape(id: UUID(), name: "Cabernet Sauvignon", localizedNames: ["ja": "カベルネ・ソーヴィニヨン"]),
      Grape(id: UUID(), name: "Merlot", localizedNames: ["ja": "メルロー"]),
      Grape(id: UUID(), name: "Pinot Noir", localizedNames: ["ja": "ピノ・ノワール"]),
      Grape(id: UUID(), name: "Syrah (Shiraz)", localizedNames: ["ja": "シラーズ"]),
      Grape(id: UUID(), name: "Grenache", localizedNames: ["ja": "グルナッシュ"]),
      Grape(id: UUID(), name: "Tempranillo", localizedNames: ["ja": "テンプラニーリョ"]),
      Grape(id: UUID(), name: "Sangiovese", localizedNames: ["ja": "サンジョベーゼ"]),
      Grape(id: UUID(), name: "Nebbiolo", localizedNames: ["ja": "ネッビオーロ"]),
      Grape(id: UUID(), name: "Malbec", localizedNames: ["ja": "メルベック"]),
      Grape(id: UUID(), name: "Zinfandel (Primitivo)", localizedNames: ["ja": "プリミティーボ"]),
      Grape(id: UUID(), name: "Mourvèdre (Monastrell)", localizedNames: ["ja": "ムールヴェールド"]),
      Grape(id: UUID(), name: "Cabernet Franc", localizedNames: ["ja": "カベルネ・フラン"]),
      Grape(id: UUID(), name: "Carignan", localizedNames: ["ja": "カリニャン"]),
      Grape(id: UUID(), name: "Barbera", localizedNames: ["ja": "バルベーラ"]),
      Grape(id: UUID(), name: "Gamay", localizedNames: ["ja": "ガメイ"]),
      Grape(id: UUID(), name: "Petit Verdot", localizedNames: ["ja": "プチ・ヴェルド"]),
      Grape(id: UUID(), name: "Aglianico", localizedNames: ["ja": "アリアニコ"]),
      Grape(id: UUID(), name: "Tannat", localizedNames: ["ja": "タナ"]),
      Grape(id: UUID(), name: "Dolcetto", localizedNames: ["ja": "ドルチェット"]),
      Grape(id: UUID(), name: "Pinotage", localizedNames: ["ja": "ピノタージュ"]),
      Grape(id: UUID(), name: "Chardonnay", localizedNames: ["ja": "シャルドネ"]),
      Grape(id: UUID(), name: "Sauvignon Blanc", localizedNames: ["ja": "ソーヴィニヨン・ブラン"]),
      Grape(id: UUID(), name: "Riesling", localizedNames: ["ja": "リースリング"]),
      Grape(id: UUID(), name: "Pinot Grigio (Pinot Gris)", localizedNames: ["ja": "ピノ・グリ"]),
      Grape(id: UUID(), name: "Chenin Blanc", localizedNames: ["ja": "シュナン・ブラン"]),
      Grape(id: UUID(), name: "Gewürztraminer", localizedNames: ["ja": "ゲヴェルツ・トラミネール"]),
      Grape(id: UUID(), name: "Viognier", localizedNames: ["ja": "ヴィオニエ"]),
      Grape(id: UUID(), name: "Semillon", localizedNames: ["ja": "セミヨン"]),
      Grape(id: UUID(), name: "Muscat (Moscato)", localizedNames: ["ja": "ミュスカデ"]),
      Grape(id: UUID(), name: "Albariño", localizedNames: ["ja": "アルヴァリーニョ"]),
      Grape(id: UUID(), name: "Verdejo", localizedNames: ["ja": "ヴェルデホ"]),
      Grape(id: UUID(), name: "Grüner Veltliner", localizedNames: ["ja": "グリューナー・ヴェルトリーナー"]),
      Grape(id: UUID(), name: "Torrontés", localizedNames: ["ja": "トロントス"]),
      Grape(id: UUID(), name: "Trebbiano (Ugni Blanc)", localizedNames: ["ja": "トレッビアーノ"]),
      Grape(id: UUID(), name: "Fiano", localizedNames: ["ja": "フィアーノ"]),
      Grape(id: UUID(), name: "Vermentino", localizedNames: ["ja": "ヴェルメンティーノ"]),
      Grape(id: UUID(), name: "Marsanne", localizedNames: ["ja": "マルサンヌ"]),
      Grape(id: UUID(), name: "Roussanne", localizedNames: ["ja": "ルーサンヌ"]),
      Grape(id: UUID(), name: "Silvaner", localizedNames: ["ja": "シルヴァーナー"]),
      Grape(id: UUID(), name: "Müller-Thurgau", localizedNames: ["ja": "ミュラー・トゥルガウ"]),
    ]
  }
  
  var showGrapes: [Grape] {
    if model.searchText.isEmpty {
      model.grapes
    } else {
      model.grapes.filter { ($0.localizedNames[locale.language.languageCode?.identifier ?? ""] ?? $0.name).localizedStandardContains(model.searchText) }
    }
  }
  
  var namePrefixes: [String] {
    Set(showGrapes.compactMap { $0.localizedNames[locale.language.languageCode?.identifier ?? ""]?.first ?? $0.name.first })
      .map { String($0) }
      .sorted(using: String.StandardComparator.localizedStandard)
  }
  
  var body: some View {
    NavigationStack {
      List(selection: $grape) {
        ForEach(namePrefixes, id: \.self) { namePrefix in
          Section {
            let grapes = showGrapes.filter {
              if let prefix = $0.localizedNames[locale.language.languageCode?.identifier ?? ""]?.first ?? $0.name.first {
                return String(prefix) == namePrefix
              } else {
                return false
              }
            }
            ForEach(grapes) { grape in
              Text(grape.localizedNames[locale.language.languageCode?.identifier ?? ""] ?? grape.name)
                .tag(grape)
            }
          } header: {
            Text(namePrefix)
          }
          .sectionIndexLabel(Text(namePrefix))
        }
      }
      .searchable(text: $model.searchText)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .close) {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var grape: Grape?
  GrapePicker(grape: $grape)
    .environment(\.locale, Locale(identifier: "ja"))
}
