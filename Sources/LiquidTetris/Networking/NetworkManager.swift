import Foundation
import MultipeerConnectivity
import Combine

// MARK: - Message Types

enum MessageType: String, Codable {
    case gameState
    case garbageLines
    case gameStart
    case gameOver
    case pieceInfo
    case chat
}

struct GameMessage: Codable {
    let type: MessageType
    let payload: Data
    let timestamp: TimeInterval

    init(type: MessageType, payload: Data) {
        self.type = type
        self.payload = payload
        self.timestamp = Date().timeIntervalSince1970
    }
}

struct GameStatePayload: Codable {
    let grid: [[Cell]]
    let score: Int
    let level: Int
    let linesCleared: Int
    let isGameOver: Bool
    let currentPieceType: TetrominoType?
    let nextPieceType: TetrominoType?
}

struct GarbagePayload: Codable {
    let lines: Int
}

// MARK: - Connection State

enum ConnectionState: Equatable {
    case idle
    case searching
    case hosting
    case connecting
    case connected
    case gameStarted
    case disconnected
}

// MARK: - Network Manager

class NetworkManager: NSObject, ObservableObject {
    static let shared = NetworkManager()

    private let serviceType = "liquid-tetris"
    private let peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    @Published var connectionState: ConnectionState = .idle
    @Published var connectedPeer: MCPeerID?
    @Published var discoveredPeers: [MCPeerID] = []

    var onGameStateReceived: ((GameStatePayload) -> Void)?
    var onGarbageReceived: ((Int) -> Void)?
    var onGameStartReceived: (() -> Void)?
    var onGameEndReceived: (() -> Void)?

    override init() {
        let hostname = Host.current().localizedName ?? "Player"
        self.peerID = MCPeerID(displayName: hostname)
        super.init()
    }

    deinit {
        stopAll()
    }

    // MARK: - Host

    func hostGame() {
        stopAll()

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        DispatchQueue.main.async {
            self.connectionState = .hosting
        }
    }

    // MARK: - Join

    func joinGame() {
        stopAll()

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser

        DispatchQueue.main.async {
            self.connectionState = .searching
        }
    }

    // MARK: - Auto Connect (tries host, then join)

    func autoConnect() {
        connectionState = .searching
        joinGame()

        // If no peers found in 2s, switch to hosting
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.connectionState == .searching else { return }
            self.hostGame()
        }
    }

    // MARK: - Send

    func sendGameState(_ state: GameStatePayload) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(state)
            let message = GameMessage(type: .gameState, payload: data)
            let msgData = try JSONEncoder().encode(message)
            try session.send(msgData, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Failed to send game state: \(error)")
        }
    }

    func sendGarbage(_ lines: Int) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(GarbagePayload(lines: lines))
            let message = GameMessage(type: .garbageLines, payload: data)
            let msgData = try JSONEncoder().encode(message)
            try session.send(msgData, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Failed to send garbage: \(error)")
        }
    }

    func sendGameStart() {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        do {
            let message = GameMessage(type: .gameStart, payload: Data())
            let msgData = try JSONEncoder().encode(message)
            try session.send(msgData, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Failed to send game start: \(error)")
        }
    }

    func sendGameOver() {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        do {
            let message = GameMessage(type: .gameOver, payload: Data())
            let msgData = try JSONEncoder().encode(message)
            try session.send(msgData, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Failed to send game over: \(error)")
        }
    }

    // MARK: - Stop

    func stopAll() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        connectedPeer = nil
        discoveredPeers = []
        DispatchQueue.main.async {
            self.connectionState = .idle
        }
    }
}

// MARK: - MCSessionDelegate

extension NetworkManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.connectionState = .connected
            case .notConnected:
                self.connectedPeer = nil
                self.connectionState = .disconnected
            case .connecting:
                self.connectionState = .connecting
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(GameMessage.self, from: data) else { return }

        DispatchQueue.main.async {
            switch message.type {
            case .gameState:
                if let state = try? JSONDecoder().decode(GameStatePayload.self, from: message.payload) {
                    self.onGameStateReceived?(state)
                }
            case .garbageLines:
                if let garbage = try? JSONDecoder().decode(GarbagePayload.self, from: message.payload) {
                    self.onGarbageReceived?(garbage.lines)
                }
            case .gameStart:
                self.connectionState = .gameStarted
                self.onGameStartReceived?()
            case .gameOver:
                self.onGameEndReceived?()
            case .chat:
                break
            case .pieceInfo:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension NetworkManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Advertiser error: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension NetworkManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Browser error: \(error)")
    }
}
