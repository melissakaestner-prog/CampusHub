import Foundation

/// Descrição declarativa de um endpoint da API.
struct Endpoint: Equatable {
    let path: String
    var queryItems: [URLQueryItem] = []

    static let schedule = Endpoint(path: "schedule")
    static let professors = Endpoint(path: "professors")
    static let units = Endpoint(path: "units")
    static let newAllocation = Endpoint(path: "schedule")
    static let newTimesheet = Endpoint(path: "timesheets")

    static func timesheets(professorID: String) -> Endpoint {
        Endpoint(
            path: "timesheets",
            queryItems: [URLQueryItem(name: "professorId", value: professorID)]
        )
    }

    func url(relativeTo baseURL: URL) -> URL? {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
}
