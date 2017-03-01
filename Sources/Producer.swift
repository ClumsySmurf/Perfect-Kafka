//
//  Producer.swift
//  Perfect-Kafka
//
//  Created by Rockford Wei on 2017-03-01.
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

import ckafka

public class KafkaProducer: Kafka {

  internal var topicHandle: OpaquePointer? = nil

  internal var topicName = ""

  public var topic: String { get { return topicName } }

  internal var sequenceId = 0

  internal var queue = Set<UnsafeMutablePointer<Int>>()

  public static var producers:[OpaquePointer: KafkaProducer] = [:]

  public func pop(_ msgId: UnsafeMutableRawPointer?) {
    guard let ticket = msgId else { return }
    let t = unsafeBitCast(ticket, to: UnsafeMutablePointer<Int>.self)
    queue.remove(t)
    t.deallocate(capacity: 1)
  }//end pop

  init(_ topic: String, topicConfig: TopicConfig? = nil, globalConfig: Config? = nil) throws {
    topicName = topic
    let gConf = try ( globalConfig ?? (try Config()))

    rd_kafka_conf_set_dr_cb(gConf.conf, { rk, _, _, _, _, ticket in
      guard let producer = KafkaProducer.producers[rk!] else { return }
      producer.pop(ticket)
      print("                          found something to pop")
    })
    try super.init(type: .PRODUCER, config: gConf)
    if let tConf = topicConfig {
      guard let h = rd_kafka_topic_new(_handle, topic, tConf.conf) else {
        #if os(Linux)
          throw Exception.UNKNOWN
        #else
          let reason = rd_kafka_errno2err(errno)
          throw Exception(rawValue: reason.rawValue) ?? Exception.UNKNOWN
        #endif
      }//end guard
      topicHandle = h
    }else {
      guard let h = rd_kafka_topic_new(_handle, topic, nil) else {
        #if os(Linux)
          throw Exception.UNKNOWN
        #else
          let reason = rd_kafka_errno2err(errno)
          throw Exception(rawValue: reason.rawValue) ?? Exception.UNKNOWN
        #endif
      }//end guard
      topicHandle = h
    }//end guard
    KafkaProducer.producers[_handle] = self
  }//end init

  public func flush(_ timeout: Int) {
    let then = time(nil)
    var now = time(nil)
    let limitation = time_t(timeout)
    while(!queue.isEmpty && limitation > (now - then)) {
      rd_kafka_poll(_handle, 100)
      now = time(nil)
    }//end while
  }//end flush

  deinit {
    guard let h = topicHandle else { return }
    // there may be some messages in queue waiting to send, so wait for at least one second
    rd_kafka_topic_destroy(h)
    queue.forEach { $0.deallocate(capacity: 1) }
  }//end

  public func send(message: String, key: String? = nil) throws {
    var r:Int32 = 0
    sequenceId += 1
    let ticket = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    ticket.pointee = sequenceId

    if let k = key {
      r = rd_kafka_produce(topicHandle, RD_KAFKA_PARTITION_UA, RD_KAFKA_MSG_F_FREE, strdup(message), message.utf8.count, k, k.utf8.count, ticket)
    }else{
      r = rd_kafka_produce(topicHandle, RD_KAFKA_PARTITION_UA, RD_KAFKA_MSG_F_FREE, strdup(message), message.utf8.count, nil, 0, ticket)
    }//end if
    if r == 0 {
      queue.insert(ticket)
      return
    }//end if
    ticket.deallocate(capacity: 1)
    #if os(Linux)
      throw Exception.UNKNOWN
    #else
      let reason = rd_kafka_errno2err(errno)
      throw Exception(rawValue: reason.rawValue) ?? Exception.UNKNOWN
    #endif
  }
}