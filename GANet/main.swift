//
//  main.swift
//  GANet
//
//  Created by Aleksei Shchekochikhin on 04/11/2019.
//  Copyright © 2019 Aleksei Shchekochikhin. All rights reserved.
//

import Foundation

print("Hello, World!")

let system = System.shared
system.initSetup()

var oservableEvolution = [[Float]]()
    
for i in 0 ... 20 {
    print("Drawing iteration: \(i)")
    oservableEvolution.append(System.shared.getObservableAgentLatentVector())
    System.shared.update()
}


print(oservableEvolution)

