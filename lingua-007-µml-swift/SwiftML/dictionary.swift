// -------------------------------------------------------------------------- //
// SwiftML                                                                    //
// -------------------------------------------------------------------------- //

extension Dictionary {
  init(_ pairs: [Element]) {
    self.init(minimumCapacity: pairs.count)

    for (k, v) in pairs {
      self[k] = v
    }
  }

  func mapValues<T>(fn: @escaping (Value) -> T) -> Dictionary<Key, T> {
    return Dictionary<Key, T>(self.map { (k, v) in (k, fn(v)) })
  }

  mutating func get(key: Key, orUpdate: @autoclosure () -> Value) -> Value {
    if let value = self[key] {
      return value
    } else {
      let value = orUpdate()
      self[key] = value
      return value
    }
  }
}
