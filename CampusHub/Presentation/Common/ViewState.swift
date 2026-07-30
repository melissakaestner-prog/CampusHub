import Foundation

/// Estado genérico de um ecrã orientado a dados: cobre explicitamente
/// carregamento, sucesso, lista vazia e erro.
enum ViewState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case error(String)
}
