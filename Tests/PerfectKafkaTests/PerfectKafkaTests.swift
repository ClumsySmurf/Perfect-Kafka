//
//  PerfectKafkaTests.swift
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

#if os(Linux)
import SwiftGlibc
#else
import Darwin
#endif

import XCTest
@testable import PerfectKafka

class PerfectKafkaTests: XCTestCase {

  let hosts = "nut.krb5.ca:9092"
    func testConfig() {
        do {
          let k = try Kafka.Config()
          let dic = k.properties
          print(dic)
          XCTAssertGreaterThan(dic.count, 0)

          let conf = try Kafka.Config(k)
          let d2 = conf.properties
          print(d2)

          let testKey = "fetch.wait.max.ms"
          var fwait = try conf.get(testKey)
          print(fwait)
          let testValue = "200"
          try conf.set(testKey, value: testValue)
          fwait =  try conf.get(testKey)
          print(fwait)
          XCTAssertEqual(testValue, fwait)
        }catch(let err) {
          XCTFail("Config \(err)")
        }
    }

  func testTopicConfig() {
    do {
      let config = try Kafka.TopicConfig()
      let conf = try Kafka.TopicConfig(config)
      let dic = conf.properties
      print(dic)
      XCTAssertGreaterThan(dic.count, 0)
      let testKey = "request.timeout.ms"
      var fwait = try conf.get(testKey)
      print(fwait)
      let testValue = "4000"
      try conf.set(testKey, value: testValue)
      fwait =  try conf.get(testKey)
      print(fwait)
      XCTAssertEqual(testValue, fwait)
    }catch(let err) {
      XCTFail("Topic Config \(err)")
    }
  }

  func testProducer () {
    do {
      let producer = try Producer("testing")
      producer.OnError = { XCTFail("producer error: \($0)") }
      let brokers = producer.connect(brokers: hosts)
      XCTAssertGreaterThanOrEqual(brokers, 1)
      let now = time(nil)
      try producer.send(message: "message test \(now)")
      var messages = [(String, String?)]()
      for i in 1 ... 10 {
        messages.append(("batch #\(i) -> \(now)", nil))
      }//next
      let r = try producer.send(messages: messages)
      XCTAssertEqual(r, messages.count)
      producer.flush(1)
    }catch(let err) {
      XCTFail("Producer \(err)")
    }
  }

  func testConsumer () {
    do {
      let k = try Kafka(type: .CONSUMER)
      print(k.name)
    }catch(let err) {
      XCTFail("Consumer \(err)")
    }
  }
    static var allTests : [(String, (PerfectKafkaTests) -> () throws -> Void)] {
        return [
            ("testConfig", testConfig),
            ("testTopicConfig", testTopicConfig),
            ("testProducer", testProducer),
            ("testConsumer", testConsumer)
        ]
    }
}
