// swift-tools-version:5.0
//
//  Package.swift
//  Perfect-Kafka
//
//  Created by Rockford Wei on 2017-02-28.
//  Copyright © 2017 PerfectlySoft. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2017 - 2018 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PackageDescription

let package = Package(
    name: "PerfectKafka",
    targets: [
        Target(name: "PerfectKefka")
    ],
    dependencies:[
      .package(url: "https://github.com/ClumsySmurf/Perfect-libKafka.git", .branch("master"))
    ]
)

