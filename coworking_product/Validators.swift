import Foundation

func formatarCPF(_ cpf: String) -> String {
    let numbers = cpf.prefix(11)
    let clean = String(numbers)
    let pattern = "(\\d{3})(\\d{3})(\\d{3})(\\d{2})"
    return clean.replacingOccurrences(of: pattern, with: "$1.$2.$3-$4", options: .regularExpression)
}

func isCPFValido(_ cpf: String) -> Bool {
    let numbers = cpf.filter(\.isNumber)
    guard numbers.count == 11, Set(numbers).count != 1 else { return false }

    let digits = numbers.compactMap { Int(String($0)) }

    func calcVerifier(_ slice: ArraySlice<Int>, factor: Int) -> Int {
        let sum = zip(slice, stride(from: factor, through: 2, by: -1)).map(*).reduce(0, +)
        let result = 11 - (sum % 11)
        return result > 9 ? 0 : result
    }

    let dv1 = calcVerifier(digits.prefix(9), factor: 10)
    let dv2 = calcVerifier(digits.prefix(10), factor: 11)

    return dv1 == digits[9] && dv2 == digits[10]
}

func isCNPJValido(_ cnpj: String) -> Bool {
    let numbers = cnpj.filter(\.isNumber)
    guard numbers.count == 14, Set(numbers).count != 1 else { return false }

    let digits = numbers.compactMap { Int(String($0)) }

    let weight1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    let weight2 = [6] + weight1

    func calcVerifier(_ weights: [Int]) -> Int {
        let sum = zip(digits.prefix(weights.count), weights).map(*).reduce(0, +)
        let result = sum % 11
        return result < 2 ? 0 : 11 - result
    }

    let dv1 = calcVerifier(weight1)
    let dv2 = calcVerifier(weight2)

    return dv1 == digits[12] && dv2 == digits[13]
}

func isEmailValido(_ email: String) -> Bool {
    let regex = #"^\S+@\S+\.\S+$"#
    return email.range(of: regex, options: .regularExpression) != nil
}
