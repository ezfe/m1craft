//
//  Constants.swift
//  M1Craft UI
//
//  Created by Ezekiel Elin on 11/15/21.
//

import Foundation

//let serverAddress = URL(string: "http://localhost:8080/api")!
let serverAddress = URL(string: "https://m1craft.ezekiel.dev/api")!

let authStartUrl = serverAddress.appendingPathComponent("auth/start")
let authRefreshUrl = serverAddress.appendingPathComponent("auth/refresh")
let preflightUrl = serverAddress.appendingPathComponent("preflight")
let manifestUrl = serverAddress.appendingPathComponent("manifest")
