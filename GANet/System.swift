//
//  System.swift
//  NetGen
//
//  Created by Aleksei Shchekochikhin on 21/08/2019.
//  Copyright © 2019 Aleksei Shchekochikhin. All rights reserved.
//

import Foundation

class System {
    static let shared = System()
    private init(){}
    
    func initSetup() {
        var res = [State]()
        for _ in 1 ... GenerativeModel.numberOfJenres {
            res.append(State())
        }
        jenresStates = res
        
        for _ in 1 ... GenerativeModel.initNumberOfAgents {
            let agent = Agent()
            register(agent)
            agent.postState()
        }
        observableAgentID = agents.first?.id
    }
    
    func getObservableAgentLatentVector() -> [Float] {
        let agent = agents.first{ (agent) -> Bool in
            return agent.id == observableAgentID
        }
        return agent!.currState.getCurrentLatentVector()
    }
    
    private var observableAgentID: UUID!
    
    func postStateFrom(_ agent:Agent) {
        currAgenStates[agent.id] = (agent.currState, agent.targetState, Date())
    }
    
    var jenresStates =  [State]()
    
    private var currAgenStates = [UUID: (state: State, target: State, postDate: Date)]()
    private var agents = [Agent]()
    
    fileprivate func register(_ agent: Agent) {
        agents.append(agent)
    }
    
    fileprivate func unregister(_ agent: Agent) {
        currAgenStates.removeValue(forKey: agent.id)
        agents.removeAll { (ag) -> Bool in
            ag.id == agent.id
        }
    }
    
    static func distance(st1: State, st2: State) -> Double {
        var result:Double = 0.0
        for i in 0 ... GenerativeModel.latentSpaceDimmensions - 1 {
            result += pow((Double(st1.vals[i] - st2.vals[i])), 2.0)
        }
//        result = result / Double((GenerativeModel.statePerParametr * GenerativeModel.statePerParametr * GenerativeModel.numberOfParametrs))
        result = sqrt(result)
        return result
    }
    
    func getTargetStates() -> [State] {
        return currAgenStates.map({ (value) -> State in
            return value.value.target
        })
    }
    
    func getCurrStates() -> [State] {
        return currAgenStates.map({ (value) -> State in
            return value.value.state
        })
    }
    
    func getDistances() -> [Double] {
        return currAgenStates.map({ (value) -> Double in
            return System.distance(st1: value.value.state, st2: value.value.target)
        }).sorted()
    }
    
    func getCurrStates(ecsept: UUID) -> [State] {
        var result = [State]()
        for pair in currAgenStates {
            if pair.key != ecsept {
                result.append(pair.value.state)
            }
        }
        
        return result
    }
    func update()  {
        for agent in agents {
            agent.mutate()
        }
    }
    
}

struct GenerativeModel {
    static let latentSpaceDimmensions = 512
    static let dimensionQuantize = 10
    static let numberOfJenres = 10
    static let initNumberOfAgents = 100
}

struct State {
    typealias StateVector = [Int]
    let vals: StateVector
    
    init(state: StateVector) {
        vals = state
    }
    
    init() {
        var res = [Int]()
        for _  in 1 ... GenerativeModel.latentSpaceDimmensions {
            res.append(Int.random(in: 0 ... GenerativeModel.dimensionQuantize - 1))
        }
        vals =  res
    }
    
    static func initNearJanre() -> State {
        var res = [Int]()
        let randomJanre = System.shared.jenresStates[Int.random(in: 0...GenerativeModel.numberOfJenres - 1)]
        for i in 0 ... GenerativeModel.latentSpaceDimmensions - 1{
            let currGenreParam = randomJanre.vals[i]
            let currAdd = (Bool.random() ? -1 : 1) * 1
            let currVal = max(0, min(currGenreParam + currAdd, GenerativeModel.dimensionQuantize - 1))
            res.append(currVal)
        }
    
        return State.init(state: res)
    }
    
    func getCurrentLatentVector() -> [Float] {
        return vals.map { (val) -> Float in
            return Float(val)/Float(GenerativeModel.dimensionQuantize)
        }
    }
}

class Agent {
    let id: UUID!
    private(set) var currState: State!
    let targetState: State!

    func postState() {
        System.shared.postStateFrom(self)
    }
    
    init() {
        id = UUID()
        currState = State()
        targetState = State.initNearJanre()
    }
    
    
    func mutate() {
        let all = System.shared.getCurrStates(ecsept: id).sorted { (st1, st2) -> Bool in
            return System.distance(st1: targetState, st2: st1) < System.distance(st1: targetState, st2: st2)
        }
        let nearest = all.first!
        
        //crosover
        let crossoverPoint = Int.random(in: 0...GenerativeModel.latentSpaceDimmensions - 1)
        
        var newStateVals = [Int]()
        for i in 0 ... GenerativeModel.latentSpaceDimmensions - 1 {
            newStateVals.append( i < crossoverPoint ? currState!.vals[i] : nearest.vals[i])
        }

        //random mutation
        let muatationPoint = Int.random(in: 0...GenerativeModel.latentSpaceDimmensions - 1)
        newStateVals[muatationPoint] = Int.random(in: 0 ... GenerativeModel.dimensionQuantize - 1)
        currState = State(state: newStateVals)
        postState()
    }
}
