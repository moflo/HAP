//
//  Client.swift
//  HAP
//
//  Created by Bouke Haarsma on 13-07-16.
//
//

import Foundation
import Bignum
import CommonCrypto

public class Client {
    internal let a: Bignum
    internal let A: Bignum
    public let M1: Data
    public let M2: Data
    internal let H: (Data) -> Data

    public init (group: Group = .N2048, alg: HashAlgorithm = .SHA1, username: String, password: String, salt: Data, B: Data) {
        H = alg.hash
        let N = group.N
        let g = group.g
        let s = Bignum(data: salt)
        let B = Bignum(data: B)
        a = Bignum(data: generateRandomBytes(count: 32))
        A = mod_exp(g, a, N)

        let u = Bignum(data: H(pad(A.data, to: N) + pad(B.data, to: N)))
        let k = Bignum(data: H(N.data + pad(g.data, to: N)))
        let x = Bignum(data: H(salt + H("\(username):\(password)".data(using: .utf8)!)))

        let v = mod_exp(g, x, N)
        // S = (B - kg^x) ^ (a + ux)
        let S = mod_exp(B - k * v, a + u * x, N)
        let K = H(S.data)
        print("Client K", K)

        //M = H(H(N) xor H(g), H(I), s, A, B, K)
//        M1 = H((H(N.data) ^ H(g.data))! + H(username.data(using: .utf8)!) + s.data + A.data + B.data + K)
        M1 = calculateM(group: group, alg: alg, username: username, salt: salt, A: A.data, B: B.data, K: K)
        M2 = H(A.data + M1 + K)
    }

    public func computeA() -> Data {
        return A.data
    }

    public func verifySession(H_AMK: Data) throws {
        guard H_AMK == M2 else { throw Error.authenticationFailed }
    }
}