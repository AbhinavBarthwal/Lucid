import Foundation
import Supabase

@MainActor
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://cemqltesxmfjtykduqoi.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNlbXFsdGVzeG1manR5a2R1cW9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyMTQzNTIsImV4cCI6MjA5Mjc5MDM1Mn0.dTD4hAmdZoPcEuLHJ7p68xD2veVktrCy8M5360mzg5A",
        options: .init(
            auth: .init(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
    
    func syncUser(_ user: User) async {
        let data: [String: AnyJSON] = [
            "id": .string(user.id.uuidString),
            "name": .string(user.name),
            "age": .integer(user.age),
            "email": .string(user.email ?? ""),
            "password": .string(user.password ?? ""),
            "gender": .string(user.gender ?? "Not Specified"),
            "left_eye_power": .double(user.leftEyePower),
            "right_eye_power": .double(user.rightEyePower),
            "previous_conditions": .array(user.previousConditions.map { .string($0) })
        ]
        
        do {
            try await client.from("users").upsert(data).execute()
            print("☁️ Profile Synced to Supabase")
        } catch {
            print("❌ Profile Sync Error: \(error)")
        }
    }
    
    func checkUserExists(email: String) async -> Bool {
        guard !email.isEmpty else { return false }
        do {
            let response = try await client.from("users")
                .select("id")
                .eq("email", value: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
                .execute()
            
            let data = response.data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], !json.isEmpty {
                return true
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], !json.isEmpty {
                return true
            }
            return false
        } catch {
            print("checkUserExists error: \(error)")
            return false
        }
    }
    
    func checkUserExists(id: UUID) async -> Bool {
        do {
            let response = try await client.from("users")
                .select("id")
                .eq("id", value: id.uuidString)
                .execute()
            
            let data = response.data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], !json.isEmpty {
                return true
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], !json.isEmpty {
                return true
            }
            return false
        } catch {
            print("checkUserExists by id error: \(error)")
            return false
        }
    }
    
    func verifyPassword(email: String, passwordToVerify: String) async -> Bool {
        guard !email.isEmpty else { return false }
        do {
            let response = try await client.from("users")
                .select("password")
                .eq("email", value: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
                .execute()
            
            if let jsonArray = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]],
               let json = jsonArray.first,
               let password = json["password"] as? String {
                return password == passwordToVerify
            }
            return false
        } catch {
            return false
        }
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(idToken: String, nonce: String? = nil) async -> (email: String?, uid: UUID?) {
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            print("☁️ Apple Sign-In successful. User ID: \(session.user.id)")
            return (session.user.email, session.user.id)
        } catch {
            print("❌ Apple Sign-In error: \(error)")
            return (nil, nil)
        }
    }
    
    // Fetches user profile from Supabase and applies it to local SwiftData User
    func fetchAndApplyUser(byEmail email: String, to localUser: User) async -> Bool {
         guard !email.isEmpty else { return false }
         do {
             let response = try await client.from("users")
                 .select()
                 .eq("email", value: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
                 .execute()
             
             let data = response.data
             let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
             if let json = jsonArray?.first {
                 if let idString = json["id"] as? String, let newId = UUID(uuidString: idString) {
                     localUser.id = newId
                 }
                 if let name = json["name"] as? String { localUser.name = name }
                 if let age = json["age"] as? Int { localUser.age = age }
                 if let gender = json["gender"] as? String { localUser.gender = gender }
                 if let left = (json["left_eye_power"] as? NSNumber)?.doubleValue { localUser.leftEyePower = left }
                 if let right = (json["right_eye_power"] as? NSNumber)?.doubleValue { localUser.rightEyePower = right }
                 if let conditions = json["previous_conditions"] as? [String] { localUser.previousConditions = conditions }
                 if let password = json["password"] as? String { localUser.password = password }
                 
                 // Parse OSDI history
                 if let osdiArray = json["osdi_history"] as? [[String: Any]] {
                     var sessions: [OSDISession] = []
                     let formatter = ISO8601DateFormatter()
                     for item in osdiArray {
                         if let score = item["score"] as? Double,
                            let severity = item["detail"] as? String {
                             let dateString = item["date"] as? String ?? ""
                             let date = formatter.date(from: dateString) ?? Date()
                             let session = OSDISession(score: score, severity: severity)
                             session.date = date
                             sessions.append(session)
                         }
                     }
                     SwiftDataManager.shared.importOSDISessions(sessions)
                 }
                 
                 // Parse C-Test history
                 if let ctestArray = json["ctest_history"] as? [[String: Any]] {
                     var sessions: [CTestSession] = []
                     let formatter = ISO8601DateFormatter()
                     for item in ctestArray {
                         if let score = item["score"] as? Double,
                            let eye = item["detail"] as? String {
                             let dateString = item["date"] as? String ?? ""
                             let date = formatter.date(from: dateString) ?? Date()
                             let session = CTestSession(score: score, eye: eye)
                             session.startingTime = date
                             session.endingTime = date
                             sessions.append(session)
                         }
                     }
                     SwiftDataManager.shared.importCTestSessions(sessions)
                 }
                 
                 print("☁️ Fetched existing profile and history from Supabase")
                 await MainActor.run {
                     RecommendationEngine.shared.generateRecommendations()
                 }
                 return true
             }
         } catch {
             print("☁️ No existing profile found or fetch error: \(error)")
         }
         return false
     }

    func fetchAndApplyUser(byId id: UUID, to localUser: User) async -> Bool {
        do {
            let response = try await client.from("users")
                .select()
                .eq("id", value: id.uuidString)
                .execute()
            
            let data = response.data
            let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            if let json = jsonArray?.first {
                localUser.id = id
                if let email = json["email"] as? String { localUser.email = email }
                if let name = json["name"] as? String { localUser.name = name }
                if let age = json["age"] as? Int { localUser.age = age }
                if let gender = json["gender"] as? String { localUser.gender = gender }
                if let left = (json["left_eye_power"] as? NSNumber)?.doubleValue { localUser.leftEyePower = left }
                if let right = (json["right_eye_power"] as? NSNumber)?.doubleValue { localUser.rightEyePower = right }
                if let conditions = json["previous_conditions"] as? [String] { localUser.previousConditions = conditions }
                if let password = json["password"] as? String { localUser.password = password }
                
                // Parse OSDI history
                if let osdiArray = json["osdi_history"] as? [[String: Any]] {
                    var sessions: [OSDISession] = []
                    let formatter = ISO8601DateFormatter()
                    for item in osdiArray {
                        if let score = item["score"] as? Double,
                           let severity = item["detail"] as? String {
                            let dateString = item["date"] as? String ?? ""
                            let date = formatter.date(from: dateString) ?? Date()
                            let session = OSDISession(score: score, severity: severity)
                            session.date = date
                            sessions.append(session)
                        }
                    }
                    SwiftDataManager.shared.importOSDISessions(sessions)
                }
                
                // Parse C-Test history
                if let ctestArray = json["ctest_history"] as? [[String: Any]] {
                    var sessions: [CTestSession] = []
                    let formatter = ISO8601DateFormatter()
                    for item in ctestArray {
                        if let score = item["score"] as? Double,
                           let eye = item["detail"] as? String {
                            let dateString = item["date"] as? String ?? ""
                            let date = formatter.date(from: dateString) ?? Date()
                            let session = CTestSession(score: score, eye: eye)
                            session.startingTime = date
                            session.endingTime = date
                            sessions.append(session)
                        }
                    }
                    SwiftDataManager.shared.importCTestSessions(sessions)
                }
                
                print("☁️ Fetched existing profile and history from Supabase by ID")
                await MainActor.run {
                    RecommendationEngine.shared.generateRecommendations()
                }
                return true
            }
        } catch {
            print("☁️ No existing profile found or fetch error by ID: \(error)")
        }
        return false
    }

    
    // Appends OSDI scores to the history array
    func appendOSDIScore(score: Double, severity: String) async {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let entry: [String: AnyJSON] = [
            "date": .string(Date().ISO8601Format()),
            "score": .double(score),
            "detail": .string(severity)
        ]
        
        let params: [String: AnyJSON] = [
            "user_id": .string(user.id.uuidString),
            "new_entry": .object(entry)
        ]
        
        do {
            try await client.rpc("append_osdi_history", params: params).execute()
            print("☁️ OSDI History Updated")
        } catch {
            print("❌ OSDI History Error: \(error)")
        }
    }
    
    // Appends C-Test scores to the history array
    func appendCTestScore(score: Double, eye: String) async {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let entry: [String: AnyJSON] = [
            "date": .string(Date().ISO8601Format()),
            "score": .double(score),
            "detail": .string(eye)
        ]
        
        let params: [String: AnyJSON] = [
            "user_id": .string(user.id.uuidString),
            "new_entry": .object(entry)
        ]
        
        do {
            try await client.rpc("append_ctest_history", params: params).execute()
            print("☁️ C-Test History Updated")
        } catch {
            print("❌ C-Test History Error: \(error)")
        }
    }
}
