import SwiftUI

struct AreaView: View {
  var area: Area
  @Environment(\.areas) var areas: [Area]
  @Environment(\.locale) var locale
  
  var body: some View {
    let childAreas = self.areas.filter { $0.parentId == area.id }
    if childAreas.isEmpty {
      Text(area.localizedNames[locale.language.languageCode?.identifier ?? ""] ?? area.name)
        .tag(area)
    } else {
      DisclosureGroup {
        ForEach(childAreas) { area in
          AreaView(area: area)
        }
      } label: {
        Text(area.localizedNames[locale.language.languageCode?.identifier ?? ""] ?? area.name)
      }
      .tag(area)
    }
  }
}

struct ProductAreaPicker: View {
  @Binding var area: Area?
  @State var areas: [Area] = []
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    NavigationStack {
      List(selection: $area) {
        let areas = self.areas.filter { $0.parentId == nil }
        ForEach(areas) { area in
          AreaView(area: area)
        }
      }
      .navigationTitle(Text("Select Production Area"))
      .toolbar {
        #if !os(macOS)
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .close) {
            dismiss()
          }
        }
        #endif
      }
    }
    .environment(\.areas, areas)
    .task {
      // MARK: - Country
      let france = Area(
        id: UUID(),
        parentId: nil,
        name: "France",
        localizedNames: ["ja": "フランス"]
      )

      // MARK: - Regions
      let burgundy = Area(
        id: UUID(),
        parentId: france.id,
        name: "Burgundy",
        localizedNames: ["ja": "ブルゴーニュ"]
      )
      let bordeaux = Area(
        id: UUID(),
        parentId: france.id,
        name: "Bordeaux",
        localizedNames: ["ja": "ボルドー"]
      )
      let champagne = Area(
        id: UUID(),
        parentId: france.id,
        name: "Champagne",
        localizedNames: ["ja": "シャンパーニュ"]
      )
      let alsace = Area(
        id: UUID(),
        parentId: france.id,
        name: "Alsace",
        localizedNames: ["ja": "アルザス"]
      )
      
      // MARK: - Burgundy » Villages
      let gevreyChambertin = Area(
        id: UUID(),
        parentId: burgundy.id,
        name: "Gevrey-Chambertin",
        localizedNames: ["ja": "ジュヴレ・シャンベルタン"]
      )
      let vosneRomanee = Area(
        id: UUID(),
        parentId: burgundy.id,
        name: "Vosne-Romanée",
        localizedNames: ["ja": "ヴォーヌ・ロマネ"]
      )
      let pulignyMontrachet = Area(
        id: UUID(),
        parentId: burgundy.id,
        name: "Puligny-Montrachet",
        localizedNames: ["ja": "ピュリニー・モンラッシェ"]
      )
      let meursault = Area(
        id: UUID(),
        parentId: burgundy.id,
        name: "Meursault",
        localizedNames: ["ja": "ムルソー"]
      )
      let chablis = Area(
        id: UUID(),
        parentId: burgundy.id,
        name: "Chablis",
        localizedNames: ["ja": "シャブリ"]
      )
      
      // MARK: - Burgundy » Producers
      let armandRousseau = Area(
        id: UUID(),
        parentId: gevreyChambertin.id,
        name: "Domaine Armand Rousseau",
        localizedNames: ["ja": "ドメーヌ・アルマン・ルソー"]
      )
      let drc = Area(
        id: UUID(),
        parentId: vosneRomanee.id,
        name: "Domaine de la Romanée-Conti",
        localizedNames: ["ja": "ドメーヌ・ド・ラ・ロマネ・コンティ"]
      )
      let leflaive = Area(
        id: UUID(),
        parentId: pulignyMontrachet.id,
        name: "Domaine Leflaive",
        localizedNames: ["ja": "ドメーヌ・ルフレーヴ"]
      )
      let cocheDury = Area(
        id: UUID(),
        parentId: meursault.id,
        name: "Domaine Coche-Dury",
        localizedNames: ["ja": "コシュ＝デュリ"]
      )
      let raveneau = Area(
        id: UUID(),
        parentId: chablis.id,
        name: "Domaine François Raveneau",
        localizedNames: ["ja": "ドメーヌ・フランソワ・ラヴノー"]
      )
      
      // MARK: - Burgundy » Vineyards (under Producer)
      let chambertin = Area(
        id: UUID(),
        parentId: armandRousseau.id,
        name: "Chambertin",
        localizedNames: ["ja": "シャンベルタン"]
      )
      let closDeBeze = Area(
        id: UUID(),
        parentId: armandRousseau.id,
        name: "Chambertin Clos de Bèze",
        localizedNames: ["ja": "シャンベルタン・クロ・ド・ベーズ"]
      )
      
      let romaneeConti = Area(
        id: UUID(),
        parentId: drc.id,
        name: "Romanée-Conti",
        localizedNames: ["ja": "ロマネ・コンティ"]
      )
      let laTache = Area(
        id: UUID(),
        parentId: drc.id,
        name: "La Tâche",
        localizedNames: ["ja": "ラ・ターシュ"]
      )
      let richebourg = Area(
        id: UUID(),
        parentId: drc.id,
        name: "Richebourg",
        localizedNames: ["ja": "リシュブール"]
      )
      let rsv = Area(
        id: UUID(),
        parentId: drc.id,
        name: "Romanée-Saint-Vivant",
        localizedNames: ["ja": "ロマネ・サン・ヴィヴァン"]
      )
      
      let chevalierMontrachet = Area(
        id: UUID(),
        parentId: leflaive.id,
        name: "Chevalier-Montrachet",
        localizedNames: ["ja": "シュヴァリエ・モンラッシェ"]
      )
      let batardMontrachet = Area(
        id: UUID(),
        parentId: leflaive.id,
        name: "Bâtard-Montrachet",
        localizedNames: ["ja": "バタール・モンラッシェ"]
      )
      let lesPucelles = Area(
        id: UUID(),
        parentId: leflaive.id,
        name: "Les Pucelles",
        localizedNames: ["ja": "レ・ピュセル"]
      )
      
      let perrieres = Area(
        id: UUID(),
        parentId: cocheDury.id,
        name: "Meursault 1er Cru Les Perrières",
        localizedNames: ["ja": "ムルソー 1級 レ・ペリエール"]
      )
      let genevrieres = Area(
        id: UUID(),
        parentId: cocheDury.id,
        name: "Meursault 1er Cru Les Genevrières",
        localizedNames: ["ja": "ムルソー 1級 レ・ジュヌヴリエール"]
      )
      
      let chablisLesClos = Area(
        id: UUID(),
        parentId: raveneau.id,
        name: "Chablis Grand Cru Les Clos",
        localizedNames: ["ja": "シャブリ 特級 レ・クロ"]
      )
      let chablisLesPreuses = Area(
        id: UUID(),
        parentId: raveneau.id,
        name: "Chablis Grand Cru Les Preuses",
        localizedNames: ["ja": "シャブリ 特級 レ・プルーズ"]
      )
      
      // MARK: - Bordeaux » Communes
      let pauillac = Area(
        id: UUID(),
        parentId: bordeaux.id,
        name: "Pauillac",
        localizedNames: ["ja": "ポイヤック"]
      )
      let saintJulien = Area(
        id: UUID(),
        parentId: bordeaux.id,
        name: "Saint-Julien",
        localizedNames: ["ja": "サン・ジュリアン"]
      )
      let margaux = Area(
        id: UUID(),
        parentId: bordeaux.id,
        name: "Margaux",
        localizedNames: ["ja": "マルゴー"]
      )
      let saintEmilion = Area(
        id: UUID(),
        parentId: bordeaux.id,
        name: "Saint-Émilion",
        localizedNames: ["ja": "サン・テミリオン"]
      )
      let pomerol = Area(
        id: UUID(),
        parentId: bordeaux.id,
        name: "Pomerol",
        localizedNames: ["ja": "ポムロール"]
      )
      
      // MARK: - Bordeaux » Producers
      let lafite = Area(
        id: UUID(),
        parentId: pauillac.id,
        name: "Château Lafite Rothschild",
        localizedNames: ["ja": "シャトー・ラフィット・ロスチャイルド"]
      )
      let latour = Area(
        id: UUID(),
        parentId: pauillac.id,
        name: "Château Latour",
        localizedNames: ["ja": "シャトー・ラトゥール"]
      )
      let mouton = Area(
        id: UUID(),
        parentId: pauillac.id,
        name: "Château Mouton Rothschild",
        localizedNames: ["ja": "シャトー・ムートン・ロスチャイルド"]
      )
      
      let chevalBlanc = Area(
        id: UUID(),
        parentId: saintEmilion.id,
        name: "Château Cheval Blanc",
        localizedNames: ["ja": "シャトー・シュヴァル・ブラン"]
      )
      let petrus = Area(
        id: UUID(),
        parentId: pomerol.id,
        name: "Pétrus",
        localizedNames: ["ja": "ペトリュス"]
      )
      
      // MARK: - Bordeaux » Vineyards (estate-level)
      let enclosLatour = Area(
        id: UUID(),
        parentId: latour.id,
        name: "L'Enclos",
        localizedNames: ["ja": "ランクロ（エンクロ）"]
      ) // ラトゥールの城壁内区画
      let carruades = Area(
        id: UUID(),
        parentId: lafite.id,
        name: "Carruades",
        localizedNames: ["ja": "カリュアド"]
      )
      let petrusVineyard = Area(
        id: UUID(),
        parentId: petrus.id,
        name: "Pétrus Vineyard",
        localizedNames: ["ja": "ペトリュスの畑"]
      )
      
      // MARK: - Champagne » Villages
      let ay = Area(
        id: UUID(),
        parentId: champagne.id,
        name: "Aÿ",
        localizedNames: ["ja": "アイ"]
      )
      let leMesnil = Area(
        id: UUID(),
        parentId: champagne.id,
        name: "Le Mesnil-sur-Oger",
        localizedNames: ["ja": "ル・メニル＝シュル＝オジェ"]
      )
      let ambonnay = Area(
        id: UUID(),
        parentId: champagne.id,
        name: "Ambonnay",
        localizedNames: ["ja": "アンボネ"]
      )
      let mareuilSurAy = Area(
        id: UUID(),
        parentId: champagne.id,
        name: "Mareuil-sur-Aÿ",
        localizedNames: ["ja": "マルイユ＝シュル＝アイ"]
      )
      
      // MARK: - Champagne » Producers
      let bollinger = Area(
        id: UUID(),
        parentId: ay.id,
        name: "Bollinger",
        localizedNames: ["ja": "ボランジェ"]
      )
      let salon = Area(
        id: UUID(),
        parentId: leMesnil.id,
        name: "Salon",
        localizedNames: ["ja": "サロン"]
      )
      let pierrePeters = Area(
        id: UUID(),
        parentId: leMesnil.id,
        name: "Pierre Péters",
        localizedNames: ["ja": "ピエール・ペテルス"]
      )
      let eglyOuriet = Area(
        id: UUID(),
        parentId: ambonnay.id,
        name: "Egly-Ouriet",
        localizedNames: ["ja": "エグリ・ウーリエ"]
      )
      let philipponnat = Area(
        id: UUID(),
        parentId: mareuilSurAy.id,
        name: "Philipponnat",
        localizedNames: ["ja": "フィリポナ"]
      )
      
      // MARK: - Champagne » Vineyards
      let vvf = Area(
        id: UUID(),
        parentId: bollinger.id,
        name: "Vieilles Vignes Françaises",
        localizedNames: ["ja": "ヴィエイユ・ヴィーニュ・フランセーズ"]
      )
      let lesChetillons = Area(
        id: UUID(),
        parentId: pierrePeters.id,
        name: "Les Chétillons",
        localizedNames: ["ja": "レ・シェティヨン"]
      )
      let lesCrayeres = Area(
        id: UUID(),
        parentId: eglyOuriet.id,
        name: "Les Crayères",
        localizedNames: ["ja": "レ・クレイエール"]
      )
      let closDesGoisses = Area(
        id: UUID(),
        parentId: philipponnat.id,
        name: "Clos des Goisses",
        localizedNames: ["ja": "クロ・デ・ゴワス"]
      )
      // Salon は特定区画名を持たず、ル・メニルの選抜なので汎用名を付与
      let mesnilParcels = Area(
        id: UUID(),
        parentId: salon.id,
        name: "Le Mesnil Grand Cru Parcels",
        localizedNames: ["ja": "ル・メニルGC選抜区画"]
      )
      
      // MARK: - Alsace » Villages
      let ribeauville = Area(
        id: UUID(),
        parentId: alsace.id,
        name: "Ribeauvillé",
        localizedNames: ["ja": "リボヴィレ"]
      )
      let turckheim = Area(
        id: UUID(),
        parentId: alsace.id,
        name: "Turckheim",
        localizedNames: ["ja": "テュルクハイム"]
      )
      let riquewihr = Area(
        id: UUID(),
        parentId: alsace.id,
        name: "Riquewihr",
        localizedNames: ["ja": "リクヴィール"]
      )
      let kaysersberg = Area(
        id: UUID(),
        parentId: alsace.id,
        name: "Kaysersberg",
        localizedNames: ["ja": "カイゼルスベルグ"]
      )
      
      // MARK: - Alsace » Producers
      let trimbach = Area(
        id: UUID(),
        parentId: ribeauville.id,
        name: "Trimbach",
        localizedNames: ["ja": "トリンバック"]
      )
      let zindHumbrecht = Area(
        id: UUID(),
        parentId: turckheim.id,
        name: "Zind-Humbrecht",
        localizedNames: ["ja": "ツィント＝フンブレヒト"]
      )
      let hugel = Area(
        id: UUID(),
        parentId: riquewihr.id,
        name: "Hugel",
        localizedNames: ["ja": "ヒュゲル"]
      )
      let weinbach = Area(
        id: UUID(),
        parentId: kaysersberg.id,
        name: "Domaine Weinbach",
        localizedNames: ["ja": "ドメーヌ・ヴァインバック"]
      )
      
      // MARK: - Alsace » Vineyards
      let closSainteHune = Area(
        id: UUID(),
        parentId: trimbach.id,
        name: "Clos Sainte Hune",
        localizedNames: ["ja": "クロ・サンテューヌ"]
      )
      let brand = Area(
        id: UUID(),
        parentId: zindHumbrecht.id,
        name: "Brand",
        localizedNames: ["ja": "ブラン"]
      )
      let herrenweg = Area(
        id: UUID(),
        parentId: zindHumbrecht.id,
        name: "Herrenweg de Turckheim",
        localizedNames: ["ja": "エルンヴェグ・ド・テュルクハイム"]
      )
      let schoenenbourg = Area(
        id: UUID(),
        parentId: hugel.id,
        name: "Schoenenbourg",
        localizedNames: ["ja": "シューネンブール"]
      )
      let closDesCapucins = Area(
        id: UUID(),
        parentId: weinbach.id,
        name: "Clos des Capucins",
        localizedNames: ["ja": "クロ・デ・カピュサン"]
      )

      self.areas = [
        france,
        burgundy, bordeaux, champagne, alsace,
        gevreyChambertin, vosneRomanee, pulignyMontrachet, meursault, chablis,
        armandRousseau, drc, leflaive, cocheDury, raveneau,
        chambertin, closDeBeze, romaneeConti, laTache, richebourg, rsv,
        chevalierMontrachet, batardMontrachet, lesPucelles, perrieres, genevrieres,
        chablisLesClos, chablisLesPreuses,
        pauillac, saintJulien, margaux, saintEmilion, pomerol,
        lafite, latour, mouton, chevalBlanc, petrus,
        enclosLatour, carruades, petrusVineyard,
        ay, leMesnil, ambonnay, mareuilSurAy,
        bollinger, salon, pierrePeters, eglyOuriet, philipponnat,
        vvf, lesChetillons, lesCrayeres, closDesGoisses, mesnilParcels,
        ribeauville, turckheim, riquewihr, kaysersberg,
        trimbach, zindHumbrecht, hugel, weinbach,
        closSainteHune, brand, herrenweg, schoenenbourg, closDesCapucins
      ]
    }
  }
}

extension EnvironmentValues {
  @Entry var areas: [Area] = []
}
