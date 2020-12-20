//
//  Cache.swift
//  Alphabet
//
//  Created by Daniel Dähling on 19.12.20.
//

import Foundation

final class Cache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider : () -> Date
    private let entryLifetime : TimeInterval
    private let keyTracker = KeyTracker()
    
    init(entryLifetime: TimeInterval = 12 * 60 * 60,
         dateProvider: @escaping () -> Date = Date.init,
         maximumEntryCount : Int = 50
    ) {
        self.dateProvider = dateProvider
        self.entryLifetime = entryLifetime
        wrapped.countLimit = maximumEntryCount
        wrapped.delegate = keyTracker
    }
    
    func insertValue(_ value: Value, for key: Key) {
        let expirationDate = dateProvider().addingTimeInterval(entryLifetime)
        wrapped.setObject(Entry(value: value, expirationDate: expirationDate, key: key), forKey: WrappedKey(key))
        keyTracker.keys.insert(key)
    }
    
    func value(for key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else { return nil }
        if entry.expirationDate > dateProvider() {
            removeValue(for: key)
            return nil
        } else {
            return entry.value
        }
    }
    
    func removeValue(for key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }
    
    subscript(key: Key) -> Value? {
        get {
            return value(for: key)
        }
        set {
            guard let value = newValue else {
                removeValue(for: key)
                return
            }
            insertValue(value, for: key)
        }
    }
    
    final class WrappedKey: NSObject {
            let key: Key

            init(_ key: Key) { self.key = key }

            override var hash: Int { return key.hashValue }

            override func isEqual(_ object: Any?) -> Bool {
                guard let value = object as? WrappedKey else {
                    return false
                }

                return value.key == key
            }
        }
    
    final class Entry {
        let value: Value
        let expirationDate: Date
        let key : Key

        init(value: Value, expirationDate: Date, key: Key) {
            self.value = value
            self.expirationDate = expirationDate
            self.key = key
        }
    }
    
    final class KeyTracker: NSObject, NSCacheDelegate {
        
        var keys = Set<Key>()
        
        func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
            guard let entry = obj as? Entry else {
                return
            }
            
            keys.remove(entry.key)
        }
    }
}

extension Cache.Entry: Codable where Key: Codable, Value: Codable {}

private extension Cache {
    func entry(for key: Key) -> Entry? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)),
              entry.expirationDate > dateProvider() else {
            return nil
        }
        return entry
    }
    
    func insert(_ entry: Entry) {
        wrapped.setObject(entry, forKey: WrappedKey(entry.key))
        keyTracker.keys.insert(entry.key)
    }
}

extension Cache: Codable where Key: Codable, Value: Codable {
    convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }
    
    func encode(to encoder: Encoder) throws {
        let entries = keyTracker.keys.compactMap(entry)
        var container = encoder.singleValueContainer()
        try container.encode(entries)
    }
    
    func saveToDisk(with name: String, using fileManager: FileManager) throws {
        let encoder = JSONEncoder()
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let url = urls[0]
            .appendingPathComponent(name)
            .appendingPathExtension("cache")
            
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}


