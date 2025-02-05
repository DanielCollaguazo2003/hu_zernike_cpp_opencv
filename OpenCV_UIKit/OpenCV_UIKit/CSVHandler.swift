import Foundation

class CSVHandler {
    static func loadMoments(from filePath: String) -> [(category: String, moments: [Double])]? {
        guard let content = try? String(contentsOfFile: filePath) else {
            print("Error al leer el archivo CSV")
            return nil
        }
        
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var momentsData: [(String, [Double])] = []
        
        for line in lines.dropFirst() {  // Omitir la cabecera
            let components = line.components(separatedBy: ",")
            guard components.count > 1 else { continue }
            
            let category = components[0]
            let moments = components.dropFirst().compactMap { Double($0) }
            momentsData.append((category, moments))
        }
        
        return momentsData
    }
}
