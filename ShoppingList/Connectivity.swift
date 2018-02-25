//
//  Connectivity.swift
//  Groceries
//
//  Created by David Brownstone on 14/02/2018.
//  Copyright © 2018 Brownstone LLC. All rights reserved.
//

import Foundation
import Alamofire


class Connectivity {
  class func isConnectedToInternet() ->Bool {
    return NetworkReachabilityManager()!.isReachable
  }
}
